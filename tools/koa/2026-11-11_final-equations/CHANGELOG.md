# Changelog

## Next version (draft of November 13, 2026; not uploaded, not published)

Changes are from version 1.13.0. The equations and coefficients are unchanged.

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
