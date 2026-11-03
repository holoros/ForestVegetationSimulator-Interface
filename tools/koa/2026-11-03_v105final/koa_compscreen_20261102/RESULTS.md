# RESULTS: koa_compscreen_20261102, revised site index (C2) and relative density (RD = SDI/923) in the non-increment components (engine v105b)

PREREG.md frozen 2026-11-02 22:03:14 AST (erratum 22:03:22, before any fit). Every number below is in out/verdicts.csv (built by 06_verdicts.R from
out/height_results.csv, hcb_results.csv, stage12_results.csv, stage3_results.csv, ingrowth_results.csv) or in the file named.
Not fitted (identical models, PREREG note): ln(SDI) -> ln(RD) in Stages 1 and 2, and SDI -> RD in ingrowth (a single population SDImax only rescales the term).

## Verdict
**No candidate passes the preregistered rule. Every deployed form stays (Eq. 2 v105b partial, HCB_P, Stages 1 to 3, Eq. 6); nothing from this screen is
carried into the final rebuild.** All candidates are reported as sensitivities.

| component | candidate | held-out (candidate vs deployed) | dAIC (ingrowth dQAIC) | signs | monotone | BYI coef bootstrap 95% | verdict | reason |
|---|---|---|---|---|---|---|---|---|
| Height (Eq. 2) | H1a | LOIO RMSE 2.3998 vs 2.3969 | 132.97 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; dAIC 132.97 > -4 |
| Height (Eq. 2) | H1b | LOIO RMSE 2.4268 vs 2.3969 |  54.48 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; dAIC 54.48 > -4 |
| Height (Eq. 2) | H1full | LOIO RMSE 2.4554 vs 2.3969 |  31.08 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; dAIC 31.08 > -4 |
| HCB (Eq. 3) | C1 | LOIO RMSE 2.3604 vs 2.3614 | -67.33 | TRUE | FALSE | -1.333 to 0.094 | FAIL (sensitivity) | monotonicity fails; BYI bootstrap interval includes zero |
| HCB (Eq. 3) | C2h | LOIO RMSE 2.3394 vs 2.3614 | -67.56 | TRUE | FALSE | -1.294 to 0.042 | FAIL (sensitivity) | monotonicity fails; BYI bootstrap interval includes zero |
| Mortality Stage 1 | M1 | LOIO AUC 0.6280 vs 0.6269; Brier 0.2242 vs 0.2261 |   0.05 | TRUE | TRUE | -1.116 to 0.074 | FAIL (sensitivity) | dAIC 0.05 > -4; BYI bootstrap interval includes zero |
| Mortality Stage 2 | M2 | LOIO RMSE ln(m) 1.0740 vs 1.0048 |   1.87 | TRUE | TRUE | -0.936 to 0.132 | FAIL (sensitivity) | held-out metric not better; dAIC 1.87 > -4; BYI bootstrap interval includes zero |
| Mortality Stage 3 | M3a | LOIO within-interval AUC 0.7761 vs 0.7764; Brier 0.1197 vs 0.1140 |  46.25 | TRUE | TRUE | n/a | FAIL (sensitivity) | held-out metric not better; dAIC 46.25 > -4 |
| Mortality Stage 3 | M3b | LOIO within-interval AUC 0.7763 vs 0.7764; Brier 0.1193 vs 0.1140 |  27.28 | TRUE | TRUE | -0.229 to 1.178 | FAIL (sensitivity) | held-out metric not better; dAIC 27.28 > -4; BYI bootstrap interval includes zero |
| Mortality Stage 3 | M3c | LOIO within-interval AUC 0.7768 vs 0.7764; Brier 0.1146 vs 0.1140 |  -1.15 | TRUE | TRUE | -0.311 to 0.862 | FAIL (sensitivity) | held-out metric not better; dAIC -1.15 > -4; BYI bootstrap interval includes zero |
| Ingrowth (Eq. 6) | I1 | LOIO deviance 59435 vs 58095 |  -0.19 | TRUE | TRUE | 0.044 to 1.825 | FAIL (sensitivity) | held-out metric not better; dAIC -0.19 > -4 |

