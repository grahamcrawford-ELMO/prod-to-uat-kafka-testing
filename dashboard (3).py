#!/usr/bin/env python3
"""
Generate a self-contained dashboard.html from all results_*/results.json runs.

Usage:
  python dashboard.py                 # scan ./results_* and write dashboard.html
  python dashboard.py --dir path      # scan a different base directory
  python dashboard.py --out file.html
No dependencies, no server, no CDN — open the file straight from disk.
Everything is always visible (no collapsed sections) and print-ready:
Ctrl+P / "Save as PDF" produces a complete report.
"""

import argparse
import json
import re
from datetime import datetime
from pathlib import Path

RUN_DIR_RE = re.compile(r"results_(\d{8}_\d{4})$")


def collect_runs(base: Path):
    runs = []
    for d in sorted(base.glob("results_*")):
        m = RUN_DIR_RE.search(d.name)
        f = d / "results.json"
        if not (m and f.exists()):
            continue
        try:
            results = json.loads(f.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        ts = datetime.strptime(m.group(1), "%Y%m%d_%H%M")
        runs.append({
            "id": d.name,
            "label": ts.strftime("%d %b %Y, %H:%M"),
            "ts": ts.isoformat(),
            "results": results,
        })
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
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kafka Migration — Test Ladder</title>
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
  --prod:#2F4B7C; --uat:#0D7E83;
  --mono:"Cascadia Mono","Cascadia Code",ui-monospace,"JetBrains Mono",Consolas,monospace;
  --sans:"Segoe UI Variable Text","Segoe UI",system-ui,-apple-system,sans-serif;
}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--paper);color:var(--ink);font:15px/1.5 var(--sans);padding:0 0 90px}
a{color:inherit;text-decoration:none}
.wrap{width:100%;max-width:1240px;margin:0 auto;padding:0 26px}

/* masthead */
header{border-bottom:1px solid var(--line);background:var(--card);position:sticky;top:0;z-index:5}
.mast{display:flex;align-items:baseline;gap:18px;padding:15px 0;flex-wrap:wrap}
.mast h1{font-size:17px;font-weight:650}
.mast .sub{font-family:var(--mono);font-size:12px;color:var(--ink-soft)}
.mast .spacer{flex:1}
select,input[type=search]{font:13px var(--mono);color:var(--ink);background:var(--card);
  border:1px solid var(--line);border-radius:6px;padding:7px 10px}
select{cursor:pointer}
:focus-visible{outline:2px solid var(--prod);outline-offset:2px}

/* KPI band + spectrum */
.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin:26px 0 8px}
.kpi{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:13px 16px}
.kpi .n{font:600 29px/1.1 var(--mono)}
.kpi .l{font-size:12px;color:var(--ink-soft);margin-top:3px;text-transform:uppercase;letter-spacing:.06em}
.kpi.pass .n{color:var(--pass)} .kpi.fail .n{color:var(--fail)}
.kpi.blocked .n{color:var(--blocked)} .kpi.err .n{color:var(--err)}
.kpi.acc .n{color:var(--acc)}
.spectrum{display:flex;gap:3px;margin:14px 0 8px;height:10px}
.spectrum a{flex:1;border-radius:2px}
.legend{display:flex;gap:16px;flex-wrap:wrap;font-size:12px;color:var(--ink-soft);margin:0 0 26px}
.legend i{display:inline-block;width:10px;height:10px;border-radius:2px;margin-right:5px;vertical-align:-1px}

/* controls (screen only) */
.controls{display:flex;gap:10px;margin:0 0 14px;flex-wrap:wrap;align-items:center}
.chip{font:12px var(--sans);border:1px solid var(--line);background:var(--card);border-radius:99px;
  padding:5px 12px;cursor:pointer;color:var(--ink-soft)}
.chip[aria-pressed="true"]{border-color:var(--ink);color:var(--ink);font-weight:600}

/* summary board */
.board{background:var(--card);border:1px solid var(--line);border-radius:12px;overflow:hidden;margin-bottom:44px}
.thead,.trow{display:grid;grid-template-columns:minmax(280px,1fr) repeat(6,52px) 150px;align-items:center}
.thead{font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--ink-soft);
  border-bottom:1px solid var(--line);padding:10px 16px}
