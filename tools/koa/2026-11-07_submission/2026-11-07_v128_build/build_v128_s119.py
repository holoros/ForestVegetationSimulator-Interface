"""koa v128 / s119, 2026-11-07: KMR is the Kealakekua Mountain Reserve (South Kona), not 'Keauhou-Mauna Loa Restoration'.
Source: Aviva Gottesman to Aaron Weiskittel and Ben Rice, 13 Nov 2025 ('Kealakekua Mountain Reserve - PSPs: Same measurement methods
as the Keauhou and Pahala plots') and 15 Dec 2025 ('KMR PSP monitoring (South Kona, Hawai'i)')."""
import sys, docx
sys.path.insert(0, '.')
from docedit import iter_all_pars, replace_in
O = '/mnt/user-data/outputs/2026-11/koa_v127/'
JOBS = [('koa_manuscript_v127_FINAL.docx', 'koa_manuscript_v128_FINAL.docx', 4),
        ('koa_manuscript_v127_FINAL_BLIND.docx', 'koa_manuscript_v128_FINAL_BLIND.docx', 4),
        ('koa_supplemental_v118_FINAL.docx', 'koa_supplemental_v119_FINAL.docx', 5),
        ('koa_supplemental_v118_FINAL_BLIND.docx', 'koa_supplemental_v119_FINAL_BLIND.docx', 5)]
OLD, NEW = 'Keauhou–Mauna Loa Restoration', 'Kealakekua Mountain Reserve'
import os
for src, dst, want in ([] if os.path.exists("koa_supplemental_v119_FINAL_BLIND.docx") else JOBS):
    d = docx.Document(O + src); n = 0
    for p in iter_all_pars(d):
        while OLD in p.text:
            replace_in(p, OLD, NEW, keep_format=True); n += 1
    assert n == want, (src, n)
    d.save(dst); print(dst, n)
# wording: 'Reserve program' -> 'Reserve'; supplement S1.1 '(KMR) program was split' -> '(KMR) record was split'
for f in ['koa_manuscript_v128_FINAL.docx', 'koa_manuscript_v128_FINAL_BLIND.docx', 'koa_supplemental_v119_FINAL.docx', 'koa_supplemental_v119_FINAL_BLIND.docx']:
    d = docx.Document(f); n = 0
    for p in iter_all_pars(d):
        for o, nw in [('Kealakekua Mountain Reserve program', 'Kealakekua Mountain Reserve'), ('Kealakekua Mountain Reserve (KMR) program was split', 'Kealakekua Mountain Reserve (KMR) record was split')]:
            while o in p.text:
                replace_in(p, o, nw, keep_format=True); n += 1
    d.save(f); print('wording', f, n)
