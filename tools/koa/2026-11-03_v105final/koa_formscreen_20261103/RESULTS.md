# RESULTS: koa_formscreen_20261103, alternative forms with C2 and RD in every component (v105d baselines refitted under SDImax_pop 741.7117)

PREREG.md written 2026-11-03 06:28:32 AST (md5 38b7bd33b0974be9c7565d213ffb5b65, PREREG_written_at.txt) before any fit (first fit, the code gate, started 06:30:04).
RD = SDI / 741.7117 = SDI / exp(11.98272195 - 1.66125832416667 ln 25.4) (posterior means, koa_brms_sdimax_20261102/out/fit_summary_rilong.csv).
Every number below is in out/verdicts.csv (built by verdicts.R) or in out/increment_results.csv, height_results.csv, hcb_results.csv, stage12_results.csv,
stage3_results.csv, ingrowth_results.csv, monotonicity_increments.csv, monotonicity_RD_by_share.csv.

## Verdict
**No candidate passes the preregistered rule in any component. Every v105d form stays; all candidates are sensitivities. No out/coefficients_<component>.csv
was written (none passed).** The v105d forms refitted under SDImax 741.7117 are in out/baseline_refit_coefficients_<component>.csv (term/estimate/se, the
prep/out layout of koa_v105d_20261102); they are baselines, not adopted replacements.

