# DWI Migration Testing

Automated comparison testing for the DWI (Data Warehouse Integration) migration
from Redshift to Snowflake, per **CRT-6323**.

Two independent comparison modes:

| Mode | Compares | Where |
|---|---|---|
| `csv` | Redshift CSV extract vs Snowflake CSV extract | S3 |
| `dwi` | `UAT_DB.EDP_DWI` vs `PROD_DB.EDP_DWI` | Snowflake |

Both write the same tracker-ready report so results can be pasted into the same
Confluence page as the BI (T0–T5) results.

## Install

```bash
pip install -r requirements.txt
cp env.example .env      # then edit
```

Keep `SNOWFLAKE_AUTHENTICATOR=externalbrowser` for SSO; the token caches locally
so later runs don't re-prompt. Password and key-pair auth are the alternatives.
`SNOWFLAKE_DATABASE` / `SNOWFLAKE_SCHEMA` are not needed — every query is fully
qualified from `dwi.prod_db` / `dwi.uat_db` in `config.yaml`.

AWS credentials come from any standard boto3 source (`AWS_PROFILE`, instance
role, SSO).

## Run

**Every view in the ticket** — omit `--views` entirely. The filter is
subtractive, so no flag means no filter:

```bash
python runner.py                    # both modes, all configured views
python runner.py --mode csv         # all 131 CSV views
python runner.py --mode dwi         # all configured EDP_DWI views
```

Confirm the intended scope without touching S3 or Snowflake first:

```bash
python runner.py --dry-run          # prints every view + the SQL it would run
```

The dry run ends with a per-mode count — expect `dwi: 127`, and `csv` equal to
the number of views actually unloaded for the client, for the
config as shipped. If a count is short, a view is missing from `config.yaml`
rather than being skipped at runtime.

Narrower runs and CI:

```bash
python runner.py --mode dwi --views DWI_LEARNING_ENROLMENT
python runner.py --mode csv --views learning_enrolment,learning_course
python runner.py --mode csv --clients uat1
python runner.py --fail-on-diff     # non-zero exit when diffs found

# Pin specific run folders instead of auto-discovering the latest
python runner.py --mode csv --clients uat1 \
  --redshift-run 20260729223000 --snowflake-run 20260729224500
```

Nothing is skipped silently. In CSV mode the views actually compared come from
S3 discovery, so a configured view that **neither** pipeline unloaded is
reported `BLOCKED` ("neither pipeline unloaded it") rather than dropped — the
report always has one row per configured view, which is what makes it safe to
paste into the ticket as evidence of coverage. Views present on only one side
are `BLOCKED` too, naming the side.

## How run folders are paired (CSV mode)

The two unload DAGs write a timestamped folder per run and **never share a
timestamp**:

```
Redshift   s3://p-elmo-data-cap/landing/data-warehouse-integration/{client}/{ts}/{view}.csv
Snowflake  s3://p-elmo-data-cap/landing/data-warehouse-integration/snowflake_outbound/{client}/{ts}/{view}.csv
```

So the harness pairs the **latest run folder per client on each side**
independently. Because both DAGs PGP-encrypt in place and move originals to
`processed/{client}/{ts}/`, a fully-completed run leaves only `.csv.pgp` behind.
Discovery therefore walks newest-first and picks the newest run that still has
plain CSV; if every run is already encrypted the view is reported `BLOCKED`
rather than silently compared as empty.

This pairing assumes both sides ran over the same source data. If one pipeline
ran hours later than the other, genuine late-arriving rows will show up as
differences — pin both timestamps when that matters.

## The ladders

Content tiers are withheld once a structural tier fails, because their results
would be meaningless.

**CSV mode**

| Tier | Check | On failure |
|---|---|---|
| C0 | View present in both run folders | `BLOCKED`, stop |
| C1 | Header names and order match | `FAIL`, stop |
| C2 | Total row counts | continue |
| C3 | Key-set diff, both directions (needs grain) | continue |
| C4 | Per-column mismatch counts over shared keys | continue |
| C5 | Order-independent fingerprint of the whole set | — |