.thead div{text-align:center}.thead div:first-child{text-align:left}.thead div:last-child{text-align:right}
.trow{padding:10px 16px;border-bottom:1px solid var(--line-soft)}
.trow:last-child{border-bottom:none}
.trow:hover{background:#F8FAFB}
.trow .tname{font-family:var(--mono);font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;padding-right:12px}
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
.v-ERROR,.v-T0{background:var(--err-bg);color:var(--err)}
.v-ACC{background:var(--acc-bg);color:var(--acc)}

/* per-table report sections */
h2.sect{font-size:13px;text-transform:uppercase;letter-spacing:.1em;color:var(--ink-soft);margin:44px 0 12px}
.tsection{background:var(--card);border:1px solid var(--line);border-radius:12px;margin:0 0 22px;overflow:hidden}
.tsection > .thd{display:flex;align-items:center;gap:14px;flex-wrap:wrap;padding:14px 18px;
  border-bottom:1px solid var(--line);background:#FBFCFD}
.thd .tname{font:600 15px var(--mono)}
.thd .meta{font:12px var(--mono);color:var(--ink-soft)}
.thd .spacer{flex:1}
.badge{font:600 11px var(--sans);background:var(--blocked-bg);color:var(--blocked);border-radius:99px;padding:4px 10px}
.badge.review{background:var(--err-bg);color:var(--err)}
.tbody{padding:16px 18px;display:grid;gap:12px}

/* tier cards — status colors the left edge */
.tier{border:1px solid var(--line-soft);border-left-width:4px;border-radius:10px;background:var(--card);min-width:0;overflow:hidden}
.tier.pass{border-left-color:var(--pass)} .tier.fail{border-left-color:var(--fail)}
.tier.error{border-left-color:var(--err)}
.tier.accepted{border-left-color:var(--acc)} .tier.skipped,.tier.none{border-left-color:var(--line)}
.tier.dry{border-left-color:var(--prod)}
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
.tier-badge.dry{background:#E9F2FF;color:var(--prod)}
.tier-sum{padding:6px 14px 0;font-size:13.5px}
.tier-sum b{font-weight:600}
.tier-bd{padding:10px 14px 12px;display:grid;gap:10px;min-width:0}
.tier-bd > *{min-width:0;max-width:100%}
.tbody{min-width:0}
.tbody > *{min-width:0}
/* compact single-line form for skipped tiers — visible, just quiet */
.tier.line{display:flex;align-items:center;gap:12px;padding:8px 14px;color:var(--ink-soft);font-size:13px}
.tier.line .tk{font:600 12.5px var(--mono);color:var(--ink-soft)}

/* the one consistent PROD/UAT/Δ component */
.stat{display:inline-grid;grid-template-columns:auto auto auto;gap:0;border:1px solid var(--line-soft);
  border-radius:8px;overflow:hidden;font-family:var(--mono);font-size:13px}
.stat > span{padding:7px 14px;display:flex;flex-direction:column;gap:1px}
.stat i{font:600 10px var(--sans);font-style:normal;text-transform:uppercase;letter-spacing:.07em}
.stat .p{background:#F4F6FA} .stat .p i{color:var(--prod)}
.stat .u{background:#F2F8F8;border-left:1px solid var(--line-soft)} .stat .u i{color:var(--uat)}
.stat .d{border-left:1px solid var(--line-soft)} .stat .d i{color:var(--ink-soft)}
.stat .d.bad{background:var(--fail-bg);color:var(--fail)}
.stat .d.ok{background:var(--pass-bg);color:var(--pass)}
.statrow{display:flex;gap:12px;flex-wrap:wrap;align-items:flex-start}
.statlabel{font:600 11px var(--sans);text-transform:uppercase;letter-spacing:.06em;color:var(--ink-soft);margin-bottom:4px}

/* tables (schema drift, samples, T4) */
.table-wrap{overflow:auto;border:1px solid var(--line-soft);border-radius:8px;width:fit-content;max-width:100%}
table.data{border-collapse:collapse;font-size:12px;font-family:var(--mono)}
table.data th,table.data td{padding:6px 12px;border-bottom:1px solid var(--line-soft);text-align:left;white-space:nowrap}
table.data th{font:600 10.5px var(--sans);text-transform:uppercase;letter-spacing:.06em;color:var(--ink-soft);background:#F8FAFB}
table.data tr:last-child td{border-bottom:none}
table.data td.num{text-align:right}
.pctbar{position:relative;min-width:150px;height:14px;background:var(--line-soft);border-radius:99px;overflow:hidden}
.pctbar span{position:absolute;inset:0 auto 0 0;background:var(--fail);border-radius:99px}
.pctlbl{font-size:11px;color:var(--ink-soft);margin-left:8px}
.t4col{border:1px solid var(--line-soft);border-radius:8px;padding:10px 12px;display:grid;gap:8px;min-width:0}
.t4col-hd{display:flex;gap:12px;align-items:baseline;flex-wrap:wrap}
.t4col-hd b{font:600 13px var(--mono)}
.t4col-hd span{font:12px var(--mono);color:var(--ink-soft)}
.colbadge{font:600 10px var(--sans);padding:3px 8px;border-radius:99px;text-transform:uppercase;letter-spacing:.04em}
.colbadge.fail{background:var(--fail-bg);color:var(--fail)}
.colbadge.acc{background:var(--acc-bg);color:var(--acc)}
th.thp{color:var(--prod)} th.thu{color:var(--uat)}
td.tdp{background:#F4F6FA} td.tdu{background:#F2F8F8}
td.tdp,td.tdu{white-space:normal;vertical-align:top}
table.data td{vertical-align:top}
.val{max-width:380px;min-width:200px;overflow-wrap:anywhere;white-space:normal;
  display:-webkit-box;-webkit-line-clamp:4;-webkit-box-orient:vertical;overflow:hidden}
.samples{display:flex;gap:14px;flex-wrap:wrap;align-items:flex-start}
tr.xrow{display:none}
table.data.xopen tr.xrow{display:table-row}
.xtoggle{font:11px var(--sans);border:1px solid var(--line);background:var(--card);
  border-radius:6px;padding:4px 10px;cursor:pointer;color:var(--ink-soft);margin-top:6px}
.exportbtn{font:12px var(--sans);border:1px solid var(--line);background:var(--card);
  border-radius:6px;padding:6px 12px;cursor:pointer;color:var(--ink)}
.samples > div{flex:0 1 auto;min-width:0;max-width:100%}
.samples .table-wrap{max-width:100%}

/* SQL — always visible, visually quiet */
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
.empty{color:var(--ink-soft);font-size:13.5px;padding:14px 16px}

/* history */
.hist{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px;overflow-x:auto}
.hgrid{display:grid;gap:4px;align-items:center;font-family:var(--mono);font-size:12px}
.hgrid .hname{white-space:nowrap;overflow:hidden;text-overflow:ellipsis;padding-right:10px}
.hcell{width:100%;height:20px;border-radius:4px}
.hcell.PASS{background:var(--pass)} .hcell.DIFFS{background:var(--fail)}
.hcell.BLOCKED{background:var(--blocked)} .hcell.ERROR,.hcell.T0{background:var(--err)}
.hcell.ACC{background:var(--acc)}
.hcell.none{background:var(--line-soft)}
.hhead{font-size:10.5px;color:var(--ink-soft);writing-mode:vertical-rl;transform:rotate(180deg);
  justify-self:center;max-height:92px;overflow:hidden}
footer{margin-top:56px;font:12px var(--mono);color:var(--ink-soft)}
@media(max-width:860px){
  .thead,.trow{grid-template-columns:minmax(140px,1fr) repeat(6,30px) 100px}
  .cell{height:16px;margin:0 2px}
}

/* print / PDF export — full report, nothing hidden, colors kept */
@media print{
  body{background:#fff;padding:0;font-size:12px}
  *{-webkit-print-color-adjust:exact;print-color-adjust:exact}
  header{position:static;border:none}
  .controls,.copy,.xtoggle,.exportbtn{display:none!important}
  tr.xrow{display:table-row!important}
  .wrap{max-width:none;padding:0 4mm}
  .tsection,.tier,.kpi,.board,.hist{break-inside:avoid}
  .tsection{border-color:#bbb}
  .sql pre{max-height:none}
  a{text-decoration:none}
}
</style>
</head>
<body>
<header><div class="wrap mast">
  <h1>Kafka Migration&ensp;·&ensp;Test Ladder</h1>
  <span class="sub">PROD (Redshift) vs UAT (Kafka) · BI models</span>
  <span class="spacer"></span>
  <button class="exportbtn" onclick="exportHtml()" title="Download this page as a standalone HTML file">⤓ HTML</button>
  <button class="exportbtn" onclick="window.print()" title="Print or save as PDF — all collapsed samples expand automatically">Print / PDF</button>
  <label class="sub" for="runSel">Run&ensp;</label>
  <select id="runSel" aria-label="Select run"></select>
</div></header>

<div class="wrap">
  <div class="kpis" id="kpis"></div>
  <div class="spectrum" id="spectrum" title="Verdict spectrum — one band per table, click to jump"></div>
  <div class="legend">
    <span><i style="background:var(--pass)"></i>Pass</span>
    <span><i style="background:var(--acc)"></i>Diffs accepted</span>
    <span><i style="background:var(--fail)"></i>Diffs found</span>
    <span><i style="background:var(--blocked)"></i>Blocked</span>
    <span><i style="background:var(--err)"></i>Error / T0 drift</span>
    <span><i style="background:var(--skip-bg);border:1px dashed var(--line)"></i>Skipped tier</span>
  </div>

  <h2 class="sect">Summary — click a row to jump to its report</h2>
  <div class="controls">
    <input id="search" type="search" placeholder="Filter tables…" aria-label="Filter tables">
    <button class="chip" data-f="all" aria-pressed="true">All</button>
    <button class="chip" data-f="PASS" aria-pressed="false">Pass</button>
    <button class="chip" data-f="ACC" aria-pressed="false">Accepted</button>
    <button class="chip" data-f="DIFFS" aria-pressed="false">Diffs</button>
    <button class="chip" data-f="BLOCKED" aria-pressed="false">Blocked</button>
    <button class="chip" data-f="ERROR" aria-pressed="false">Error</button>
  </div>
  <div class="board">
    <div class="thead">
      <div>Table</div><div>T0</div><div>T1</div><div>T2</div><div>T3</div><div>T4</div><div>T5</div><div>Verdict</div>
    </div>
    <div id="rows"></div>
  </div>

  <h2 class="sect">Per-table reports</h2>
  <div id="sections"></div>

  <h2 class="sect">History — verdict per table across runs</h2>
  <div class="hist"><div class="hgrid" id="hist"></div></div>

  <footer id="foot"></footer>
</div>

<script>
const RUNS = /*__DATA__*/null;
const TIERS = ["T0","T1","T2","T3","T4","T5"];
const TEST_LABELS = {T0:"Schema parity",T1:"Row counts",T2:"Grain uniqueness",
  T3:"Key set & full-row EXCEPT (both directions)",T4:"Column-level diff on shared keys",T5:"Aggregate fingerprint"};
const state = { run: RUNS.length-1, filter: "all", q: "" };

const vkey = v => !v ? "none" : v==="PASS" ? "PASS" : v==="BLOCKED" ? "BLOCKED"
  : v.startsWith("PASS (") ? "ACC"
  : v.startsWith("T0") ? "T0" : v==="ERROR" ? "ERROR" : "DIFFS";
const vlabel = {PASS:"Pass",ACC:"Pass · diffs accepted",DIFFS:"Diffs found",BLOCKED:"Blocked",ERROR:"Error",T0:"T0 drift",none:"—"};
const vcolor = {PASS:"var(--pass)",ACC:"var(--acc)",DIFFS:"var(--fail)",BLOCKED:"var(--blocked)",ERROR:"var(--err)",T0:"var(--err)",none:"var(--line-soft)"};
const fmt = n => n==null ? "–" : Number(n).toLocaleString("en-AU");
const esc = s => String(s).replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const anchor = t => "t-" + String(t).replace(/[^A-Za-z0-9_]/g,"_");

const tierStatus = (r,t) => { const x=(r.tiers||{})[t]; return x ? x.status : "none"; };
const pct = (n,d) => (d && n!=null) ? (100*Number(n)/Number(d)).toFixed(3).replace(/\.?0+$/,"")+"%" : null;
function thresholdVerdict(tier, worst, denom){
  if (!tier.threshold_pct || !denom) return "";
  const p = 100*worst/denom;
  return p<=tier.threshold_pct
    ? ` <b>Within the accepted threshold</b> (worst ${pct(worst,denom)} ≤ ${tier.threshold_pct}%).`
    : ` <b>Exceeds the ${tier.threshold_pct}% threshold</b> (worst ${pct(worst,denom)}).`;
}

const renderValue = v => v==null ? "NULL" : typeof v==="boolean" ? String(v)
  : String(v).length>120 ? String(v).slice(0,120)+"…" : String(v);

/* ---------- shared components ---------- */

function stat(label, prodVal, uatVal, delta){
  const dcell = delta==null ? "" :
    `<span class="d ${Number(delta)===0?"ok":"bad"}"><i>Δ</i>${(delta>0?"+":"")+fmt(delta)}</span>`;
  return `<div><div class="statlabel">${esc(label)}</div><div class="stat">
    <span class="p"><i>PROD</i>${fmt(prodVal)}</span>
    <span class="u"><i>UAT</i>${fmt(uatVal)}</span>${dcell}</div></div>`;
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
function sampleTable(title, columns, rowsArr, maxRows=Infinity, maxDataCols=4){
  const rowsAll = (rowsArr||[]).slice(0, maxRows);
  if (!rowsAll.length) return "";
  const cols = (columns||[]).length ? columns : rowsAll[0].map((_,i)=>`col${i+1}`);
  const isClient = c => /^client_(name|region)$/i.test(String(c));
  const keep = new Set();
  cols.forEach((c,i)=>{ if(isClient(c)) keep.add(i); });
  let taken = 0;
  cols.forEach((c,i)=>{ if(!isClient(c) && taken<maxDataCols){ keep.add(i); taken++; } });
  const idx = [...keep].sort((a,b)=>a-b);
  const body = rowsAll.map((row,ri)=>`<tr${ri>=VISIBLE_SAMPLE_ROWS?' class="xrow"':""}>${
    idx.map(i=>`<td>${esc(renderValue(row[i]))}</td>`).join("")}</tr>`).join("");
  const toggle = rowsAll.length>VISIBLE_SAMPLE_ROWS
    ? `<button class="xtoggle" data-all="Show all ${rowsAll.length} rows" onclick="toggleRows(this)">Show all ${rowsAll.length} rows</button>` : "";
  return `<div><div class="statlabel">${esc(title)}${cols.length>idx.length?` (${idx.length} of ${cols.length} columns)`:""}${
    rowsAll.length>VISIBLE_SAMPLE_ROWS?` — showing ${VISIBLE_SAMPLE_ROWS} of ${rowsAll.length}`:""}</div>
    <div class="table-wrap"><table class="data"><thead><tr>${idx.map(i=>`<th>${esc(cols[i])}</th>`).join("")}</tr></thead><tbody>${body}</tbody></table></div>${toggle}</div>`;
}

function sqlBlocks(tier){
  const qs = Array.isArray(tier.queries) ? tier.queries : tier.sql ? [tier.sql] : [];
  return qs.map((s,i)=>`<div class="sql"><div class="sql-hd"><b>Query${qs.length>1?" "+(i+1):""}</b>
    <button class="copy" data-sql="${esc(s)}">Copy</button></div><pre>${esc(s)}</pre></div>`).join("");
}

/* ---------- per-tier plain-language summary ---------- */

function tierSummary(key, tier, all){
  const st = tier.status;
  if (st==="ERROR") return `Query failed — see error below.`;
  const accSuffix = st==="ACCEPTED" && tier.threshold_pct
    ? ` <b>Within the accepted threshold (≤${tier.threshold_pct}%).</b>` : "";
  if (st==="SKIPPED") return esc(tier.reason || "Skipped.");
  if (st==="DRY") return "Dry run — SQL generated, not executed.";
  if (key==="T0"){
    const n=(tier.drift||[]).length;
    return n ? `<b>${n} column${n>1?"s":""} drifted</b> between PROD and UAT — everything below this tier is unreliable until schemas agree.` : "Schemas match exactly (names, order, types).";
  }
  if (key==="T1"){
    if (!("prod_rows" in tier)) return "No result recorded.";
    if (tier.diff===0) return `Row counts match — ${fmt(tier.prod_rows)} rows each (active tenants).`;
    const side = tier.diff>0 ? "PROD has" : "UAT has";
    const denom = Math.max(tier.prod_rows||0, tier.uat_rows||0);
    return `<b>${side} ${fmt(Math.abs(tier.diff))} more rows</b> than the other side`
      + (denom?` (${pct(Math.abs(tier.diff),denom)})`:"") + "."
      + thresholdVerdict(tier, Math.abs(tier.diff), denom);
  }
  if (key==="T2"){
    if (!tier.dups) return "No detail recorded.";
    if (tier.grain_unique) return "Grain is unique on both sides.";
    const pd=(tier.dups?.prod||{}).dup_key_count||0, ud=(tier.dups?.uat||{}).dup_key_count||0;
    const dupTxt = `<b>Grain is NOT unique</b> — PROD ${fmt(pd)} / UAT ${fmt(ud)} duplicate grain keys`;
    const tv = thresholdVerdict(tier, Math.max(pd,ud), tier.denominator);
    return st==="ACCEPTED" ? `${dupTxt} — key-based tests proceed with minor fan-out risk.${tv}`
      : `${dupTxt}; key-based tests (T3 key set, T4) are unreliable.${tv}`;
  }
  if (key==="T3"){
    if (!tier.counts) return "No difference counts recorded.";
    const parts=[];
    const d = tier.denominator;
    let worst = 0;
    if (tier.key_diff){
      const kp=tier.key_diff.in_prod_not_uat||0, ku=tier.key_diff.in_uat_not_prod||0;
      worst = Math.max(worst, kp, ku);
      parts.push((kp===0&&ku===0) ? "Key sets are identical."
        : `Keys: <b>${fmt(kp)}</b>${d?` (${pct(kp,d)})`:""} exist only in PROD, <b>${fmt(ku)}</b>${d?` (${pct(ku,d)})`:""} only in UAT.`);
    }
    const p=tier.counts.in_prod_not_uat||0, u=tier.counts.in_uat_not_prod||0;
    worst = Math.max(worst, p, u);
    const scope = tier.rows_scope==="shared_keys" ? " Content diff measured on shared keys only — one-sided keys are excluded here and counted above." : "";
    parts.push((p===0&&u===0) ? "Row sets are identical under the normalised projection." + scope
      : `Rows: <b>${fmt(p)}</b>${d?` (${pct(p,d)})`:""} appear only in PROD, <b>${fmt(u)}</b>${d?` (${pct(u,d)})`:""} only in UAT (after blank/NULL normalisation).${scope}`);
    if (tier.key_diff && all && all.T1 && all.T1.diff!=null){
      const net=(tier.key_diff.in_prod_not_uat||0)-(tier.key_diff.in_uat_not_prod||0);
      parts.push(net===all.T1.diff
        ? `Net key drift (${net>0?"+":""}${fmt(net)}) reconciles exactly with the T1 row-count Δ — same population, unique grain.`
        : `⚠ Net key drift (${net>0?"+":""}${fmt(net)}) ≠ T1 Δ (${all.T1.diff>0?"+":""}${fmt(all.T1.diff)}) — row multiplicity (duplicate keys) is inflating one side.`);
    }
    if (tier.rows_scope==="shared_keys" && p>0 && p===u)
      parts.push(`Equal row counts both directions = pure content drift: <b>${fmt(p)}</b> shared keys have at least one differing column (see T4).`);
    return parts.join(" ") + (worst?thresholdVerdict(tier, worst, d):"");
  }
  if (key==="T4"){
    const mc=tier.mismatched_columns||{}; const n=Object.keys(mc).length;
    if (!n) return tier.reason ? esc(tier.reason) : "No column-level mismatches across shared keys.";
    const cs=tier.column_status||{};
    const failing=Object.keys(mc).filter(c=>(cs[c]||"FAIL")==="FAIL").length;
    const accepted=n-failing;
    const worst=Object.entries(mc).sort((a,b)=>b[1]-a[1])[0];
    let txt=`<b>${n} column${n>1?"s":""} disagree</b> across ${fmt(tier.shared_keys)} shared keys — worst: <b>${esc(worst[0])}</b> (${fmt(worst[1])} keys).`;
    if (accepted) txt += ` ${failing?`<b>${failing}</b> failing, `:""}<b>${accepted}</b> accepted (marked or within threshold).`;
    return txt;
  }
  if (key==="T5"){
    if (st==="PASS") return "HASH_AGG fingerprints match — the two sets are identical under the normalised projection.";
    if (st==="FAIL") return "<b>Fingerprints differ</b> — the sets are not identical.";
    return esc(tier.reason || "No fingerprint result recorded.");
  }
  return "";
}

/* ---------- per-tier body detail ---------- */

function tierBody(key, tier){
  const parts=[];
  if (key==="T0" && (tier.drift||[]).length){
    parts.push(dataTable(["Column","PROD pos/type","UAT pos/type"],
      tier.drift.map(d=>[`<td>${esc(d.column??"—")}</td>`,
        `<td>${esc(d.prod_ord??"—")} / ${esc(d.prod_type??"—")}</td>`,
        `<td>${esc(d.uat_ord??"—")} / ${esc(d.uat_type??"—")}</td>`])));
  }
  if (key==="T1" && "prod_rows" in tier){
    parts.push(`<div class="statrow">${stat("Rows (active tenants)", tier.prod_rows, tier.uat_rows, tier.diff)}</div>`);
    if (tier.breakdown && tier.breakdown.length)
      parts.push(sampleTable(`Per-client contribution to the difference (worst first)`,
        tier.breakdown_columns, tier.breakdown, Infinity, 5));
  }
  if (key==="T2" && tier.dups){
    const d=tier.dups||{};
    parts.push(`<div class="statrow">
      ${stat("Duplicate grain keys", (d.prod||{}).dup_key_count, (d.uat||{}).dup_key_count, null)}</div>`);
    if (tier.sample_rows){
      const label={prod:"Duplicate grain keys in PROD (worst first)",uat:"Duplicate grain keys in UAT (worst first)"};
      const blocks = Object.entries(tier.sample_rows).map(([env,rows]) =>
        sampleTable(label[env]||env, tier.sample_columns, rows)).filter(Boolean);
      if (blocks.length) parts.push(`<div class="samples">${blocks.join("")}</div>`);
    }
  }
  if (key==="T3" && tier.counts){
    const statBits=[];
    if (tier.key_diff) statBits.push(stat("Grain keys only on one side",
      tier.key_diff.in_prod_not_uat, tier.key_diff.in_uat_not_prod, null));
    statBits.push(stat("Full rows only on one side",
      tier.counts.in_prod_not_uat, tier.counts.in_uat_not_prod, null));
    parts.push(`<div class="statrow">${statBits.join("")}</div>`);
    if (tier.key_samples){
      const blocks = Object.entries(tier.key_samples).map(([dir,rows]) =>
        sampleTable(dir==="in_prod_not_uat"?"Sample keys only in PROD":"Sample keys only in UAT",
          tier.key_columns, rows)).filter(Boolean);
      if (blocks.length) parts.push(`<div class="samples">${blocks.join("")}</div>`);
    }
    if (tier.samples){
      const blocks = Object.entries(tier.samples).map(([dir,rows]) =>
        sampleTable(dir==="in_prod_not_uat"?"Sample full rows only in PROD":"Sample full rows only in UAT",
          tier.sample_columns, rows)).filter(Boolean);
      if (blocks.length) parts.push(`<div class="samples">${blocks.join("")}</div>`);
    }
  }
  if (key==="T4" && tier.mismatched_columns && Object.keys(tier.mismatched_columns).length){
    const total=Number(tier.shared_keys||0);
    const order=Object.entries(tier.mismatched_columns).sort((a,b)=>b[1]-a[1]);
    parts.push(`<div class="kv"><span>shared keys:</span> ${fmt(total)}${
      tier.column_samples_note?`&ensp;<span>· ${esc(tier.column_samples_note)}</span>`:""}</div>`);
    if (!tier.column_samples)
      parts.push(`<div class="kv"><span>No per-column examples in this run's results — re-run with the latest runner.py to capture side-by-side PROD/UAT examples for each column.</span></div>`);
    const sampCols = tier.column_sample_columns || [];
    const isP = c => /^prod[ _]value$/i.test(String(c));
    const isU = c => /^uat[ _]value$/i.test(String(c));
    parts.push(order.map(([c,nMis])=>{
      const pct = total ? (100*Number(nMis)/total).toFixed(2) : "0.00";
      let body = "";
      const rowsArr = (tier.column_samples||{})[c];
      if (rowsArr && rowsArr.length){
        body = `<div class="table-wrap"><table class="data"><thead><tr>${
          sampCols.map(cc=>`<th${isP(cc)?' class="thp"':isU(cc)?' class="thu"':""}>${esc(cc)}</th>`).join("")
        }</tr></thead><tbody>${
          rowsArr.slice(0,8).map(row=>`<tr>${row.map((v,i)=>{
            const cc=sampCols[i]||"";
            if (isP(cc)||isU(cc))
              return `<td class="${isP(cc)?"tdp":"tdu"}"><div class="val" title="${esc(renderValue(v))}">${esc(renderValue(v))}</div></td>`;
            return `<td>${esc(renderValue(v))}</td>`;
          }).join("")}</tr>`).join("")}</tbody></table></div>`;
      }
      const cst=(tier.column_status||{})[c]||"FAIL";
      const badge = cst==="FAIL" ? `<span class="colbadge fail">fail</span>`
        : cst==="ACCEPTED_THRESHOLD" ? `<span class="colbadge acc">accepted · within threshold</span>`
        : `<span class="colbadge acc">accepted · marked</span>`;
      const reason=(tier.accepted_reasons||{})[c];
      return `<div class="t4col"><div class="t4col-hd"><b>${esc(c)}</b>
        <span>${fmt(nMis)} of ${fmt(total)} shared keys differ (${pct}%)</span>${badge}${
        reason?`<span>— ${esc(reason)}</span>`:""}</div>${body}</div>`;
    }).join(""));
  }
  if (tier.error) parts.push(`<div class="errbox">${esc(tier.error)}</div>`);
  const sql = sqlBlocks(tier);
  if (sql) parts.push(sql);
  return parts.join("");
}

function tierCard(key, tier, allTiers){
  const st=(tier.status||"none").toLowerCase();
  // skipped tiers: visible but one quiet line — nothing else to show
  if ((st==="skipped"||st==="none") && !tier.error && !tier.sql && !tier.queries)
    return `<div class="tier line ${st}"><span class="tk">${key}</span>
      <span>${esc(TEST_LABELS[key])} — skipped${tier.reason?` · ${esc(tier.reason)}`:""}</span></div>`;
  return `<div class="tier ${st}">
    <div class="tier-hd"><span class="tk">${key}</span><span class="tl">${esc(TEST_LABELS[key])}</span>
      <span class="spacer"></span><span class="tier-badge ${st}">${esc(tier.status||"none")}</span></div>
    <div class="tier-sum">${tierSummary(key,tier,allTiers)}</div>
    <div class="tier-bd">${tierBody(key,tier)}</div>
  </div>`;
}

/* ---------- page assembly ---------- */

function kpis(run){
  const c={PASS:0,ACC:0,DIFFS:0,BLOCKED:0,ERROR:0,T0:0,none:0};
  run.results.forEach(r=>c[vkey(r.verdict)]++);
  document.getElementById("kpis").innerHTML=`
    <div class="kpi"><div class="n">${run.results.length}</div><div class="l">Tables tested</div></div>
    <div class="kpi pass"><div class="n">${c.PASS}</div><div class="l">Pass</div></div>
    <div class="kpi acc"><div class="n">${c.ACC}</div><div class="l">Diffs accepted</div></div>
    <div class="kpi fail"><div class="n">${c.DIFFS}</div><div class="l">Diffs found</div></div>
    <div class="kpi blocked"><div class="n">${c.BLOCKED}</div><div class="l">Blocked</div></div>
    <div class="kpi err"><div class="n">${c.ERROR+c.T0}</div><div class="l">Error / drift</div></div>`;
  document.getElementById("spectrum").innerHTML = run.results.map(r=>
    `<a href="#${anchor(r.table)}" style="background:${vcolor[vkey(r.verdict)]}" title="${esc(r.table)} — ${vlabel[vkey(r.verdict)]}"></a>`).join("");
}

function visible(run){
  const q=state.q.toLowerCase();
  return run.results.filter(r=>
    (state.filter==="all"||vkey(r.verdict)===state.filter) && r.table.toLowerCase().includes(q));
}

function rows(run){
  const el=document.getElementById("rows");
  const vis=visible(run);
  if(!vis.length){ el.innerHTML=`<div class="empty">No tables match — clear the filter or search.</div>`; return; }
  el.innerHTML=vis.map(r=>{
    const vk=vkey(r.verdict);
    return `<a class="trow" href="#${anchor(r.table)}">
      <span class="tname">${esc(r.table)}</span>
      ${TIERS.map(k=>`<span class="cell ${tierStatus(r,k)}" title="${k}: ${tierStatus(r,k)}"></span>`).join("")}
      <span class="verdict v-${vk}">${vlabel[vk]}</span></a>`;
  }).join("");
}

function sections(run){
  const el=document.getElementById("sections");
  const vis=visible(run);
  if(!vis.length){ el.innerHTML=`<div class="empty">No tables match — clear the filter or search.</div>`; return; }
  el.innerHTML=vis.map(r=>{
    const vk=vkey(r.verdict);
    const rt=r.runtime_seconds!=null?`${Number(r.runtime_seconds).toFixed(1)}s`:null;
    return `<section class="tsection" id="${anchor(r.table)}">
      <div class="thd">
        <span class="tname">${esc(r.table)}</span>
        <span class="verdict v-${vk}">${vlabel[vk]}</span>
        ${rt?`<span class="meta">runtime ${rt}</span>`:""}
        ${r.review_required?`<span class="badge review">review required</span>`:""}
        ${(r.expected_blocked||[]).map(b=>`<span class="badge">expected: ${esc(b)}</span>`).join("")}
        ${r.excluded_columns?`<span class="badge" title="${esc(Object.entries(r.excluded_columns).map(([c,x])=>c+(x?": "+x:"")).join("; "))}">${Object.keys(r.excluded_columns).length} column(s) excluded</span>`:""}
        ${r.accepted_columns?`<span class="badge review" style="background:var(--acc-bg);color:var(--acc)" title="${esc(Object.entries(r.accepted_columns).map(([c,x])=>c+(x?": "+x:"")).join("; "))}">${Object.keys(r.accepted_columns).length} column(s) accepted</span>`:""}
        <span class="spacer"></span>
        <span class="meta"><a href="#top" onclick="window.scrollTo({top:0});return false;">↑ summary</a></span>
      </div>
      <div class="tbody">
        ${TIERS.map(k=>tierCard(k,(r.tiers||{})[k]||{},r.tiers||{})).join("")}
        ${(r.notes&&r.notes.length)?`<div><div class="statlabel">Notes</div><ul class="notes">${r.notes.map(n=>`<li>${esc(n)}</li>`).join("")}</ul></div>`:""}
      </div>
    </section>`;
  }).join("");
  el.querySelectorAll(".copy").forEach(b=>b.addEventListener("click",()=>{
    if(navigator.clipboard) navigator.clipboard.writeText(b.dataset.sql).then(()=>{
      b.textContent="Copied"; setTimeout(()=>b.textContent="Copy",1200);
    });
  }));
}

function history(){
  const el=document.getElementById("hist");
  const tables=[...new Set(RUNS.flatMap(r=>r.results.map(x=>x.table)))].sort();
  el.style.gridTemplateColumns=`minmax(220px,320px) repeat(${RUNS.length}, minmax(34px,60px))`;
  let h=`<div></div>`+RUNS.map(r=>`<div class="hhead" title="${esc(r.label)}">${esc(r.label.split(",")[0])}</div>`).join("");
  for(const t of tables){
    h+=`<div class="hname" title="${esc(t)}">${esc(t)}</div>`;
    for(const run of RUNS){
      const rec=run.results.find(x=>x.table===t);
      const vk=rec?vkey(rec.verdict):"none";
      h+=`<div class="hcell ${vk}" title="${esc(t)} · ${esc(run.label)} — ${vlabel[vk]}"></div>`;
    }
  }
  el.innerHTML=h;
}

function boot(){
  const sel=document.getElementById("runSel");
  sel.innerHTML=RUNS.map((r,i)=>`<option value="${i}" ${i===state.run?"selected":""}>${esc(r.label)}</option>`).join("");
  sel.addEventListener("change",e=>{state.run=+e.target.value;render();});
  document.getElementById("search").addEventListener("input",e=>{state.q=e.target.value;rows(RUNS[state.run]);sections(RUNS[state.run]);});
  document.querySelectorAll(".chip").forEach(c=>c.addEventListener("click",()=>{
    state.filter=c.dataset.f;
    document.querySelectorAll(".chip").forEach(x=>x.setAttribute("aria-pressed",x===c?"true":"false"));
    rows(RUNS[state.run]);sections(RUNS[state.run]);
  }));
  document.getElementById("foot").textContent=
    `${RUNS.length} run(s) · generated ${new Date().toLocaleString("en-AU")} · dashboard.py · print (Ctrl+P) for a PDF export`;
  history();render();
}
function exportHtml(){
  const blob = new Blob(["<!DOCTYPE html>\n"+document.documentElement.outerHTML],
    {type:"text/html"});
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "kafka_migration_dashboard.html";
  a.click(); URL.revokeObjectURL(a.href);
}
function render(){const run=RUNS[state.run];kpis(run);rows(run);sections(run);}
boot();
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()
