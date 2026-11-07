"""Update draft 24013562 in place. DRAFT ONLY, never publishes."""
import os,json,hashlib,requests
H={'Authorization':'Bearer '+open(os.path.expanduser('~/.config/zenodo/token')).read().strip()}
A='https://zenodo.org/api/deposit/depositions'; DID=24013562
d=requests.get(f'{A}/{DID}',headers=H,timeout=60).json(); assert d['state']=='unsubmitted' and not d['submitted']
cur={f['filename']:(f['id'],f['checksum'].replace('md5:','')) for f in d['files']}; B=d['links']['bucket']
for n in sorted(os.listdir('files')):
    b=open('files/'+n,'rb').read(); m=hashlib.md5(b).hexdigest()
    if cur.get(n,(0,''))[1]==m: continue
    if n in cur: requests.delete(f"{A}/{DID}/files/{cur[n][0]}",headers=H,timeout=60)
    r=requests.put(B+'/'+n,data=b,headers=H,timeout=600); ok=r.ok and r.json().get('checksum','').replace('md5:','')==m
    print('OK' if ok else 'FAIL',n,m,flush=True)
d=requests.get(f'{A}/{DID}',headers=H,timeout=60).json(); md=d['metadata']
for c in md['creators']:
    if c['name'].startswith('Rice'): c['affiliation']='Midgard Natural Resources LLC, New Hampshire'
o='supplement v118, the supplement'
if o in md['description']:
    md['description']=md['description'].replace(o,'supplement v119, the supplement')
n0='Version 1.12.1 (6 and 7 November 2026)'
if 'supplement v118' in md.get('notes',''):
    md['notes']=md['notes'].replace('supplement v118','supplement v119',1)
for k in ['prereserve_doi','doi']: md.pop(k,None) if k=='doi' else None
r=requests.put(f'{A}/{DID}',headers={**H,'Content-Type':'application/json'},data=json.dumps({'metadata':md}),timeout=60)
print('metadata',r.status_code,r.text[:300] if not r.ok else '')
d=requests.get(f'{A}/{DID}',headers=H,timeout=60).json()
print('state',d['state'],'n_files',len(d['files']),'version',d['metadata']['version'],'rice',[c['affiliation'] for c in d['metadata']['creators'] if c['name'].startswith('Rice')],'supp v118 in desc','v119' in d['metadata']['description'], 'v118' in d['metadata']['description'])
print({f['filename']:f['checksum'] for f in d['files'] if f['filename'] in os.listdir('files')})
