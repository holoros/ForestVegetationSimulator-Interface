# Changelog

## 1.14.2 (November 20, 2026)

Changes are from version 1.14.1. Crown base E3c, HCB = HT / (1 + exp(b0 + lH ln HT + x (BAL/BA) RD)), fitted a longer crown with more competition. Two sets of alternatives were tested on the same 360 US Forest Service FIA koa trees (Cardinal jobs 16999243 and 17000073): 17 crown ratio forms (script 59) and 15 forms fitted directly to crown base as a height (script 60), with koa-only and all-species basal area, BAL, relative BAL, relative height, DBH/HT, BYI, rainfall and elevation. Every competition and density term fitted the unexpected way, and with the expected sign it sat at zero. E3d replaces E3c: HCB = min(exp(b0 + lH ln HT), 0.98 HT), b0 = -1.4985 (95% interval -2.900 to -0.306) and lH = 1.0781 (0.648 to 1.551), plot-cluster bootstrap with 2,000 resamples. Held-out RMSE is 2.77 m against 2.26 m for E3c; the change is post hoc and disclosed. Nothing else in the system uses crown base, so basal area, stems, QMD, SDI, RD, height, the benchmark and the gates are unchanged. The fitting frame (rebuilt from HI_TREE.csv; md5 093c759addd9e713ee42b98fd6524266) carries plot identifiers and is not deposited.

## Presentation pass (November 18, 2026; version 1.14.1 unchanged)

No equation, coefficient, table value or scenario changed, and no new deposit version was made. Figures 3 to 5 and S4 were redrawn from the saved fits and scenarios (scripts 57a, 57b, 57c and mk57.py): relative density axes stop at 1.0, axis titles and panel tags no longer overlap, and Fig. 5 marks the end of the benchmark record with a dashed line in place of shading. Manuscript v137 and supplement v129 carry these figures, and their tables may break across pages. Script 58 is a sensitivity run that holds relative density at or below 1.0 by a set rule; it is not deployed (planted basal area at 40 years 2 to 8% lower, benchmark unchanged, yield-density gate fails; see notes/2026-11-18_koa-rd-cap-sensitivity_REVIEW.md).

## 1.14.1 (November 15, 2026)

Changes are from version 1.14.0. The height curve (E2) and the height increment equation (E5) are now fitted jointly and share one asymptote that depends on BYI (form J1 of a fourth round of height increment forms); E2 loses its own asymptote coefficient and takes BYI as an argument, and the fallback rule uses the joint curve. A two-stage ingrowth rate with koa QMD is added for natural stands as a scenario assumption. S1, E3c, E4r and E6r are unchanged. Planted scenarios are unchanged in basal area, stems, QMD, SDI and RD, and so are the benchmark and the gates; height and assumed volume changed, and the natural scenarios changed through ingrowth. New scripts 42 to 56 with logs, the rules note with sections 7 to 13, and outputs without plot identifiers. `koa_step_rdbyi.R`: `koa_height(dbh, byi, cf)`, `koa_asymptote()`, `koa_ingrowth()`, and `koa_project(..., ingrowth = FALSE)`.

## 1.14.0 (November 14, 2026)

Changes are from version 1.13.1. Height increment (E5) changed from the rule E2(D + dD) - E2(D) to a fitted equation, with the rule kept as the fallback; crown base equation E3c added; stand-level mortality forms compared and not adopted; height to diameter ratio and crown ratio reported for the 200-year runs. E2, S1, E4r and E6r are unchanged, and so are basal area, stems, QMD, SDI, the benchmark and the gates; height and assumed volume changed. New scripts 32 to 41 with logs, the rules note, and outputs without plot identifiers. `koa_step_rdbyi.R` gains `koa_dht()`, `koa_hcb()` and the argument `height`; `koa_rdbyi_equations.csv` gains the rows of E3c and E5.

## 1.13.1 (November 13, 2026)

Status: draft on Zenodo, version DOI 10.5281/zenodo.24203239 reserved. Changes are from version 1.13.0. The equations and coefficients are unchanged. GitHub: pull request 21, commit 6c1aa6e90f78d48a9ad7a15642d5a8a2a0989bae.

