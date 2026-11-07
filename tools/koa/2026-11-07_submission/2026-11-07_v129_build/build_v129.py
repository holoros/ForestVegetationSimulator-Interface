"""koa v129 / s120, 2026-11-07 (OODA run). Verified fixes only, word neutral where possible.
v129: Section 3.5 'Planted projections beyond about age 18 lie outside the plantation record' contradicted 'The only old planting in the record'
(same paragraph) and Section 4.3 'Planted rows beyond about age 18 rest on the Kulani plantation alone'; now matches them.
Withdrawn, not added: the Oct 1 containment sentence (planted age-20 BAPH above the planted 95th percentile). With origin assigned at plot level
(plot_intervals_origin_v103.csv and dDBH_CS_v103_model.csv), 468 planted plot-years have BAPH 95th percentile 46.4 and maximum 68.9 m2/ha
(firebreather ~/jobs/koa_v128_containment/c2.py), so 44.0 to 49.0 lies inside the record; the 157 / 20.4 figures used the tree-level flag.
s120: KMR defined in the Table S14 and Table S24 captions (verifier finding)."""
import sys, docx
sys.path.insert(0, '.')
from docedit import iter_all_pars, replace_in
O = '/mnt/user-data/outputs/2026-11/koa_v128/'
def ed(src, dst, edits):
    d = docx.Document(O + src); P = list(iter_all_pars(d))
    for a, o, n in edits:
        h = [p for p in P if a in p.text]; assert len(h) == 1, (src, a, len(h)); replace_in(h[0], o, n, keep_format=True)
    d.save(dst); print(dst, len(edits))
MS = [('Planted projections beyond about age 18 lie outside', 'lie outside the plantation record (Section 3.1).', 'rest on the single old Kulani planting (Section 3.1).')]
SU = [('Table S14. Preliminary covariate assembly', 'against 877 (Section S3.4).', 'against 877 (Section S3.4). KMR PSP is the Kealakekua Mountain Reserve permanent sample plot network.'),
      ('Table S24. Monte Carlo parameter distributions', 'estimated across candidate definitions of the constant.', 'estimated across candidate definitions of the constant. FIA is the Forest Inventory and Analysis program, KMR PSP the Kealakekua Mountain Reserve permanent sample plots and PSP the plantation permanent sample plots.')]
ed('koa_manuscript_v128_FINAL.docx', 'koa_manuscript_v129_FINAL.docx', MS)
ed('koa_manuscript_v128_FINAL_BLIND.docx', 'koa_manuscript_v129_FINAL_BLIND.docx', MS)
ed('koa_supplemental_v119_FINAL.docx', 'koa_supplemental_v120_FINAL.docx', SU)
ed('koa_supplemental_v119_FINAL_BLIND.docx', 'koa_supplemental_v120_FINAL_BLIND.docx', SU)