## Table (component x candidate x metric x verdict)
| component | candidate | held-out | dAIC | signs | monotone | BYI boot 95% | verdict | reason |
|---|---|---|---|---|---|---|---|---|
| dDBH | B (v105d refit) | LOSO mean 1.1181 (1.0371/1.8528/0.6073/0.9753) | 0.00 | TRUE | TRUE | n/a | baseline |  |
| dDBH | D1 | LOSO mean 1.1477 (1.0283/1.9963/0.6054/0.9607); better 3 of 4 | 17.64 | TRUE | TRUE | n/a | FAIL (sensitivity) | dAIC 17.64 > -4 |
| dDBH | D2 | LOSO mean NA (1.0482/2.0203/0.6104/   NA); better 0 of 4 | 14.63 | TRUE | TRUE | n/a | FAIL (sensitivity) | better than baseline on 0 of 4 sources; dAIC 14.63 > -4 |
| dDBH | D3 | LOSO mean 1.1734 (1.0032/2.0648/0.6496/0.9760); better 1 of 4 | -20.67 | TRUE | TRUE | not run | FAIL (sensitivity) | better than baseline on 1 of 4 sources; b10 bootstrap not run (fails other conditions) |
| dHT | B (v105d refit) | LOSO mean 1.0667 (1.2310/1.3780/0.7647/0.8930) | 0.00 | TRUE | FALSE | n/a | baseline | baseline fails monotonicity (reported) |
| dHT | T1 | LOSO mean 1.0512 (1.2056/1.3273/0.7772/0.8948); better 2 of 4 | 75.41 | TRUE | TRUE | n/a | FAIL (sensitivity) | better than baseline on 2 of 4 sources; dAIC 75.41 > -4 |
| dHT | T2 | fit failed (both starts) |  | NA | NA | NA | FAIL (sensitivity) | no converged fit |
| dHT | T3 | LOSO mean 1.0859 (1.2855/1.3721/0.7909/0.8952); better 1 of 4 | -3.22 | FALSE | FALSE | n/a | FAIL (sensitivity) | signs fail: b6_neg; monotonicity fails (d ln g/dRD > 0 at 340000 of 341000 grid points); better than baseline on 1 of 4 sources; dAIC -3.22 > -4 |
| dHT | T4 | LOSO mean 1.0473 (1.1967/1.3235/0.7733/0.8956); better 2 of 4 | 77.98 | TRUE | TRUE | not run | FAIL (sensitivity) | better than baseline on 2 of 4 sources; dAIC 77.98 > -4; b10 bootstrap not run (fails other conditions) |
| Height (Eq. 2) | B (v105d refit) | LOIO RMSE 2.3996 vs 2.3996 | 0.00 | TRUE | TRUE | n/a | baseline |  |
| Height (Eq. 2) | HT1 | LOIO RMSE 2.4168 vs 2.3996 | 9.99 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; dAIC 9.99 > -4;  |
| Height (Eq. 2) | HT2 | LOIO RMSE 2.4330 vs 2.3996 | 66.58 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; dAIC 66.58 > -4;  |
| Height (Eq. 2) | HT3 | LOIO RMSE 2.3993 vs 2.3996 | 1.87 | TRUE | TRUE | n/a | FAIL (sensitivity) | dAIC 1.87 > -4;  |
| HCB (Eq. 3) | B (v105d refit) | LOIO RMSE 2.3411 vs 2.3411 | 0.00 | TRUE | FALSE | n/a | baseline | baseline fails monotonicity (reported) |
| HCB (Eq. 3) | HC1 | LOIO RMSE 2.3966 vs 2.3411 | 4.84 | FALSE | FALSE | n/a | FAIL (sensitivity) | signs fail; monotonicity fails; held-out metric not better; dAIC 4.84 > -4;  |
| HCB (Eq. 3) | HC3 | LOIO RMSE 2.4134 vs 2.3411 | 1.57 | FALSE | FALSE | -0.6457 to 1.532 | FAIL (sensitivity) | signs fail; monotonicity fails; held-out metric not better; dAIC 1.57 > -4; BYI bootstrap interval includes zero;  |
| HCB (Eq. 3) | HC2 | LOIO RMSE 2.2988 vs 2.3411 | 4.86 | FALSE | TRUE | n/a | FAIL (sensitivity) | signs fail; dAIC 4.86 > -4;  |
| Mortality Stage 1 | B (v105d refit) | LOIO AUC 0.6269 vs 0.6269; Brier 0.2261 vs 0.2261 | 0.00 | TRUE | TRUE | n/a | baseline |  |
| Mortality Stage 1 | S1a | LOIO AUC 0.6307 vs 0.6269; Brier 0.2246 vs 0.2261 | 0.33 | TRUE | TRUE | n/a | FAIL (sensitivity) | dAIC 0.33 > -4; r0 = 0.64 |
| Mortality Stage 1 | S1b | LOIO AUC 0.6266 vs 0.6269; Brier 0.2254 vs 0.2261 | 0.69 | TRUE | FALSE | -0.3212 to 0.4413 | FAIL (sensitivity) | monotonicity fails; held-out metric not better; dAIC 0.69 > -4; BYI bootstrap interval includes zero;  |
| Mortality Stage 1 | S1c | LOIO AUC 0.6252 vs 0.6269; Brier 0.2265 vs 0.2261 | -0.03 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; dAIC -0.03 > -4;  |
| Mortality Stage 2 | B (v105d refit) | LOIO RMSE ln(m) 1.0048 vs 1.0048 | 0.00 | TRUE | TRUE | n/a | baseline |  |
| Mortality Stage 2 | S2a | LOIO RMSE ln(m) 0.9726 vs 1.0048 | -0.39 | TRUE | FALSE | n/a | FAIL (sensitivity) | monotonicity fails; dAIC -0.39 > -4; r0 = 0.06 |
| Mortality Stage 2 | S2b | LOIO RMSE ln(m) 0.9974 vs 1.0048 | -4.25 | TRUE | FALSE | -0.07417 to 0.4481 | FAIL (sensitivity) | monotonicity fails; BYI bootstrap interval includes zero;  |
| Mortality Stage 2 | S2c | LOIO RMSE ln(m) 0.9712 vs 1.0048 | -2.17 | TRUE | FALSE | n/a | FAIL (sensitivity) | monotonicity fails; dAIC -2.17 > -4;  |
| Mortality Stage 3 | B (v105d refit) | LOIO within AUC 0.7761 vs 0.7761; Brier 0.11958 vs 0.11958 | 0.00 | TRUE | TRUE | n/a | baseline |  |
| Mortality Stage 3 | S3a | LOIO within AUC 0.7769 vs 0.7761; Brier 0.12297 vs 0.11958 | 30.04 | TRUE | TRUE | -1.366 to 0.4674 | FAIL (sensitivity) | held-out metric not better; dAIC 30.04 > -4; BYI bootstrap interval includes zero;  |
| Mortality Stage 3 | S3b | LOIO within AUC 0.7705 vs 0.7761; Brier 0.11271 vs 0.11958 | -54.18 | FALSE | FALSE | n/a | FAIL (sensitivity) | signs fail; monotonicity fails; held-out metric not better;  |
| Mortality Stage 3 | S3c | LOIO within AUC 0.7752 vs 0.7761; Brier 0.11178 vs 0.11958 | -68.29 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; r0 = 0.16 |
| Ingrowth (Eq. 6) | B (v105d refit) | LOIO deviance 58095 vs 58095 | 0.00 | TRUE | TRUE | n/a | baseline |  |
| Ingrowth (Eq. 6) | Ia | LOIO deviance 62984 vs 58095 | 5.83 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; dAIC 5.83 > -4;  |
| Ingrowth (Eq. 6) | Ib | LOIO deviance 59044 vs 58095 | 3.03 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; dAIC 3.03 > -4;  |
| Ingrowth (Eq. 6) | Ic | LOIO deviance 59542 vs 58095 | 1.51 | TRUE | TRUE | -7.134 to 9.686 | FAIL (sensitivity) | held-out metric not better; dAIC 1.51 > -4; BYI bootstrap interval includes zero;  |

