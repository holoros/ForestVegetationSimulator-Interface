import os,requests,re
H={'Authorization':'Bearer '+open(os.path.expanduser('~/.config/zenodo/token')).read().strip()}
d=requests.get('https://zenodo.org/api/deposit/depositions/24013562',headers=H,timeout=60).json()
os.makedirs('draft_text',exist_ok=True)
for f in d['files']:
    n=f['filename']
    if re.search(r'\.(md|csv|cff|tsv|txt|py|R|r)$',n) and f['filesize']<3_000_000:
        p='draft_text/'+n
        if not os.path.exists(p):
            r=requests.get(f['links']['download'],headers=H,timeout=120); open(p,'wb').write(r.content)
        t=open(p,encoding='utf-8',errors='replace').read()
        k=len(re.findall(r'Mauna Loa|Keauhou.Mauna',t)); c=len(re.findall(r'competitive annual',t))
        if k or c: print(n,'MaunaLoa',k,'competitive',c)
print('done')
