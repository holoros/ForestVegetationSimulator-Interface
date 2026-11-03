# RESULTS v105final: koa growth and yield engine (koa_v105final_20261103)

Engine: dDBH K3c1 and dHT K3c1h refitted with RD = SDI/741.996871565 (brms RI_LONG population SDImax at QMD 25.4 cm, posterior median; 95% 679.96 to 807.39),
mortality Stage 3 M3a refitted under the same divisor, total height Eq. 2 and HCB Eq. 3 at the v105c forms, natural mortality level re-solved (MORT_CAL 2.43532).
Selection: FINAL_ENGINE.md (koa_v105attr_20261103 attribution; rule reading declared there). Columns: v105b = koa_v105_20261102, v105c = koa_v105c_20261102,
v105d = koa_v105d_20261102 (all read only), v105final = this job. Every value is read from the file named in final/out/compare_final_long.csv. Site levels
Low/Medium/High = BYI 142/303/418 (10th/50th/90th percentiles). v105b coverage was never computed (blank).

## Gates

- Increment bootstraps (400 installation-cluster resamples, full refit): dDBH K3c1 400 of 400 converged, dHT K3c1h 400 of 400; dHT vector-fixed re-solve 400 ok.
  CAL_SE_LOG dDBH 0.2012 / 0.0913, dHT 0.1287 / 0.0745 (full refit 0.579 / 0.511), out/v105_constants.json.
- Joint draws (chain 1 and paired MC): vectors vs constants json <= 3.1e-15; engine CAL gate 4.8e-6; Stage 1 reproduction PASS.
- Registry gate 21 of 21 (registry s02 = the v105c Eq. 2 files). Paired-MC gate PASS (both). Literal grep: LITERALS PASS, 0 code hits (logs/check_literals.log).
- LOIO: all 14 fold refits ok (rows dropped 18 to 427 per fold, distinct vectors; a5/loio/logs/fit_g*.log), 0 failed chains; V105EXACT gate max 0 (PASS),
  NONE (full-frame refit) max 9.92e-4 < 1e-3 (PASS; v105d 1.197e-3 FLAG).
- Figures: Fig. 3 increment curves evaluated with the deployed K3c1 / K3c1h forms (script stops otherwise) at RD = SDI/741.997; height panels and Fig. S1 use the
  v105c Eq. 2 and HCB forms (final/patch_figs_final.py).

## Regressions and notes

- Plot-level validation returns to the v105c level: BA RMSE (all 17) 13.258 vs v105d 12.659 (v105c 13.265); QMD RMSE 2.779 vs 2.225 (v105c 2.814). The v105d
  improvement came from C2h HCB, which the realism rule reverted.
- Paired MC BOOT planted high>med 0.889 (WEAK; v105d 0.926 SUPPORTED, v105c 0.891 WEAK).
- dHT of suppressed trees still rises with stand density at fixed share in 22,951 of 25,200 evaluations (max derivative 0.144; v105c 24,925, max 0.74).
- Uneven-aged natural Eichhorn median 9.2% and even-aged planted Eichhorn max CV 45.6% (median 8.2%, PASS) are within the rule but worth watching.
- Increment frames keep the HCB_P crown ratio, which is now also the projected HCB form (the v105d declared inconsistency is removed).
- HiGy.R (FVS-HI mirror) not updated (Python engine of record).

## Volume (m3/ha) and QMD (cm) at 40 yr, 500-replicate MC median (95%)

