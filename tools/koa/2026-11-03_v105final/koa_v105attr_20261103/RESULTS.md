# RESULTS: koa v105d component attribution under the brms SDImax of record (koa_v105attr_20261103)

## Verdicts (preregistered rule, PREREG.md; values in the tables below, rule applied by scripts/attribute.py -> out/attribution.csv)

All four v105d realism failures are reproduced in D742 (v105d forms refitted under SDImax 742.0): low-site natural MAI culmination at the 10-yr floor,
Eichhorn flags in even-aged natural (11.35%) and uneven-aged natural (12.63%), Bakuzis 94/35 (C742 96/33), pooled plot-level BA coverage 0.647 (C742 0.706).
Rescaling RD from 923 to 742 changes none of the v105d or v105c realism outcomes (compare D742 with v105d@923 and C742 with v105c@923).

| failure | identified cause(s) (single revert removes it) | notes |
|---|---|---|
| low-site natural culmination at 10-yr floor | total height Eq. 2 (H1a) and HCB Eq. 3 (C2h) | R_HT 22 yr, R_HCB 21 yr (C742 21); dHT and Stage 3 reverts leave it at 10 |
| Eichhorn even-aged natural | total height Eq. 2 (H1a) | R_HT 8.82% (C742 8.53%); other reverts 11.12 to 11.35% |
| Eichhorn uneven-aged natural | total height Eq. 2 (H1a) | R_HT 9.98% (narrow margin to the 10% limit; C742 9.42%) |
| Bakuzis flags > C742 | total height Eq. 2 (H1a) | R_HT 96/33 = C742; the two extra D742 flags are the two Eichhorn rows |
| pooled BA coverage 0.647 vs 0.706 | HCB Eq. 3 (C2h) | R_HCB 0.706 (planted BA 0.636 vs 0.545); dHT, Eq. 2 and Stage 3 reverts move it by 0 |

No failure required pairwise reverts under the rule. dHT K3c1h and Stage 3 M3a are not identified as a cause of any failure. Side effect: the HCB revert
alone adds a new flag (Eichhorn even-aged planted 10.06%, Bakuzis 93/36) that disappears when Eq. 2 is also reverted (information run P_HT_HCB: every
failure removed, Eichhorn 8.68 / 9.21 / 8.22%, Bakuzis 96/33, coverage 0.706, low-site culmination 23 yr). Final engine choice: FINAL_ENGINE.md.

Validation trade-off: the two components that cause the realism failures are also the ones that improved validation in v105d. Reverting HCB returns
plot-level BA / QMD RMSE (all 17 units) from 12.605 / 2.171 (D742) to 13.258 / 2.779 (R_HCB, P_HT_HCB; C742 13.259 / 2.808). Reverting Eq. 2 leaves
validation unchanged (projections start from measured heights).

Realism derivatives: suppressed-tree dDBH never rises with density or share in any run (0 of 25,200). Suppressed-tree dHT rises with stand density in
22,360 to 22,951 of 25,200 evaluations in the K3c1h runs vs 24,942 / 24,925 in the v105c-form dHT runs (R_dHT, C742): a pre-existing dHT property,
reduced but not removed by K3c1h. RD reaches 1.16 in projections under the 742 divisor (0.93 under 923).


Population SDImax at QMD 25.4 cm (brms RI_LONG, 12000 posterior draws of exp(b0 + b1 log 25.4)): median 742.00, 95% interval 679.96 to 807.39 (mean 742.42; at posterior means 741.72). RD = SDI / 741.996872 in every run (prep/out/sdimax_pop.csv).

Runs: D742 = v105d all-RD forms refitted under the new divisor; R-x = D742 with component x at its v105c form (MORT_CAL re-solved); C742 = v105c with RD rescaled (dDBH K3c1 refitted). v105d@923 and v105c@923 are the read-only jobs (reference only, not part of the rule). All values from the run's own output files (out/metrics_long.csv lists the file of each value).

## Attribution verdicts (preregistered rule)

