"""Fill draft 24039072 as 1.12.2. DRAFT ONLY, never publishes."""
import os, json, hashlib, requests
H = {'Authorization': 'Bearer ' + open(os.path.expanduser('~/.config/zenodo/token')).read().strip()}
A = 'https://zenodo.org/api/deposit/depositions'; DID = 24039072
d = requests.get(f'{A}/{DID}', headers=H, timeout=60).json(); assert d['state'] == 'unsubmitted' and not d['submitted']
cur = {f['filename']: (f['id'], f['checksum'].replace('md5:', '')) for f in d['files']}; B = d['links']['bucket']
if 'FILE_MAP_1.12.1.tsv' in cur:
    r = requests.delete(f"{A}/{DID}/files/{cur['FILE_MAP_1.12.1.tsv'][0]}", headers=H, timeout=60); print('DELETE FILE_MAP_1.12.1.tsv', r.status_code, flush=True)
for n in sorted(os.listdir('files')):
    b = open('files/' + n, 'rb').read(); m = hashlib.md5(b).hexdigest()
    if cur.get(n, (0, ''))[1] == m: print('SKIP', n, flush=True); continue
    if n in cur: requests.delete(f"{A}/{DID}/files/{cur[n][0]}", headers=H, timeout=60)
    r = requests.put(B + '/' + n, data=b, headers=H, timeout=900); ok = r.ok and r.json().get('checksum', '').replace('md5:', '') == m
    print('OK' if ok else 'FAIL', n, m, flush=True)
d = requests.get(f'{A}/{DID}', headers=H, timeout=60).json(); md = d['metadata']
md['version'] = '1.12.2'; md['publication_date'] = '2026-11-07'
add = ('<p><strong>Version 1.12.2 (7 November 2026)</strong> replaces <code>koa_supplemental.pdf</code> with supplement v123, the supplement submitted with the manuscript to Forest Ecosystems '
       '(reporting corrections only). The engine, parameters, frames and numbers are unchanged; see README.md.</p>')
if 'Version 1.12.2' not in md.get('description', ''): md['description'] = add + md.get('description', '')
if 'Version 1.12.2' not in md.get('notes', ''): md['notes'] = 'Version 1.12.2 (7 November 2026): supplement v123 of the submitted manuscript; content otherwise identical to 1.12.1. Earlier note: ' + md.get('notes', '')
md.pop('doi', None); md = {k: v for k, v in md.items() if v not in ('', [], {}, None)}
r = requests.put(f'{A}/{DID}', headers={**H, 'Content-Type': 'application/json'}, data=json.dumps({'metadata': md}), timeout=120)
print('metadata', r.status_code, r.text[:500] if not r.ok else '', flush=True)
d = requests.get(f'{A}/{DID}', headers=H, timeout=60).json(); after = {f['filename']: f['checksum'].replace('md5:', '') for f in d['files']}
local = {n: hashlib.md5(open('files/' + n, 'rb').read()).hexdigest() for n in os.listdir('files')}
res = dict(state=d['state'], n_files=len(after), version=d['metadata']['version'], reserved=(d['metadata'].get('prereserve_doi') or {}).get('doi'),
           mismatch=[n for n in local if after.get(n) != local[n]], old_map='FILE_MAP_1.12.1.tsv' in after, supp=after.get('koa_supplemental.pdf'))
json.dump(res, open('result_1122.json', 'w')); print(json.dumps(res)); print('DRAFT 24039072 FILLED AS 1.12.2, NOT PUBLISHED')
