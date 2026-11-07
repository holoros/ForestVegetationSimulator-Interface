"""koa v131, 2026-11-07. Aaron's Option 1 on the v130 referee read (abstract-level framing, title kept) plus the cheap verified items.
F1 mapped index (abstract), F2 pooled agreement (Table S37), F3 projection beyond the 33-year natural record (Sec 4.6),
F5 intended use limited to productivity levels (Table S31: QMD at 40 not ordered by initial density),
F14 stem-number wording (Table S31: 171 to 277 and 201 to 351 stems at 40 from 8-fold starting ranges),
F10 environmental form (Table S40: dAIC +4.90, held-out RMSE worse than the applied index in all four sources)."""
import sys, docx
sys.path.insert(0, '.')
from docedit import iter_all_pars, replace_in
O = '/mnt/user-data/outputs/2026-11/koa_v130/'
E = [
 ('Modeled diameter growth was about 36% faster', 'faster on high than on low productivity sites,', 'faster at high than at low mapped productivity,'),
 ('the system reproduced average survival, tree size', 'the system reproduced average survival', 'the system reproduced pooled average survival'),
 ('Forty years ahead, natural stands on medium and high', 'Forty years ahead, natural stands on medium and high productivity sites were projected to hold', 'Projected forty years ahead, beyond the longest natural record, natural stands on medium and high productivity sites held'),
 ('a quantitative basis for comparing average stand', 'development across sites, planting densities, and thinning regimes.', 'development across sites.'),
 ('Its intended use is to compare mean development', 'across productivity levels, initial densities, and thinning regimes over the 52-year span', 'across productivity levels over the 52-year span'),
 ('its proper use is to compare mean development across BYI levels', 'across BYI levels, initial densities, and thinning regimes within the 52-year span', 'across BYI levels within the 52-year span'),
 ('and stem numbers converge by age 40', 'and stem numbers converge by age 40', 'and the eightfold range in stem numbers narrows below twofold by age 40'),
 ('richer forms of the site term did not transfer across data sources', 'did not transfer across data sources (Tables S36 and S40; Section S3.2)', 'did not transfer across data sources, and an environmental form in rainfall, temperature, and available water fitted worse (ΔAIC +4.9) and predicted every held-out source worse (Tables S36 and S40; Section S3.2)'),
]
for s, t in [('koa_manuscript_v130_FINAL.docx', 'koa_manuscript_v131_FINAL.docx'), ('koa_manuscript_v130_FINAL_BLIND.docx', 'koa_manuscript_v131_FINAL_BLIND.docx')]:
    d = docx.Document(O + s); P = list(iter_all_pars(d))
    for a, o, n in E:
        h = [p for p in P if a in p.text]; assert len(h) == 1, (s, a, len(h)); assert o in h[0].text, (s, o[:50])
        replace_in(h[0], o, n, keep_format=True)
    d.save(t); print(t, len(E))

# --- second part (after the fresh-context check of the changed sentences) ---
E2 = [
 ('did not transfer across data sources, and an environmental form', 'did not transfer across data sources, and an environmental form in rainfall, temperature, and available water fitted worse (ΔAIC +4.9) and predicted every held-out source worse (Tables S36 and S40; Section S3.2).', 'did not transfer across data sources (Tables S36 and S40; Section S3.2). An environmental form in rainfall, temperature, and available water fitted worse than the adjusted index (ΔAIC +9.4) and predicted every held-out source worse.'),
 ('a quantitative basis for comparing average stand', 'development across sites.', 'development across productivity levels.'),
]
for t in ['koa_manuscript_v131_FINAL.docx', 'koa_manuscript_v131_FINAL_BLIND.docx']:
    d = docx.Document(t); P = list(iter_all_pars(d))
    for a, o, n in E2:
        h = [p for p in P if a in p.text]; assert len(h) == 1, (t, a); assert o in h[0].text, (t, o[:40])
        replace_in(h[0], o, n, keep_format=True)
    d.save(t); print('part2', t)
OS = '/mnt/user-data/outputs/2026-11/koa_v130/'
for s, t in [('koa_supplemental_v121_FINAL.docx', 'koa_supplemental_v122_FINAL.docx'), ('koa_supplemental_v121_FINAL_BLIND.docx', 'koa_supplemental_v122_FINAL_BLIND.docx')]:
    d = docx.Document(OS + s); P = list(iter_all_pars(d))
    h = [p for p in P if 'initial densities, and thinning regimes' in p.text]; assert len(h) == 1, (s, len(h))
    replace_in(h[0], 'Comparing BYI levels, initial densities, and thinning regimes within', 'Comparing mean development across BYI levels within', keep_format=True)
    d.save(t); print('supp', t)