| failure | metric | present in D742 | D742 | C742 | removed by single revert | movement toward C742 (D742 distance minus run distance) |
|---|---|---|---|---|---|---|
| low-site natural culmination | culmination pt | Even-aged natural|Low (142) | True | 10.0 | 21.0 | R_HT;R_HCB;P_HT_HCB | R_HCB +11; R_HT +10; P_HT_HCB +9; R_dHT +0; R_S3 +0 |
| Eichhorn Even-aged natural | Eichhorn median CV % unrounded | Even-aged natural | True | 11.3479 | 8.5286 | R_HT;P_HT_HCB | P_HT_HCB +2.67; R_HT +2.53; R_S3 +0.229; R_HCB +0.174; R_dHT -0.0016 |
| Eichhorn Uneven-aged natural | Eichhorn median CV % unrounded | Uneven-aged natural | True | 12.6331 | 9.4197 | R_HT;P_HT_HCB | P_HT_HCB +3; R_HT +2.65; R_HCB +0.895; R_S3 +0.395; R_dHT +0.0479 |
| Eichhorn Even-aged planted | Eichhorn median CV % unrounded | Even-aged planted | False | 9.3368 | 8.1891 | n/a (not present in D742) | P_HT_HCB +1.12; R_HT +0.649; R_dHT +0.0293; R_S3 +0.0167; R_HCB -0.728 |
| Bakuzis flags | Bakuzis FLAG | True | 35.0 | 33.0 | R_HT;P_HT_HCB | R_HT +2; P_HT_HCB +2; R_dHT +0; R_S3 +0; R_HCB -1 |
| pooled BA coverage | coverage plotlevel BA | pooled | True | 0.647 | 0.706 | R_HCB;P_HT_HCB | R_HCB +0.059; P_HT_HCB +0.059; R_dHT +0; R_HT +0; R_S3 +0 |

### Key metrics

| metric | D742 | R_dHT | R_HT | R_HCB | R_S3 | P_HT_HCB | C742 | v105d@923 | v105c@923 |
|---|---|---|---|---|---|---|---|---|---|
| MORT_CAL natural | 2.37588 | 2.37923 | 2.37588 | 2.43532 | 2.49154 | 2.43532 | 2.55412 | 2.39002 | 2.55705 |
| culmination pt | Even-aged natural|Low (142) | 10 | 10 | 22 | 21 | 10 | 23 | 21 | 10 | 21 |
| culmination MC | Even-aged natural|Low (142) | 10 (10 to 35) | 10 (10 to 35) | 10 (10 to 39) | 10 (10 to 35) | 10 (10 to 32) | 19 (10 to 38) | 16 (10 to 36) | 10 (10 to 34) | 16 (10 to 36) |
| Eichhorn median CV % unrounded | Even-aged natural | 11.3479 | 11.3495 | 8.816 | 11.1741 | 11.1191 | 8.6751 | 8.5286 | 11.3695 | 8.5404 |
| Eichhorn median CV % unrounded | Uneven-aged natural | 12.6331 | 12.5852 | 9.9847 | 11.7381 | 12.2384 | 9.2113 | 9.4197 | 12.6281 | 9.3859 |
| Eichhorn median CV % unrounded | Even-aged planted | 9.3368 | 9.3075 | 7.6903 | 10.065 | 9.3201 | 8.2176 | 8.1891 | 9.3536 | 8.1865 |
| Bakuzis PASS | 94 | 94 | 96 | 93 | 94 | 96 | 96 | 94 | 96 |
| Bakuzis FLAG | 35 | 35 | 33 | 36 | 35 | 33 | 33 | 35 | 33 |
| Bakuzis info | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 | 9 |
| Bakuzis NOT EVALUATED | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| Bakuzis evaluated | 129 | 129 | 129 | 129 | 129 | 129 | 129 | 129 | 129 |
| Bakuzis Reineke step | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| coverage plotlevel BA | pooled | 0.647 | 0.647 | 0.647 | 0.706 | 0.647 | 0.706 | 0.706 | 0.647 | 0.706 |
| coverage plotlevel BA | natural | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 |
| coverage plotlevel BA | planted | 0.545 | 0.545 | 0.545 | 0.636 | 0.545 | 0.636 | 0.636 | 0.545 | 0.636 |
| coverage plotlevel QMD | pooled | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 |
| realism suppressed positive | dht_d_density | 22360 of 25200 | 24942 of 25200 | 22881 of 25200 | 22432 of 25200 | 22374 of 25200 | 22951 of 25200 | 24925 of 25200 | 21777 of 25200 | 24925 of 25200 |
| realism suppressed positive | ddbh_d_density | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 |
| realism suppressed positive | ddbh_d_share | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 | 0 of 25200 |
| realism RD max in projections | 1.162 | 1.162 | 1.162 | 1.163 | 1.161 | 1.163 | 1.161 | 0.934 | 0.933 |

