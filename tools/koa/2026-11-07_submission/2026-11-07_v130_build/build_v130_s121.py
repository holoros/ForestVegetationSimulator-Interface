"""koa v130 / s121, 2026-11-07, manuscript-preparer full pass (Stages 5, 6, 8). Verified fixes only.
Sources: Stage 5 claim check (Conclusions 63.5 -> 64), citation check (Baker 2009 Table 3 defines the 5.7-8.2 values as aboveground
biomass increment; Elevitch & Wilkinson 2000 is an edited agroforestry guide set that does not address koa restoration, watershed or habitat;
it is an edited volume), meter caption gate (Fig. 3 and Table 1 captions at 6 sentences), deposited koa_params.py INDEX_DIAMETER_CM = 25.0
(supplement S5 step 5 said 25.4), abstract wording (the 36% is a model-predicted effect at equal size and competition)."""
import sys, docx
sys.path.insert(0, '.')
from docedit import iter_all_pars, replace_in
O = '/mnt/user-data/outputs/2026-11/koa_v129/'
MS = [
 ('Diameter growth was about 36% faster', 'Diameter growth was about 36% faster', 'Modeled diameter growth was about 36% faster'),
 ('95% Monte Carlo ranges 63 to 244', '63 to 244', '64 to 244'),
 ('of koa wood biomass increment', 'of koa wood biomass increment', 'of koa aboveground biomass increment'),
 ('may be the more defensible objectives there (Elevitch and Wilkinson, 2000)', 'objectives there (Elevitch and Wilkinson, 2000), with', 'objectives there, with'),
 ('Fig. 3. Component equations for koa', 'Table 2 notes). (d) Annual diameter increment', 'Table 2 notes); (d) annual diameter increment'),
 ('Table 1. Data sources in the koa permanent plot network', 'measured once. Per-source statistics are in Table S2.', 'measured once, and per-source statistics are in Table S2.'),
]
SU = [
 ('(5) computes absolute SDI = TPH', 'SDI = TPH × (QMD/25.4)', 'SDI = TPH × (QMD/25)'),
 ('Elevitch, C.R., Wilkinson, K.M., 2000.', 'Wilkinson, K.M., 2000.', 'Wilkinson, K.M. (Eds.), 2000.'),
]
def ed(src, dst, edits, drop_ref=False):
    d = docx.Document(O + src); P = list(iter_all_pars(d)); n = 0
    for a, o, nw in edits:
        h = [p for p in P if a in p.text]
        if not h and 'BLIND' in src and a.startswith('Fig'): continue
        assert len(h) == 1, (src, a, len(h)); assert o in h[0].text, (src, o)
        replace_in(h[0], o, nw, keep_format=True); n += 1
    if drop_ref:
        r = [p for p in P if p.text.startswith('Elevitch, C.R., Wilkinson, K.M., 2000.')]; assert len(r) == 1
        r[0]._element.getparent().remove(r[0]._element); n += 1
    d.save(dst); print(dst, n)
ed('koa_manuscript_v129_FINAL.docx', 'koa_manuscript_v130_FINAL.docx', MS, True)
ed('koa_manuscript_v129_FINAL_BLIND.docx', 'koa_manuscript_v130_FINAL_BLIND.docx', MS, True)
ed('koa_supplemental_v120_FINAL.docx', 'koa_supplemental_v121_FINAL.docx', SU)
ed('koa_supplemental_v120_FINAL_BLIND.docx', 'koa_supplemental_v121_FINAL_BLIND.docx', SU)