**DWI mode**

| Tier | Check | On failure |
|---|---|---|
| D0 | Schema parity via `INFORMATION_SCHEMA` | `FAIL`, stop |
| D1 | Grain uniqueness on both sides | continue |
| D2 | Key-set diff, both directions (`MINUS`) | continue |
| D3 | `COUNT_IF(NOT EQUAL_NULL(...))` per column | continue |
| D4 | `HASH_AGG` fingerprint | — |

C5/D4 only run when every content tier is clean. Once any row differs the
fingerprints differ by construction, so running them would add nothing — and
would contradict a difference that was deliberately accepted within threshold.

## Grain

**Grain is never defaulted.** Views in `config.yaml` may ship with an empty
`grain: []` for you to fill in:

```yaml
- name: DWI_LEARNING_POSITION_COURSES
  grain: []
```

```yaml
- name: DWI_LEARNING_POSITION_COURSES
  grain: [POSITION_ID, COURSE_ID, CLIENT_NAME, CLIENT_REGION]
```

There is no inferred fallback, because a guessed grain fails in two silent ways:
if the column doesn't exist every row keys identically and the diff reads clean,
and if it isn't unique the join fans out and the column counts are meaningless.
Both produce a confident wrong answer, which is worse than no answer. The
CRT-6248 grains in the BI harness are BI-schema keys and do **not** apply to
`EDP_DWI`.

### What still runs without a grain

An empty grain is not an error and does not block the view:

| Tier | Without a grain |
| --- | --- |
| C0/C1 file presence, header parity | runs |
| C2 row counts | runs |
| C3/C4 key-set and column diffs | **skipped** |
| C5 fingerprint | runs |
| D0 schema parity | runs |
| D1/D3 grain uniqueness, row-level diff | **skipped** |
| D2 row counts, D4 fingerprint | runs |

So a blank-grain view still catches schema drift, row-count drift, and — via the
fingerprint — a row that changed in place. What it cannot do is tell you *which*
row or column changed.

Because that is partial coverage, the verdict says so rather than borrowing
`PASS`: a clean blank-grain view reports **`PASS (NO GRAIN)`**, and the dashboard
counts it in its own amber *No grain (partial)* bucket with its own filter chip.
`summary.md` carries a **Grain coverage** section listing every view still
awaiting one, so progress is trackable across runs.

Where an earlier revision of this harness had inferred a grain, that inference is
preserved in `config.yaml` as a commented `# suggested (unverified)` line — a
starting point to verify, not a value in force.

### Once a grain is set

Grain columns that don't exist in a given view are dropped with a note, rather
than silently keying every row identically. If the grain turns out not to be
unique, D1/C3 say so and flag that the column-level counts cover only the first
occurrence per key — extend the grain for that view rather than trusting the
numbers.

Three escalating levers, all reported rather than hidden.

**1. `diff_threshold_pct`** — differences at or below this percentage become
`ACCEPTED` instead of `FAIL`, across row counts, key-set diffs and column diffs.

**2. `accepted_columns`** — a column that is measured and reported but never
fails the view. Add a `where` predicate to accept only the *known* pattern, so
anything else still counts as a genuine diff:

```yaml
- name: DWI_LEARNING_EXTERNAL_TRAINING
  accepted_columns:
    - column: EXPIRY_DATE
      reason: Prod sentinel dates on/before 1971-01-01 are correctly nulled in UAT
      where: "prod_value::date <= '1971-01-01'"
```

The report then shows both the total and the **residual** — e.g.
`EXPIRY_DATE=400 (residual 2)` means the rule explained 398 and two genuine
differences remain. Sample CSVs contain only the residual rows.

