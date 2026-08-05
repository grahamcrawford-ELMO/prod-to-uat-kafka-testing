"""Locating and reading the two sides' CSV extracts in S3.

Redshift  : s3://p-elmo-data-cap/landing/data-warehouse-integration/{client}/{ts}/{view}.csv
Snowflake : s3://p-elmo-data-cap/landing/data-warehouse-integration/snowflake_outbound/{client}/{ts}/{view}.csv

Both unload DAGs write a {ts} folder per run (TIME_FORMAT = %Y%m%d%H%M%S,
Australia/Sydney) and the two sides never share a timestamp, so run folders are
paired by "latest on each side" unless overridden.

Both DAGs also PGP-encrypt in place and move originals to processed/{client}/{ts}/,
so a finished run leaves only .csv.pgp behind. discover_run() therefore prefers a
run folder that still holds plain .csv and reports when only .pgp remains.
"""

from __future__ import annotations

import csv
import io
import logging
import re
from dataclasses import dataclass, field

TS_RE = re.compile(r"^\d{14}$")


@dataclass
class RunFolder:
    side: str
    bucket: str
    prefix: str          # no trailing slash
    timestamp: str
    files: dict = field(default_factory=dict)   # view_name -> key
    encrypted_only: bool = False

    @property
    def uri(self):
        return f"s3://{self.bucket}/{self.prefix}"


def split_uri(uri):
    body = uri[len("s3://"):] if uri.startswith("s3://") else uri
    bucket, _, key = body.partition("/")
    return bucket, key.strip("/")


class S3Source:
    def __init__(self, s3_client, csv_cfg):
        self.s3 = s3_client
        base = csv_cfg["redshift_base"].rstrip("/")
        snow = csv_cfg["snowflake_base"].rstrip("/")
        self.redshift_bucket, self.redshift_prefix = split_uri(base)
        self.snowflake_bucket, self.snowflake_prefix = split_uri(snow)
        self.encoding = csv_cfg.get("encoding", "utf-8")
        self.delimiter = csv_cfg.get("delimiter", ",")

    # -- discovery ----------------------------------------------------------

    def _list_dirs(self, bucket, prefix):
        out, token = [], None
        while True:
            kw = {"Bucket": bucket, "Prefix": prefix + "/", "Delimiter": "/"}
            if token:
                kw["ContinuationToken"] = token
            resp = self.s3.list_objects_v2(**kw)
            for cp in resp.get("CommonPrefixes", []):
                out.append(cp["Prefix"].rstrip("/").rsplit("/", 1)[-1])
            if not resp.get("IsTruncated"):
                return out
            token = resp.get("NextContinuationToken")

    def _list_keys(self, bucket, prefix):
        out, token = [], None
        while True:
            kw = {"Bucket": bucket, "Prefix": prefix + "/"}
            if token:
                kw["ContinuationToken"] = token
            resp = self.s3.list_objects_v2(**kw)
            out.extend(o["Key"] for o in resp.get("Contents", []))
            if not resp.get("IsTruncated"):
                return out
            token = resp.get("NextContinuationToken")

    def list_runs(self, side, client):
        bucket, base = self._side(side)
        dirs = self._list_dirs(bucket, f"{base}/{client}")
        return sorted(d for d in dirs if TS_RE.match(d))

    def _side(self, side):
        if side == "redshift":
            return self.redshift_bucket, self.redshift_prefix
        if side == "snowflake":
            return self.snowflake_bucket, self.snowflake_prefix
        raise ValueError(f"unknown side {side!r}")

    def discover_run(self, side, client, timestamp=None, prefer_plain_csv=True):
        """Resolve one side's run folder.

        With no timestamp, walks candidate runs newest-first and returns the
        first that still contains plain .csv files. If every run is already
        encrypted, returns the newest with encrypted_only=True so the caller
        can report BLOCKED instead of silently comparing nothing.
        """
        bucket, base = self._side(side)
        runs = [timestamp] if timestamp else list(reversed(self.list_runs(side, client)))
        if not runs or runs == [None]:
            raise FileNotFoundError(f"No run folders for {side}/{client} under s3://{bucket}/{base}")
        newest_encrypted = None
        for ts in runs:
            prefix = f"{base}/{client}/{ts}"
            keys = self._list_keys(bucket, prefix)
            plain = {}
            enc = False
            for key in keys:
                name = key.rsplit("/", 1)[-1]
                low = name.lower()
                if low.endswith(".pgp"):
                    enc = True
                    continue
                if low == "marker.json":
                    continue
                if ".csv" not in low:
                    continue
                view = low.split(".csv", 1)[0]
                plain[view] = key
            run = RunFolder(side, bucket, prefix, ts, plain, encrypted_only=bool(enc and not plain))
            if plain or not prefer_plain_csv or timestamp:
                return run
            if run.encrypted_only and newest_encrypted is None:
                newest_encrypted = run
        return newest_encrypted or RunFolder(side, bucket, f"{base}/{client}/{runs[0]}", runs[0], {}, True)

    # -- reading ------------------------------------------------------------

    def read_csv(self, run: RunFolder, view):
        """Yield (header, row_iterator) for one view's CSV.

        Streams the object rather than materialising the whole body twice, and
        lowercases the header so the Snowflake side's lowercase aliasing and
        Redshift's native lowercase agree on names.
        """
        key = run.files[view]
        body = self.s3.get_object(Bucket=run.bucket, Key=key)["Body"]
        text = io.TextIOWrapper(body, encoding=self.encoding, newline="")
        reader = csv.reader(text, delimiter=self.delimiter)
        try:
            header = next(reader)
        except StopIteration:
            return [], iter(())
        header = [h.strip().lstrip("\ufeff").lower() for h in header]
        return header, reader

    def shared_views(self, left: RunFolder, right: RunFolder):
        l, r = set(left.files), set(right.files)
        return sorted(l & r), sorted(l - r), sorted(r - l)


def pair_runs(source: S3Source, client, redshift_ts=None, snowflake_ts=None):
    """Pair the latest (or pinned) run folder on each side."""
    rs = source.discover_run("redshift", client, redshift_ts)
    sf = source.discover_run("snowflake", client, snowflake_ts)
    logging.info("%s: redshift %s <-> snowflake %s", client, rs.timestamp, sf.timestamp)
    return rs, sf
