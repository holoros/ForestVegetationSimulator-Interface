import hashlib
F='files/'
def sub(path, pairs):
    t=open(F+path,encoding='utf-8').read()
    for o,n in pairs:
        assert t.count(o)>=1,(path,o[:50]); t=t.replace(o,n)
    open(F+path,'w',encoding='utf-8').write(t)
V118,M118='supplement v118','9d97c1fc268442bc40544e3698331b8c'; M119='7d882d745f749453f6280ea0d0abe702'
sub('README.md',[
 ('(the Keauhou-Mauna Loa Restoration program contributes two plot networks, KMR CAR and KMR PSP, counted as one program)','(the Kealakekua Mountain Reserve, KMR, in South Kona contributes two plot networks, KMR CAR and KMR PSP, counted as one program)'),
 ('- **KMR CAR**: Keauhou-Mauna Loa Restoration CAR plot network (the expansion of CAR is to be confirmed with the data provider; an earlier README expanded it as "competitive annual remeasurements", which the data do not support)','- **KMR CAR**: Kealakekua Mountain Reserve plots of the CAR network, measured once (the source does not expand CAR; the data provider listed a South Kona koa plantation carbon project among the supplemental datasets, and confirmation is pending; earlier README versions expanded KMR as "Keauhou-Mauna Loa Restoration" and CAR as "competitive annual remeasurements", both withdrawn)'),
 ('- **KMR PSP**: Keauhou-Mauna Loa Restoration permanent sample plots','- **KMR PSP**: Kealakekua Mountain Reserve permanent sample plots (same measurement methods as the Keauhou and Pahala PSP network)'),
 ('`koa_supplemental.pdf` is now supplement v118 of the submitted manuscript (v127), md5 9d97c1fc268442bc40544e3698331b8c, replacing v117','`koa_supplemental.pdf` is now supplement v119 of the submitted manuscript (v128), md5 '+M119+', replacing v117'),
 ('and this version and DOI in the data reference.','this version and DOI in the data reference, and the name of KMR (Kealakekua Mountain Reserve, not Keauhou-Mauna Loa Restoration).'),
])
sub('CITATION.cff',[('replaces\n# koa_supplemental.pdf with supplement v118','replaces\n# koa_supplemental.pdf with supplement v119')])
m=open(F+'FILE_MAP_1.12.1.tsv',encoding='utf-8').read().split('\n')
i=[k for k,l in enumerate(m) if l.startswith('koa_supplemental.pdf\t')]; assert len(i)==1
m[i[0]]='koa_supplemental.pdf\tsubmission/koa_supplemental_v119_FINAL.pdf (supplement v119, md5 '+M119+') (staged 1.12.1, 2026-11-07)\tManuscript supplement v119, final, matching manuscript v128 (replaces v117, md5 a13c8e441e3d7a1bd6901d3fd977365b; reporting corrections and the KMR name only)'
open(F+'FILE_MAP_1.12.1.tsv','w',encoding='utf-8').write('\n'.join(m))
sub('DEPOSIT_CHANGELOG.md',[('`koa_supplemental.pdf` replaced with supplement v118 (md5 9d97c1fc268442bc40544e3698331b8c), the supplement of manuscript v127 as submitted to Forest Ecosystems; reporting corrections only, engine and outputs unchanged.','`koa_supplemental.pdf` replaced with supplement v119 (md5 '+M119+'), the supplement of manuscript v128 as submitted to Forest Ecosystems (v118, md5 '+M118+', was staged earlier the same day); reporting corrections only, engine and outputs unchanged. KMR is the Kealakekua Mountain Reserve (South Kona), per the data provider, and the README now says so.')])
s=open(F+'SHA256SUMS').read().split('\n'); out=[]
for l in s:
    p=l.split('  ',1)
    if len(p)==2 and p[1] in ('README.md','CITATION.cff','FILE_MAP_1.12.1.tsv','koa_supplemental.pdf','DEPOSIT_CHANGELOG.md'):
        l=hashlib.sha256(open(F+p[1],'rb').read()).hexdigest()+'  '+p[1]
    out.append(l)
open(F+'SHA256SUMS','w').write('\n'.join(out)); print('texts ok')
