#!/usr/bin/env python3
"""Koa deposit 1.9.6 as a DRAFT new version of 1.9.5 (record 22997704), run on Cardinal. Never publishes.
Inherited files stay; replaced: koa_supplemental.docx (s105), README.md, DEPOSIT_CHANGELOG.md, SHA256SUMS,
FILE_MAP_1.9.5.tsv -> FILE_MAP_1.9.6.tsv; removed: koa_deposit_companion_v82.docx. Token read from ~/.zenodo_token, never printed."""
import hashlib, json, os, re, sys, datetime, requests
W = os.path.dirname(os.path.abspath(__file__)); os.chdir(W)
API = 'https://zenodo.org/api'; REC = '22997704'; CONCEPT = '21081014'
SUP_OLD, SUP_NEW = 'edc052b9924b491cf505d94f862e5110', 'a11cf9ca2bc0941471ffae80d8deae7d'
DROP = ['koa_deposit_companion_v82.docx']
TODAY = datetime.date.today().isoformat()
md5 = lambda p: hashlib.md5(open(p, 'rb').read()).hexdigest()
sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
tok = open(os.path.expanduser('~/.zenodo_token')).read().strip(); print('token file: ~/.zenodo_token')
H = {'Authorization': 'Bearer ' + tok}
def die(r, what):
    body = r.text.replace(tok, '***')[:1500]; sys.exit('ERROR %s: HTTP %s %s' % (what, r.status_code, body))
assert md5('koa_supplemental_v105.docx') == SUP_NEW, 's105 md5 mismatch'
# 1. latest must still be 1.9.5
r = requests.get(API + '/records/' + CONCEPT + '/versions/latest', timeout=60)
lat = r.json() if r.ok else requests.get(API + '/records/' + REC, timeout=60).json()
if str(lat['id']) != REC: sys.exit('STOP: latest published record is %s, not %s' % (lat['id'], REC))
# 2. pull the text files to edit
os.makedirs('src', exist_ok=True)
for f in ['README.md', 'DEPOSIT_CHANGELOG.md', 'FILE_MAP_1.9.5.tsv', 'SHA256SUMS']:
    rr = requests.get('https://zenodo.org/records/%s/files/%s?download=1' % (REC, f), timeout=120)
    if not rr.ok: die(rr, 'download ' + f)
    open('src/' + f, 'wb').write(rr.content)
os.makedirs('up', exist_ok=True)
desc = open('description_v196.html').read().strip()
# README: version note at the top after the title
t = open('src/README.md', encoding='utf8').read()
note = ('\n**Version 1.9.6 (%s).** Supplement replaced by s105 (md5 %s), which accompanies manuscript v109: revision-history wording '
        'replaced, record retention rules for duplicated and status-conflict visits stated in Section S1.3, and the description of BYI skill '
        'in Section S2.2 corrected; no number changed. koa_deposit_companion_v82.docx removed, since it describes a superseded model generation. '
        'No data value, constant or script changed from 1.9.5. FILE_MAP_1.9.5.tsv is now FILE_MAP_1.9.6.tsv.\n' % (TODAY, SUP_NEW))
t = re.sub(r'\A(# [^\n]*\n)', lambda m: m.group(1) + note, t, count=1) if t.startswith('# ') else note + t
open('up/README.md', 'w', encoding='utf8').write(t)
# CHANGELOG: new entry and archived old description
old = requests.get(API + '/records/' + REC, timeout=60).json()['metadata']['description']
plain = re.sub(r'[ \t]+', ' ', re.sub(r'<[^>]+>', ' ', old)).strip()
c = open('src/DEPOSIT_CHANGELOG.md', encoding='utf8').read()
entry = ('## %s (deposit 1.9.6): supplement s105, companion retired, description shortened\n\n' % TODAY + note.strip() + '\n\n'
         '### Record description through 1.9.5 (archived)\n\n' + plain + '\n\n')
c = re.sub(r'\A(# [^\n]*\n)', lambda m: m.group(1) + '\n' + entry, c, count=1) if c.startswith('# ') else entry + c
open('up/DEPOSIT_CHANGELOG.md', 'w', encoding='utf8').write(c)
# FILE_MAP
rows = open('src/FILE_MAP_1.9.5.tsv', encoding='utf8').read().splitlines()
out = []
for row in rows:
    k = row.split('\t', 1)[0]
    if k in DROP: row += '\tRETIRED in 1.9.6'
    if k == 'koa_supplemental.docx': row += '\tREPLACED in 1.9.6 by s105, md5 ' + SUP_NEW
    out.append(row)
