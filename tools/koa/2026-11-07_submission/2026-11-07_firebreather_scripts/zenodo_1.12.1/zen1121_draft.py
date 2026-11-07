"""Create the 1.12.1 draft of the koa record as a new version of the published 1.12.0 (record 23846609). DRAFT ONLY, never publishes."""
import os,json,hashlib,time,sys,requests
TP=os.path.expanduser('~/.config/zenodo/token'); print('token file:',TP,flush=True)
H={'Authorization':'Bearer '+open(TP).read().strip()}; A='https://zenodo.org/api/deposit/depositions'
md5=lambda b: hashlib.md5(b).hexdigest()
d=requests.get(A+'/23846609',headers=H,timeout=60).json()
print('1.12.0 state',d['state'],'submitted',d['submitted'],'version',d['metadata'].get('version'),flush=True)
assert d['submitted'] and d['metadata'].get('version')=='1.12.0'
ld=d['links'].get('latest_draft'); 
if ld and not ld.endswith('/23846609'):
    nd=requests.get(ld,headers=H,timeout=60).json(); print('existing draft found',nd['id'],nd['metadata'].get('version'),flush=True)
else:
    r=requests.post(A+'/23846609/actions/newversion',headers=H,timeout=120); print('newversion',r.status_code,flush=True); r.raise_for_status()
    nd=requests.get(r.json()['links']['latest_draft'],headers=H,timeout=60).json()
DID=nd['id']; assert nd['state']=='unsubmitted' and not nd['submitted']
B=nd['links']['bucket']; before={f['filename']:f['checksum'].replace('md5:','') for f in nd['files']}
doi=(nd['metadata'].get('prereserve_doi') or {}).get('doi'); print('draft',DID,'reserved DOI',doi,'n_files',len(before),flush=True)
res={'draft':DID,'reserved_doi':doi,'uploaded':{},'failed':[]}
if 'FILE_MAP_1.12.0.tsv' in before:
    fid=[f['id'] for f in nd['files'] if f['filename']=='FILE_MAP_1.12.0.tsv'][0]
    r=requests.delete(f"{A}/{DID}/files/{fid}",headers=H,timeout=60); print('DELETE FILE_MAP_1.12.0.tsv',r.status_code,flush=True); res['deleted']=r.status_code
for n in sorted(os.listdir('files'),key=lambda n: os.path.getsize('files/'+n)):
    b=open('files/'+n,'rb').read(); m=md5(b)
    if before.get(n)==m: print('SKIP',n,flush=True); continue
    if n in before:
        fid=[f['id'] for f in nd['files'] if f['filename']==n][0]; requests.delete(f"{A}/{DID}/files/{fid}",headers=H,timeout=60)
    ok=False
    for a in range(4):
        try:
            rr=requests.put(B+'/'+n,data=b,headers=H,timeout=900)
            if rr.ok and rr.json().get('checksum','').replace('md5:','')==m: ok=True; break
            print('retry',n,rr.status_code,rr.text[:200],flush=True)
        except Exception as e: print('err',n,str(e)[:200],flush=True)
        time.sleep(20*(a+1))
    print(('OK ' if ok else 'FAIL ')+n,m,len(b),flush=True); (res['uploaded'].__setitem__(n,m) if ok else res['failed'].append(n))
cur=requests.get(f'{A}/{DID}',headers=H,timeout=60).json(); m=cur['metadata']
m['version']='1.12.1'; m['publication_date']='2026-11-06'
add=("<p><strong>Version 1.12.1 (6 November 2026)</strong> adds <code>koa_frames.sqlite</code>, the stand, plot and tree frames of 1.12.0 as one SQLite database "
     "(320, 768 and 16,914 rows; md5-checked against this record), and <code>build_sqlite_v2.py</code>, its builder. Nothing else changed; see README.md.</p>")
if 'Version 1.12.1' not in m.get('description',''): m['description']=add+m.get('description','')
m['notes']='Version 1.12.1 (6 November 2026): adds koa_frames.sqlite and build_sqlite_v2.py; content otherwise identical to 1.12.0. Earlier note: '+m.get('notes','')
m.pop('prereserve_doi',None); m.pop('doi',None); m={k:v for k,v in m.items() if v not in ('',[],{},None)}
pm=requests.put(f'{A}/{DID}',headers={**H,'Content-Type':'application/json'},data=json.dumps({'metadata':m}),timeout=120); print('metadata PUT',pm.status_code,flush=True)
if not pm.ok: print(pm.text[:1500])
f=requests.get(f'{A}/{DID}',headers=H,timeout=60).json(); after={x['filename']:x['checksum'].replace('md5:','') for x in f['files']}
local={n:md5(open('files/'+n,'rb').read()) for n in os.listdir('files')}
res.update(n_files=len(after),state=f['state'],submitted=f['submitted'],version=f['metadata'].get('version'),
  missing_local=[n for n in local if after.get(n)!=local[n]],old_map_present='FILE_MAP_1.12.0.tsv' in after,metadata_put=pm.status_code,
  html=f['links'].get('html'))
json.dump(res,open('result_1121.json','w'),indent=1); print(json.dumps(res,indent=1))
print('DRAFT %s FILLED AS 1.12.1, NOT PUBLISHED'%DID)