In `dwi` mode the `where` is SQL against `prod_value` / `uat_value`. In `csv`
mode it is a restricted Python expression over the normalised values
(`prod_value`, `uat_value`, plus `startswith`, `contains`, `isblank`, `date`,
`year`, `num`); it runs with no builtins, and a broken or malicious predicate
evaluates to `False` rather than hiding a diff.

**3. `accept_diff`** — force a whole tier to `ACCEPTED`, with a reason on the
report. Structural tiers (C0/C1, D0) can never be accepted this way; schema and
header drift stay hard stops.

`exclude_columns` removes a column from comparison entirely — use it only for
columns that are meaningless to compare, since excluded columns are invisible to
the fingerprint too.

## Active tenants

The BI harness joins `UAT_DB.BI.TEMP_ACTIVE_TENANTS` because both of its sides
live in `UAT_DB`. Comparing `UAT_DB` to `PROD_DB` means that table exists on one
side only, so joining it would **silently filter one side**. The join is
therefore off by default here and must be opted into per view with a tenants
list visible to both databases.

## Output

Each run writes `results_<timestamp>/`:

* `summary.md` — the tier matrix plus per-view detail, ready to paste
* `results.json` — machine-readable, for trend tracking
* `queries.sql` — every statement issued, for audit
* `samples/<view>_<tier>_<column>.csv` — offending rows per mismatching column

## Dashboard

`dashboard.py` turns every `results_*/results.json` into a single
self-contained `dashboard.html` — no dependencies, no server, no CDN. Open it
straight from disk.

The runner rebuilds it automatically after each run, so normally there is
nothing to do. Pass `--no-dashboard` to skip it, or build it by hand:

```bash
python dashboard.py                     # scan ./results_* -> dashboard.html
python dashboard.py --dir path/to/runs  # scan elsewhere
python dashboard.py --out report.html
```

What it shows:

* **One board per mode.** `csv` and `dwi` have different tier vocabularies
  (C0–C5 vs D0–D4) and different sides, so they get separate summary matrices
  rather than being forced into one table. Side labels follow the mode —
  REDSHIFT/SNOWFLAKE for `csv`, PROD/UAT for `dwi`.
* **Plain-language verdict per tier**, not just a status colour: which columns
  drifted, how many keys are one-sided, which column is worst and by how much,
  and whether a difference was inside the threshold or accepted by config.
* **Residual counts** where an `accepted_columns` `where` predicate applied, so
  an explained difference and a genuine one are never conflated.
* **Side-by-side sample rows** per mismatching column, plus the exact SQL or
  file plan behind every tier with a copy button.
* **Run history** — verdict per view across every run in the folder, so a
  regression between runs is visible at a glance.
* Filters by mode, verdict, and view/client name; **Print / PDF** expands every
  collapsed sample first, so the export is the complete report.

Dry runs are labelled as such: tiers read `DRY`, verdicts are withheld rather
than reported as `PASS`, and only the generated SQL is shown — a dry run
executes nothing, so any counter in the payload would be a placeholder rather
than a measurement.

It also still reads the BI harness's `results.json` (a bare list with T0–T4
tiers), so old runs render alongside the new ones.

## Roles

Comparing `UAT_DB` to `PROD_DB` usually needs more than one role. Prefer an
explicit list over `true` (which issues `USE SECONDARY ROLES ALL`) — `ALL` can
trip row-level-security scalar subqueries (error `090150`) when several mapped
roles are in session:

```yaml
connection:
  use_secondary_roles: [PROD_ANALYTICS_ENGINEER_ROLE]
```

## Tests

```bash
python tests/test_csv_comparison.py     # CSV ladder, fake S3
python tests/test_dashboard.py          # dashboard rendering, fixture payloads
python tests/test_schema_diff_sql.py    # assets/schema_diff.sql, synthetic drift
```

17 offline test groups covering the CSV ladder against a fake S3 — no AWS or
Snowflake needed. They cover identical extracts, the rendering quirks that must
be absorbed, genuine diffs that must **not** be, header drift, key-set diffs,
threshold acceptance, `where`-clause residuals, encrypted-only run folders,
missing views, non-unique grains, predicate sandboxing, the no-grain partial
verdict, configured-but-absent coverage, and per-tenant client scoping.

