import sys, docx
sys.path.insert(0, '.')
from docedit import iter_all_pars, replace_in
def apply(src, dst, edits):
    d = docx.Document(src); pars = list(iter_all_pars(d))
    for anchor, old, new in edits:
        hits = [p for p in pars if anchor in p.text]
        if len(hits) != 1: raise SystemExit(f'{dst}: {len(hits)} hits for {anchor}')
        replace_in(hits[0], old, new, keep_format=True)
    d.save(dst); print('saved', dst)
V = '/mnt/user-data/outputs/2026-11/koa_v126/'
apply(V + 'koa_title_page_v126.docx', 'koa_title_page_v127.docx', [
 ('Midgard Natural Resources LLC, New Hampshire, USA', 'Midgard Natural Resources LLC, New Hampshire, USA', 'Midgard Natural Resources LLC, 175 Reed Road, Colebrook, NH 03576, USA'),
 ('with Version 1.12.0', 'Version 1.12.0 (https://doi.org/10.5281/zenodo.23846609)', 'Version 1.12.1 (https://doi.org/10.5281/zenodo.24013562)'),
 ('by up to 5.0 cm in DBH', 'final equations, by up to 5.0 cm in DBH', 'final equations, and departs by up to 5.0 cm in DBH'),
])
apply(V + 'koa_cover_letter_v126.docx', 'koa_cover_letter_v127.docx', [
 ('version 1.12.0 of a public Zenodo deposit', 'version 1.12.0 of a public Zenodo deposit (https://doi.org/10.5281/zenodo.23846609)', 'version 1.12.1 of a public Zenodo deposit (https://doi.org/10.5281/zenodo.24013562)'),
])