dAIC: ML AIC difference vs the baseline refit (ingrowth: dQAIC). Increment held-out = LOSO RMSE of log annual increment, sources DOFAW / FIA / KMR PSP / PSP;
"improves" = better on at least 3 of 4. A failed LOSO fit counts as not better (D2, PSP).

## Coefficients of the increment fits (estimate, model SE; out/increment_results.csv)
- dDBH B (K3c1, SDImax 741.71): logLik -9560.250 (14 df); b1 0.2935, b2 -0.03061, b4 -2.628 (SE 0.104), b5 0.5385, b6 -0.05095, b7 -0.01443, b8 0.2819 (SE 0.106), b9 0.0826.
  Under SDImax 923 the same code gives logLik -9564.063 (gate below), so the new divisor improves the baseline by 3.8 logLik units.
- dDBH D1 (exp(-e^lc x^e^ld) modifier): logLik -9569.068, lc 0.622, ld -0.333 (shape d = 0.717). D2 adds -e^lg RD: lg -1.579 (0.206 per unit RD), logLik -9566.567.
  D3 adds b10 D lc2: b10 -0.01546 (SE 0.00217), b8 0.463, logLik -9548.915 (dAIC -20.67) but better on only 1 of 4 sources (DOFAW); bootstrap not run (PREREG compute order).
- dHT B (K3c1h, SDImax 741.71): logLik -6952.298; b4 -0.9722, b6 +0.3006 (SE 0.0347) on sqrt(RD HT), b8 0.1121.
- dHT T1 (modifier, no stand RD term): logLik -6990.000 (dAIC +75.41); lc -0.238, ld -0.603. T4 = T1 + b10 H lc2: b10 -0.00472 (SE 0.00737), logLik -6990.287
  (nlme stopped below its nested T1 from the T1 + b10 = 0 start; start-dependent stop, verdict unaffected). T2 (T1 - e^lg RD): no converged fit from the two
  preregistered starts nor from an extra start lg = log(1e-3) (singular backsolve, out/t2_extra.txt): the RD coefficient runs to the boundary 0, i.e. T2 -> T1.
  T3 (b6 (1 - CR) RD): b6 = +2.757 (SE 0.308), sign fails; dAIC -3.22.
- Realism reading: every dHT form that forbids a positive stand-RD effect (T1, T4, and T2 at its boundary) loses 75 to 78 AIC units; every dHT form that lets
  RD act freely (B, T3) estimates a positive RD effect on height growth. The data do not support a monotone-in-RD dHT; this is why the suppressed-tree density
  rise of v105d persists. Baseline dHT, d ln g/dRD at fixed share is positive at 286,450 of 341,000 grid points; at share 1.0 (most suppressed) 20,800 of 31,000
  (max 4.17), at share 0 31,000 of 31,000 (out/monotonicity_RD_by_share.csv).
- Large-tree and top-BAL strata (observed/predicted, not part of the rule): dDBH 40-60 cm 1.748 (B), 1.686 (D1), 1.735 (D2), 1.758 (D3); BAL Q5 1.246, 1.191, 1.206, 1.216.
  dHT 20-30 m 1.471 (B), 1.639 (T1), 1.529 (T3), 1.650 (T4).