| metric | v105b | v105c | v105d | v105final |
|---|---|---|---|---|
| QMD40 | Even-aged natural | High (418) | 37.2 (30.8 to 48.7) | 37.2 (31.2 to 46.9) | 37.8 (31.6 to 47.4) | 37.4 (31.2 to 47.0) |
| QMD40 | Even-aged natural | Low (142) | 30.5 (25.5 to 40.2) | 31.0 (25.8 to 39.8) | 30.3 (25.7 to 38.8) | 31.1 (25.8 to 40.1) |
| QMD40 | Even-aged natural | Medium (303) | 35.1 (29.4 to 44.7) | 35.3 (29.6 to 44.2) | 35.5 (30.0 to 44.1) | 35.4 (29.6 to 44.3) |
| QMD40 | Even-aged planted | High (418) | 45.1 (38.6 to 52.9) | 46.1 (39.0 to 55.0) | 47.1 (39.9 to 55.5) | 47.0 (39.6 to 55.6) |
| QMD40 | Even-aged planted | Low (142) | 39.0 (33.3 to 46.2) | 39.8 (33.6 to 47.5) | 39.6 (33.8 to 47.1) | 40.5 (34.1 to 48.6) |
| QMD40 | Even-aged planted | Medium (303) | 43.2 (37.1 to 51.2) | 44.1 (37.5 to 53.1) | 44.8 (38.3 to 53.7) | 45.0 (38.2 to 54.1) |
| VOL40 | Even-aged natural | High (418) | 184.1 (77.8 to 275.0) | 177.7 (72.3 to 265.6) | 183.9 (77.0 to 264.9) | 183.2 (77.1 to 270.3) |
| VOL40 | Even-aged natural | Low (142) | 128.2 (53.3 to 188.2) | 127.4 (50.3 to 187.1) | 123.0 (53.3 to 173.2) | 130.5 (53.1 to 189.0) |
| VOL40 | Even-aged natural | Medium (303) | 164.9 (62.5 to 243.7) | 160.3 (58.4 to 240.3) | 163.0 (63.6 to 233.1) | 165.0 (63.5 to 243.6) |
| VOL40 | Even-aged planted | High (418) | 483.7 (319.8 to 578.1) | 484.4 (317.7 to 583.2) | 470.1 (313.1 to 558.8) | 490.7 (320.0 to 592.1) |
| VOL40 | Even-aged planted | Low (142) | 381.6 (268.4 to 467.5) | 383.5 (265.1 to 478.1) | 359.6 (252.6 to 433.3) | 389.2 (268.6 to 486.4) |
| VOL40 | Even-aged planted | Medium (303) | 447.2 (283.4 to 540.0) | 448.3 (283.3 to 554.2) | 430.6 (281.4 to 514.7) | 454.4 (285.5 to 561.3) |

## MAI culmination age (yr): point (window 10-100); MC median (95%)

| metric | v105b | v105c | v105d | v105final |
|---|---|---|---|---|
| culmination | Even-aged natural|High (418) | 18; 16 (10 to 30) | 16; 14 (10 to 28) | 13; 12 (10 to 25) | 17; 16 (10 to 29) |
| culmination | Even-aged natural|Low (142) | 25; 20 (10 to 40) | 21; 16 (10 to 36) | 10; 10 (10 to 34) | 23; 19 (10 to 38) |
| culmination | Even-aged natural|Medium (303) | 19; 18 (10 to 34) | 17; 16 (10 to 31) | 14; 12 (10 to 28) | 19; 17 (10 to 33) |
| culmination | Even-aged planted|High (418) | 10; 10 (10 to 10) | 10; 10 (10 to 10) | 10; 10 (10 to 10) | 10; 10 (10 to 10) |
| culmination | Even-aged planted|Low (142) | 10; 10 (10 to 13) | 10; 10 (10 to 13) | 10; 10 (10 to 12) | 10; 10 (10 to 14) |
| culmination | Even-aged planted|Medium (303) | 10; 10 (10 to 10) | 10; 10 (10 to 11) | 10; 10 (10 to 10) | 10; 10 (10 to 11) |
| culmination | Uneven-aged natural|High (418) | 17; 18 (13 to 57) | 19; 20 (13 to 63) | 19; 19 (13 to 46) | 20; 20 (14 to 54) |
| culmination | Uneven-aged natural|Low (142) | 25; 27 (18 to 71) | 28; 30 (18 to 75) | 29; 31 (19 to 61) | 28; 30 (19 to 72) |
| culmination | Uneven-aged natural|Medium (303) | 19; 20 (14 to 60) | 21; 22 (15 to 56) | 21; 22 (14 to 46) | 22; 22 (15 to 57) |

## Validation, predicted minus observed (bias / RMSE)

