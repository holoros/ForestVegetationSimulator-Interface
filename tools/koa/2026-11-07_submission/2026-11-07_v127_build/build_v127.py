"""koa v127, 2026-11-07: open items resolved on v126 (sources: firebreather ledgers, Baker et al. 2009 GTR text, Wilton et al. 2015 text, Ben Rice's signature for the Midgard address)."""
import sys, docx
sys.path.insert(0, '.')
from docedit import find_par, iter_all_pars, replace_in
COMMON = [
 ('plot elevations of about 580 to 1,980 m', 'plot elevations of about 580 to 1,980 m where elevation was recorded (Table S34 for rainfall and temperature)', 'plot elevations of about 460 to 1,980 m on the 100 plots where elevation was recorded (Table S34; Section S1.1)'),
 ('232 forested plots of Hawaii Island', '232 forested plots of Hawaii Island', '232 forested plots of Hawaii Island with complete predictors'),
 ('Kap and Kualoa values are imputed', 'and the Kap and Kualoa values are imputed (Section S2.1)', 'the Kap values are imputed, and the Kualoa values are direct predictions of the statewide forest (Section S2.1)'),
 ('The conditional fit statistics sit at or above', 'The conditional fit statistics sit', 'The conditional fit statistics, which carry the tree and installation intercepts, sit'),
 ('40 to 60 years that sawlog quality requires', 'the 40 to 60 years that sawlog quality requires (Baker et al., 2009)', 'the 40 to 70 years over which koa diameter growth stays nearly linear (Baker et al., 2009)'),
 ('At a basic density of 510 kg', 'At a basic density of 510 kg m⁻³ (Wilton et al., 2015)', 'At a basic density of 510 kg m⁻³, within the koa specific gravities of 0.46 to 0.55 compiled by Wilton et al. (2015),'),
 ('at a basic density of 510 kg', 'at a basic density of 510 kg m⁻³ (Wilton et al., 2015)', 'at a basic density of 510 kg m⁻³ (within the range compiled by Wilton et al., 2015)'),
]
NAMED = [
 ('Midgard Natural Resources LLC, New Hampshire, USA', 'Midgard Natural Resources LLC, New Hampshire, USA', 'Midgard Natural Resources LLC, 175 Reed Road, Colebrook, NH 03576, USA'),
 ('with Version 1.12.0 (https://doi.org/10.5281/zenodo.23846609)', 'Version 1.12.0 (https://doi.org/10.5281/zenodo.23846609)', 'Version 1.12.1 (https://doi.org/10.5281/zenodo.24013562)'),
 ('Version 1.12.0. Zenodo. https://doi.org/10.5281/zenodo.23846609', 'Version 1.12.0. Zenodo. https://doi.org/10.5281/zenodo.23846609', 'Version 1.12.1. Zenodo. https://doi.org/10.5281/zenodo.24013562'),
]
def apply(src, dst, edits):
    d = docx.Document(src); pars = list(iter_all_pars(d)); n = 0
    for anchor, old, new in edits:
        old = old.replace('m⁻³', 'm−3'); new = new.replace('m⁻³', 'm^−3^')
        hits = [p for p in pars if anchor in p.text]
        if len(hits) != 1: raise SystemExit(f'{dst}: {len(hits)} hits for {anchor}')
        replace_in(hits[0], old, new, keep_format=True); n += 1
    d.save(dst); print('saved', dst, n)
V = '/mnt/user-data/outputs/2026-11/koa_v126/'
apply(V + 'koa_manuscript_v126_FINAL.docx', 'koa_manuscript_v127_FINAL.docx', COMMON + NAMED)
apply(V + 'koa_manuscript_v126_FINAL_BLIND.docx', 'koa_manuscript_v127_FINAL_BLIND.docx', COMMON)
