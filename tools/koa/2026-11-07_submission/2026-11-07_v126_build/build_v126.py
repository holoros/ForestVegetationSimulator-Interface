"""koa v126, 2026-11-07: stress-test fixes on v125 (main text only; supplement v117 and deposit 1.12.0 untouched).
Each edit is a verified finding from reviews/2026-11-07_koa-v125_STRESS-TEST_REVIEW.md."""
import sys, docx
sys.path.insert(0, '.')
from docedit import set_par, find_par, iter_all_pars, replace_in
ABS = open('abstract_v126.txt', encoding='utf-8').read().strip()
ABS = ABS.replace('Acacia koa A. Gray', '*Acacia koa* A. Gray').replace('m³ ha⁻¹', '{m3ha}').replace('Mg C ha⁻¹', '{MgCha}')
EDITS = [  # (anchor text in paragraph, old, new)
 ('Koa diameter growth was more sensitive to relative competition', 'rose with crown ratio and with BYI.', 'rose with BYI.'),
 ('scales it to the koa self-thinning limit', 'scales it to the koa self-thinning limit (Section 2.4.2)', 'scales it to a koa maximum density line, the 95th percentile of the plot data (Section 2.4.2)'),
 ('Competition is BAL (m', 'Competition is BAL (', 'Competition is basal area in larger trees (BAL, '),
 ('fitted to the 360 FIA crown records', 'fitted to the 360 FIA crown records (Table S9)', 'kept from an earlier fit to 359 FIA crown records and scored on 360 (Table S9)'),
 ('is weak and its sign unstable across refits', ' and its sign unstable across refits', ''),
 ('passed a selection rule fixed before fitting, with its squared term dropped', 'the candidate that passed a selection rule fixed before fitting', 'the candidate that passed the competition-form screen (Section S3.7)'),
 ('ΔAIC +37.8 against the BAL form', '(ΔAIC +37.8 against the BAL form)', '(change in Akaike information criterion, ΔAIC, +37.8 against the BAL form)'),
 ('where elevation was recorded', 'where elevation was recorded (Table S34)', 'where elevation was recorded (Table S34 for rainfall and temperature)'),
 ('so BYI is an extrapolation of current biomass', 'extrapolation of current biomass (Section 4.2)', 'extrapolation of current biomass (Section S2.2)'),
 ('returns an RMSE of 2.36 m on the 360 crown records', 'on the 360 crown records (Table S9)', 'on the 360 crown records (Section S3.1)'),
 ('predicted from competition and slenderness, raised diameter growth', 'raised diameter growth (b5 = 0.537)', 'was positively associated with diameter growth (b~5~ = 0.537, bootstrap interval −0.354 to 1.62; Table S13)'),
 ('the self-thinning response expected of crowded stands', 'the self-thinning response expected of crowded stands', 'consistent with self-thinning in crowded stands'),
 ('intervals that include zero (Table S21)', 'intervals that include zero (Table S21)', 'intervals that include zero (Section S4.1)'),
 ('of total aboveground biomass reported for 10-year-old koa stands', 'of total aboveground biomass reported', 'of koa wood biomass increment reported'),
 ('three plantations aged 18 to 27 years', 'aged 18 to 27 years', 'aged 18 to 28 years'),
 ('Both lie below the 230 cm that koa reach', 'Both lie below the 230 cm that koa reach', 'Both lie far below the 363 cm of the largest koa on record (Whitesell, 1990)'),
 ('expansion-weighted mean height of the 40 largest-diameter trees', '(Table S20).', '(Table S20). N is stems ha^−1^, and a and k~HD~ are given in Table S20.'),
 ('Koa productivity follows water and substrate', 'Koa productivity follows water and substrate, and', 'Mapped productivity tracks water and substrate predictors, which mainly separate forest from nonforest, and'),
 ('narrowed the diameter site interval away from zero', 'and narrowed the diameter site interval away from zero in the site-variable screen (Table S40), consistent with stocking having masked site in the unadjusted index',
  'and raised the lower bound of the diameter site interval from 0.058 to 0.083 in the site-variable screen (Table S40), consistent with stocking having masked part of the site signal in the unadjusted index'),
 ('Long-term trajectory validation of the linked koa system', 'Long-term trajectory validation', 'Long-term trajectory evaluation'),
 ('NLCD Hawaii 2001', '(NLCD Hawaii 2001,', '(National Land Cover Database, NLCD, Hawaii 2001,'),
 ('Software (FVS-HI variant)', 'Software (FVS-HI variant)', 'Software (Forest Vegetation Simulator Hawaii variant, FVS-HI)'),
 ('by up to 5.0 cm in DBH after ten years', 'final equations, by up to 5.0 cm in DBH', 'final equations, and departs by up to 5.0 cm in DBH'),
]
U = '/mnt/user-data/outputs/2026-11/koa_v125/'
for src, dst, blind in [(U + 'koa_manuscript_v125_FINAL.docx', 'koa_manuscript_v126_FINAL.docx', False),
                        (U + 'koa_manuscript_v125_FINAL_BLIND.docx', 'koa_manuscript_v126_FINAL_BLIND.docx', True)]:
    d = docx.Document(src); pars = list(iter_all_pars(d))
    set_par(find_par(pars, 'Acacia koa A. Gray (koa), a nitrogen-fixing tree found only', startswith=True), ABS)
    done = 0
    for anchor, old, new in EDITS:
        try:
            p = find_par(pars, anchor)
        except Exception as e:
            if blind and anchor.startswith('Software'):
                print('  blind: no author contributions, skipped'); continue
            raise SystemExit(f'{dst}: anchor not found: {anchor} ({e})')
        replace_in(p, old, new, keep_format=True); done += 1
    d.save(dst); print('saved', dst, 'edits', done)