| metric | v105b | v105c | v105d | v105final |
|---|---|---|---|---|
| plot-level BA bias / RMSE | DOFAW (n 7) | 5.074 / 14.774 | 5.132 / 15.120 | 5.592 / 14.447 | 5.726 / 15.200 |
| plot-level BA bias / RMSE | PSP (n 10) | -5.526 / 11.603 | -5.937 / 11.794 | -4.822 / 11.239 | -5.848 / 11.708 |
| plot-level BA bias / RMSE | all (n 17) | -1.161 / 13.003 | -1.379 / 13.265 | -0.534 / 12.659 | -1.082 / 13.258 |
| plot-level QMD bias / RMSE | DOFAW (n 7) | -0.583 / 2.359 | -0.127 / 2.484 | -0.161 / 1.599 | 0.205 / 2.454 |
| plot-level QMD bias / RMSE | PSP (n 10) | -1.793 / 2.877 | -2.004 / 3.023 | -1.366 / 2.574 | -1.961 / 2.986 |
| plot-level QMD bias / RMSE | all (n 17) | -1.295 / 2.676 | -1.231 / 2.814 | -0.870 / 2.225 | -1.069 / 2.779 |
| plot-level survW bias / RMSE | DOFAW (n 7) | 0.099 / 0.151 | 0.091 / 0.142 | 0.100 / 0.157 | 0.092 / 0.142 |
| plot-level survW bias / RMSE | PSP (n 10) | 0.007 / 0.150 | 0.011 / 0.149 | -0.001 / 0.152 | 0.010 / 0.149 |
| plot-level survW bias / RMSE | all (n 17) | 0.045 / 0.150 | 0.044 / 0.146 | 0.041 / 0.154 | 0.044 / 0.146 |
| trajectory BA bias / RMSE | DOFAW (n 25) | 5.510 / 13.103 | 5.652 / 13.493 | 5.849 / 12.503 | 6.224 / 13.589 |
| trajectory BA bias / RMSE | PSP (n 60) | -5.207 / 9.376 | -5.500 / 9.625 | -4.279 / 8.839 | -5.455 / 9.572 |
| trajectory BA bias / RMSE | all (n 85) | -2.055 / 10.609 | -2.220 / 10.906 | -1.300 / 10.056 | -2.020 / 10.908 |
| trajectory QMD bias / RMSE | DOFAW (n 25) | 0.571 / 3.484 | 0.900 / 3.691 | 0.714 / 2.851 | 1.159 / 3.729 |
| trajectory QMD bias / RMSE | PSP (n 60) | -2.166 / 2.984 | -2.334 / 3.144 | -1.596 / 2.547 | -2.310 / 3.119 |
| trajectory QMD bias / RMSE | all (n 85) | -1.321 / 3.147 | -1.336 / 3.322 | -0.883 / 2.645 | -1.240 / 3.319 |

## Coverage of 95% MC intervals (plot level, 500 joint draws)

| metric | v105b | v105c | v105d | v105final |
|---|---|---|---|---|
| coverage plotlevel BA | natural |  | 0.833 | 0.833 | 0.833 |
| coverage plotlevel BA | planted |  | 0.636 | 0.545 | 0.636 |
| coverage plotlevel BA | pooled |  | 0.706 | 0.647 | 0.706 |
| coverage plotlevel QMD | natural |  | 1.000 | 1.000 | 1.000 |
| coverage plotlevel QMD | planted |  | 0.818 | 0.818 | 0.818 |
| coverage plotlevel QMD | pooled |  | 0.882 | 0.882 | 0.882 |
| coverage plotlevel survival_count | natural |  | 1.000 | 1.000 | 1.000 |
| coverage plotlevel survival_count | planted |  | 0.636 | 0.636 | 0.636 |
| coverage plotlevel survival_count | pooled |  | 0.765 | 0.765 | 0.765 |
| coverage plotlevel survival_w | natural |  | 1.000 | 1.000 | 1.000 |
| coverage plotlevel survival_w | planted |  | 0.636 | 0.636 | 0.636 |
| coverage plotlevel survival_w | pooled |  | 0.765 | 0.765 | 0.765 |

## LOIO held-out verdicts and gates

