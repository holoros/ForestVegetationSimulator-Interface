import hashlib
F='files/'; M119='7d882d745f749453f6280ea0d0abe702'; M120='96d1440059a92488d8479f7c77a28a16'
def sub(path,pairs):
    t=open(F+path,encoding='utf-8').read()
    for o,n in pairs:
        assert t.count(o)==1,(path,o[:60]); t=t.replace(o,n)
    open(F+path,'w',encoding='utf-8').write(t)
sub('README.md',[
 ('`koa_supplemental.pdf` is now supplement v119 of the submitted manuscript (v128), md5 '+M119+', replacing v117','`koa_supplemental.pdf` is now supplement v120 of the submitted manuscript (v129), md5 '+M120+', replacing v117'),
 ('and the name of KMR (Kealakekua Mountain Reserve, not Keauhou-Mauna Loa Restoration).','the name of KMR (Kealakekua Mountain Reserve, not Keauhou-Mauna Loa Restoration), and abbreviations defined in the Table S14 and S24 captions.\n\n**HiGy.R in this record.** The deposited `HiGy.R` (VersionTag HiGyV0.5.0) is the v104 mirror kept as history, as FILE_MAP says. The R carrier of the v105final engine is HiGy 0.4.2 on GitHub (holoros/ForestVegetationSimulator-Interface, branch ClaudeDevelopment, commit 304f645, fvsOL/inst/extdata/HiGy.R); the Python engine in this record is the engine of record. The version numbers are not ordered by date.'),
])
sub('CITATION.cff',[('koa_supplemental.pdf with supplement v119','koa_supplemental.pdf with supplement v120')])
m=open(F+'FILE_MAP_1.12.1.tsv',encoding='utf-8').read().split('\n')
i=[k for k,l in enumerate(m) if l.startswith('koa_supplemental.pdf\t')]; assert len(i)==1
m[i[0]]='koa_supplemental.pdf\tsubmission/koa_supplemental_v120_FINAL.pdf (supplement v120, md5 '+M120+') (staged 1.12.1, 2026-11-07)\tManuscript supplement v120, final, matching manuscript v129 (replaces v117, md5 a13c8e441e3d7a1bd6901d3fd977365b; reporting corrections, the KMR name and caption abbreviations only)'
open(F+'FILE_MAP_1.12.1.tsv','w',encoding='utf-8').write('\n'.join(m))
sub('DEPOSIT_CHANGELOG.md',[('`koa_supplemental.pdf` replaced with supplement v119 (md5 '+M119+'), the supplement of manuscript v128','`koa_supplemental.pdf` replaced with supplement v120 (md5 '+M120+'), the supplement of manuscript v129 (v119, md5 '+M119+', and')])
t=open(F+'DEPOSIT_CHANGELOG.md',encoding='utf-8').read()
t=t.replace('(v119, md5 '+M119+', and as submitted to Forest Ecosystems (v118','as submitted to Forest Ecosystems (v119, md5 '+M119+', and v118',1)
open(F+'DEPOSIT_CHANGELOG.md','w',encoding='utf-8').write(t)
s=open(F+'SHA256SUMS').read().split('\n'); out=[]
for l in s:
    p=l.split('  ',1)
    if len(p)==2 and p[1] in ('README.md','CITATION.cff','FILE_MAP_1.12.1.tsv','koa_supplemental.pdf','DEPOSIT_CHANGELOG.md'):
        l=hashlib.sha256(open(F+p[1],'rb').read()).hexdigest()+'  '+p[1]
    out.append(l)
open(F+'SHA256SUMS','w').write('\n'.join(out)); print('texts ok')