### Volume (m3/ha) and QMD (cm) at 40 yr, 500-replicate MC median (95% range)

| metric | D742 | R_dHT | R_HT | R_HCB | R_S3 | P_HT_HCB | C742 | v105d@923 | v105c@923 |
|---|---|---|---|---|---|---|---|---|---|
| QMD40 | Even-aged natural | High (418) | 37.9 (31.9 to 47.4) | 37.8 (31.8 to 47.4) | 37.8 (31.8 to 47.3) | 37.5 (31.3 to 47.0) | 37.7 (31.8 to 47.5) | 37.4 (31.2 to 47.0) | 37.2 (31.1 to 47.0) | 37.8 (31.6 to 47.4) | 37.2 (31.2 to 46.9) |
| QMD40 | Even-aged natural | Low (142) | 30.2 (25.6 to 39.0) | 30.2 (25.7 to 39.0) | 30.1 (25.6 to 39.0) | 31.1 (25.8 to 40.1) | 30.1 (25.7 to 38.9) | 31.1 (25.8 to 40.1) | 31.0 (25.9 to 40.1) | 30.3 (25.7 to 38.8) | 31.0 (25.8 to 39.8) |
| QMD40 | Even-aged natural | Medium (303) | 35.5 (29.9 to 44.1) | 35.5 (29.9 to 44.1) | 35.4 (29.9 to 44.1) | 35.5 (29.6 to 44.3) | 35.3 (29.9 to 43.9) | 35.4 (29.6 to 44.3) | 35.3 (29.6 to 44.0) | 35.5 (30.0 to 44.1) | 35.3 (29.6 to 44.2) |
| QMD40 | Even-aged planted | High (418) | 47.2 (40.0 to 55.5) | 47.1 (39.9 to 55.4) | 47.1 (40.0 to 55.5) | 47.0 (39.6 to 55.6) | 46.3 (39.3 to 54.8) | 47.0 (39.6 to 55.6) | 46.1 (38.9 to 54.9) | 47.1 (39.9 to 55.5) | 46.1 (39.0 to 55.0) |
| QMD40 | Even-aged planted | Low (142) | 39.6 (33.9 to 47.1) | 39.6 (33.8 to 47.0) | 39.6 (33.8 to 47.0) | 40.5 (34.1 to 48.6) | 39.0 (33.5 to 46.3) | 40.5 (34.1 to 48.6) | 39.8 (33.7 to 47.6) | 39.6 (33.8 to 47.1) | 39.8 (33.6 to 47.5) |
| QMD40 | Even-aged planted | Medium (303) | 44.9 (38.4 to 53.6) | 44.8 (38.3 to 53.5) | 44.8 (38.3 to 53.6) | 45.0 (38.2 to 54.1) | 44.1 (37.8 to 52.5) | 45.0 (38.2 to 54.1) | 44.2 (37.6 to 53.1) | 44.8 (38.3 to 53.7) | 44.1 (37.5 to 53.1) |
| VOL40 | Even-aged natural | High (418) | 185.0 (78.0 to 267.0) | 184.7 (77.9 to 266.6) | 187.7 (79.6 to 275.0) | 180.4 (75.0 to 262.2) | 180.0 (74.4 to 261.1) | 183.2 (77.1 to 270.3) | 178.0 (72.7 to 264.0) | 183.9 (77.0 to 264.9) | 177.7 (72.3 to 265.6) |
| VOL40 | Even-aged natural | Low (142) | 122.9 (53.7 to 171.2) | 122.9 (53.7 to 170.8) | 125.6 (52.7 to 181.7) | 127.1 (54.6 to 180.8) | 120.4 (51.2 to 167.6) | 130.5 (53.1 to 189.0) | 127.6 (51.0 to 185.2) | 123.0 (53.3 to 173.2) | 127.4 (50.3 to 187.1) |
| VOL40 | Even-aged natural | Medium (303) | 163.7 (64.2 to 233.3) | 163.5 (64.1 to 232.9) | 166.8 (65.2 to 243.9) | 161.7 (62.7 to 232.1) | 159.6 (60.2 to 228.0) | 165.0 (63.5 to 243.6) | 160.6 (59.3 to 237.0) | 163.0 (63.6 to 233.1) | 160.3 (58.4 to 240.3) |
| VOL40 | Even-aged planted | High (418) | 471.2 (312.8 to 558.0) | 470.7 (312.4 to 557.5) | 491.8 (321.6 to 591.1) | 470.0 (311.6 to 558.4) | 466.0 (311.3 to 551.5) | 490.7 (320.0 to 592.1) | 485.0 (318.5 to 584.3) | 470.1 (313.1 to 558.8) | 484.4 (317.7 to 583.2) |
| VOL40 | Even-aged planted | Low (142) | 359.8 (253.2 to 433.7) | 359.4 (252.8 to 433.2) | 380.3 (265.3 to 474.9) | 367.8 (258.9 to 442.3) | 355.6 (251.0 to 428.3) | 389.2 (268.6 to 486.4) | 384.2 (266.6 to 479.9) | 359.6 (252.6 to 433.3) | 383.5 (265.1 to 478.1) |
| VOL40 | Even-aged planted | Medium (303) | 431.4 (282.0 to 515.4) | 430.9 (281.4 to 515.3) | 452.8 (284.4 to 556.2) | 432.8 (283.4 to 519.0) | 426.6 (280.6 to 510.1) | 454.4 (285.5 to 561.3) | 448.9 (283.9 to 554.3) | 430.6 (281.4 to 514.7) | 448.3 (283.3 to 554.2) |