| metric | v105b | v105c | v105d | v105final |
|---|---|---|---|---|
| LOIO gate NONE max abs diff | 0.000333054 (PASS) | 1.17357 (FLAG) | 0.00119703 (FLAG) | 0.000992482 (PASS) |
| LOIO gate V105EXACT max abs diff | 0 (PASS) | 1.17331 (FLAG) | 0 (PASS) | 0 (PASS) |
| LOIO | all | BA_m2ha | SUPPORTS; bias -1.0437 (90% -6.4224 to 2.9497) | SUPPORTS; bias -1.0437 (90% -6.4224 to 2.9497) | SUPPORTS; bias -0.4086 (90% -5.7210 to 3.5512) | SUPPORTS; bias -0.9626 (90% -6.5148 to 3.1642) |
| LOIO | all | QMD_cm | SUPPORTS; bias -1.1573 (90% -2.2795 to -0.0796) | SUPPORTS; bias -1.1573 (90% -2.2795 to -0.0796) | SUPPORTS; bias -0.6960 (90% -1.7260 to 0.2307) | SUPPORTS; bias -0.8797 (90% -2.1784 to 0.3404) |
| LOIO | all | survival | SUPPORTS; bias 0.0445 (90% -0.0202 to 0.0957) | SUPPORTS; bias 0.0445 (90% -0.0202 to 0.0957) | SUPPORTS; bias 0.0389 (90% -0.0270 to 0.0907) | SUPPORTS; bias 0.0423 (90% -0.0193 to 0.0922) |
| LOIO | natural | BA_m2ha | INCONCLUSIVE; bias 0.5951 (90% -11.1592 to 6.7043) | INCONCLUSIVE; bias 0.5951 (90% -11.1592 to 6.7043) | INCONCLUSIVE; bias 1.4997 (90% -10.0464 to 7.4894) | INCONCLUSIVE; bias 1.2510 (90% -10.2966 to 7.3113) |
| LOIO | natural | QMD_cm | SUPPORTS; bias -1.5052 (90% -2.3331 to -1.0763) | SUPPORTS; bias -1.5052 (90% -2.3331 to -1.0763) | SUPPORTS; bias -0.5681 (90% -1.1205 to -0.2747) | SUPPORTS; bias -0.6042 (90% -1.1949 to -0.2890) |
| LOIO | natural | survival | INCONCLUSIVE; bias 0.0706 (90% -0.0261 to 0.1211) | INCONCLUSIVE; bias 0.0706 (90% -0.0261 to 0.1211) | INCONCLUSIVE; bias 0.0632 (90% -0.0304 to 0.1130) | INCONCLUSIVE; bias 0.0618 (90% -0.0306 to 0.1104) |
| LOIO | planted | BA_m2ha | INCONCLUSIVE; bias -1.9377 (90% -9.3729 to 6.0747) | INCONCLUSIVE; bias -1.9377 (90% -9.3729 to 6.0747) | INCONCLUSIVE; bias -1.4496 (90% -8.6904 to 6.2005) | INCONCLUSIVE; bias -2.1700 (90% -9.6731 to 5.9677) |
| LOIO | planted | QMD_cm | SUPPORTS; bias -0.9675 (90% -2.6202 to 0.8910) | SUPPORTS; bias -0.9675 (90% -2.6202 to 0.8910) | SUPPORTS; bias -0.7657 (90% -2.2232 to 0.7303) | SUPPORTS; bias -1.0299 (90% -2.7938 to 1.0026) |
| LOIO | planted | survival | SUPPORTS; bias 0.0302 (90% -0.0445 to 0.1075) | SUPPORTS; bias 0.0302 (90% -0.0445 to 0.1075) | SUPPORTS; bias 0.0257 (90% -0.0527 to 0.1084) | SUPPORTS; bias 0.0316 (90% -0.0409 to 0.1073) |

## Paired Monte Carlo probabilities, 40-yr volume