open('up/FILE_MAP_1.9.6.tsv', 'w', encoding='utf8').write('\n'.join(out) + '\n')
import shutil; shutil.copy2('koa_supplemental_v105.docx', 'up/koa_supplemental.docx')
# SHA256SUMS
newsum = {f: sha('up/' + f) for f in os.listdir('up')}
lines = []
for ln in open('src/SHA256SUMS', encoding='utf8').read().splitlines():
    if not ln.strip() or ln.startswith('#'): lines.append(ln); continue
    hx, name = ln.split(None, 1); name = name.strip().lstrip('*')
    if name in DROP or name == 'FILE_MAP_1.9.5.tsv': continue
    if name in newsum: hx = newsum.pop(name)
    lines.append('%s  %s' % (hx, name))
for name, hx in sorted(newsum.items()): lines.append('%s  %s' % (hx, name))
open('up/SHA256SUMS', 'w').write('\n'.join(lines) + '\n')
for f in sorted(os.listdir('up')):
    s = open('up/' + f, 'rb').read()
    if f.endswith(('.md', '.tsv')) or f == 'SHA256SUMS':
        assert '—'.encode() not in s or f == 'DEPOSIT_CHANGELOG.md', 'em dash in ' + f
print('staged', sorted(os.listdir('up')))
if os.environ.get('DRAFT') != '1':
    print('Built only. Rerun with DRAFT=1 to create the draft.'); sys.exit(0)
# 3. new version draft
if os.environ.get('DRAFT_ID'):
    d = requests.get(API + '/deposit/depositions/%s' % os.environ['DRAFT_ID'], headers=H, timeout=60).json()
    assert d.get('submitted') is False and d['metadata'].get('version') in ('1.9.5', '1.9.6'), 'DRAFT_ID is not an open 1.9.6 draft'
else:
    r = requests.post(API + '/deposit/depositions/%s/actions/newversion' % REC, headers=H, timeout=120)
    if not r.ok: die(r, 'newversion (if a draft already exists, rerun with DRAFT_ID=<id>)')
    d = requests.get(r.json()['links']['latest_draft'], headers=H, timeout=60).json()
dep, bucket = d['id'], d['links']['bucket']; print('draft id', dep)
replace = set(os.listdir('up')) | set(DROP) | {'FILE_MAP_1.9.5.tsv'}
for f in d.get('files', []):
    if f['filename'] in replace:
        dr = requests.delete(API + '/deposit/depositions/%s/files/%s' % (dep, f['id']), headers=H, timeout=120)
        if not dr.ok and dr.status_code != 404: die(dr, 'delete ' + f['filename'])
        print('removed', f['filename'])
for f in sorted(os.listdir('up')):
    with open('up/' + f, 'rb') as fh:
        ur = requests.put('%s/%s' % (bucket, f), headers=H, data=fh, timeout=600)
    if not ur.ok: die(ur, 'upload ' + f)
    print('uploaded', f, ur.json().get('checksum'))
md = d['metadata']
md['version'] = '1.9.6'; md['publication_date'] = TODAY; md['description'] = desc
md['notes'] = ('Version 1.9.6 replaces the supplement with s105 and removes koa_deposit_companion_v82.docx; no data value changed. '
               + (md.get('notes') or ''))[:5000]
md.pop('doi', None)
mr = requests.put(API + '/deposit/depositions/%s' % dep, headers={**H, 'Content-Type': 'application/json'}, json={'metadata': md}, timeout=120)
if not mr.ok: die(mr, 'metadata')
d = requests.get(API + '/deposit/depositions/%s' % dep, headers=H, timeout=60).json()
names = sorted(f['filename'] for f in d['files'])
sup = [f for f in d['files'] if f['filename'] == 'koa_supplemental.docx'][0]['checksum']
res = {'draft_id': dep, 'reserved_doi': d['metadata'].get('prereserve_doi', {}).get('doi'), 'edit_url': d['links'].get('html'),
       'n_files': len(names), 'supplement_md5': sup, 'companion_present': any(n in names for n in DROP),
       'file_map': [n for n in names if n.startswith('FILE_MAP')], 'version': d['metadata'].get('version'), 'published': False}
json.dump(res, open('zenodo_dois_v196.json', 'w'), indent=2); print(json.dumps(res, indent=2))
assert sup == SUP_NEW and not res['companion_present'] and 'FILE_MAP_1.9.6.tsv' in names
print('DRAFT READY, not published')