### MAI culmination age (yr), point path windowed 10-100 yr and MC median (95%)

| metric | D742 | R_dHT | R_HT | R_HCB | R_S3 | P_HT_HCB | C742 | v105d@923 | v105c@923 |
|---|---|---|---|---|---|---|---|---|---|
| culmination MC | Even-aged natural|High (418) | 12 (10 to 25) | 12 (10 to 25) | 14 (10 to 27) | 14 (10 to 27) | 10 (10 to 24) | 16 (10 to 29) | 15 (10 to 28) | 12 (10 to 25) | 14 (10 to 28) |
| culmination MC | Even-aged natural|Low (142) | 10 (10 to 35) | 10 (10 to 35) | 10 (10 to 39) | 10 (10 to 35) | 10 (10 to 32) | 19 (10 to 38) | 16 (10 to 36) | 10 (10 to 34) | 16 (10 to 36) |
| culmination MC | Even-aged natural|Medium (303) | 13 (10 to 29) | 12 (10 to 29) | 15 (10 to 31) | 16 (10 to 31) | 10 (10 to 27) | 17 (10 to 33) | 16 (10 to 32) | 12 (10 to 28) | 16 (10 to 31) |
| culmination MC | Even-aged planted|High (418) | 10 (10 to 10) | 10 (10 to 10) | 10 (10 to 10) | 10 (10 to 10) | 10 (10 to 10) | 10 (10 to 10) | 10 (10 to 10) | 10 (10 to 10) | 10 (10 to 10) |
| culmination MC | Even-aged planted|Low (142) | 10 (10 to 12) | 10 (10 to 12) | 10 (10 to 13) | 10 (10 to 13) | 10 (10 to 12) | 10 (10 to 14) | 10 (10 to 13) | 10 (10 to 12) | 10 (10 to 13) |
| culmination MC | Even-aged planted|Medium (303) | 10 (10 to 10) | 10 (10 to 10) | 10 (10 to 10) | 10 (10 to 11) | 10 (10 to 10) | 10 (10 to 11) | 10 (10 to 11) | 10 (10 to 10) | 10 (10 to 11) |
| culmination MC | Uneven-aged natural|High (418) | 19 (13 to 48) | 19 (13 to 48) | 20 (13 to 53) | 20 (14 to 50) | 18 (12 to 50) | 20 (14 to 54) | 20 (13 to 58) | 19 (13 to 46) | 20 (13 to 63) |
| culmination MC | Uneven-aged natural|Low (142) | 31 (19 to 64) | 31 (19 to 66) | 33 (20 to 76) | 29 (18 to 62) | 30 (18 to 66) | 30 (19 to 72) | 30 (18 to 81) | 31 (19 to 61) | 30 (18 to 75) |
| culmination MC | Uneven-aged natural|Medium (303) | 21 (15 to 46) | 21 (15 to 48) | 22 (15 to 52) | 22 (15 to 51) | 21 (14 to 49) | 22 (15 to 57) | 22 (15 to 57) | 22 (14 to 46) | 22 (15 to 56) |
| culmination pt | Even-aged natural|High (418) | 13 | 13 | 15 | 16 | 12 | 17 | 16 | 13 | 16 |
| culmination pt | Even-aged natural|Low (142) | 10 | 10 | 22 | 21 | 10 | 23 | 21 | 10 | 21 |
| culmination pt | Even-aged natural|Medium (303) | 14 | 14 | 17 | 17 | 13 | 19 | 17 | 14 | 17 |
| culmination pt | Even-aged planted|High (418) | 10 | 10 | 10 | 10 | 10 | 10 | 10 | 10 | 10 |
| culmination pt | Even-aged planted|Low (142) | 10 | 10 | 10 | 10 | 10 | 10 | 10 | 10 | 10 |
| culmination pt | Even-aged planted|Medium (303) | 10 | 10 | 10 | 10 | 10 | 10 | 10 | 10 | 10 |
| culmination pt | Uneven-aged natural|High (418) | 19 | 18 | 19 | 19 | 18 | 20 | 19 | 19 | 19 |
| culmination pt | Uneven-aged natural|Low (142) | 29 | 29 | 30 | 27 | 28 | 28 | 27 | 29 | 28 |
| culmination pt | Uneven-aged natural|Medium (303) | 21 | 21 | 22 | 21 | 20 | 22 | 21 | 21 | 21 |