| metric | v105b | v105c | v105d | v105final |
|---|---|---|---|---|
| pairmc 40yr | B | natural | high>low | 0.989 (SUPPORTED) | 0.989 (SUPPORTED) | 0.989 (SUPPORTED) | 0.989 (SUPPORTED) |
| pairmc 40yr | B | natural | high>med | 0.743 (WEAK) | 0.743 (WEAK) | 0.743 (WEAK) | 0.743 (WEAK) |
| pairmc 40yr | B | natural | med>low | 0.931 (SUPPORTED) | 0.931 (SUPPORTED) | 0.931 (SUPPORTED) | 0.931 (SUPPORTED) |
| pairmc 40yr | B | planted | high>low | 0.991 (SUPPORTED) | 0.991 (SUPPORTED) | 0.991 (SUPPORTED) | 0.991 (SUPPORTED) |
| pairmc 40yr | B | planted | high>med | 0.742 (WEAK) | 0.742 (WEAK) | 0.742 (WEAK) | 0.742 (WEAK) |
| pairmc 40yr | B | planted | med>low | 0.945 (SUPPORTED) | 0.945 (SUPPORTED) | 0.945 (SUPPORTED) | 0.945 (SUPPORTED) |
| pairmc 40yr | BOOT | natural | high>low | 0.985 (SUPPORTED) | 0.979 (SUPPORTED) | 0.996 (SUPPORTED) | 0.980 (SUPPORTED) |
| pairmc 40yr | BOOT | natural | high>med | 0.953 (SUPPORTED) | 0.936 (SUPPORTED) | 0.975 (SUPPORTED) | 0.940 (SUPPORTED) |
| pairmc 40yr | BOOT | natural | med>low | 0.995 (SUPPORTED) | 0.994 (SUPPORTED) | 0.998 (SUPPORTED) | 0.994 (SUPPORTED) |
| pairmc 40yr | BOOT | planted | high>low | 0.932 (SUPPORTED) | 0.934 (SUPPORTED) | 0.967 (SUPPORTED) | 0.935 (SUPPORTED) |
| pairmc 40yr | BOOT | planted | high>med | 0.885 (WEAK) | 0.891 (WEAK) | 0.926 (SUPPORTED) | 0.889 (WEAK) |
| pairmc 40yr | BOOT | planted | med>low | 0.956 (SUPPORTED) | 0.955 (SUPPORTED) | 0.984 (SUPPORTED) | 0.955 (SUPPORTED) |
| pairmc 40yr | BOOT_PPB | natural | high>low | 0.638 (WEAK) | 0.627 (WEAK) | 0.671 (WEAK) | 0.626 (WEAK) |
| pairmc 40yr | BOOT_PPB | natural | high>med | 0.535 (WEAK) | 0.529 (WEAK) | 0.545 (WEAK) | 0.529 (WEAK) |
| pairmc 40yr | BOOT_PPB | natural | med>low | 0.611 (WEAK) | 0.602 (WEAK) | 0.619 (WEAK) | 0.603 (WEAK) |
| pairmc 40yr | BOOT_PPB | planted | high>low | 0.659 (WEAK) | 0.653 (WEAK) | 0.690 (WEAK) | 0.657 (WEAK) |
| pairmc 40yr | BOOT_PPB | planted | high>med | 0.532 (WEAK) | 0.521 (WEAK) | 0.542 (WEAK) | 0.522 (WEAK) |
| pairmc 40yr | BOOT_PPB | planted | med>low | 0.630 (WEAK) | 0.613 (WEAK) | 0.655 (WEAK) | 0.613 (WEAK) |
| pairmc 40yr | P | natural | high>low | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) |
| pairmc 40yr | P | natural | high>med | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) |
| pairmc 40yr | P | natural | med>low | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) |
| pairmc 40yr | P | planted | high>low | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) |
| pairmc 40yr | P | planted | high>med | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) |
| pairmc 40yr | P | planted | med>low | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) | 1.000 (SUPPORTED) |
| pairmc 40yr | PP | natural | high>low | 0.690 (WEAK) | 0.674 (WEAK) | 0.707 (WEAK) | 0.674 (WEAK) |
| pairmc 40yr | PP | natural | high>med | 0.552 (WEAK) | 0.549 (WEAK) | 0.561 (WEAK) | 0.550 (WEAK) |
| pairmc 40yr | PP | natural | med>low | 0.619 (WEAK) | 0.609 (WEAK) | 0.631 (WEAK) | 0.608 (WEAK) |
| pairmc 40yr | PP | planted | high>low | 0.747 (WEAK) | 0.723 (WEAK) | 0.761 (WEAK) | 0.725 (WEAK) |
| pairmc 40yr | PP | planted | high>med | 0.572 (WEAK) | 0.566 (WEAK) | 0.591 (WEAK) | 0.574 (WEAK) |
| pairmc 40yr | PP | planted | med>low | 0.660 (WEAK) | 0.655 (WEAK) | 0.684 (WEAK) | 0.656 (WEAK) |
| pairmc 40yr | PPB | natural | high>low | 0.660 (WEAK) | 0.642 (WEAK) | 0.679 (WEAK) | 0.642 (WEAK) |
| pairmc 40yr | PPB | natural | high>med | 0.544 (WEAK) | 0.547 (WEAK) | 0.555 (WEAK) | 0.546 (WEAK) |
| pairmc 40yr | PPB | natural | med>low | 0.615 (WEAK) | 0.602 (WEAK) | 0.627 (WEAK) | 0.604 (WEAK) |
| pairmc 40yr | PPB | planted | high>low | 0.697 (WEAK) | 0.690 (WEAK) | 0.718 (WEAK) | 0.691 (WEAK) |
| pairmc 40yr | PPB | planted | high>med | 0.554 (WEAK) | 0.548 (WEAK) | 0.557 (WEAK) | 0.549 (WEAK) |
| pairmc 40yr | PPB | planted | med>low | 0.652 (WEAK) | 0.640 (WEAK) | 0.668 (WEAK) | 0.641 (WEAK) |

