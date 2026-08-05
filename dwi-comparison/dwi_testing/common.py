"""Shared vocabulary for both comparison modes.

Statuses, verdicts, config normalisation (exclude_columns / accepted_columns /
accept_diff) and the value-normalisation rules that decide whether two rendered
values are "the same". Kept deliberately free of boto3/snowflake imports so it
can be unit-tested offline.
"""

from __future__ import annotations

import re
from decimal import Decimal, InvalidOperation

PASS, FAIL, SKIP, ERR, BLOCKED = "PASS", "FAIL", "SKIPPED", "ERROR", "BLOCKED"
ACC = "ACCEPTED"

# Tiers an accept_diff override may target. Structural tiers (C0/C1, D0) are
# deliberately excluded: schema/header drift stays a hard stop, exactly as T0
# does in the BI ladder.
CSV_TIERS = ("C2", "C3", "C4", "C5")
DWI_TIERS = ("D1", "D2", "D3", "D4")


def col_map(cfg, key):
    """Normalise exclude_columns to {name: reason}."""
    out = {}
    for item in (cfg.get(key) or []):
        if isinstance(item, dict):
            out[item["column"]] = item.get("reason", "")
        else:
            out[str(item)] = ""
    return out


def accepted_columns_map(cfg):
    """Normalise accepted_columns to {name: {"reason": str, "where": str|None}}.

    Same contract as the BI harness: omit `where` to accept the whole column,
    supply `where` to accept only the mismatches matching a known pattern so
    the residual still counts as a genuine diff.
    """
    out = {}
    for item in (cfg.get("accepted_columns") or []):
        if isinstance(item, dict):
            out[item["column"]] = {
                "reason": item.get("reason", ""),
                "where": item.get("where"),
            }
        else:
            out[str(item)] = {"reason": "", "where": None}
    return out


def accept_diff_map(cfg, tier_names, notes=None):
    """Normalise accept_diff to {TIER: reason_or_None}.

    Accepts true / "C2" / [C2, C4] / {C2: "reason"} / [{tier:, reason:}],
    matching the BI harness so config habits carry over. Unknown tiers are
    dropped with a note rather than silently doing nothing.
    """
    raw = cfg.get("accept_diff")
    out = {}
    if not raw:
        return out
    if raw is True:
        return {t: None for t in tier_names}
    if isinstance(raw, dict):
        items = [{"tier": k, "reason": v} for k, v in raw.items()]
    elif isinstance(raw, (list, tuple)):
        items = raw
    else:
        items = [raw]
    for item in items:
        if isinstance(item, dict):
            tier, reason = item.get("tier"), item.get("reason")
        else:
            tier, reason = item, None
        tier = str(tier).upper()
        reason = reason if isinstance(reason, str) else None
        if tier not in tier_names:
            if notes is not None:
                notes.append(
                    f"accept_diff references unknown tier '{tier}' "
                    f"(expected one of {', '.join(tier_names)}) - ignored."
                )
            continue
        out[tier] = reason
    return out


def within_threshold(count, denom, threshold_pct):
    """True if a non-zero difference is small enough to be ACCEPTED."""
    if not threshold_pct or not denom or not count:
        return False
    return (100.0 * count / denom) <= float(threshold_pct)


def verdict_from(statuses, has_accepted_columns=False, dry_run=False,
                 no_grain=False):
    """Collapse tier statuses into one verdict.

    no_grain=True means the row-level tiers were skipped because no grain is
    configured. That is NOT a clean pass: the remaining tiers cannot see a row
    that changed in place without changing the row count or the fingerprint
    input, so it gets its own verdict rather than borrowing PASS.
    """
    sts = set(statuses)
    if dry_run or (sts and sts <= {"DRY", SKIP}):
        # Nothing executed - never report PASS for a dry run.
        return "DRY"
    if ERR in sts:
        return ERR
    if FAIL in sts:
        return "DIFFS FOUND"
    if ACC in sts or has_accepted_columns:
        return "PASS (DIFFS ACCEPTED, NO GRAIN)" if no_grain else "PASS (DIFFS ACCEPTED)"
    if sts <= {PASS, SKIP, "DRY"}:
        return "PASS (NO GRAIN)" if no_grain else PASS
    return "DIFFS FOUND"


# ---------------------------------------------------------------------------
# Value normalisation
#
# The two pipelines render the same instant/number/flag differently even when
# the underlying data agrees. unload_snowflake_views_to_s3.py already pins
# TIMESTAMP_*/DATE/TIME output formats and uses NULL_IF = () to match Redshift
# UNLOAD, so most of this is a second line of defence for the residue: numeric
# scale, boolean spelling, trailing whitespace and the blank-vs-NULL quirk.
# ---------------------------------------------------------------------------

_TRUE = {"true", "t", "1", "yes", "y"}
_FALSE = {"false", "f", "0", "no", "n"}
_NUMERIC_RE = re.compile(r"^-?\d+(\.\d+)?$")
_TS_TRAILING_ZEROS = re.compile(r"^(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2})(\.0+)?(\+00:?00|Z)?$")


