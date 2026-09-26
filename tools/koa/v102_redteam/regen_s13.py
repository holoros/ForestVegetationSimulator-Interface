import csv, collections, statistics as st
rows=list(csv.DictReader(open('trajectories.csv')))
pt=collections.defaultdict(dict); reps=collections.defaultdict(lambda: collections.defaultdict(list))
cum=collections.defaultdict(dict)
traj=collections.defaultdict(list)
for r in rows:
    k=(r['scenario'],r['site']); a=float(r['age'])
    if r['rep']=='0': traj[k].append((a,r))
    else:
        if int(a) in (20,40,60,100):
            reps[(k,int(a))]['QMD'].append(float(r['QMD'])); reps[(k,int(a))]['VOL'].append(float(r['VOL']))
for k,v in traj.items():
    v.sort(key=lambda t:t[0]); s=0.0
    for a,r in v:
        s+=float(r['MORT_VOL'])
        if int(a) in (20,40,60,100): pt[k][int(a)]=(r,s)
q=lambda v,p: st.quantiles(sorted(v), n=1000)[int(p*1000)-1]
print("scenario|site|age|QMD|HT|BAPH|TPH|VOL|NetMAI|GrossMAI|SDI")
for sc in ('Even-aged natural','Even-aged planted','Uneven-aged natural'):
    for si in ('Low','Medium','High'):
        for a in (20,40,60,100):
            r,cm=pt[(sc,si)][a]
            qv=reps[((sc,si),a)]['QMD']; vv=reps[((sc,si),a)]['VOL']
            V=float(r['VOL'])
            print(f"{sc}|{si}|{a}|{float(r['QMD']):.1f} ({q(qv,.025):.1f}-{q(qv,.975):.1f})|{float(r['HT']):.1f}|"
                  f"{float(r['BAPH']):.1f}|{float(r['TPH']):.0f}|{V:.1f} ({q(vv,.025):.1f}-{q(vv,.975):.1f})|"
                  f"{V/a:.2f}|{(V+cm)/a:.2f}|{float(r['SDI']):.0f}")
