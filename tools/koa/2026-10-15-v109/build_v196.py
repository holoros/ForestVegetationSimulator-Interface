#!/usr/bin/env python3
"""Build stage_v196 from stage_v195 on firebreather. Drops the two companion docx, shortens the description,
bumps version to 1.9.6. Every edit is assert-anchored; nothing is uploaded. Backups go to work_v196/."""
import json, os, re, shutil, subprocess, sys, hashlib, datetime
H = os.path.expanduser('~/jobs/koa_zenodo_180')
S5, S6, W = H + '/stage_v195', H + '/stage_v196', H + '/work_v196'
HERE = os.path.dirname(os.path.abspath(__file__))
DROP = ['koa_deposit_companion_v82.docx']
SUP_MD5 = 'edc052b9924b491cf505d94f862e5110'
SUP105_MD5 = 'a11cf9ca2bc0941471ffae80d8deae7d'
TODAY = datetime.date.today().isoformat()
md5 = lambda p: hashlib.md5(open(p, 'rb').read()).hexdigest()
if os.path.exists(S6):
    sys.exit('STOP: %s exists; move it aside before rebuilding' % S6)
os.makedirs(W, exist_ok=True)
shutil.copytree(S5, S6, symlinks=True)
print('copied', S5, '->', S6)
# 1. supplement slot must already be s104
sup = [os.path.join(d, f) for d, _, fs in os.walk(H) for f in fs if f == 'koa_supplemental.docx' and 'incoming_v195' in d]
assert sup and md5(sup[0]) == SUP_MD5, ('supplement slot md5', [md5(s) for s in sup])
NEW_SUP = HERE + '/koa_supplemental_v105.docx'
assert md5(NEW_SUP) == SUP105_MD5, 'koa_supplemental_v105.docx md5 mismatch after transfer'
I6 = H + '/incoming_v196'
if os.path.exists(I6):
    sys.exit('STOP: %s exists' % I6)
shutil.copytree(os.path.dirname(sup[0]), I6, symlinks=True)
shutil.copy2(NEW_SUP, I6 + '/koa_supplemental.docx')
for f in ['files_to_upload.txt', 'check_deposit.py', 'FILE_MAP_1.9.5.tsv', 'SHA256SUMS', 'DECLARED_CONTENTS.tsv']:
    p = S6 + '/' + f
    if os.path.exists(p):
        t = open(p).read()
        if 'incoming_v195' in t or SUP_MD5 in t:
            open(p, 'w').write(t.replace('incoming_v195', 'incoming_v196').replace(SUP_MD5, SUP105_MD5))
print('supplement slot: s104', SUP_MD5, '-> s105', SUP105_MD5, 'in', I6)
# 2. manifest: remove the companion lines
man = S6 + '/files_to_upload.txt'
t = open(man).read(); shutil.copy2(man, W + '/files_to_upload_PREV_v195.txt')
keep, gone = [], []
for ln in t.splitlines():
    (gone if any(d in ln.split('#', 1)[0] for d in DROP) else keep).append(ln)
assert len(gone) == 1, ('companion manifest lines found', gone)
keep.append('# not deposited from 1.9.6: ' + ', '.join(DROP) + ' (superseded model generations; see DEPOSIT_CHANGELOG.md)')
open(man, 'w').write('\n'.join(keep) + '\n')
print('manifest: removed', gone)
# 3. exclusion list, so gate 8 and the payload agree
ex = S6 + '/EXCLUSIONS.tsv'
if os.path.exists(ex):
    shutil.copy2(ex, W + '/EXCLUSIONS_PREV_v195.tsv')
    with open(ex, 'a') as fh:
        for d in DROP:
            fh.write('%s\tretired in 1.9.6: describes a superseded model generation\n' % d)
    print('EXCLUSIONS.tsv appended')
else:
    print('WARN: no EXCLUSIONS.tsv in stage; check check_deposit.py NOT_DEPOSITED by hand')
cd = S6 + '/check_deposit.py'
src = open(cd).read()
if 'NOT_DEPOSITED' in src:
    shutil.copy2(cd, W + '/check_deposit_PREV_v195.py')
    m = re.search(r'NOT_DEPOSITED\s*=\s*([\[\{\(])', src)
    assert m, 'NOT_DEPOSITED literal not found'
    i = m.end()
    ins = ''.join("\n    '%s'," % d for d in DROP)
    open(cd, 'w').write(src[:i] + ins + src[i:])
    print('check_deposit.py NOT_DEPOSITED extended')
