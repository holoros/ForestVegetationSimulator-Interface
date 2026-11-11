"""koa supplement v118, 2026-11-07: verified stress-test fixes on s117 (sources in reviews/2026-11-07_koa-v125_STRESS-TEST_REVIEW.md)."""
import sys, docx
sys.path.insert(0, '.')
from docedit import find_par, iter_all_pars, replace_in
EDITS = [  # (anchor, old, new, count) ; count None = every paragraph containing anchor
 ('sources was measured once.', 'sources was measured once.', 'sources was measured once. Plot elevation was recorded on 100 of the 343 plots and runs from 457 to 1,981 m (DOFAW 579 to 1,539 m, FIA 457 to 1,981 m, PSP 638 to 1,567 m), with the FIA, DOFAW, and PSP 101 to 113 values converted from feet.', 1),
 ('namely the 98 Kap plots and 151 FIA installations', 'namely the 98 Kap plots and 151 FIA installations,', 'namely 98 Kap plots (53 of them holding live koa) and 151 statewide FIA installations outside the modeling sample,', 1),
 ('(R2 = 0.934). All 98 Kap plots', '(R2 = 0.934).', '(R^2^ = 0.934). The six Kualoa plots were not imputed; they take direct predictions from the statewide forest (77.0 to 95.8 Mg ha^−1^).', 1),
 ('98 Kap plots and 151 FIA installations (Section S2.1)', '98 Kap plots and 151 FIA installations', '98 Kap plots (53 with live koa) and 151 statewide FIA installations outside the sample', 1),
 ('but did not rank the 232 forested plots', 'did not rank the 232 forested plots', 'did not rank the 232 forested plots with complete predictors in all three predictor sets (of 235)', 1),
 ('but did not rank the 232 forested plots', 'Spearman correlation 0.33) (Table S7).', 'Spearman correlation 0.33) (Table S7). The error layer of the unadjusted surface, the local out-of-bag RMSE mapped through each cell\'s BYI, runs from 78 Mg ha^−1^ on the least productive substrates to 419 Mg ha^−1^ on the most productive sites (median 159 Mg ha^−1^ on Hawaii Island).', 1),
 ('projected planted stands reach RD of 1.16', 'projected planted stands reach RD of 1.16.', 'projected planted stands reach RD of 1.16 (the planted SDI of 885 in Section S7.1 is on the simulator\'s 25 cm index diameter).', 1),
 ('SDI at 437, 885, and 609', 'SDI at 437, 885, and 609', 'SDI at 437, 885, and 609 on the simulator\'s 25 cm index diameter', 1),
 ('the Eichhorn medians are 8.68, 9.21, and 8.22%', 'are 8.68, 9.21, and 8.22%', 'are 8.68, 9.21, and 8.22% (even-aged natural, uneven-aged natural, even-aged planted)', 1),
 ('a planted coefficient of −0.219 (−2.162 to +0.198)', '(−2.162 to +0.198)', '(−2.162 to +0.198 from 2,000 plot-cluster bootstrap resamples; Table S24 gives the narrower spread across the 500 joint replicates)', 1),
 ('0.88 (0.64 to 0.98)', '0.88 (0.64 to 0.98)', '0.88 (0.64 to 0.99)', None),
 ('0.75 (0.43 to 0.94)', '0.75 (0.43 to 0.94)', '0.75 (0.43 to 0.95)', None),
 ('0.56 (0.34 to 0.77)', '0.56 (0.34 to 0.77)', '0.57 (0.34 to 0.77)', None),
 ('planted diameter multiplier (0.45 to 0.98; Table S13)', '(0.45 to 0.98; Table S13)', '(0.45 to 0.98; Section S3.2)', 1),
 ('with gamma/alpha fixed at 1, fixed;', 'with gamma/alpha fixed at 1, fixed;', 'with gamma/alpha fixed at 1 and alpha drawn from N(2.96, 0.8546), clipped to 1 to 6, in the Monte Carlo;', 1),
 ('Version 1.12.0. Zenodo. https://doi.org/10.5281/zenodo.23846609', 'Version 1.12.0. Zenodo. https://doi.org/10.5281/zenodo.23846609', 'Version 1.12.1. Zenodo. https://doi.org/10.5281/zenodo.24013562', 'named'),
 ('5 of 62 jackknife folds failing', '5 of 62 jackknife folds failing', '5 of 62 delete-one-installation jackknife folds failing', 1),
]
for src, dst in [('s117.docx', 'koa_supplemental_v118_FINAL.docx'), ('s117_blind.docx', 'koa_supplemental_v118_FINAL_BLIND.docx')]:
    d = docx.Document(src); pars = list(iter_all_pars(d)); n = 0
    for anchor, old, new, cnt in EDITS:
        hits = [p for p in pars if anchor in p.text or anchor.replace('R2', 'R²') in p.text]
        if not hits:
            hits = [p for p in pars if anchor.replace('(R2 = 0.934)', '(R2 = 0.934)') in ''.join(c for c in p.text)]
        if cnt == 'named':
            if 'BLIND' in dst: continue
            cnt = 1
        if not hits: raise SystemExit(f'{dst}: anchor not found: {anchor}')
        if cnt == 1 and len(hits) != 1: raise SystemExit(f'{dst}: anchor not unique ({len(hits)}): {anchor}')
        for p in (hits if cnt is None else hits[:1]):
            replace_in(p, old, new, keep_format=True); n += 1
    d.save(dst); print('saved', dst, 'edits', n)