## Bakuzis (step aware), mortality level, CAL SE, realism

| metric | v105b | v105c | v105d | v105final |
|---|---|---|---|---|
| Bakuzis PASS / FLAG / info / NOT EVALUATED | 100 / 29 / 9 / 3 | 96 / 33 / 9 / 3 | 94 / 35 / 9 / 3 | 96 / 33 / 9 / 3 |
| Bakuzis Reineke step | 1 | 1 | 1 | 1 |
| CAL_SE_LOG DDBH (nat, plt) | 0.1965, 0.0760 | 0.2105, 0.0915 | 0.2105, 0.0915 | 0.2012, 0.0913 |
| CAL_SE_LOG DHT (nat, plt) | 0.1284, 0.0720 | 0.1284, 0.0720 | 0.1286, 0.0745 | 0.1287, 0.0745 |
| Eichhorn | Even-aged natural | median 7.9%, max 11.9% PASS | median 8.5%, max 30.7% PASS | median 11.4%, max 32.4% FLAG | median 8.7%, max 28.2% PASS |
| Eichhorn | Even-aged planted | median 7.7%, max 34.6% PASS | median 8.2%, max 32.1% PASS | median 9.4%, max 17.6% PASS | median 8.2%, max 45.6% PASS |
| Eichhorn | Uneven-aged natural | median 9.3%, max 12.7% PASS | median 9.4%, max 12.9% PASS | median 12.6%, max 16.5% FLAG | median 9.2%, max 12.9% PASS |
| MORT_CAL natural | 2.51767 | 2.55705 | 2.39002 | 2.43532 |
| realism suppressed positive | ddbh_d_density | 0 of 25200 (max -0.0639) | 0 of 25200 (max -0.0594) | 0 of 25200 (max -0.0658) | 0 of 25200 (max -0.0616) |
| realism suppressed positive | ddbh_d_share | 0 of 25200 (max -0.0407) | 0 of 25200 (max -0.0544) | 0 of 25200 (max -0.0601) | 0 of 25200 (max -0.0556) |
| realism suppressed positive | dht_d_density | 24934 of 25200 (max 0.738) | 24925 of 25200 (max 0.74) | 21777 of 25200 (max 0.135) | 22951 of 25200 (max 0.144) |
| realism suppressed positive | dht_d_share | 0 of 25200 (max 0) | 0 of 25200 (max 0) | 0 of 25200 (max 0) | 0 of 25200 (max 0) |

