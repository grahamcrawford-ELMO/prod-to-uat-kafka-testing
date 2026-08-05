#!/usr/bin/env python3
"""Generate a self-contained dashboard.html from all results_*/results.json runs.

Usage:
    python dashboard.py                 # scan ./results_* and write dashboard.html
    python dashboard.py --dir path      # scan a different base directory
    python dashboard.py --out file.html

No dependencies, no server, no CDN - open the file straight from disk.

Handles both payload shapes:
  * this harness   {"csv": [...], "dwi": [...], "generated": ..., "dry_run": ...}
  * the BI harness [ ... ]   (legacy list of table results, tiers T0-T4)

Everything is always visible (no collapsed sections) and print-ready:
Ctrl+P / "Save as PDF" produces a complete report.
"""

import argparse
import json
import re
from datetime import datetime
from pathlib import Path

RUN_DIR_RE = re.compile(r"results_(\d{8}_\d{4})$")


def normalise(payload):
    """Return {"csv": [...], "dwi": [...], "bi": [...], "dry_run": bool}."""
    if isinstance(payload, list):
        return {"csv": [], "dwi": [], "bi": payload, "dry_run": False}
    out = {"csv": payload.get("csv") or [], "dwi": payload.get("dwi") or [],
           "bi": [], "dry_run": bool(payload.get("dry_run"))}
    for r in out["csv"]:
        r.setdefault("mode", "csv")
    for r in out["dwi"]:
        r.setdefault("mode", "dwi")
    return out


def collect_runs(base: Path):
    runs = []
    for d in sorted(base.glob("results_*")):
        m = RUN_DIR_RE.search(d.name)
        f = d / "results.json"
        if not (m and f.exists()):
            continue
        try:
            payload = json.loads(f.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        ts = datetime.strptime(m.group(1), "%Y%m%d_%H%M")
        data = normalise(payload)
        if not (data["csv"] or data["dwi"] or data["bi"]):
            continue
        runs.append({"id": d.name, "label": ts.strftime("%d %b %Y, %H:%M"),
                     "ts": ts.isoformat(), **data})
    return runs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=".", help="directory containing results_* folders")
    ap.add_argument("--out", default="dashboard.html")
    args = ap.parse_args()

    base = Path(args.dir)
    runs = collect_runs(base)
    if not runs:
        raise SystemExit(f"No results_*/results.json found under {base.resolve()}")

    payload = json.dumps(runs, default=str).replace("</", "<\\/")
    html = TEMPLATE.replace("/*__DATA__*/null", payload)
    out = Path(args.out)
    out.write_text(html, encoding="utf-8")
    print(f"Wrote {out.resolve()}  ({len(runs)} run{'s' if len(runs) != 1 else ''})")


TEMPLATE = r"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>DWI Migration - Comparison Ladder</title>
<style>
:root{
  --paper:#F2F4F6; --card:#FFFFFF; --ink:#17222C; --ink-soft:#5A6B79;
  --line:#DDE3E8; --line-soft:#EBEFF2;
  --pass:#1E7A4E; --pass-bg:#E2F2E9;
  --fail:#C13A3F; --fail-bg:#FAE7E7;
  --blocked:#A87715; --blocked-bg:#F8EFDA;
  --skip:#8A97A1; --skip-bg:#EDF0F3;
  --err:#8348B5; --err-bg:#F0E7F9;
  --acc:#0B6E8F; --acc-bg:#E1F0F6;
  --left:#2F4B7C; --right:#0D7E83;
  --mono:"Cascadia Mono","Cascadia Code",ui-monospace,"JetBrains Mono",Consolas,monospace;
  --sans:"Segoe UI Variable Text","Segoe UI",system-ui,-apple-system,sans-serif;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--paper);color:var(--ink);font:15px/1.5 var(--sans);padding:0 0 90px}
a{color:inherit;text-decoration:none}
.wrap{width:100%;max-width:1240px;margin:0 auto;padding:0 26px}
header{border-bottom:1px solid var(--line);background:var(--card);position:sticky;top:0;z-index:5}
.mast{display:flex;align-items:baseline;gap:18px;padding:15px 0;flex-wrap:wrap}
.mast h1{font-size:17px;font-weight:650}
.mast .sub{font-family:var(--mono);font-size:12px;color:var(--ink-soft)}
.mast .spacer{flex:1}
select,input[type=search]{font:13px var(--mono);color:var(--ink);background:var(--card);
  border:1px solid var(--line);border-radius:6px;padding:7px 10px}
select{cursor:pointer}
:focus-visible{outline:2px solid var(--left);outline-offset:2px}
.drybanner{background:var(--blocked-bg);color:var(--blocked);border:1px solid #E8D6A8;
  border-radius:10px;padding:10px 14px;margin:20px 0 0;font-size:13.5px}
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin:26px 0 8px}
.kpi{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:13px 16px}
.kpi .n{font:600 29px/1.1 var(--mono)}
.kpi .l{font-size:12px;color:var(--ink-soft);margin-top:3px;text-transform:uppercase;letter-spacing:.06em}
.kpi.pass .n{color:var(--pass)} .kpi.fail .n{color:var(--fail)}
.kpi.blocked .n{color:var(--blocked)} .kpi.err .n{color:var(--err)}
.kpi.acc .n{color:var(--acc)}
.spectrum{display:flex;gap:3px;margin:14px 0 8px;height:10px}
.spectrum a{flex:1;border-radius:2px;min-width:2px}
.legend{display:flex;gap:16px;flex-wrap:wrap;font-size:12px;color:var(--ink-soft);margin:0 0 26px}
.legend i{display:inline-block;width:10px;height:10px;border-radius:2px;margin-right:5px;vertical-align:-1px}
.controls{display:flex;gap:10px;margin:0 0 14px;flex-wrap:wrap;align-items:center}
.chip{font:12px var(--sans);border:1px solid var(--line);background:var(--card);border-radius:99px;
  padding:5px 12px;cursor:pointer;color:var(--ink-soft)}
.chip[aria-pressed="true"]{border-color:var(--ink);color:var(--ink);font-weight:600}
.board{background:var(--card);border:1px solid var(--line);border-radius:12px;overflow-x:auto;margin-bottom:34px}
.thead,.trow{min-width:640px}
.thead,.trow{display:grid;align-items:center}
.thead{font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--ink-soft);
  border-bottom:1px solid var(--line);padding:10px 16px}
