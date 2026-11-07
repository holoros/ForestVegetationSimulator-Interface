import json,requests,re,os
TP=os.path.expanduser('~/.config/zenodo/token'); H={'Authorization':'Bearer '+open(TP).read().strip()}
A='https://zenodo.org/api/deposit/depositions'
d=requests.get(A+'/24013562',headers=H,timeout=60).json(); m=d['metadata']
out={'state':d['state'],'submitted':d['submitted'],'title':m.get('title'),'version':m.get('version'),'pubdate':m.get('publication_date'),
 'creators':m.get('creators'),'keywords':m.get('keywords'),'license':m.get('license'),'related':m.get('related_identifiers'),
 'n_files':len(d['files']),'files':sorted((f['filename'],f['checksum'],f['filesize']) for f in d['files'])}
json.dump({**out,'description':m.get('description'),'notes':m.get('notes')},open('audit_1121.json','w'),indent=1)
for k,v in out.items():
  if k!='files': print(k,':',v)
for f in out['files']: print(*f)
