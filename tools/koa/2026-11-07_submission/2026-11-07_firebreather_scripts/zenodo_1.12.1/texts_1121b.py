import hashlib,re
F='files/'
OLD_T='# Data for: Development of individual-tree static and dynamic equations for Acacia koa in Hawaii for use in a growth and yield model'
NEW_T='# Data for: Growth, site productivity, and mortality of Acacia koa A. Gray across Hawaii: an individual-tree growth and yield model\n\n(Manuscript title as submitted to Forest Ecosystems, November 2026; earlier working title: "Development of individual-tree static and dynamic equations for Acacia koa in Hawaii for use in a growth and yield model".)'
SUPP=('\n\n**Supplement (added 7 November 2026, same draft).** `koa_supplemental.pdf` is now supplement v118 of the submitted manuscript (v127), md5 9d97c1fc268442bc40544e3698331b8c, replacing v117 (md5 a13c8e441e3d7a1bd6901d3fd977365b). The changes are reporting corrections only: the elevation range and its source plots (S1.1), the description of the 98 Kap and 151 statewide FIA units and of the Kualoa predictions (S2.1, Table S3), the 232 forested plots with complete predictors and the Fig. 2 error layer (S2.2), the index diameter behind SDI 885 (S3.3, S7.1), the Eichhorn order (S3.7), the bootstrap source of the planted interval (S4.1), Clopper-Pearson rounding in Table S26 and Section S6.3, the gamma/alpha note of Table S20, the jackknife fold count of Fig. S3, and this version and DOI in the data reference. The engine, parameters, frames and computed outputs are unchanged. Version DOI of 1.12.1: 10.5281/zenodo.24013562 (reserved; resolves once published).')
r=open(F+'README.md',encoding='utf-8').read()
assert r.count(OLD_T)==1; r=r.replace(OLD_T,NEW_T)
a='Version DOI: reserved when this draft was created; see the record page. Cite the concept DOI 10.5281/zenodo.21081014.'
assert r.count(a)==1; r=r.replace(a,a+SUPP)
c='- **KMR CAR**: Keauhou-Mauna Loa Restoration competitive annual remeasurements'
assert r.count(c)==1; r=r.replace(c,'- **KMR CAR**: Keauhou-Mauna Loa Restoration CAR plot network (the expansion of CAR is to be confirmed with the data provider; an earlier README expanded it as "competitive annual remeasurements", which the data do not support)')
open(F+'README.md','w',encoding='utf-8').write(r)
c=open(F+'CITATION.cff',encoding='utf-8').read()
o='# Version 1.12.1 (2026-11-06) adds koa_frames.sqlite to the published 1.12.0; its version DOI is reserved by the new draft.'
assert c.count(o)==1; c=c.replace(o,'# Version 1.12.1 (2026-11-06; supplement v118 added 2026-11-07) adds koa_frames.sqlite to the published 1.12.0 and replaces\n# koa_supplemental.pdf with supplement v118; its version DOI 10.5281/zenodo.24013562 is reserved by draft 24013562.')
o='identifiers:\n'
assert c.count(o)==1; c=c.replace(o,o+'  - type: doi\n    value: "10.5281/zenodo.24013562"\n    description: "Version DOI of deposit 1.12.1 (reserved by draft 24013562; the version cited by the submitted manuscript)"\n')
assert c.count('Midgard Natural Resources, New Hampshire')==1; c=c.replace('Midgard Natural Resources, New Hampshire','Midgard Natural Resources LLC, New Hampshire')
open(F+'CITATION.cff','w',encoding='utf-8').write(c)
m=open(F+'FILE_MAP_1.12.1.tsv',encoding='utf-8').read().split('\n')
i=[k for k,l in enumerate(m) if l.startswith('koa_supplemental.pdf\t')]; assert len(i)==1
m[i[0]]='koa_supplemental.pdf\tsubmission/koa_supplemental_v118_FINAL.pdf (supplement v118, md5 9d97c1fc268442bc40544e3698331b8c) (staged 1.12.1, 2026-11-07)\tManuscript supplement v118, final, matching manuscript v127 (replaces v117, md5 a13c8e441e3d7a1bd6901d3fd977365b; reporting corrections only)'
open(F+'FILE_MAP_1.12.1.tsv','w',encoding='utf-8').write('\n'.join(m))
d=open(F+'DEPOSIT_CHANGELOG.md',encoding='utf-8').read()
h='## 2026-11-06 (deposit 1.12.1): new version of the published 1.12.0 (record 23846609)'
assert d.count(h)==1
d=d.replace(h,'## 2026-11-07 (deposit 1.12.1, same draft 24013562): supplement v118 and record alignment\n\n`koa_supplemental.pdf` replaced with supplement v118 (md5 9d97c1fc268442bc40544e3698331b8c), the supplement of manuscript v127 as submitted to Forest Ecosystems; reporting corrections only, engine and outputs unchanged. README.md: manuscript title updated to the submitted title, the unverified expansion of KMR CAR withdrawn, 1.12.1 supplement note added. CITATION.cff: 1.12.1 version DOI 10.5281/zenodo.24013562 added; Midgard Natural Resources LLC. FILE_MAP_1.12.1.tsv and SHA256SUMS updated for the changed files. Metadata: creator affiliation for Ben Rice and the 1.12.1 description and notes. Nothing published.\n\n'+h)
open(F+'DEPOSIT_CHANGELOG.md','w',encoding='utf-8').write(d)
s=open(F+'SHA256SUMS').read().split('\n'); out=[]
for l in s:
    p=l.split('  ',1)
    if len(p)==2 and p[1] in ('README.md','CITATION.cff','FILE_MAP_1.12.1.tsv','koa_supplemental.pdf','DEPOSIT_CHANGELOG.md'):
        l=hashlib.sha256(open(F+p[1],'rb').read()).hexdigest()+'  '+p[1]
    out.append(l)
open(F+'SHA256SUMS','w').write('\n'.join(out)); print('texts ok')
