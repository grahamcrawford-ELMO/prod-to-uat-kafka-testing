import duckdb, re
con = duckdb.connect()
con.execute("""CREATE TABLE cols(db TEXT, table_schema TEXT, table_name TEXT,
 column_name TEXT, ordinal_position INT, data_type TEXT,
 character_maximum_length INT, numeric_precision INT, numeric_scale INT, is_nullable TEXT)""")
con.execute("CREATE TABLE vws(db TEXT, table_schema TEXT, table_name TEXT)")

def add(db, tbl, cols):
    con.execute("INSERT INTO vws VALUES (?,?,?)", [db,'EDP_DWI',tbl])
    for i,(n,t,l,p,s,nl) in enumerate(cols,1):
        con.execute("INSERT INTO cols VALUES (?,?,?,?,?,?,?,?,?,?)",[db,'EDP_DWI',tbl,n,i,t,l,p,s,nl])

BASE=[('ID','NUMBER',None,38,0,'YES'),('CLIENT_NAME','TEXT',16777216,None,None,'YES'),('STATUS','TEXT',16777216,None,None,'YES')]
# clean view
add('PROD','DWI_CLEAN',BASE); add('UAT','DWI_CLEAN',BASE)
# type changed
add('PROD','DWI_TYPE',BASE)
add('UAT','DWI_TYPE',[('ID','NUMBER',None,38,0,'YES'),('CLIENT_NAME','TEXT',16777216,None,None,'YES'),('STATUS','NUMBER',None,38,0,'YES')])
# column only in prod
add('PROD','DWI_EXTRA',BASE+[('NEW_COL','TEXT',16777216,None,None,'YES')])
add('UAT','DWI_EXTRA',BASE)
# reordered
add('PROD','DWI_ORDER',BASE)
add('UAT','DWI_ORDER',[BASE[0],BASE[2],BASE[1]])
# precision only
add('PROD','DWI_PREC',[('AMT','NUMBER',None,38,2,'YES')])
add('UAT','DWI_PREC',[('AMT','NUMBER',None,38,4,'YES')])
# nullability only
add('PROD','DWI_NULL',[('ID','NUMBER',None,38,0,'NO')])
add('UAT','DWI_NULL',[('ID','NUMBER',None,38,0,'YES')])
# view missing in UAT
add('PROD','DWI_ONLY_PROD',BASE)

import os
HERE = os.path.dirname(os.path.abspath(__file__))
sql = open(os.path.join(HERE, '..', 'assets', 'schema_diff.sql')).read()
stmts=[s for s in sql.split(';') if s.strip() and not all(l.strip().startswith('--') or not l.strip() for l in s.strip().splitlines())]

def port(s):
    s = re.sub(r'(PROD|UAT)_DB\.INFORMATION_SCHEMA\.COLUMNS',
               lambda m: f"(SELECT * FROM cols WHERE db='{m.group(1)}')", s)
    s = re.sub(r'(PROD|UAT)_DB\.INFORMATION_SCHEMA\.VIEWS',
               lambda m: f"(SELECT * FROM vws WHERE db='{m.group(1)}')", s)
    s = re.sub(r'\bIFF\(', 'IF(', s)
    s = re.sub(r'NOT EQUAL_NULL\(([^,]+),\s*([^)]+)\)', r'(\1 IS DISTINCT FROM \2)', s)
    s = re.sub(r'COUNT_IF\(', 'SUM_IF_HACK(', s)
    return s

def fix_countif(s):
    # replace SUM_IF_HACK(expr) -> COUNT_IF equivalent using SUM(CASE)
    out=[]; i=0
    while True:
        k=s.find('SUM_IF_HACK(',i)
        if k<0: out.append(s[i:]); break
        out.append(s[i:k]); j=k+len('SUM_IF_HACK('); depth=1; st=j
        while depth:
            if s[j]=='(':depth+=1
            elif s[j]==')':depth-=1
            j+=1
        inner=s[st:j-1]
        out.append(f"SUM(CASE WHEN {inner} THEN 1 ELSE 0 END)")
        i=j
    return ''.join(out)

names=['Q0 sanity','Q1 object-level','Q2 column drift','Q3 rollup']
res={}
for name, st in zip(names, stmts):
    q = fix_countif(port(st))
    res[name[:2]] = con.execute(q).fetchall()

fails=[]
def check(label, cond):
    print(("  [ok ] " if cond else "  [FAIL] ")+label)
    if not cond: fails.append(label)

print("== schema_diff.sql")
check("Q0 returns one row per side", len(res['Q0'])==2)
check("Q1 finds the view missing in UAT",
      res['Q1']==[('DWI_ONLY_PROD','MISSING IN UAT')])
q2={(r[0],r[1]):r[2] for r in res['Q2']}
check("Q2 flags TYPE CHANGED", q2.get(('DWI_TYPE','STATUS'))=='TYPE CHANGED')
check("Q2 flags COLUMN ONLY IN PROD", q2.get(('DWI_EXTRA','NEW_COL'))=='COLUMN ONLY IN PROD')
check("Q2 flags PRECISION CHANGED", q2.get(('DWI_PREC','AMT'))=='PRECISION CHANGED')
check("Q2 flags NULLABILITY CHANGED", q2.get(('DWI_NULL','ID'))=='NULLABILITY CHANGED')
check("Q2 flags both reordered columns",
      q2.get(('DWI_ORDER','CLIENT_NAME'))=='POSITION CHANGED' and
      q2.get(('DWI_ORDER','STATUS'))=='POSITION CHANGED')
check("Q2 excludes the clean view", not any(k[0]=='DWI_CLEAN' for k in q2))
check("Q2 does not emit a row per column for a wholly-absent view",
      not any(k[0]=='DWI_ONLY_PROD' for k in q2))
q3={r[0]:r for r in res['Q3']}
check("Q3 verdicts PASS for the clean view", q3['DWI_CLEAN'][9]=='PASS')
check("Q3 verdicts DRIFT for every drifting view",
      all(q3[v][9]=='DRIFT' for v in
          ('DWI_TYPE','DWI_EXTRA','DWI_ORDER','DWI_PREC','DWI_NULL')))
check("Q3 does not double-count a type change as precision drift",
      q3['DWI_TYPE'][5]==1 and q3['DWI_TYPE'][6]==0)
check("Q3 counts both reordered columns", q3['DWI_ORDER'][8]==2)
check("Q3 sorts DRIFT before PASS", res['Q3'][-1][0]=='DWI_CLEAN')
check("Q3 excludes the wholly-absent view", 'DWI_ONLY_PROD' not in q3)

n=14
print(f"\n{n-len(fails)}/{n} checks passed")
if fails: raise SystemExit(1)
