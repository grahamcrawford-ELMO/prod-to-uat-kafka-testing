"""Snowflake + AWS connection setup.

Snowflake auth mirrors the BI harness: externalbrowser SSO by default with the
token cached so re-runs don't re-prompt, falling back to password or key-pair.
Secondary roles matter more here than in the BI comparison because UAT_DB and
PROD_DB are rarely visible to one primary role.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path


def load_dotenv(path=".env", override=False):
    """Minimal .env loader - no extra dependency. Real env vars win unless override."""
    p = Path(path)
    if not p.exists():
        return
    for line in p.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        key, val = key.strip(), val.strip().strip("'\"")
        if override:
            os.environ[key] = val
        else:
            os.environ.setdefault(key, val)


def connect_snowflake(cfg):
    import snowflake.connector

    conn_cfg = cfg.get("connection") or {}
    params = dict(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        role=os.getenv("SNOWFLAKE_ROLE") or conn_cfg.get("role"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE") or conn_cfg.get("warehouse"),
        session_parameters={"QUERY_TAG": conn_cfg.get("query_tag", "dwi_migration_testing")},
    )
    if not params["account"] or not params["user"]:
        sys.exit("SNOWFLAKE_ACCOUNT and SNOWFLAKE_USER must be set (in .env or the environment).")

    authenticator = (os.getenv("SNOWFLAKE_AUTHENTICATOR") or "").lower()
    password = os.getenv("SNOWFLAKE_PASSWORD")
    key_path = os.getenv("SNOWFLAKE_PRIVATE_KEY_PATH")

    if authenticator == "externalbrowser":
        params["authenticator"] = "externalbrowser"
        params["client_store_temporary_credential"] = True
    elif password:
        params["password"] = password
    elif key_path:
        from cryptography.hazmat.primitives import serialization
        passphrase = os.getenv("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE")
        with open(key_path, "rb") as f:
            pkey = serialization.load_pem_private_key(
                f.read(), password=passphrase.encode() if passphrase else None)
        params["private_key"] = pkey.private_bytes(
            encoding=serialization.Encoding.DER,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
    else:
        sys.exit("Set SNOWFLAKE_AUTHENTICATOR=externalbrowser, SNOWFLAKE_PASSWORD, "
                 "or SNOWFLAKE_PRIVATE_KEY_PATH (in .env or the environment).")

    conn = snowflake.connector.connect(**params)

    # Comparing UAT_DB to PROD_DB usually needs more than one role. Prefer an
    # explicit list: ALL can trip row-level-security scalar subqueries (090150)
    # when several mapped roles are in session.
    sec = conn_cfg.get("use_secondary_roles", True)
    if sec:
        stmt = ("USE SECONDARY ROLES ALL" if sec is True
                else "USE SECONDARY ROLES " + ", ".join(sec))
        cur = conn.cursor()
        try:
            cur.execute(stmt)
        finally:
            cur.close()
    return conn


def s3_client(cfg):
    """boto3 S3 client. Region/profile come from config or the usual AWS env vars."""
    import boto3

    aws = cfg.get("aws") or {}

    # An EMPTY value must be treated as unset, not as a profile named "".
    # env.example ships `AWS_PROFILE=` as a placeholder, and the .env loader
    # sets it verbatim, so boto3 would raise ProfileNotFound: profile ().
    def _first(*vals):
        for v in vals:
            if v is not None and str(v).strip() != "":
                return str(v).strip()
        return None

    session_kwargs = {}
    profile = _first(aws.get("profile"), os.getenv("AWS_PROFILE"))
    if profile:
        session_kwargs["profile_name"] = profile
    region = _first(aws.get("region"), os.getenv("AWS_DEFAULT_REGION"),
                    os.getenv("AWS_REGION"))
    if region:
        session_kwargs["region_name"] = region

    try:
        return boto3.Session(**session_kwargs).client("s3")
    except Exception as exc:
        name = type(exc).__name__
        if "ProfileNotFound" in name:
            sys.exit(
                f"AWS profile {profile!r} not found.\n"
                "  - If you use SSO/named profiles, set AWS_PROFILE in .env to a real\n"
                "    profile from ~/.aws/config (list them: aws configure list-profiles).\n"
                "  - If you use env-var or instance credentials, remove the AWS_PROFILE\n"
                "    line from .env entirely (or leave it blank - blank is now ignored)."
            )
        raise