`test_schema_diff_sql.py` runs `assets/schema_diff.sql` against a synthetic
INFORMATION_SCHEMA in DuckDB with drift planted in it — a type change, an extra
column, reordered columns, a precision-only change, a nullability-only change, a
view present on one side only, and one clean view. It asserts each is classified
correctly and that the clean view verdicts PASS.

## Standalone schema diff

`assets/schema_diff.sql` answers "what differs between the two schemas" in one
worksheet, without running the harness. Four queries: a role-visibility sanity
check, views present on one side only, one row per drifting column, and a
one-row-per-view rollup to paste into the ticket.

It is deliberately **stricter than the D0 tier** — it also flags length,
precision, scale and nullability, so it can report DRIFT where D0 passes. Header
comments explain how to narrow it to D0's exact definition.

## Scope

`config.yaml` carries **one canonical `views:` list — all 127 `EDP_DWI` views**,
in module order, taken from the live schema listing. Both modes are expanded from
it at load time, so a grain is defined once and cannot drift between them.

A CSV object and its `EDP_DWI` view are the same object: `learning_enrolment.csv`
is an unload of `DWI_LEARNING_ENROLMENT`, so a key that identifies a row in one
identifies it in the other. Names are written lowercase without the `DWI_`
prefix; the expansion adds what each mode needs:

| | `csv` | `dwi` |
| --- | --- | --- |
| view name | `learning_enrolment` | `DWI_LEARNING_ENROLMENT` |
| grain / column names | lowercase | UPPERCASE |
| `clients:` scoping | applied | dropped (not meaningful) |

The casing is not cosmetic. CSV headers are written lowercase by the unload,
while Snowflake resolves identifiers uppercase — and the DWI ladder matches
`accepted_columns` / `exclude_columns` keys against real Snowflake column names
**exactly**, so a lowercase key would silently never match and a
known-accepted column would be reported as a genuine diff.

A per-mode `views:` list still wins if present, so an older split config keeps
working and a single mode can be overridden deliberately.

### Verified against a real uat1 unload

The `uat1` object listing was diffed against both configured lists:

| Check | Result |
| --- | --- |
| CSV files unloaded for `uat1` | 108 |
| Files with a matching `DWI_` view | **108 / 108** |
| Files missing from the `csv` config | 0 |

So the naming assumption holds exactly: **object name = view name, lowercased,
`DWI_` stripped**. The remaining 19 configured-but-absent views are all the
per-tenant `syd_<tenant>_user_profile_data` family, which is expected — see
below.

### Per-tenant views

`DWI_SYD_<tenant>_USER_PROFILE_DATA` is one view per tenant, and only that
tenant's unload ever contains the matching CSV. Each of the 20 is therefore
scoped in `config.yaml`:

```yaml
  - name: syd_uat1_user_profile_data
    grain: [user_id, client_name, client_region]
    clients: [uat1]
```

`clients:` is a CSV-mode concept — it scopes which unload should contain the
object — so the expansion drops it from `dwi` mode, where every view is present
regardless of tenant.

A view with no `clients:` key runs for every client, so this only affects the
tenant family. Without it, a `uat1` run reports the other 19 tenants' views as
`BLOCKED` every time — noise that buries genuine pipeline misses.

### PGP is out of scope

Decryption is handled separately, upstream of this harness. Discovery reads
plain `.csv` only — point it at a run folder whose files have already been
decrypted in place, or at a prefix holding the decrypted output. A run folder
containing nothing but `.csv.pgp` reports `BLOCKED` rather than silently
comparing zero rows.

The other module tickets (CRT-6322 HRCore, 6324 Onboarding, 6325 Performance,
6326 Recruitment, 6327 Rewards, 6328 Succession, 6329 Pivot tables) no longer
need view additions — only grains.
