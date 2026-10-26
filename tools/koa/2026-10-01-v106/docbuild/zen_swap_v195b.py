#!/usr/bin/env python3
"""Round 3: swap the revised s104 into the 1.9.5 slot and document the DBH.max column. Backups suffix _PREV_20261001b."""
import os, shutil, hashlib, csv, io
H = os.path.expanduser('~/jobs/koa_zenodo_180')
S, W, I = H + '/stage_v195', H + '/work_v195', H + '/incoming_v195'
TAG = '_PREV_20261001b'
md5 = lambda p: hashlib.md5(open(p, 'rb').read()).hexdigest()
OLD, NEW = 'ae999069804f08f4053d2b98b2250410', md5(H + '/koa_supplemental_v104.docx')
assert md5(I + '/koa_supplemental.docx') == OLD
shutil.copy2(I + '/koa_supplemental.docx', W + '/koa_supplemental_s104a' + TAG + '.docx')
shutil.move(H + '/koa_supplemental_v104.docx', I + '/koa_supplemental.docx')
for f in ['check_deposit.py', 'FILE_MAP_1.9.5.tsv', 'DEPOSIT_CHANGELOG.md', 'README.md', 'INTEGRITY_REPORT.md', 'data_dictionary.csv']:
    b, e = os.path.splitext(f); shutil.copy2(S + '/' + f, W + '/' + b + TAG + e)
for f in ['check_deposit.py', 'FILE_MAP_1.9.5.tsv', 'DEPOSIT_CHANGELOG.md', 'INTEGRITY_REPORT.md']:
    t = open(S + '/' + f).read(); assert OLD in t, f
    open(S + '/' + f, 'w').write(t.replace(OLD, NEW))
NOTE = ("The DBH.max column of AK_TREE.csv (and rDBH = DBH / DBH.max) is the plot-year maximum as first assembled. In 73 of 739 plot-years "
        "it exceeds the largest live stem of the v103 tree list (60 values left from before deduplication, 13 dead stems), so it is not the "
        "predictor of Eq. 2. Table 3 is fitted with rDBH recomputed as DBH over the largest DBH among live stems with EXPF > 0 in the plot-year, "
        "from v103_rebuild_20260930/frames/final/tree_join_v103.csv by v103_rebuild_20260930/track2/height_refit_v103.R, which reproduces "
        "Table 3 exactly; fitting with the deposited column returns a0 = 25.47 and a1 = 0.604.")
t = open(S + '/README.md').read()
anchor = '**Installation ids.**'
assert anchor in t
open(S + '/README.md', 'w').write(t.replace(anchor, '**Relative diameter (rDBH).** ' + NOTE + '\n\n' + anchor, 1))
t = open(S + '/DEPOSIT_CHANGELOG.md').read()
assert '**Supplement slot, October 1, 2026.**' in t
t = t.replace('**Supplement slot, October 1, 2026.**', '**rDBH note, October 1, 2026.** ' + NOTE + ' README.md and data_dictionary.csv now say so; no data value changed.\n\n**Supplement slot, October 1, 2026.**', 1)
t = t.replace('(md5 ' + NEW + '), replacing s103', '(md5 ' + NEW + ', revised the same day for the open items of the v106 review), replacing s103', 1)
open(S + '/DEPOSIT_CHANGELOG.md', 'w').write(t)
raw = open(S + '/data_dictionary.csv', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
rows = list(csv.reader(io.StringIO(raw)))
hit = 0
for r in rows:
    if len(r) >= 5 and r[0] == 'AK_TREE.csv' and r[1] in ('DBH.max', 'rDBH'):
        r[4] = r[4] + ' NOTE 1 October 2026: ' + NOTE; hit += 1
assert hit == 2, hit
buf = io.StringIO(); csv.writer(buf, lineterminator=nl).writerows(rows)
open(S + '/data_dictionary.csv', 'w', newline='').write(buf.getvalue())
print('slot', OLD, '->', NEW, 'dictionary rows', hit)