## Non-increment components (details)
- Height (8,914 records, 143 installations, LOIO 143 folds, 0 failed; non-converged folds B 1, HT2 2, HT3 2): HT3 (RD x relative diameter, g3 -0.00424, SE 0.0128)
  has LOIO 2.3993 vs 2.3996 but dAIC +1.87. HT1 (RD on the rate, g1 0.0627) +9.99; HT2 (RD on the exponent) +66.58. All monotone (height non-decreasing in RD).
- HCB (360 records, 36 installations): baseline C2h refit b3 0.1192, b4 -0.1493 on ln RD, still non-monotone (HCB falls with RD). HC1 (linear RD, share RD) and
  HC3 (+ lc2 RD, b6 0.469, bootstrap -0.646 to 1.532, 398 of 400) fail signs (b1 < 0) and monotonicity. HC2 (non-negative RD effects) did not converge in the
  exp parametrization; refitted with b3, b4 >= 0 by nls port (deviation 2): b3 at the bound 0, b4 0.00196, monotone, LOIO 2.2988 vs 2.3411 (better) but b1 -0.448
  (sign fails) and dAIC +4.86. As in compscreen, the 360 FIA crown records do not support HCB rising with density.
- Stage 1 (282 intervals, 37 installations): S1a hinge max(0, RD - 0.64) slope 1.374 (SE 0.461): LOIO AUC 0.6307 vs 0.6269 and Brier 0.2246 vs 0.2261 (both
  better) but dAIC +0.33. S1b non-monotone (lnRD 0.034, lnRD:lc2 0.144; bootstrap -0.321 to 0.441). S1c linear RD: dAIC -0.03, held-out worse.
- Stage 2 (117 intervals): the baseline ln RD slope is negative (-0.0688) and all three candidates estimate a decreasing conditional rate with RD
  (S2a hinge at 0.06 slope -0.407; S2b lnRD -0.264 + lnRD:lc2 0.224, dAIC -4.25, bootstrap -0.074 to 0.448; S2c RD -0.390), so Stage 1 x Stage 2 expected
  annual mortality falls with RD somewhere on the grid (max decrease 2.65e-4 to 0.353): monotonicity fails for all three.
- Stage 3 (4,223 records, 877 deaths, 51 installations, all folds scoreable): S3c (hinge max(0, RD - 0.16) slope 0.995, ln(share RD + 1) 0.442) has dAIC -68.29
  and LOIO Brier 0.11178 vs 0.11958 but within-interval AUC 0.7752 vs 0.7761, so the held-out condition (both must improve) fails. S3b (ln CR for rHT) dAIC
  -54.18 but ln CR coefficient +7.22 (sign fails), ln RD -0.339 (non-monotone). S3a (share RD + share:lc2) dAIC +30.04, share:lc2 -0.024 (bootstrap -1.366 to 0.467).
- Ingrowth (357 plot-periods, 37 installations): baseline LOIO deviance 58,095 (= compscreen deployed). I-a ln(max(1 - RD, 0.05)) 1.632, I-b ln RD -0.445,
  I-c RD:lc2 1.61 (bootstrap -7.13 to 9.69): all held-out worse and dQAIC +1.5 to +5.8.

## Gates
- Increment code: the baseline recursion at SDImax 923 reproduces the deployed vectors: dHT K3c1h logLik -6952.802 vs v105d -6952.801, max coefficient diff
  2e-5; dDBH K3c1 predictions identical to the koa_rdcomp constrained code to 1.4e-14 on the same vector, coefficients within 5e-4 (b4; < 0.005 SE) of the
  v105c/v105d K3c1 vector, logLik -9564.063 vs -9564.022 (both starts, and the rdcomp lib_c code itself from this vector, stop at -9564.063: start-dependent
  nlme stop, as v105d RUN gate 1 records for K3p).
- Height baseline: logLik -18782.79 vs compscreen H1a -18782.83 (identical model; ln RD rescaling absorbed by a0, a1; nlme stop difference 0.04).
- Stage 3 code at SDImax 923 = v105d M3a vector, max abs diff 8.9e-16 (out/gate_stage3_923.txt). Stage 1/2 baseline slopes = deployed STAGE1 (6e-16, 3e-16).
  Ingrowth baseline RD slope x 500/741.71 = v103 slope (1.3e-15).
