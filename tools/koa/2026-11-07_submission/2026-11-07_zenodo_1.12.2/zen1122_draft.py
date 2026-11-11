"""Create the 1.12.2 draft of the koa record as a new version of published 1.12.1 (record 24013562). DRAFT ONLY, never publishes. Prints the reserved DOI."""
import os,json,requests
H={'Authorization':'Bearer '+open(os.path.expanduser('~/.config/zenodo/token')).read().strip()}
A='https://zenodo.org/api/deposit/depositions'
d=requests.get(A+'/24013562',headers=H,timeout=60).json()
assert d['submitted'] and d['metadata'].get('version')=='1.12.1'
ld=d['links'].get('latest_draft')
if ld and not ld.endswith('/24013562'):
    nd=requests.get(ld,headers=H,timeout=60).json(); print('existing draft',nd['id'],flush=True)
else:
    r=requests.post(A+'/24013562/actions/newversion',headers=H,timeout=120); print('newversion',r.status_code,flush=True); r.raise_for_status()
    nd=requests.get(r.json()['links']['latest_draft'],headers=H,timeout=60).json()
assert nd['state']=='unsubmitted' and not nd['submitted']
doi=(nd['metadata'].get('prereserve_doi') or {}).get('doi')
json.dump({'draft':nd['id'],'reserved_doi':doi,'n_files':len(nd['files'])},open('draft_1122.json','w'))
print('DRAFT',nd['id'],'RESERVED',doi,'files',len(nd['files']),flush=True)
