import json,csv,re,os,glob
EXP='.'; RUNS='C:/Users/Shadow/sandbox/runs'
m={}
for l in open('.blind_map.csv'):
    b,r=l.strip().split(',');m[b]=r
def kv(p):
    d={}
    for l in open(p,errors='ignore'):
        if '=' in l:
            k,v=l.strip().split('=',1);d.setdefault(k.split()[0],v)
    return d
rows=[]
for b,r in sorted(m.items(),key=lambda x:(x[1].split('_')[0],int(re.search(r'_b(\d+)',x[1]).group(1)))):
    res=f'scoring/results/{b}'
    f=json.load(open(f'{res}/findings.json'))
    sa=json.load(open(f'{res}/seed_audit.json'))
    j=json.load(open(f'{res}/judge_rep1.json'))['result']
    if isinstance(j,str):
        j=json.loads(j[j.index('['):j.rindex(']')+1])
    nc=sum(1 for x in j if x['verdict']=='NON_COMPLIANT'); ap=sum(1 for x in j if x['verdict']!='NOT_APPLICABLE')
    p=kv(f'{RUNS}/{r}/provenance.txt'); u=json.load(open(f'{RUNS}/{r}/usage.json'))
    rows.append(dict(arm=r.split('_')[0],run=r,blind=b,check=f['check_outcome'],resid=f.get('residual_burden',''),
      seed_resid=sa.get('residual_burden_seed_relative',''),judge_nc=nc,judge_applicable=ap,
      term=p.get('termination'),turns=u['num_turns'],wall_s=p.get('wall_clock_s'),first_check_evt=p.get('first_check_event_index'),
      checks=p.get('check_invocations'),cost=round(u['total_cost_usd'],2),out_tok=u['output_tokens']))
out=os.environ.get('OUT','unblinded.csv')
w=csv.DictWriter(open(out,'w',newline=''),fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
print(len(rows))
