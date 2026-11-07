import hashlib,os,re,json
F='files'; sha=lambda p: hashlib.sha256(open(p,'rb').read()).hexdigest(); md5=lambda p: hashlib.md5(open(p,'rb').read()).hexdigest()
SQ=os.path.join(F,'koa_frames.sqlite'); n_sq=os.path.getsize(SQ)
sec=("## VERSION 1.12.1 (November 6, 2026): the frames as one SQLite file\n\n"
"This version adds `koa_frames.sqlite`, the three data frames of 1.12.0 in a single SQLite database, and `build_sqlite_v2.py`, the script that builds it. "
"Nothing else changed: the engine, parameters, frames, figures and numbers are those of 1.12.0. "
"The tables are `stand` (AK_PLT_GEO.csv, 320 rows), `plot` (AK_PLT.csv, 768 rows) and `tree` (AK_TREE.csv, 16,914 rows, all 38 columns including the repair provenance columns), "
"plus `readme` (source file, row and column counts, and the md5 of each source frame on this record) and `about`. "
"The builder downloads each frame from record 23846609 and stops unless its md5 matches the record, so each table holds exactly the rows and columns of the deposited CSV. "
"Data, Install and Plot join the three tables, and tree joins plot on Measure as well. "
"Join coverage follows the frames themselves: 729 of 768 plot rows have a stand row (the 39 FIA plot-years without one belong to the plots listed in `AK_PLT_missing_GEO.csv`), "
"and 14,417 of 16,914 tree rows have a matching plot-year row (the other 2,497 are PSP, Kualoa and KMR measurement years with no plot-year row in AK_PLT.csv). "
"The builder fails on any coordinate-named column and on any text cell holding a decimal-degree pair in the Hawaii envelope; installations carry deposit ids such as KFRP-01. "
"Version DOI: reserved when this draft was created; see the record page. Cite the concept DOI 10.5281/zenodo.21081014.\n\n")
r=open('prev_README.md',encoding='utf8').read()
i=r.index('**Version 1.12.0')
r=r[:i]+'**Version 1.12.1 (2026-11-06) adds the frames as one SQLite file; see the 1.12.1 section below. Everything else is 1.12.0.**\n\n'+r[i:]
j=r.index('## VERSION 1.12.0'); r=r[:j]+sec+r[j:]
open(F+'/README.md','w',encoding='utf8').write(r)
c=open('prev_DEPOSIT_CHANGELOG.md',encoding='utf8').read()
ent=("## 2026-11-06 (deposit 1.12.1): new version of the published 1.12.0 (record 23846609)\n\n"
"Created with the Zenodo new-version action from 1.12.0; the draft starts with its 96 files. "
f"Added: `koa_frames.sqlite` ({n_sq:,} bytes, md5 {md5(SQ)}), the stand, plot and tree frames of 1.12.0 as SQLite tables, and `build_sqlite_v2.py`, its builder. "
"Replaced: `README.md` (1.12.1 section), `DEPOSIT_CHANGELOG.md`, `CITATION.cff` (version), `SHA256SUMS`. Removed: `FILE_MAP_1.12.0.tsv`, replaced by `FILE_MAP_1.12.1.tsv`. Record file count after the update: 98. "
"An earlier build of the database (5 November 2026, `build_sqlite.py`) read the plot and tree frames from the engine working copy, where 64 Kahikinui installations still carried coordinate strings as Install ids; it was not deposited, and `build_sqlite_v2.py` reads the published frames instead. "
"Restricted data: the builder sweeps every column name and text cell for coordinates (no hits); the new text files carry no coordinates.\n\n\n")
k=c.index('## 2026-11-03'); c=c[:k]+ent+c[k:]
open(F+'/DEPOSIT_CHANGELOG.md','w',encoding='utf8').write(c)
y=open('prev_CITATION.cff',encoding='utf8').read()
y=y.replace('version: "1.12.0"','version: "1.12.1"').replace('date-released: "2026-11-03"','date-released: "2026-11-06"')
y=y.replace('# 1.9.4 was staged','# Version 1.12.1 (2026-11-06) adds koa_frames.sqlite to the published 1.12.0; its version DOI is reserved by the new draft.\n# 1.9.4 was staged')
y=y.replace('    value: "10.5281/zenodo.23846609"\n    description: "Version DOI of deposit 1.12.0"','    value: "10.5281/zenodo.23846609"\n    description: "Version DOI of deposit 1.12.0 (published 2026-11-03); 1.12.1 adds the SQLite frames"')
assert 'version: "1.12.1"' in y
open(F+'/CITATION.cff','w',encoding='utf8').write(y)
m=open('prev_FILE_MAP_1.12.0.tsv',encoding='utf8').read().rstrip('\n').split('\n')
m=[l for l in m if not l.startswith('FILE_MAP_1.12.0.tsv')]
m+=['koa_frames.sqlite\tbuild_sqlite_v2.py on the published 1.12.0 frames (2026-11-06)\tStand, plot and tree frames of 1.12.0 as SQLite tables, with readme and about tables',
    'build_sqlite_v2.py\tkoa_sqlite_zenodo_20261106 (firebreather)\tBuilds koa_frames.sqlite from the published frames, md5-checked, with a coordinate gate',
    'FILE_MAP_1.12.1.tsv\tthis file\tFile map of deposit 1.12.1']
open(F+'/FILE_MAP_1.12.1.tsv','w',encoding='utf8').write('\n'.join(m)+'\n')
s=[l for l in open('prev_SHA256SUMS',encoding='utf8').read().split('\n') if l.strip()]
hdr=[l for l in s if l.startswith('#')]; body={l.split('  ',1)[1]:l.split('  ',1)[0] for l in s if not l.startswith('#')}
body.pop('FILE_MAP_1.12.0.tsv',None)
for n in ['koa_frames.sqlite','build_sqlite_v2.py','README.md','DEPOSIT_CHANGELOG.md','CITATION.cff','FILE_MAP_1.12.1.tsv']: body[n]=sha(os.path.join(F,n))
out=['# SHA-256 of every file on deposit 1.12.1 except this file, written by build_texts_1121.py on 2026-11-06']+[f'{body[n]}  {n}' for n in sorted(body,key=str.lower)]
open(F+'/SHA256SUMS','w',encoding='utf8').write('\n'.join(out)+'\n')
print('files to PUT',sorted(os.listdir(F)),'SHA lines',len(body))
# gates on new/changed files
deg=re.compile(r'(?i)(lat|lon|coord)[^\n]{0,40}?(?<![\w.])-?(1[5-6]\d|1[89]|2[0-3])\.\d{3,}'); pair=re.compile(r'(?<![\w.])-?15\d\.\d{3,}[ ,;-]+-?(1[89]|2[0-3])\.\d{3,}')
for n in os.listdir(F):
    if n.endswith('.sqlite'): continue
    t=open(os.path.join(F,n),encoding='utf8',errors='replace').read()
    for rx in (deg,pair):
        h=rx.findall(t)
        if h: print('GATE3 HIT',n,h[:3])
for n in os.listdir(F):
    t=open(os.path.join(F,n),'rb').read()
    if not n.endswith('.sqlite') and (b'\xe2\x80\x94' in t and n in ('README.md','DEPOSIT_CHANGELOG.md')):
        print('em dash present in',n,'(count',t.count(b'\xe2\x80\x94'),')')
print('GATES DONE')
