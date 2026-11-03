# PREREG: koa_formscreen_20261103, alternative equation forms with revised site index (C2) and RD in every component (engine v105d)

Job ~/jobs/koa_formscreen_20261103 (firebreather). Written before any model fit in this job. Read only: koa_v105d_20261102, koa_v105c_20261102,
koa_compscreen_20261102, koa_rdcomp_20261102 (incl. constrained/), koa_brms_sdimax_20261102, koa_v104_20261030, and (as in compscreen/rdcomp)
the frames of koa_v105_20261102 and the stage-1 sample path / cloglog fitter they used. No engine is modified. No coordinate column is read or written
(nocoord asserted on every input). At most 2 R processes.

## Definitions
- C2 = C2V105B (the BYI/byi column of the v105b/v105d frames). lc2 = ln(C2/100).
- SDI = TPH (QMD/25.4)^1.605 per plot-year (koa_rdcomp_20261102/out/stand_plotyear.csv SDI_qmd; HCB: TPH_hi, BAPH_hi; ingrowth: frame SDI = 500 x RD column).
- SDImax_pop = exp(b0 + b1 ln 25.4) with the posterior means of koa_brms_sdimax_20261102/out/fit_summary_rilong.csv (b0 11.98272195, b1 -1.66125832416667)
  = 741.7117 (computed in R before this file; posterior mean of the derived SDImax_pop column is 742.42, not used). RD = SDI / 741.7117.
- share = BAL / BAPH (0 if BAPH = 0); x = share x RD. CR = crown ratio column of each frame. rD = rd_max column of the height frame (relative diameter).
- Baselines = the deployed v105d forms refitted with RD = SDI/741.7117 on the same rows as the candidates:
  dDBH K3c1: ln g = b0 + b9 Pl + b1 ln(D+1) + b2 D + b4 ln(x+1) + b5 ln CR + b6 sqrt(RD D) + b7 Pl min(D,45) + b8 ln C2 (annual recursion gr.hat3, nlme
  random b0 | Data/Install/TreeID, varPower(DBH.0), rdcomp control); dHT K3c1h: same with H, guard 20 m; total height H1a: (a0 + a1 C2/100)
  (1-exp(-b DBH))^c exp(g1 ln RD + g2 rD), a0 a1 g1 free, b c g2 at v104; HCB C2h (nls, six free); Stage 1: cloglog any_mort ~ ln RD + planted, offset
  ln YIP; Stage 2: lm ln m_ann ~ ln RD + planted; Stage 3 M3a: cloglog dead ~ ln DBH + rHT + ln RD + ln(share RD + 1), offset ln YIP; ingrowth:
  quasi-Poisson ing_tph ~ RD + planted_new. (For ln RD terms and the linear ingrowth term the divisor change only rescales a coefficient; the
  refit is still done and its likelihood reported.)

## Candidates (2 to 4 per component; none is an exact rerun of a compscreen/rdcomp/constrained candidate)
Increments (same recursion, frames, random effects, variance function, control; parameters lc, ld, lg are logs of positive quantities):
- dDBH D1 (potential x exponential modifier): ln g = [b0 + b9 Pl + b1 ln(D+1) + b2 D + b7 Pl min(D,45) + b8 ln C2] + b5 ln CR - exp(lc) x^exp(ld).
- dDBH D2: D1 - exp(lg) RD (stand RD suppression at fixed share, sign fixed by construction).
- dDBH D3: D1 + b10 D lc2 (C2 changes the size decline of the potential; new BYI term b10).
- dHT T1, T2, T4: as D1, D2, D3 with H (guard 20 m; T4 term b10 H lc2).
- dHT T3 (crown ratio x RD): K3c1h with b6 sqrt(RD H) replaced by b6 (1 - CR) RD (b6 must be < 0).
Total height (a0, a1 free with b, c, g2 at v104 unless stated):
- HT1 (RD shifts the rate): (a0 + a1 C2/100) (1 - exp(-b RD^g1 DBH))^c exp(g2 rD); a0 a1 g1 free.
- HT2 (RD shifts the shape exponent): (a0 + a1 C2/100) (1 - exp(-b DBH))^(c RD^-g1) exp(g2 rD); a0 a1 g1 free.
- HT3 (RD x relative diameter): (a0 + a1 C2/100) (1 - exp(-b DBH))^c exp(g1 ln RD + g2 rD + g3 rD ln RD); a0 a1 g1 g3 free.
HCB (HCB = HT / (1 + exp(-eta)), nls; common part eta0 = b0 + b1 sqrt(HT/100) + b2 ln(max(HT/DBH, 0.5)) + b5 lc2):
- HC1: eta0 + b3 RD + b4 share RD.  HC2: eta0 + exp(g3) ln RD + exp(g4) share RD (monotone by construction).
- HC3: HC1 + b6 lc2 RD (new BYI term b6).
Mortality:
- Stage 1 S1a: any_mort ~ max(0, RD - r0) + planted (r0 profiled on a 0.01 grid between the 5th and 95th percentile of RD; counted as a parameter).
  S1b: ~ ln RD + ln RD:lc2 + planted (new BYI term). S1c: ~ RD + planted (linear).