Added: scripts and logs 26, 26b, 27, 28_common, 28a, 28b, 29 and 29b; `out/check28_benchmark_heldout.csv`, `out/check28_deathrules_scenarios.csv`, `out/check29_benchmark_after_thinning.csv`; the inputs the scripts read (`frames/frames.rds`, `frames/mf_confirmed.rds`, `release/koa_step.R`, `release/koa_final_equations.csv`, the plot SDImax table, `out/sdimax_byi.rds`, `out/rdbyi2_fits.rds`, `out/rdbyi2_boot.rds`, `out/E2_height_cr3.rds`). Replaced: `koa_supplemental.pdf`, now supplement v125 (Tables S27 to S31 and corrections to Table S1, Sections S2.1, S3.1, S3.2, S3.4, S3.5, S5 and S7 and Tables S14, S24 and S26).

Corrected in the documents: the difference between 6.74 and 6.76 m² ha⁻¹ is the fold partition, not the fitting start; the direct quantile model coefficient is 0.51 (bootstrap median 0.54); the thinning table is in `data_20260916.zip`; the licence is CC BY 4.0; the manuscript is v133.

Still to be confirmed with the data provider: that thinned stems are recorded as dead in the permanent sample plot database and that the removal years are complete.

## 1.13.0 (November 11, 2026)

Status: published November 11, 2026, DOI 10.5281/zenodo.24116922. Changes are from version 1.12.2 (November 7, 2026).

### Why the earlier engine was replaced

An audit of the deposited v105final engine on November 10, 2026 found that the model it runs differs from the model its documentation describes. On the deployed path the audit counted 85 numeric constants and 4 rules. Of the 85, 38 are fitted, 4 come from the literature, 9 are calibrated and 34 are hand set, so 47 of the 85 are not fitted; 13 of those 47 were shown or judged material. Mortality Stage 1, the Stage 3 tree equation and the natural-stand mortality level factor are defined in the code and never applied. One mortality function is never called anywhere in the folder. The mortality step that runs is a self-thinning step with hand-set floors, and diameter and height increment are scaled by solved origin multipliers.

### What was done, in order

A first refit on November 10, 2026 applied four fitted equations with no multiplier, floor or cap. It failed in the long run: on the real starting lists it failed the basal area bound, the level gate and the Sukachev relation.

A relative-density framework followed the same day. Competition in the diameter increment equation became (BAL / BA) × RD, and mortality gained a DBH² term and ln(RD), where RD is the stand density index of live koa over a maximum (SDImax). It was applied to a new stand with a single SDImax of 742.

On November 11, 2026 SDImax was modeled from BYI and origin (S1), and the increment and mortality equations were refitted with the SDImax they are applied with. The rule written before the test did not prefer this form. The author adopted S1 for consistency between fitting and use.

Later that day a defect was found in the November 10 frames. The plantation permanent sample plot (PSP) database records thinned stems as dead, and the frames did not censor removal intervals, so every fit and benchmark until then counted thinning removals as deaths: 756 of 7,478 mortality tree-intervals and 324 of 1,169 deaths. Intervals that end in or span a removal year are now censored (6,722 tree-intervals and 845 deaths remain), and benchmark horizons stop before the first removal year (53 plots and 182 plot-horizons remain). S1, the height equation and the diameter increment equation are unchanged. Mortality, benchmark, gates, projections and coverage changed. Under the correction the rule still does not prefer S1 (benchmark basal area RMSE 6.74 m² ha⁻¹ against 6.60 for 742), and the Sukachev gate fails.

### Files

Added, all inside `final_equations_20261111.zip`: `koa_step_rdbyi.R`, `koa_rdbyi_equations.csv`, scripts and logs 20, 21, 22t, 23t, 24b and 25, `utils.R`, `out/`, `workbook/`, Figs. 3 to 5 and four documentation files. Replaced: `koa_supplemental.pdf`, now supplement v124. Superseded and not published: the November 10 refit, the single-SDImax release and the uncensored build of this system. The v105final engine and its outputs remain in the record as deposited.
