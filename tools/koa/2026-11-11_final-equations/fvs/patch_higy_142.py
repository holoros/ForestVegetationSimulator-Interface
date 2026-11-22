# HiGy.R parameters from koa 1.15.0 to koa v142: replace every 1.15.0 estimate by its v142 value, matched as the exact string in HiGy.R.
# v142 recomputed the site variable BYI and refitted the equations. IG_ingrowth and E3e_crown_base are skipped (unchanged).
import csv, sys
OLD = '/home/aaron/jobs/koa_1150_20261121/release_v1150/koa_rdbyi_equations.csv'
NEW = '/home/aaron/jobs/koa_bendb_20261121/v142/release_v1150/koa_rdbyi_equations.csv'  # v142 coefficients despite the folder name
old = {(r['equation'], r['term']): r['estimate'] for r in csv.DictReader(open(OLD))}
new = {(r['equation'], r['term']): r['estimate'] for r in csv.DictReader(open(NEW))}
assert set(old) == set(new), set(old) ^ set(new)
p = sys.argv[1]; s = open(p).read(); n = 0
for k, v in old.items():
    if k[0] in ('IG_ingrowth', 'E3e_crown_base') or new[k] == v: continue
    c = s.count(v)
    assert c == 1, (k, v, c)
    s = s.replace(v, new[k]); n += 1
open(p, 'w').write(s); print('replaced', n)