- Stage 2 S2a, S2b, S2c: same three forms for ln m_ann (lm).
- Stage 3 S3a: dead ~ ln DBH + rHT + ln RD + share RD + share:lc2 (new BYI term). S3b: ~ ln DBH + ln CR + ln RD + ln(share RD + 1) (CR replaces rHT).
  S3c: ~ ln DBH + rHT + max(0, RD - r0) + ln(share RD + 1) (r0 profiled as Stage 1, counted as a parameter).
- Ingrowth I-a: ing_tph ~ ln(max(1 - RD, 0.05)) + planted_new (free growing space). I-b: ~ ln RD + planted_new. I-c: ~ RD + RD:lc2 + planted_new (new BYI term).

## Metrics (as compscreen/rdcomp)
- Common rows per component (candidate and baseline on identical rows).
- Increments: LOSO (DOFAW, FIA, KMR PSP, PSP): refit on the other three from the full-data vector, re-solve origin constants (solve_c), RMSE of log annual
  increment of the held-out source. "Improves" = lower RMSE than the baseline on at least 3 of 4 sources (rdcomp convention); held-out error for choosing
  among passing candidates = mean of the 4 source RMSEs. Two starts per candidate (baseline-derived and a rescaled start); the higher logLik is kept.
  AIC from the nlme ML fits.
- Height: LOIO RMSE (population-average prediction, nlme random a0 | source/installation), ΔAIC (ML).
- HCB: LOIO RMSE (36 installations), Gaussian ΔAIC.
- Stage 1: LOIO AUC and Brier (both must improve). Stage 2: LOIO RMSE of ln m_ann. Stage 3: LOIO within-interval AUC and Brier (both must improve).
  Ingrowth: LOIO Poisson deviance; ΔQAIC = (D_c - D_b)/phi_c + 2 Δk.
- BYI coefficient bootstrap: installation-cluster, B = 400, seed 20261103, for every candidate that adds or changes a BYI term (D3, T4, HC3, S1b, S2b,
  S3a, I-c). A BYI term whose functional form is unchanged from the baseline (b8 ln C2, b5 lc2, a1 C2/100) is not "added or changed". Compute order:
  cheap components bootstrapped regardless; for D3 and T4 (about 2 min per refit) the bootstrap runs only if every other condition passes (otherwise
  reported as not run, fails the rule regardless).
- Signs: increments b1 > 0, b5 > 0 for dDBH (as rdcomp; dHT b5 not sign-checked, deployed dHT b5 is not constrained), competition effects judged by
  monotonicity, T3 b6 < 0; height a0 > 0, a1 > 0; HCB b1 > 0, b2 < 0, b5 < 0; Stage 1 density slope > 0 (S1b: at the median lc2); Stage 3 ln DBH < 0,
  rHT or ln CR < 0, density and competition terms > 0; ingrowth suppressor sign (RD or ln RD < 0; ln(1 - RD) > 0).
- Monotonicity over the observed range: increments: d ln g/dx <= 0 at fixed RD and d ln g/dRD <= 0 at fixed share (x = share RD), one annual step, grid
  of size (1st-99th pct, 20 values), CR and C2 (1st-99th pct, 5 values), origin 0/1, x from 0 to the observed maximum of x, RD from the 1st pct to
  the observed maximum, share 0 to 1; height: non-decreasing in RD at fixed DBH (compscreen check; static height is not growth); HCB: non-decreasing in RD
  at fixed share and in share at fixed RD; Stage 1 occurrence and Stage 1 x Stage 2 expected annual mortality non-decreasing in RD (Stage 2 candidates
  combined with the baseline Stage 1); Stage 3 death probability non-decreasing in RD at fixed share and in share at fixed RD; ingrowth non-increasing in
  RD. Grids at the 10th/50th/90th percentiles of the other covariates and over the C2 percentiles where C2 interacts.

## Rule (verbatim)
"A candidate replaces the v105d form of its component only if signs pass, the monotonicity check passes over the observed range (growth and survival never increase with competition; HCB never decreases with density), its held-out metric improves on the v105d form refit under the same SDImax, its ΔAIC (or deviance-based equivalent) is at most −4, and any BYI term it adds or changes has a bootstrap interval excluding zero. Where competition enters, the candidate must use an RD-based competition measure. If several candidates in a component pass, the one with the lowest held-out error is chosen. Otherwise the v105d form stays and candidates are reported as sensitivities."
Held-out error for the tie-break: increments mean LOSO RMSE; height/HCB LOIO RMSE; Stage 1 and Stage 3 Brier; Stage 2 RMSE; ingrowth LOIO deviance.
Outputs: RUN.md, RESULTS.md (component x candidate x metric x verdict), out/coefficients_<component>.csv for any passing candidate, monotonicity diagnostics.
