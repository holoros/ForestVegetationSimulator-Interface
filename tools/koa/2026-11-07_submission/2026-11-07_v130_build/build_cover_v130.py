"""Cover letter v130: counts regenerated from manuscript v130 (300-word abstract, 64 references)."""
import sys, docx; sys.path.insert(0,'.')
from docedit import iter_all_pars, replace_in
d=docx.Document('/mnt/user-data/outputs/2026-11/koa_v127/koa_cover_letter_v127.docx'); P=list(iter_all_pars(d))
for o,n in [('299-word abstract','300-word abstract'),('65 references','64 references')]:
    h=[p for p in P if o in p.text]; assert len(h)==1,o; replace_in(h[0],o,n,keep_format=True)
d.save('koa_cover_letter_v130.docx'); print('ok')