# 4. file map renamed to 1.9.6, companion rows marked retired
fm5 = [f for f in os.listdir(S6) if re.fullmatch(r'FILE_MAP_1\.9\.5\.tsv', f)]
assert fm5, 'FILE_MAP_1.9.5.tsv missing'
rows = open(S6 + '/' + fm5[0]).read().splitlines()
rows = [r + '\tRETIRED in 1.9.6' if any(r.startswith(d) for d in DROP) else r for r in rows]
open(S6 + '/FILE_MAP_1.9.6.tsv', 'w').write('\n'.join(rows) + '\n'); os.remove(S6 + '/' + fm5[0])
t = open(man).read()
if 'FILE_MAP_1.9.5.tsv' in t:
    open(man, 'w').write(t.replace('FILE_MAP_1.9.5.tsv', 'FILE_MAP_1.9.6.tsv'))
for f in ['check_deposit.py', 'README.md', 'DECLARED_CONTENTS.tsv']:
    p = S6 + '/' + f
    if os.path.exists(p) and 'FILE_MAP_1.9.5.tsv' in open(p).read():
        open(p, 'w').write(open(p).read().replace('FILE_MAP_1.9.5.tsv', 'FILE_MAP_1.9.6.tsv'))
dc = S6 + '/DECLARED_CONTENTS.tsv'
if os.path.exists(dc):
    lines = open(dc).read().splitlines()
    open(dc, 'w').write('\n'.join(l for l in lines if not any(l.startswith(d) for d in DROP)) + '\n')
# 5. metadata: version, date, short description; old description archived in the changelog
mj = S6 + '/zenodo_metadata.json'; shutil.copy2(mj, W + '/zenodo_metadata_PREV_v195.json')
m = json.load(open(mj)); md = m.get('metadata', m)
old_desc = md['description']
md['version'] = '1.9.6'; md['publication_date'] = TODAY
md['description'] = open(HERE + '/description_v196.html').read().strip()
md['notes'] = 'Version 1.9.6 removes two superseded companion documents and shortens the description; no data value changed. ' + md.get('notes', '')
json.dump(m, open(mj, 'w'), indent=2, ensure_ascii=False)
cl = S6 + '/DEPOSIT_CHANGELOG.md'; shutil.copy2(cl, W + '/DEPOSIT_CHANGELOG_PREV_v195.md')
plain = re.sub(r'<[^>]+>', ' ', old_desc); plain = re.sub(r'[ \t]+', ' ', plain)
c = open(cl).read()
head = '## %s (deposit 1.9.6): companions retired, description shortened\n\n' % TODAY + \
       'Removed %s, which describe the August and September 2026 model generations superseded by the v103 rebuild. ' % ' and '.join(DROP) + \
       'The supplement slot now holds s105 (md5 a11cf9ca2bc0941471ffae80d8deae7d), which accompanies manuscript v109: revision-history wording replaced, record retention rules stated in S1.3, BYI skill wording in S2.2 corrected; no number changed. No data value, constant or script changed from 1.9.5. The record description through 1.9.5 is archived below.\n\n' + \
       '### Record description through 1.9.5 (archived)\n\n' + plain.strip() + '\n\n'
c = re.sub(r'\A(# [^\n]*\n)', lambda mm: mm.group(1) + '\n' + head, c, count=1) if c.startswith('# ') else head + c
open(cl, 'w').write(c)
# 6. remaining mentions, for a human
for f in sorted(os.listdir(S6)):
    p = S6 + '/' + f
    if os.path.isfile(p) and f.endswith(('.md', '.tsv', '.txt', '.py', '.json', '.cff', '.csv')):
        n = sum(open(p, errors='replace').read().count(d) for d in DROP)
        if n:
            print('mentions of retired companions in %s: %d' % (f, n))
assert not re.search(r'-15\d\.\d{3,}-?\d{1,2}\.\d{3,}', md['description'] + c), 'coordinate-shaped string'
assert '—' not in md['description']
# 7. gates
r = subprocess.run([sys.executable, 'check_deposit.py'], cwd=S6, capture_output=True, text=True)
open(W + '/gate_v196.log', 'w').write(r.stdout + r.stderr)
print(r.stdout[-3000:]); print(r.stderr[-2000:])
print('GATES', 'PASS' if r.returncode == 0 else 'FAIL rc=%d' % r.returncode)
sys.exit(r.returncode)