### Validation, predicted minus observed (bias / RMSE)

| metric | D742 | R_dHT | R_HT | R_HCB | R_S3 | P_HT_HCB | C742 | v105d@923 | v105c@923 |
|---|---|---|---|---|---|---|---|---|---|
| plot-level BA bias / RMSE | DOFAW (n 7) | 5.636 / 14.378 | 5.610 / 14.364 | 5.636 / 14.378 | 5.726 / 15.200 | 5.064 / 14.311 | 5.726 / 15.200 | 5.154 / 15.129 | 5.592 / 14.447 | 5.132 / 15.120 |
| plot-level BA bias / RMSE | PSP (n 10) | -4.705 / 11.198 | -4.736 / 11.214 | -4.705 / 11.198 | -5.848 / 11.708 | -4.775 / 11.268 | -5.848 / 11.708 | -5.911 / 11.775 | -4.822 / 11.239 | -5.937 / 11.794 |
| plot-level BA bias / RMSE | all (n 17) | -0.447 / 12.605 | -0.476 / 12.607 | -0.447 / 12.605 | -1.082 / 13.258 | -0.723 / 12.611 | -1.082 / 13.258 | -1.355 / 13.259 | -0.534 / 12.659 | -1.379 / 13.265 |
| plot-level QMD bias / RMSE | DOFAW (n 7) | -0.135 / 1.494 | -0.172 / 1.503 | -0.135 / 1.494 | 0.205 / 2.454 | -0.416 / 1.619 | 0.205 / 2.454 | -0.098 / 2.479 | -0.161 / 1.599 | -0.127 / 2.484 |
| plot-level QMD bias / RMSE | PSP (n 10) | -1.303 / 2.540 | -1.319 / 2.549 | -1.303 / 2.540 | -1.961 / 2.986 | -1.339 / 2.572 | -1.961 / 2.986 | -1.993 / 3.017 | -1.366 / 2.574 | -2.004 / 3.023 |
| plot-level QMD bias / RMSE | all (n 17) | -0.822 / 2.171 | -0.847 / 2.180 | -0.822 / 2.171 | -1.069 / 2.779 | -0.959 / 2.230 | -1.069 / 2.779 | -1.212 / 2.808 | -0.870 / 2.225 | -1.231 / 2.814 |
| trajectory BA bias / RMSE | DOFAW (n 25) | 5.868 / 12.404 | 5.839 / 12.387 | 5.868 / 12.404 | 6.224 / 13.589 | 5.321 / 12.328 | 6.224 / 13.589 | 5.675 / 13.506 | 5.849 / 12.503 | 5.652 / 13.493 |
| trajectory BA bias / RMSE | PSP (n 60) | -4.171 / 8.779 | -4.189 / 8.793 | -4.171 / 8.779 | -5.455 / 9.572 | -4.199 / 8.818 | -5.455 / 9.572 | -5.477 / 9.604 | -4.279 / 8.839 | -5.500 / 9.625 |
| trajectory BA bias / RMSE | all (n 85) | -1.218 / 9.983 | -1.240 / 9.985 | -1.218 / 9.983 | -2.020 / 10.908 | -1.399 / 9.980 | -2.020 / 10.908 | -2.197 / 10.898 | -1.300 / 10.056 | -2.220 / 10.906 |
| trajectory QMD bias / RMSE | DOFAW (n 25) | 0.711 / 2.766 | 0.683 / 2.762 | 0.711 / 2.766 | 1.159 / 3.729 | 0.492 / 2.770 | 1.159 / 3.729 | 0.921 / 3.696 | 0.714 / 2.851 | 0.900 / 3.691 |
| trajectory QMD bias / RMSE | PSP (n 60) | -1.533 / 2.504 | -1.543 / 2.511 | -1.533 / 2.504 | -2.310 / 3.119 | -1.548 / 2.521 | -2.310 / 3.119 | -2.321 / 3.132 | -1.596 / 2.547 | -2.334 / 3.144 |
| trajectory QMD bias / RMSE | all (n 85) | -0.840 / 2.588 | -0.856 / 2.591 | -0.840 / 2.588 | -1.240 / 3.319 | -0.919 / 2.600 | -1.240 / 3.319 | -1.321 / 3.316 | -0.883 / 2.645 | -1.336 / 3.322 |