## Details
- Height (8,914 records, 143 installations, LOIO population-average prediction; every full fit took < 3 s, so LOIO not the LOSO fallback). RD is a worse
  stand-density term than ln(BAPH+1) in Eq. 2: logLik -18,717.35 (deployed) vs -18,782.83 (H1a, ln RD), -18,743.59 (H1b, RD). H1full (all six free with
  ln RD) converges (a0 43.19, a1 2.321, b 0.01646, c 0.8586, g1 0.01748, g2 -0.4431) but is still 31.1 AIC worse and LOIO 2.4554 vs 2.3969.
  Diagnostic H0g (deployed form, g1 freed): g1 0.07755 (v104 0.07684), logLik -18,717.57, i.e. not above the nested deployed fit (nlme's alternating PNLS/LME
  algorithm; difference 0.22), LOIO 2.4018: freeing g1 alone gains nothing. cor(ln(BAPH+1), ln RD) = 0.962. Non-converged LOIO folds (returned object used):
  D 4, H0g 2, H1a 3, H1b 5, H1full 2 of 143 (out/height_heldout_folds.csv).
- HCB (360 FIA records, 36 installations, 69 plots). Deployed HCB_P on C2: RMSE 2.3614. C1 (refit, C2) and C2h (RD terms) both cut AIC by about 67 in sample but
  barely move LOIO RMSE (2.3604, 2.3394), keep the HCB_P signs only for b1, b2, b5 (the intercept flips in both and b3 flips in C2h, +0.149; strict all-sign match fails for both), and
  their BYI coefficient (-0.594, -0.632) has a plot bootstrap interval spanning zero (997 and 998 of 1,000 resamples converged). Monotonicity fails for both
  (predicted HCB falls as density rises: b4 -0.140 on ln(BAPH+1), -0.150 on ln RD); the deployed HCB_P fails the same check (b3 -0.0078, b4 -0.3734).
- Stage 1 (282 intervals, 54 plots, 37 installations, 117 with mortality). M1: ln(C2/100) -0.354 (SE 0.275), plot bootstrap -1.116 to 0.074; LOIO AUC 0.6280 vs
  0.6269 and Brier 0.2242 vs 0.2261 (both slightly better) but dAIC +0.05.
- Stage 2 (117 intervals with mortality). M2: ln(C2/100) -0.053, bootstrap -0.936 to 0.132; LOIO RMSE 1.0740 vs 1.0048. The deployed Stage 2 ln(SDI) slope is
  negative (-0.069); the combined Stage 1 x Stage 2 expected annual mortality still rises with SDI (monotone for both D and M2).
- Stage 3 (4,223 records, 877 deaths, 51 installations, all 51 LOIO folds scoreable). RD in place of BAPH/BAL (M3a) loses 46 AIC (cor(ln(BAPH+1), ln RD) 0.964) and
  Brier worsens 0.1140 -> 0.1197. M3c (deployed + ln(C2/100)): coefficient 0.128, installation bootstrap -0.311 to 0.862, dAIC -1.15, within-interval AUC 0.7768 vs
  0.7764 but Brier 0.1146 vs 0.1140.
- Ingrowth (357 plot-periods, 54 plots, 37 installations). I1: ln(C2/100) 0.785, plot bootstrap 0.044 to 1.825 (excludes zero) but dQAIC -0.19 (phi 644.9) and LOIO
  deviance worse (59,435 vs 58,095).

## Gates
Stage 3 refit = STAGE3_COEF (4.2e-15); ingrowth refit = v103 vector (3.3e-15); HCB_P on the old-index frame reproduces the v103 RMSE (2.7e-15); height partial
refit = engine a0, a1 (6.7e-8); Stage 1/2 reproduce STAGE1 on the stage1_garcia_v103 sample (2e-15, 8.9e-16; the plot_intervals_origin frame does not, 0.030 /
0.083; RUN.md deviation 1).
