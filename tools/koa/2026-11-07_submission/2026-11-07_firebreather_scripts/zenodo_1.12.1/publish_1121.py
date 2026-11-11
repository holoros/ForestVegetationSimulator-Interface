"""Publish draft 24013562 as version 1.12.1. Run at Aaron's explicit request (2026-11-07)."""
import os,requests,json
H={'Authorization':'Bearer '+open(os.path.expanduser('~/.config/zenodo/token')).read().strip()}
A='https://zenodo.org/api/deposit/depositions/24013562'
d=requests.get(A,headers=H,timeout=60).json()
assert d['state']=='unsubmitted' and d['metadata']['version']=='1.12.1'
sup=[f for f in d['files'] if f['filename']=='koa_supplemental.pdf'][0]['checksum'].replace('md5:','')
assert sup=='96d1440059a92488d8479f7c77a28a16', sup
print('pre-check ok, files',len(d['files']),flush=True)
r=requests.post(A+'/actions/publish',headers=H,timeout=300)
print('publish',r.status_code,flush=True)
j=r.json(); print(json.dumps({k:j.get(k) for k in ['state','submitted','doi','doi_url','record_id']}))
if not r.ok: print(r.text[:800])