### Eichhorn detail (Bakuzis script rounding and unrounded)

| metric | D742 | R_dHT | R_HT | R_HCB | R_S3 | P_HT_HCB | C742 | v105d@923 | v105c@923 |
|---|---|---|---|---|---|---|---|---|---|
| Eichhorn height range | Even-aged natural | CV of VOL at equal HT (7.7 to 21.4 m) | CV of VOL at equal HT (7.7 to 21.4 m) | CV of VOL at equal HT (7.3 to 22.1 m) | CV of VOL at equal HT (7.7 to 21.4 m) | CV of VOL at equal HT (7.7 to 21.3 m) | CV of VOL at equal HT (7.3 to 22.2 m) | CV of VOL at equal HT (7.3 to 22.1 m) | CV of VOL at equal HT (7.7 to 21.3 m) | CV of VOL at equal HT (7.3 to 22.1 m) |
| Eichhorn height range | Even-aged planted | CV of VOL at equal HT (6.4 to 20.4 m) | CV of VOL at equal HT (6.4 to 20.4 m) | CV of VOL at equal HT (6.0 to 21.7 m) | CV of VOL at equal HT (6.4 to 20.4 m) | CV of VOL at equal HT (6.4 to 20.4 m) | CV of VOL at equal HT (6.0 to 21.8 m) | CV of VOL at equal HT (6.0 to 21.8 m) | CV of VOL at equal HT (6.4 to 20.4 m) | CV of VOL at equal HT (6.0 to 21.8 m) |
| Eichhorn height range | Uneven-aged natural | CV of VOL at equal HT (5.5 to 18.7 m) | CV of VOL at equal HT (5.5 to 18.8 m) | CV of VOL at equal HT (5.2 to 19.8 m) | CV of VOL at equal HT (5.5 to 19.0 m) | CV of VOL at equal HT (5.5 to 18.7 m) | CV of VOL at equal HT (5.2 to 20.1 m) | CV of VOL at equal HT (5.2 to 20.1 m) | CV of VOL at equal HT (5.5 to 18.7 m) | CV of VOL at equal HT (5.2 to 20.0 m) |
| Eichhorn max CV % | Even-aged natural | 31.6 | 31.6 | 31.7 | 28.1 | 33.1 | 28.2 | 29.6 | 32.4 | 30.7 |
| Eichhorn max CV % | Even-aged planted | 17.6 | 17.6 | 32.9 | 42.5 | 17.6 | 45.6 | 32.1 | 17.6 | 32.1 |
| Eichhorn max CV % | Uneven-aged natural | 16.4 | 16.4 | 13.0 | 16.0 | 16.4 | 12.9 | 12.9 | 16.5 | 12.9 |
| Eichhorn median CV % unrounded | Even-aged natural | 11.3479 | 11.3495 | 8.816 | 11.1741 | 11.1191 | 8.6751 | 8.5286 | 11.3695 | 8.5404 |
| Eichhorn median CV % unrounded | Even-aged planted | 9.3368 | 9.3075 | 7.6903 | 10.065 | 9.3201 | 8.2176 | 8.1891 | 9.3536 | 8.1865 |
| Eichhorn median CV % unrounded | Uneven-aged natural | 12.6331 | 12.5852 | 9.9847 | 11.7381 | 12.2384 | 9.2113 | 9.4197 | 12.6281 | 9.3859 |
| Eichhorn median CV % | Even-aged natural | 11.3 | 11.3 | 8.8 | 11.2 | 11.1 | 8.7 | 8.5 | 11.4 | 8.5 |
| Eichhorn median CV % | Even-aged planted | 9.3 | 9.3 | 7.7 | 10.1 | 9.3 | 8.2 | 8.2 | 9.4 | 8.2 |
| Eichhorn median CV % | Uneven-aged natural | 12.6 | 12.6 | 10.0 | 11.7 | 12.2 | 9.2 | 9.4 | 12.6 | 9.4 |
| Eichhorn result | Even-aged natural | FLAG | FLAG | PASS | FLAG | FLAG | PASS | PASS | FLAG | PASS |
| Eichhorn result | Even-aged planted | PASS | PASS | PASS | FLAG | PASS | PASS | PASS | PASS | PASS |
| Eichhorn result | Uneven-aged natural | FLAG | FLAG | PASS | FLAG | FLAG | PASS | PASS | FLAG | PASS |