.thead div{text-align:center}
.thead div:first-child{text-align:left}
.thead div:last-child{text-align:right}
.trow{padding:10px 16px;border-bottom:1px solid var(--line-soft)}
.trow:last-child{border-bottom:none}
.trow:hover{background:#F8FAFB}
.trow .tname{font-family:var(--mono);font-size:13px;overflow:hidden;text-overflow:ellipsis;
  white-space:nowrap;padding-right:12px}
.trow .tname em{font-style:normal;color:var(--ink-soft)}
.cell{height:20px;margin:0 3px;border-radius:4px}
.cell.PASS{background:var(--pass)} .cell.FAIL{background:var(--fail)}
.cell.SKIPPED{background:var(--skip-bg);border:1px dashed var(--line)}
.cell.ERROR{background:var(--err)}
.cell.ACCEPTED{background:var(--acc)}
.cell.DRY{background:repeating-linear-gradient(45deg,#cfd6db 0 4px,#e6eaee 4px 8px)}
.cell.none{background:transparent}
.verdict{justify-self:end;font:600 11px var(--sans);letter-spacing:.05em;border-radius:99px;
  padding:4px 11px;text-transform:uppercase;white-space:nowrap}
.v-PASS{background:var(--pass-bg);color:var(--pass)}
.v-DIFFS{background:var(--fail-bg);color:var(--fail)}
.v-BLOCKED{background:var(--blocked-bg);color:var(--blocked)}
.v-ERROR,.v-DRIFT{background:var(--err-bg);color:var(--err)}
.v-ACC{background:var(--acc-bg);color:var(--acc)}
.v-DRY{background:var(--skip-bg);color:var(--ink-soft)}
.v-NOGRAIN{background:var(--blocked-bg);color:var(--blocked)}
h2.sect{font-size:13px;text-transform:uppercase;letter-spacing:.1em;color:var(--ink-soft);margin:40px 0 12px}
h2.sect .n{font-family:var(--mono);text-transform:none;letter-spacing:0}
.tsection{background:var(--card);border:1px solid var(--line);border-radius:12px;margin:0 0 22px;overflow:hidden}
.tsection > .thd{display:flex;align-items:center;gap:14px;flex-wrap:wrap;padding:14px 18px;
  border-bottom:1px solid var(--line);background:#FBFCFD}
.thd .tname{font:600 15px var(--mono)}
.thd .meta{font:12px var(--mono);color:var(--ink-soft)}
.thd .spacer{flex:1}
.badge{font:600 11px var(--sans);background:var(--blocked-bg);color:var(--blocked);border-radius:99px;padding:4px 10px}
.badge.review{background:var(--err-bg);color:var(--err)}
.badge.mode{background:#E9F2FF;color:var(--left)}
.tbody{padding:16px 18px;display:grid;gap:12px;min-width:0}
.tbody > *{min-width:0}
.tier{border:1px solid var(--line-soft);border-left-width:4px;border-radius:10px;background:var(--card);
  min-width:0;overflow:hidden}
.tier.pass{border-left-color:var(--pass)} .tier.fail{border-left-color:var(--fail)}
.tier.error{border-left-color:var(--err)}
.tier.accepted{border-left-color:var(--acc)} .tier.skipped,.tier.none{border-left-color:var(--line)}
.tier.dry{border-left-color:var(--left)}
.tier-hd{display:flex;align-items:baseline;gap:12px;padding:10px 14px 0;flex-wrap:wrap}
.tier-hd .tk{font:600 13px var(--mono)}
.tier-hd .tl{font-size:13px;color:var(--ink-soft)}
.tier-hd .spacer{flex:1}
.tier-badge{font:600 10.5px var(--sans);padding:3px 9px;border-radius:999px;text-transform:uppercase;letter-spacing:.04em}
.tier-badge.pass{background:var(--pass-bg);color:var(--pass)}
.tier-badge.fail{background:var(--fail-bg);color:var(--fail)}
.tier-badge.error{background:var(--err-bg);color:var(--err)}
.tier-badge.accepted{background:var(--acc-bg);color:var(--acc)}
.tier-badge.skipped,.tier-badge.none{background:var(--skip-bg);color:var(--ink-soft)}
.tier-badge.dry{background:#E9F2FF;color:var(--left)}
.tier-sum{padding:6px 14px 0;font-size:13.5px}
.tier-sum b{font-weight:600}
.tier-bd{padding:10px 14px 12px;display:grid;gap:10px;min-width:0}
.tier-bd > *{min-width:0;max-width:100%}
.tier.line{display:flex;align-items:center;gap:12px;padding:8px 14px;color:var(--ink-soft);font-size:13px}
.tier.line .tk{font:600 12.5px var(--mono);color:var(--ink-soft)}
.stat{display:inline-grid;grid-template-columns:auto auto auto;gap:0;border:1px solid var(--line-soft);
  border-radius:8px;overflow:hidden;font-family:var(--mono);font-size:13px}
.stat > span{padding:7px 14px;display:flex;flex-direction:column;gap:1px}
.stat i{font:600 10px var(--sans);font-style:normal;text-transform:uppercase;letter-spacing:.07em}
.stat .p{background:#F4F6FA} .stat .p i{color:var(--left)}
.stat .u{background:#F2F8F8;border-left:1px solid var(--line-soft)} .stat .u i{color:var(--right)}
.stat .d{border-left:1px solid var(--line-soft)} .stat .d i{color:var(--ink-soft)}
.stat .d.bad{background:var(--fail-bg);color:var(--fail)}
.stat .d.ok{background:var(--pass-bg);color:var(--pass)}
.statrow{display:flex;gap:12px;flex-wrap:wrap;align-items:flex-start}
.statlabel{font:600 11px var(--sans);text-transform:uppercase;letter-spacing:.06em;color:var(--ink-soft);margin-bottom:4px}
.table-wrap{overflow:auto;border:1px solid var(--line-soft);border-radius:8px;width:fit-content;max-width:100%}
table.data{border-collapse:collapse;font-size:12px;font-family:var(--mono)}
table.data th,table.data td{padding:6px 12px;border-bottom:1px solid var(--line-soft);text-align:left;white-space:nowrap}
table.data th{font:600 10.5px var(--sans);text-transform:uppercase;letter-spacing:.06em;
  color:var(--ink-soft);background:#F8FAFB}
table.data tr:last-child td{border-bottom:none}
table.data td{vertical-align:top}
.t4col{border:1px solid var(--line-soft);border-radius:8px;padding:10px 12px;display:grid;gap:8px;min-width:0}
.t4col-hd{display:flex;gap:12px;align-items:baseline;flex-wrap:wrap}
.t4col-hd b{font:600 13px var(--mono)}
.t4col-hd span{font:12px var(--mono);color:var(--ink-soft)}
.colbadge{font:600 10px var(--sans);padding:3px 8px;border-radius:99px;text-transform:uppercase;letter-spacing:.04em}
.colbadge.fail{background:var(--fail-bg);color:var(--fail)}
.colbadge.acc{background:var(--acc-bg);color:var(--acc)}
th.thp{color:var(--left)} th.thu{color:var(--right)}
td.tdp{background:#F4F6FA} td.tdu{background:#F2F8F8}
td.tdp,td.tdu{white-space:normal;vertical-align:top}
.val{max-width:380px;min-width:180px;overflow-wrap:anywhere;white-space:normal;
  display:-webkit-box;-webkit-line-clamp:4;-webkit-box-orient:vertical;overflow:hidden}
.samples{display:flex;gap:14px;flex-wrap:wrap;align-items:flex-start}
.samples > div{flex:0 1 auto;min-width:0;max-width:100%}
.samples .table-wrap{max-width:100%}
tr.xrow{display:none}
table.data.xopen tr.xrow{display:table-row}
.xtoggle{font:11px var(--sans);border:1px solid var(--line);background:var(--card);
  border-radius:6px;padding:4px 10px;cursor:pointer;color:var(--ink-soft);margin-top:6px}
.exportbtn{font:12px var(--sans);border:1px solid var(--line);background:var(--card);
  border-radius:6px;padding:6px 12px;cursor:pointer;color:var(--ink)}
.sql{border:1px solid var(--line-soft);border-radius:8px;background:#F8FAFB;min-width:0;max-width:100%}
.sql .sql-hd{display:flex;align-items:center;gap:10px;padding:6px 10px;border-bottom:1px solid var(--line-soft)}
.sql .sql-hd b{font:600 10.5px var(--sans);text-transform:uppercase;letter-spacing:.07em;color:var(--ink-soft)}
.sql .copy{margin-left:auto;font:11px var(--sans);border:1px solid var(--line);background:var(--card);
  border-radius:6px;padding:3px 9px;cursor:pointer;color:var(--ink-soft)}
.sql pre{padding:10px 12px;font:11.5px/1.55 var(--mono);white-space:pre-wrap;overflow-wrap:anywhere;
  word-break:break-word;overflow:auto;max-height:340px}
.notes li{margin-left:18px;font-size:13.5px}
.errbox{font-family:var(--mono);font-size:12.5px;color:var(--err);background:var(--err-bg);
  border-radius:8px;padding:10px 12px;white-space:pre-wrap}
.kv{font-family:var(--mono);font-size:13px}
.kv span{color:var(--ink-soft)}
.fp{display:flex;gap:10px;flex-wrap:wrap;font-family:var(--mono);font-size:12.5px}
.fp code{background:#F8FAFB;border:1px solid var(--line-soft);border-radius:5px;padding:3px 8px}
.wherebox{font:12px var(--mono);color:var(--ink-soft);display:flex;gap:6px;align-items:baseline;flex-wrap:wrap}
.wherebox code{background:#F8FAFB;border:1px solid var(--line-soft);border-radius:5px;padding:2px 7px;
  color:var(--ink);white-space:pre-wrap;overflow-wrap:anywhere}
.empty{color:var(--ink-soft);font-size:13.5px;padding:14px 16px}
.hist{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px;overflow-x:auto}
.hgrid{display:grid;gap:4px;align-items:center;font-family:var(--mono);font-size:12px}
.hgrid .hname{white-space:nowrap;overflow:hidden;text-overflow:ellipsis;padding-right:10px}
.hcell{width:100%;height:20px;border-radius:4px}
.hcell.PASS{background:var(--pass)} .hcell.DIFFS{background:var(--fail)}
.hcell.BLOCKED{background:var(--blocked)} .hcell.ERROR,.hcell.DRIFT{background:var(--err)}
.hcell.ACC{background:var(--acc)} .hcell.DRY{background:repeating-linear-gradient(45deg,#cfd6db 0 4px,#e6eaee 4px 8px)}
.hcell.none{background:var(--line-soft)}
.hhead{font-size:10.5px;color:var(--ink-soft);writing-mode:vertical-rl;transform:rotate(180deg);
  justify-self:center;max-height:92px;overflow:hidden}
footer{margin-top:56px;font:12px var(--mono);color:var(--ink-soft)}
@media(max-width:860px){ .cell{height:16px;margin:0 2px} .thead,.trow{min-width:560px} }
@media print{
  body{background:#fff;padding:0;font-size:12px}
  *{-webkit-print-color-adjust:exact;print-color-adjust:exact}
  header{position:static;border:none}
  .controls,.copy,.xtoggle,.exportbtn{display:none!important}
  tr.xrow{display:table-row!important}
  .wrap{max-width:none;padding:0 4mm}
  .tsection,.tier,.kpi,.board,.hist{break-inside:avoid}
  .board{overflow:visible}
  .thead,.trow{min-width:0}
  .tsection{border-color:#bbb}
  .sql pre{max-height:none}
  a{text-decoration:none}
}
</style></head><body>
<header><div class="wrap mast">
  <h1>DWI Migration&ensp;&middot;&ensp;Comparison Ladder</h1>
  <span class="sub" id="scopelbl"></span>
  <span class="spacer"></span>
  <button class="exportbtn" onclick="exportHtml()" title="Download this page as a standalone HTML file">HTML</button>
  <button class="exportbtn" onclick="window.print()" title="Print or save as PDF - all collapsed samples expand automatically">Print / PDF</button>
  <label class="sub" for="runSel">Run&ensp;</label>
  <select id="runSel" aria-label="Select run"></select>
</div></header>

<div class="wrap">
  <div id="dry"></div>
  <div class="kpis" id="kpis"></div>
  <div class="spectrum" id="spectrum" title="Verdict spectrum - one band per row, click to jump"></div>
  <div class="legend">
    <span><i style="background:var(--pass)"></i>Pass</span>
    <span><i style="background:var(--acc)"></i>Diffs accepted</span>
    <span><i style="background:var(--fail)"></i>Diffs found</span>
    <span><i style="background:var(--blocked)"></i>Blocked</span>
    <span><i style="background:var(--err)"></i>Error / schema drift</span>
    <span><i style="background:var(--skip-bg);border:1px dashed var(--line)"></i>Skipped tier</span>
  </div>

  <div class="controls">
    <input id="search" type="search" placeholder="Filter view or client" aria-label="Filter">
    <button class="chip" data-m="all" data-g="mode" aria-pressed="true">All modes</button>
    <button class="chip" data-m="csv" data-g="mode" aria-pressed="false">S3 CSV</button>
    <button class="chip" data-m="dwi" data-g="mode" aria-pressed="false">Warehouse</button>
    <span style="width:12px"></span>
    <button class="chip" data-f="all" data-g="v" aria-pressed="true">All</button>
    <button class="chip" data-f="PASS" data-g="v" aria-pressed="false">Pass</button>
    <button class="chip" data-f="ACC" data-g="v" aria-pressed="false">Accepted</button>
    <button class="chip" data-f="DIFFS" data-g="v" aria-pressed="false">Diffs</button>
    <button class="chip" data-f="NOGRAIN" data-g="v" aria-pressed="false">No grain</button>
    <button class="chip" data-f="BLOCKED" data-g="v" aria-pressed="false">Blocked</button>
    <button class="chip" data-f="ERROR" data-g="v" aria-pressed="false">Error</button>
  </div>

  <div id="boards"></div>
  <h2 class="sect">Per-view reports</h2>
  <div id="sections"></div>
  <h2 class="sect">History - verdict per view across runs</h2>
  <div class="hist"><div class="hgrid" id="hist"></div></div>
<footer id="foot"></footer></div>

<script>
const RUNS = /*__DATA__*/null;

/* Each mode has its own tier vocabulary and its own pair of side labels. */
const MODES = {
  csv: {
    key:"csv", title:"S3 CSV comparison", scope:"Redshift extract vs Snowflake extract",
    tiers:["C0","C1","C2","C3","C4","C5"], left:"REDSHIFT", right:"SNOWFLAKE",
    labels:{C0:"File presence",C1:"Header parity",C2:"Row counts",
            C3:"Key-set diff",C4:"Column-level diff",C5:"Fingerprint"},
    idcols:["Client","View"]
  },
  dwi: {
    key:"dwi", title:"Warehouse comparison", scope:"UAT_DB.EDP_DWI vs PROD_DB.EDP_DWI",
    tiers:["D0","D1","D2","D3","D4"], left:"PROD", right:"UAT",
    labels:{D0:"Schema parity",D1:"Grain uniqueness",D2:"Row counts & key-set diff",
            D3:"Column-level diff",D4:"Fingerprint"},
    idcols:["View"]
  },
  bi: {
    key:"bi", title:"BI model comparison", scope:"PROD (Redshift) vs UAT (Kafka)",
    tiers:["T0","T1","T2","T3","T4"], left:"PROD", right:"UAT",
    labels:{T0:"Schema parity",T1:"Grain uniqueness",T2:"Key set & full-row EXCEPT",
            T3:"Column-level diff",T4:"Fingerprint"},
    idcols:["Table"]
  }
};

const state = { run: RUNS.length-1, filter:"all", mode:"all", q:"" };

const vkey = v => !v ? "none"
  : v==="PASS" ? "PASS"
  : v==="BLOCKED" ? "BLOCKED"
  : v==="DRY" ? "DRY"
  // NO GRAIN is its own bucket: the row-level tiers never ran, so it must not
  // be counted or coloured as a clean pass.
  : /NO GRAIN/.test(v) ? "NOGRAIN"
  : v.startsWith("PASS (") ? "ACC"
  : /DRIFT/.test(v) ? "DRIFT"
  : v==="ERROR" ? "ERROR" : "DIFFS";
const vlabel = {PASS:"Pass",ACC:"Pass - diffs accepted",DIFFS:"Diffs found",BLOCKED:"Blocked",
                ERROR:"Error",DRIFT:"Schema drift",DRY:"Dry run",
                NOGRAIN:"Pass - no grain (partial)",none:"-"};
const vcolor = {PASS:"var(--pass)",ACC:"var(--acc)",DIFFS:"var(--fail)",BLOCKED:"var(--blocked)",
                ERROR:"var(--err)",DRIFT:"var(--err)",DRY:"#cfd6db",
                NOGRAIN:"var(--blocked)",none:"var(--line-soft)"};

const fmt = n => n==null ? "-" : Number(n).toLocaleString("en-AU");
const esc = s => String(s).replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const rid = r => (r.mode||"bi") + ":" + (r.client?r.client+"/":"") + (r.view||r.table);
const anchor = r => "x-" + rid(r).replace(/[^A-Za-z0-9_]/g,"_");
const label = r => (r.view||r.table||"");
const tierStatus = (r,t) => { const x=(r.tiers||{})[t]; return x ? x.status : "none"; };
const pct = (n,d) => (d && n!=null) ? (100*Number(n)/Number(d)).toFixed(3).replace(/\.?0+$/,"")+"%" : null;
const renderValue = v => v==null ? "NULL" : typeof v==="boolean" ? String(v)
  : String(v)==="" ? "(blank)" : String(v).length>120 ? String(v).slice(0,120)+"..." : String(v);

/* rows for a run, tagged with their mode config */
function allRows(run){
  const out=[];
  for (const m of ["csv","dwi","bi"])
    for (const r of (run[m]||[])) out.push({r, M:MODES[m]});
  return out;
}
function visible(run){
  const q=state.q.toLowerCase();
  return allRows(run).filter(({r,M}) =>
    (state.mode==="all"||M.key===state.mode) &&
    (state.filter==="all"||vkey(r.verdict)===state.filter) &&
    (label(r)+" "+(r.client||"")).toLowerCase().includes(q));
}

function thresholdVerdict(tier, worst, denom){
  if (tier.accepted_via_config)
    return ` <b>Accepted via config override</b>${tier.accept_reason?` - ${esc(tier.accept_reason)}`:""}.`;
  if (!tier.threshold_pct || !denom) return "";
  const p = 100*worst/denom;
  return p<=tier.threshold_pct
    ? ` <b>Within the accepted threshold</b> (worst ${pct(worst,denom)} of ${tier.threshold_pct}%).`
    : ` <b>Exceeds the ${tier.threshold_pct}% threshold</b> (worst ${pct(worst,denom)}).`;
}

/* ---------- shared components ---------- */
function stat(M, lbl, leftVal, rightVal, delta){
  const dcell = delta==null ? "" :
    `<span class="d ${Number(delta)===0?"ok":"bad"}"><i>diff</i>${(delta>0?"+":"")+fmt(delta)}</span>`;
  return `<div><div class="statlabel">${esc(lbl)}</div><div class="stat">
    <span class="p"><i>${esc(M.left)}</i>${fmt(leftVal)}</span>
    <span class="u"><i>${esc(M.right)}</i>${fmt(rightVal)}</span>${dcell}</div></div>`;
}
function dataTable(cols, rowsArr){
  return `<div class="table-wrap"><table class="data"><thead><tr>${
    cols.map(c=>`<th>${esc(c)}</th>`).join("")}</tr></thead><tbody>${
    rowsArr.map(row=>`<tr>${row.join("")}</tr>`).join("")}</tbody></table></div>`;
}
const VISIBLE_SAMPLE_ROWS = 10;
function toggleRows(btn){
  const tbl = btn.parentElement.querySelector("table.data");
  const open = tbl.classList.toggle("xopen");
  btn.textContent = open ? "Show first "+VISIBLE_SAMPLE_ROWS : btn.dataset.all;
}
function sampleTable(title, columns, rowsArr, maxDataCols=5){
  const rowsAll = rowsArr||[];
  if (!rowsAll.length) return "";
  const cols = (columns||[]).length ? columns : rowsAll[0].map((_,i)=>`col${i+1}`);
  const isKey = c => /^(client_(name|region)|id|n)$/i.test(String(c));
  const keep=new Set(); cols.forEach((c,i)=>{ if(isKey(c)) keep.add(i); });
  let taken=0; cols.forEach((c,i)=>{ if(!isKey(c)&&taken<maxDataCols){ keep.add(i); taken++; } });
  const idx=[...keep].sort((a,b)=>a-b);
  const body = rowsAll.map((row,ri)=>`<tr${ri>=VISIBLE_SAMPLE_ROWS?' class="xrow"':""}>${
    idx.map(i=>`<td>${esc(renderValue(row[i]))}</td>`).join("")}</tr>`).join("");
  const toggle = rowsAll.length>VISIBLE_SAMPLE_ROWS
    ? `<button class="xtoggle" data-all="Show all ${rowsAll.length} rows" onclick="toggleRows(this)">Show all ${rowsAll.length} rows</button>` : "";
  return `<div><div class="statlabel">${esc(title)}${cols.length>idx.length?` (${idx.length} of ${cols.length} columns)`:""}${
    rowsAll.length>VISIBLE_SAMPLE_ROWS?` - showing ${VISIBLE_SAMPLE_ROWS} of ${rowsAll.length}`:""}</div>
    <div class="table-wrap"><table class="data"><thead><tr>${
      idx.map(i=>`<th>${esc(cols[i])}</th>`).join("")}</tr></thead><tbody>${body}</tbody></table></div>${toggle}</div>`;
}
function sqlBlocks(tier){
  let qs = Array.isArray(tier.queries) ? tier.queries.slice() : [];
  if (!qs.length && tier.sql) qs=[tier.sql];
  qs = qs.filter(Boolean);
  if (!qs.length) return "";
  return qs.map((s,i)=>`<div class="sql"><div class="sql-hd"><b>Query${qs.length>1?" "+(i+1):""}</b>
    <button class="copy" data-sql="${esc(s)}">Copy</button></div><pre>${esc(s)}</pre></div>`).join("");
}
/* direction dicts use side-specific key names (in_prod_not_uat / in_redshift_not_snowflake)
   - render them with the mode's own side labels rather than the raw payload words. */
function dirLabel(k, M){
  const m = /^in_(.+?)_not_(.+)$/.exec(String(k));
  if (!m) return String(k).replace(/_/g," ");
  const nice = s => { const u=s.toUpperCase();
    return u===String(M.left).toUpperCase()||u===String(M.right).toUpperCase() ? u
         : s==="prod" ? M.left : s==="uat" ? M.right : u; };
  return `only in ${nice(m[1])} (absent from ${nice(m[2])})`;
}
function dirPair(d){ const e=Object.entries(d||{}); return e.length>=2?e:e.concat([["",0]]); }

/* ---------- per-tier plain-language summary ---------- */
function tierSummary(M, key, tier){
  const st=tier.status;
  if (st==="ERROR") return "Check failed - see error below.";
  if (st==="DRY") return "Dry run - SQL generated, not executed.";
  if (st==="SKIPPED") return esc(tier.reason || "Skipped.");
  const T = M.tiers.indexOf(key);

  /* file presence (CSV only) */
  if (tier.present){
    const miss=Object.entries(tier.present).filter(([,v])=>!v).map(([k])=>k);
    return miss.length ? `<b>Missing on the ${miss.map(esc).join(" and ")} side</b> - nothing to compare, ladder stopped.`
                       : "File present in both run folders.";
  }
  /* header / schema parity */
  if (key==="C1"||key==="D0"||key==="T0"){
    const n=(tier.drift||[]).length;
    if (!n) return "Columns match exactly (names, order, types).";
    const ol=tier.only_in_redshift||[], or=tier.only_in_snowflake||[];
    const extras=[];
    if (ol.length) extras.push(`${ol.length} only in ${esc(M.left)}: ${esc(ol.slice(0,4).join(", "))}`);
    if (or.length) extras.push(`${or.length} only in ${esc(M.right)}: ${esc(or.slice(0,4).join(", "))}`);
    const renamed = ol.length===or.length && ol.length && n===ol.length;
    return `<b>${n} column${n>1?"s":""} drifted</b>${
      renamed?` - looks like a rename`:""}${extras.length?` (${extras.join("; ")})`:""} - every content tier below is withheld until the schemas agree.`;
  }
  /* grain uniqueness */
  if (key==="D1"||key==="T1"){
    if (!tier.dups) return "No detail recorded.";
    if (tier.grain_unique) return "Grain is unique on both sides.";
    const pd=(tier.dups.prod||{}).dup_key_count||0, ud=(tier.dups.uat||{}).dup_key_count||0;
    const txt=`<b>Grain is NOT unique</b> - ${esc(M.left)} ${fmt(pd)} / ${esc(M.right)} ${fmt(ud)} duplicate grain keys`;
    const tv=thresholdVerdict(tier, Math.max(pd,ud), tier.denominator);
    return st==="ACCEPTED" ? `${txt} - key-based tiers proceed with minor fan-out risk.${tv}`
                           : `${txt}; the key-based tiers below would fan out and are unreliable.${tv}`;
  }
  /* row counts */
  if (key==="C2"){
    const l=tier.redshift_rows, r=tier.snowflake_rows, d=tier.diff||0;
    if (!d) return `Row counts agree (${fmt(l)} rows on both sides).`;
    return `<b>Row counts differ</b> - ${esc(M.left)} ${fmt(l)} vs ${esc(M.right)} ${fmt(r)} (${d>0?"+":""}${fmt(d)}).`
      + thresholdVerdict(tier, Math.abs(d), tier.denominator||l);
  }
  /* key-set diff (+ row counts for DWI D2) */
  if (key==="C3"||key==="D2"||key==="T2"){
    const parts=[]; let worst=0; const den=tier.denominator||tier.prod_rows||tier.redshift_rows;
    if (tier.prod_rows!=null){
      // BI harness calls it row_diff, this harness calls it diff; fall back to
      // subtracting so a real gap can never render as "counts agree".
      const d = tier.diff ?? tier.row_diff ?? ((tier.prod_rows||0)-(tier.uat_rows||0));
      parts.push(d? `Rows: ${esc(M.left)} ${fmt(tier.prod_rows)} vs ${esc(M.right)} ${fmt(tier.uat_rows)} (${d>0?"+":""}${fmt(d)}).`
                  : `Row counts agree (${fmt(tier.prod_rows)}).`);
      worst=Math.max(worst,Math.abs(d));
    }
    if (tier.key_diff){
      const [a,b]=dirPair(tier.key_diff);
      worst=Math.max(worst,a[1]||0,b[1]||0);
      parts.push((!a[1]&&!b[1]) ? "Key sets are identical."
        : `Keys: <b>${fmt(a[1])}</b>${den?` (${pct(a[1],den)})`:""} ${esc(dirLabel(a[0],M))}, <b>${fmt(b[1])}</b>${den?` (${pct(b[1],den)})`:""} ${esc(dirLabel(b[0],M))}.`);
    }
    if (tier.shared_keys!=null) parts.push(`${fmt(tier.shared_keys)} shared keys carried into the column-level tier.`);
    if (tier.grain_unique===false) parts.push("<b>Grain is not unique</b> in the extracts - key counts may fan out.");
    return parts.join(" ") + (worst?thresholdVerdict(tier, worst, den):"");
  }
  /* column-level diff */
  if (key==="C4"||key==="D3"||key==="T3"){
    const mc=tier.mismatched_columns||{}; const n=Object.keys(mc).length;
    if (!n) return tier.reason ? esc(tier.reason) : `No column-level mismatches across ${fmt(tier.shared_keys)} shared keys.`;
    const cs=tier.column_status||{};
    const failing=Object.keys(mc).filter(c=>(cs[c]||"FAIL")==="FAIL").length;
    const accepted=n-failing;
    const worst=Object.entries(mc).sort((a,b)=>b[1]-a[1])[0];
    let txt=`<b>${n} column${n>1?"s":""} ${n>1?"disagree":"disagrees"}</b> across ${fmt(tier.shared_keys)} shared keys - worst: <b>${esc(worst[0])}</b> (${fmt(worst[1])} keys).`;
    if (accepted) txt += ` ${failing?`<b>${failing}</b> failing, `:""}<b>${accepted}</b> accepted (marked or within threshold).`;
    if (tier.accepted_via_config) txt += ` <b>Tier accepted via config override</b>${tier.accept_reason?` - ${esc(tier.accept_reason)}`:""}.`;
    return txt;
  }
  /* fingerprint */
  if (key==="C5"||key==="D4"||key==="T4"){
    if (tier.accepted_via_config) return `<b>Fingerprints differ</b> - accepted via config override${tier.accept_reason?`: ${esc(tier.accept_reason)}`:""}.`;
    if (st==="PASS") return "Fingerprints match - the two sets are identical under the normalised projection.";
    if (st==="FAIL") return "<b>Fingerprints differ</b> - the sets are not identical.";
    return esc(tier.reason || "No fingerprint result recorded.");
  }
  return "";
}

/* ---------- per-tier detail ---------- */
function tierBody(M, key, tier){
  const parts=[];
  if (tier.status==="DRY"){
    // Nothing executed - any counter in the payload is a default, not a measurement.
    // Show the generated SQL only, so a dry run can be reviewed without reading
    // zeros as results.
    const sqlOnly=sqlBlocks(tier);
    return sqlOnly || `<div class="kv"><span>No SQL generated for this tier.</span></div>`;
  }

  if (tier.present && Object.values(tier.present).some(v=>!v))
    parts.push(`<div class="kv">${Object.entries(tier.present).map(([k,v])=>
      `<span>${esc(k)}:</span> ${v?"present":"<b>missing</b>"}`).join("&ensp;&middot;&ensp;")}</div>`);

  if ((key==="C1"||key==="D0"||key==="T0") && (tier.drift||[]).length){
    const isCsv = key==="C1";
    const anyAt = tier.drift.some(d=>d.snowflake_column_at_position);
    const cols = ["Column", `${M.left} pos${isCsv?"":"/type"}`, `${M.right} pos${isCsv?"":"/type"}`];
    if (anyAt) cols.push(`${M.right} column at that position`);
    parts.push(dataTable(cols, tier.drift.map(d=>{
      const row=[
        `<td>${esc(d.column??"")}</td>`,
        `<td>${esc(d.redshift_ord ?? d.prod_ord ?? "-")}${isCsv?"":" / "+esc(d.prod_type??"-")}</td>`,
        `<td>${esc(d.snowflake_ord ?? d.uat_ord ?? "-")}${isCsv?"":" / "+esc(d.uat_type??"-")}</td>`];
      if (anyAt) row.push(`<td>${esc(d.snowflake_column_at_position ?? "-")}</td>`);
      return row;
    })));
    if ((tier.only_in_redshift||[]).length||(tier.only_in_snowflake||[]).length)
      parts.push(`<div class="kv"><span>only in ${esc(M.left)}:</span> ${
        esc((tier.only_in_redshift||[]).join(", ")||"-")}&ensp;&middot;&ensp;<span>only in ${esc(M.right)}:</span> ${
        esc((tier.only_in_snowflake||[]).join(", ")||"-")}</div>`);
  }

  if ((key==="D1"||key==="T1") && tier.dups){
    parts.push(`<div class="statrow">${stat(M,"Duplicate grain keys",
      (tier.dups.prod||{}).dup_key_count,(tier.dups.uat||{}).dup_key_count,null)}</div>`);
    const lbl={prod:`Duplicate grain keys in ${M.left} (worst first)`,uat:`Duplicate grain keys in ${M.right} (worst first)`};
    const blocks=Object.entries(tier.sample_rows||{}).map(([env,rows])=>
      sampleTable(lbl[env]||env, tier.sample_columns, rows)).filter(Boolean);
    if (blocks.length) parts.push(`<div class="samples">${blocks.join("")}</div>`);
  }

  if (key==="C3" && tier.duplicate_keys)
    parts.push(`<div class="statrow">${stat(M,"Duplicate grain keys in extract",
      tier.duplicate_keys.redshift, tier.duplicate_keys.snowflake, null)}</div>`);

  if (key==="C2" && tier.redshift_rows!=null)
    parts.push(`<div class="statrow">${stat(M,"Rows in extract",tier.redshift_rows,tier.snowflake_rows,tier.diff)}</div>`);

  if ((key==="C3"||key==="D2"||key==="T2")){
    const bits=[];
    if (tier.prod_rows!=null) bits.push(stat(M,"Rows (as counted)",tier.prod_rows,tier.uat_rows,
      tier.diff ?? tier.row_diff ?? ((tier.prod_rows||0)-(tier.uat_rows||0))));
    if (tier.key_diff){ const [a,b]=dirPair(tier.key_diff);
      bits.push(stat(M,"Grain keys only on one side",a[1],b[1],null)); }
    if (bits.length) parts.push(`<div class="statrow">${bits.join("")}</div>`);
    if (tier.key_columns) parts.push(`<div class="kv"><span>grain:</span> ${esc(tier.key_columns.join(", "))}</div>`);
    const ks=tier.key_samples||{};
    const blocks=Object.entries(ks).map(([dir,rows])=>
      sampleTable(`Sample keys ${dirLabel(dir,M)}`, tier.key_columns, rows)).filter(Boolean);
    if (blocks.length) parts.push(`<div class="samples">${blocks.join("")}</div>`);
  }

  if ((key==="C4"||key==="D3"||key==="T3") && tier.mismatched_columns
      && Object.keys(tier.mismatched_columns).length){
    const total=Number(tier.shared_keys||0);
    const residual=tier.residual_mismatches||{};
    const order=Object.entries(tier.mismatched_columns).sort((a,b)=>{
      const aw=a[0] in residual, bw=b[0] in residual;
      if (aw!==bw) return aw?-1:1;
      if (aw&&bw) return residual[b[0]]-residual[a[0]];
      return b[1]-a[1];
    });
    parts.push(`<div class="kv"><span>shared keys:</span> ${fmt(total)}${
      Object.keys(tier.excluded_columns||{}).length?`&ensp;<span>excluded:</span> ${
        esc(Object.keys(tier.excluded_columns).join(", "))}`:""}</div>`);
    const sc=tier.column_sample_columns||[];
    const isL=c=>new RegExp("^"+M.left+"[ _]value$","i").test(String(c));
    const isR=c=>new RegExp("^"+M.right+"[ _]value$","i").test(String(c));
    parts.push(order.map(([c,nMis])=>{
      const p = total ? (100*Number(nMis)/total).toFixed(2) : "0.00";
      const rows=(tier.column_samples||{})[c];
      let body="";
      if (rows&&rows.length){
        body=`<div class="table-wrap"><table class="data"><thead><tr>${
          sc.map(cc=>`<th${isL(cc)?' class="thp"':isR(cc)?' class="thu"':""}>${esc(cc)}</th>`).join("")
        }</tr></thead><tbody>${
          rows.slice(0,8).map(row=>`<tr>${row.map((v,i)=>{
            const cc=sc[i]||"";
            if (isL(cc)||isR(cc))
              return `<td class="${isL(cc)?"tdp":"tdu"}"><div class="val" title="${esc(renderValue(v))}">${esc(renderValue(v))}</div></td>`;
            return `<td>${esc(renderValue(v))}</td>`;
          }).join("")}</tr>`).join("")}</tbody></table></div>`;
      } else if (tier.column_samples && !(c in tier.column_samples)){
        body=`<div class="kv"><span>Not sampled this run - outside the top columns captured.</span></div>`;
      }
      const cst=(tier.column_status||{})[c]||"FAIL";
      const badge = cst==="FAIL" ? `<span class="colbadge fail">fail</span>`
        : cst==="ACCEPTED_THRESHOLD" ? `<span class="colbadge acc">accepted - within threshold</span>`
        : `<span class="colbadge acc">accepted - marked</span>`;
      const reason=(tier.accepted_reasons||{})[c];
      const whereSql=(tier.accepted_where||{})[c];
      const res = c in residual
        ? `<span>${fmt(nMis)} differ, <b>${fmt(residual[c])} residual</b> after the accepted pattern (${p}% raw)</span>`
        : `<span>${fmt(nMis)} of ${fmt(total)} shared keys differ (${p}%)</span>`;
      return `<div class="t4col"><div class="t4col-hd"><b>${esc(c)}</b>${res}${badge}${
        reason?`<span>- ${esc(reason)}</span>`:""}</div>${
        whereSql?`<div class="wherebox"><span>accepted where:</span><code>${esc(whereSql)}</code></div>`:""}${body}</div>`;
    }).join(""));
  }

  if (key==="C5" && (tier.redshift_fingerprint||tier.snowflake_fingerprint))
    parts.push(`<div class="fp"><span>${esc(M.left)} <code>${esc(tier.redshift_fingerprint||"-")}</code></span>
      <span>${esc(M.right)} <code>${esc(tier.snowflake_fingerprint||"-")}</code></span></div>`);
  if ((key==="D4"||key==="T4") && tier.distinct_fingerprints!=null)
    parts.push(`<div class="kv"><span>distinct fingerprints across both sides:</span> ${fmt(tier.distinct_fingerprints)} <span>(1 = identical)</span></div>`);

  for (const w of (tier.warnings||[])) parts.push(`<div class="kv"><span>! ${esc(w)}</span></div>`);
  if (tier.error) parts.push(`<div class="errbox">${esc(tier.error)}</div>`);
  const sql=sqlBlocks(tier);
  if (sql) parts.push(sql);
  return parts.join("");
}

function tierCard(M, key, tier){
  const st=(tier.status||"none").toLowerCase();
  if ((st==="skipped"||st==="none") && !tier.error && !tier.sql && !(tier.queries||[]).length)
    return `<div class="tier line ${st}"><span class="tk">${key}</span>
      <span>${esc(M.labels[key]||key)} - skipped${tier.reason?` - ${esc(tier.reason)}`:""}</span></div>`;
  const ov = tier.accepted_via_config
    ? `<span class="tier-badge accepted" title="${tier.accept_reason?esc(tier.accept_reason):'accept_diff config override'}">config override</span>` : "";
  return `<div class="tier ${st}">
    <div class="tier-hd"><span class="tk">${key}</span><span class="tl">${esc(M.labels[key]||key)}</span>
      <span class="spacer"></span>${ov}<span class="tier-badge ${st}">${esc(tier.status||"none")}</span></div>
    <div class="tier-sum">${tierSummary(M,key,tier)}</div>
    <div class="tier-bd">${tierBody(M,key,tier)}</div></div>`;
}

/* ---------- page assembly ---------- */
function kpis(run){
  const rows=allRows(run).filter(({M})=>state.mode==="all"||M.key===state.mode);
  const c={PASS:0,ACC:0,DIFFS:0,BLOCKED:0,ERROR:0,DRIFT:0,DRY:0,NOGRAIN:0,none:0};
  rows.forEach(({r})=>c[vkey(r.verdict)]++);
  document.getElementById("kpis").innerHTML=`
    <div class="kpi"><div class="n">${rows.length}</div><div class="l">Comparisons</div></div>
    ${c.DRY?`<div class="kpi"><div class="n">${c.DRY}</div><div class="l">Dry run</div></div>`:""}
    <div class="kpi pass"><div class="n">${c.PASS}</div><div class="l">Pass</div></div>
    <div class="kpi acc"><div class="n">${c.ACC}</div><div class="l">Diffs accepted</div></div>
    <div class="kpi fail"><div class="n">${c.DIFFS}</div><div class="l">Diffs found</div></div>
    ${c.NOGRAIN?`<div class="kpi blocked"><div class="n">${c.NOGRAIN}</div><div class="l">No grain (partial)</div></div>`:""}
    <div class="kpi blocked"><div class="n">${c.BLOCKED}</div><div class="l">Blocked</div></div>
    <div class="kpi err"><div class="n">${c.ERROR+c.DRIFT}</div><div class="l">Error / drift</div></div>`;
  document.getElementById("spectrum").innerHTML = rows.map(({r})=>
    `<a href="#${anchor(r)}" style="background:${vcolor[vkey(r.verdict)]}" title="${esc(label(r))}${
      r.client?" ("+esc(r.client)+")":""} - ${vlabel[vkey(r.verdict)]}"></a>`).join("");
  const run_ = run;
  document.getElementById("dry").innerHTML = run_.dry_run
    ? `<div class="drybanner"><b>Dry run.</b> SQL and file plans were generated but nothing was executed - tier statuses read <code>DRY</code> and verdicts are withheld.</div>` : "";
  document.getElementById("scopelbl").textContent =
    Object.values(MODES).filter(M=>(run[M.key]||[]).length).map(M=>M.scope).join("  |  ");
}

/* one board per mode present */
function boards(run){
  const el=document.getElementById("boards");
  const out=[];
  for (const M of Object.values(MODES)){
    const rows=visible(run).filter(x=>x.M.key===M.key);
    if (!(run[M.key]||[]).length) continue;
    if (state.mode!=="all" && state.mode!==M.key) continue;
    const nT=M.tiers.length, nId=M.idcols.length;
    const grid=`grid-template-columns:minmax(240px,1fr) repeat(${nT},52px) 160px`;
    let body;
    if (!rows.length){
      body=`<div class="empty">No rows match - clear the filter or search.</div>`;
    } else {
      body=rows.map(({r})=>{
        const vk=vkey(r.verdict);
        return `<a class="trow" style="${grid}" href="#${anchor(r)}">
          <span class="tname">${esc(label(r))}${r.client?` <em>&middot; ${esc(r.client)}</em>`:""}</span>
          ${M.tiers.map(k=>`<span class="cell ${tierStatus(r,k)}" title="${k} ${esc(M.labels[k]||"")}: ${tierStatus(r,k)}"></span>`).join("")}
          <span class="verdict v-${vk}">${vlabel[vk]}</span></a>`;
      }).join("");
    }
    out.push(`<h2 class="sect">${esc(M.title)} <span class="n">${esc(M.scope)}</span></h2>
      <div class="board"><div class="thead" style="${grid}">
        <div>${esc(M.idcols.join(" / "))}</div>${M.tiers.map(k=>`<div title="${esc(M.labels[k]||"")}">${k}</div>`).join("")}<div>Verdict</div>
      </div>${body}</div>`);
  }
  el.innerHTML = out.join("") || `<div class="empty">Nothing to show for this mode.</div>`;
}

function sections(run){
  const el=document.getElementById("sections");
  const vis=visible(run);
  if(!vis.length){ el.innerHTML=`<div class="empty">No rows match - clear the filter or search.</div>`; return; }
  el.innerHTML=vis.map(({r,M})=>{
    const vk=vkey(r.verdict);
    const rt=r.runtime_seconds!=null?`${Number(r.runtime_seconds).toFixed(1)}s`:null;
    const runs=(r.redshift_run||r.snowflake_run)
      ? `<span class="meta">${esc(M.left)} run ${esc(r.redshift_run||"-")} vs ${esc(M.right)} run ${esc(r.snowflake_run||"-")}</span>` : "";
    return `<section class="tsection" id="${anchor(r)}">
      <div class="thd">
        <span class="tname">${esc(label(r))}</span>
        ${r.client?`<span class="meta">${esc(r.client)}</span>`:""}
        <span class="verdict v-${vk}">${vlabel[vk]}</span>
        <span class="badge mode">${esc(M.key==="csv"?"S3 CSV":M.key==="dwi"?"warehouse":"BI")}</span>
        ${rt?`<span class="meta">runtime ${rt}</span>`:""}
        ${runs}
        ${r.review_required?`<span class="badge review">review required</span>`:""}
        ${(r.expected_blocked||[]).map(b=>`<span class="badge">expected: ${esc(b)}</span>`).join("")}
        <span class="spacer"></span>
        <span class="meta"><a href="#top" onclick="window.scrollTo({top:0});return false;">&uarr; summary</a></span>
      </div>
      <div class="tbody">
        ${M.tiers.map(k=>tierCard(M,k,(r.tiers||{})[k]||{})).join("")}
        ${(r.notes&&r.notes.length)?`<div><div class="statlabel">Notes</div><ul class="notes">${
          r.notes.map(n=>`<li>${esc(n)}</li>`).join("")}</ul></div>`:""}
      </div></section>`;
  }).join("");
  el.querySelectorAll(".copy").forEach(b=>b.addEventListener("click",()=>{
    if(navigator.clipboard) navigator.clipboard.writeText(b.dataset.sql).then(()=>{
      b.textContent="Copied"; setTimeout(()=>b.textContent="Copy",1200);
    });
  }));
}

function history(){
  const el=document.getElementById("hist");
  const keys=new Map();
  RUNS.forEach(run=>allRows(run).forEach(({r,M})=>{
    if (state.mode!=="all" && M.key!==state.mode) return;
    keys.set(rid(r), label(r)+(r.client?" \u00b7 "+r.client:""));
  }));
  const ids=[...keys.keys()].sort();
  if (!ids.length){ el.innerHTML=`<div class="empty">No history for this mode.</div>`; return; }
  el.style.gridTemplateColumns=`minmax(220px,320px) repeat(${RUNS.length}, minmax(34px,60px))`;
  let h=`<div></div>`+RUNS.map(r=>`<div class="hhead" title="${esc(r.label)}">${esc(r.label.split(",")[0])}</div>`).join("");
  for(const id of ids){
    h+=`<div class="hname" title="${esc(keys.get(id))}">${esc(keys.get(id))}</div>`;
    for(const run of RUNS){
      const rec=allRows(run).find(({r})=>rid(r)===id);
      const vk=rec?vkey(rec.r.verdict):"none";
      h+=`<div class="hcell ${vk}" title="${esc(keys.get(id))} - ${esc(run.label)} - ${vlabel[vk]}"></div>`;
    }
  }
  el.innerHTML=h;
}

function render(){ const run=RUNS[state.run]; kpis(run); boards(run); sections(run); history(); }

function boot(){
  const sel=document.getElementById("runSel");
  sel.innerHTML=RUNS.map((r,i)=>`<option value="${i}" ${i===state.run?"selected":""}>${esc(r.label)}</option>`).join("");
  sel.addEventListener("change",e=>{state.run=+e.target.value;render();});
  document.getElementById("search").addEventListener("input",e=>{state.q=e.target.value;boards(RUNS[state.run]);sections(RUNS[state.run]);});
  document.querySelectorAll(".chip").forEach(c=>c.addEventListener("click",()=>{
    const g=c.dataset.g;
    document.querySelectorAll(`.chip[data-g="${g}"]`).forEach(x=>x.setAttribute("aria-pressed",x===c?"true":"false"));
    if (g==="mode") state.mode=c.dataset.m; else state.filter=c.dataset.f;
    render();
  }));
  document.getElementById("foot").textContent=
    `${RUNS.length} run(s) - generated ${new Date().toLocaleString("en-AU")} - dashboard.py - print (Ctrl+P) for a PDF export`;
  render();
}
function exportHtml(){
  const blob=new Blob(["<!DOCTYPE html>\n"+document.documentElement.outerHTML],{type:"text/html"});
  const a=document.createElement("a");
  a.href=URL.createObjectURL(blob); a.download="dwi_comparison_dashboard.html";
  a.click(); URL.revokeObjectURL(a.href);
}
boot();
</script></body></html>"""


if __name__ == "__main__":
    main()