class Normaliser:
    """Turns a raw CSV cell into its comparison form.

    Every rule is individually switchable from config so a genuine difference
    is never hidden by a normalisation you did not ask for.
    """

    def __init__(self, opts=None):
        o = opts or {}
        self.trim = o.get("trim_text", True)
        self.blank_as_null = o.get("blank_as_null", True)
        self.null_tokens = {str(t).lower() for t in o.get("null_tokens", ["", "null", "\\n"])}
        self.numeric_scale = o.get("numeric_scale")          # e.g. 2 -> compare to 2dp
        self.normalise_booleans = o.get("normalise_booleans", True)
        self.normalise_timestamps = o.get("normalise_timestamps", True)
        self.case_insensitive = o.get("case_insensitive", False)
        # Columns where 1/0 mean true/false. Numeric tokens are NEVER treated as
        # booleans outside this list - otherwise an id of 1 normalises to "true"
        # and silently corrupts the join key.
        self.boolean_columns = {str(c).lower() for c in (o.get("boolean_columns") or [])}

    def __call__(self, value, column=None):
        if value is None:
            return None
        s = str(value)
        if self.trim:
            s = s.strip()
        if s.lower() in self.null_tokens:
            return None if self.blank_as_null else s
        if self.normalise_timestamps:
            m = _TS_TRAILING_ZEROS.match(s)
            if m:
                s = m.group(1)
        if self.normalise_booleans:
            low = s.lower()
            numeric = bool(_NUMERIC_RE.match(s))
            bool_ok = (not numeric) or (column and str(column).lower() in self.boolean_columns)
            if bool_ok:
                if low in _TRUE:
                    return "true"
                if low in _FALSE:
                    return "false"
        if self.numeric_scale is not None and _NUMERIC_RE.match(s):
            try:
                q = Decimal(1).scaleb(-int(self.numeric_scale))
                return str(Decimal(s).quantize(q))
            except (InvalidOperation, ValueError):
                return s
        if _NUMERIC_RE.match(s) and "." in s:
            # 45.6357000 == 45.6357; keeps scale-only noise out of the diff
            s = s.rstrip("0").rstrip(".") or "0"
        if self.case_insensitive:
            s = s.lower()
        return s


def evaluate_where(expr, prod_value, uat_value):
    """Evaluate an accepted_columns `where` predicate for the CSV path.

    `prod_value` / `uat_value` are the NORMALISED strings (or None) the diff
    logic just compared, so the predicate sees exactly what failed. Restricted
    namespace - no builtins, no imports.
    """
    if not expr:
        return False
    env = {
        "prod_value": prod_value,
        "uat_value": uat_value,
        "redshift_value": prod_value,
        "snowflake_value": uat_value,
        "None": None,
    }
    helpers = {
        "startswith": lambda v, p: bool(v) and str(v).startswith(p),
        "contains": lambda v, p: bool(v) and p in str(v),
        "isblank": lambda v: v is None or str(v) == "",
        "year": lambda v: int(str(v)[:4]) if v and str(v)[:4].isdigit() else None,
        "date": lambda v: str(v)[:10] if v else None,
        "num": lambda v: float(v) if v not in (None, "") else None,
        "abs": abs,
        "round": round,
        "len": len,
    }
    try:
        return bool(eval(expr, {"__builtins__": {}}, {**env, **helpers}))  # noqa: S307
    except Exception:  # noqa: BLE001 - a broken predicate must not hide a diff
        return False

# ---------------------------------------------------------------------------
# Shared view list
# ---------------------------------------------------------------------------
# A CSV object and its EDP_DWI view are the same object: learning_enrolment.csv
# is an unload of DWI_LEARNING_ENROLMENT, so the grain that identifies a row in
# one identifies it in the other. Maintaining two lists meant two places to
# drift. The config therefore carries ONE canonical `views:` list, written in
# lowercase without the DWI_ prefix, which is expanded into both modes here.
#
# Only the spelling differs, and only because the pipelines differ:
#   csv  object name lowercase, no prefix; CSV headers are written lowercase
#   dwi  DWI_ prefix, UPPERCASE; Snowflake resolves identifiers uppercase
#
# Casing matters for more than cosmetics: the DWI ladder matches
# accepted_columns / exclude_columns keys against real Snowflake column names
# exactly, so a lowercase key would silently never match and a known-accepted
# column would be reported as a genuine diff.

_CSV_ONLY_FIELDS = ("clients",)


def _case_columns(items, caser):
    out = []
    for item in (items or []):
        if isinstance(item, dict):
            item = dict(item)
            if "column" in item:
                item["column"] = caser(str(item["column"]))
            out.append(item)
        else:
            out.append(caser(str(item)))
    return out


def _view_for_mode(entry, mode):
    """Project one canonical view entry into a mode-specific entry."""
    caser = str.upper if mode == "dwi" else str.lower
    name = re.sub(r"^dwi_", "", str(entry.get("name", "")), flags=re.I).lower()
    out = dict(entry)
    out["name"] = f"DWI_{name.upper()}" if mode == "dwi" else name
    if entry.get("grain"):
        out["grain"] = [caser(str(c)) for c in entry["grain"]]
    for field in ("accepted_columns", "exclude_columns"):
        if entry.get(field):
            out[field] = _case_columns(entry[field], caser)
    if mode == "dwi":
        for field in _CSV_ONLY_FIELDS:
            out.pop(field, None)
    return out


def expand_shared_views(cfg):
    """Populate cfg['csv']['views'] and cfg['dwi']['views'] from cfg['views'].

    A per-mode `views:` list still wins, so an existing split config keeps
    working unchanged and a mode can be overridden deliberately.
    """
    shared = cfg.get("views")
    if not shared:
        return cfg
    for mode in ("csv", "dwi"):
        section = cfg.setdefault(mode, {}) or {}
        cfg[mode] = section
        if section.get("views"):
            continue
        section["views"] = [_view_for_mode(v, mode) for v in shared
                            if v and v.get("name")]
    return cfg