### Coverage of 95% MC intervals, plot level

| metric | D742 | R_dHT | R_HT | R_HCB | R_S3 | P_HT_HCB | C742 | v105d@923 | v105c@923 |
|---|---|---|---|---|---|---|---|---|---|
| coverage plotlevel BA | 2628 disturbance case | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| coverage plotlevel BA | DOFAW | 0.714 | 0.714 | 0.714 | 0.714 | 0.714 | 0.714 | 0.714 | 0.714 | 0.714 |
| coverage plotlevel BA | PSP | 0.600 | 0.600 | 0.600 | 0.700 | 0.600 | 0.700 | 0.700 | 0.600 | 0.700 |
| coverage plotlevel BA | all 18 incl. 2628 | 0.667 | 0.667 | 0.667 | 0.722 | 0.667 | 0.722 | 0.722 | 0.667 | 0.722 |
| coverage plotlevel BA | natural | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 |
| coverage plotlevel BA | natural DOFAW | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 |
| coverage plotlevel BA | planted | 0.545 | 0.545 | 0.545 | 0.636 | 0.545 | 0.636 | 0.636 | 0.545 | 0.636 |
| coverage plotlevel BA | pooled | 0.647 | 0.647 | 0.647 | 0.706 | 0.647 | 0.706 | 0.706 | 0.647 | 0.706 |
| coverage plotlevel QMD | 2628 disturbance case | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| coverage plotlevel QMD | DOFAW | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| coverage plotlevel QMD | PSP | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 |
| coverage plotlevel QMD | all 18 incl. 2628 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 | 0.833 |
| coverage plotlevel QMD | natural | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| coverage plotlevel QMD | natural DOFAW | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| coverage plotlevel QMD | planted | 0.818 | 0.818 | 0.818 | 0.818 | 0.818 | 0.818 | 0.818 | 0.818 | 0.818 |
| coverage plotlevel QMD | pooled | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 | 0.882 |

