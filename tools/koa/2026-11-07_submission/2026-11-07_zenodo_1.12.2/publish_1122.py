"""Publish draft 24039072 as 1.12.2. Run at Aaron's request (2026-11-07: resolve open items including Zenodo)."""
import os, requests, json
H = {'Authorization': 'Bearer ' + open(os.path.expanduser('~/.config/zenodo/token')).read().strip()}
A = 'https://zenodo.org/api/deposit/depositions/24039072'
d = requests.get(A, headers=H, timeout=60).json()
assert d['state'] == 'unsubmitted' and d['metadata']['version'] == '1.12.2'
sup = [f for f in d['files'] if f['filename'] == 'koa_supplemental.pdf'][0]['checksum'].replace('md5:', '')
assert sup == '0262e9b58360d31e6cf7dab6777f8a3a', sup
assert not any(f['filename'] == 'FILE_MAP_1.12.1.tsv' for f in d['files'])
print('pre-check ok, files', len(d['files']), flush=True)
r = requests.post(A + '/actions/publish', headers=H, timeout=300); print('publish', r.status_code, flush=True)
j = r.json(); print(json.dumps({k: j.get(k) for k in ['state', 'submitted', 'doi', 'doi_url', 'record_id']}))
if not r.ok: print(r.text[:800])
