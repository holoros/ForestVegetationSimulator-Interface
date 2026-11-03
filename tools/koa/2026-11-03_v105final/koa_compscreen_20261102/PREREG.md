# PREREG: koa component screen of revised site index (C2) and relative density (RD), non-increment components (engine v105b)

Job ~/jobs/koa_compscreen_20261102 (firebreather). Written before any model fit in this job (only key/coverage checks were run: every
tree_join, survival, HCB, ingrowth and plot-interval row joins to stand_plotyear.csv and to repair_v105b/out/c2imp_pltgeo_all.csv C2V105B;
byi columns of the v105b frames equal C2V105B with max abs diff 0). Read only: koa_v105_20261102, koa_v105c_20261102, koa_v104_20261030,
koa_rdcomp_20261102. No engine is modified. No coordinate column is read or written (nocoord asserted on every input). At most 2 cores
(1 used: 7 of 8 cores are held by other jobs).

## Definitions
- C2 = C2V105B (v105b site index: BYI residualized on stocking, P0, Kap/FIA gaps imputed), the value in the byi/BYI column of every v105b frame.
- SDI = TPH (QMD/25.4)^1.605 per plot-year (koa_rdcomp_20261102/out/stand_plotyear.csv, SDI_qmd; HCB: same formula from TPH_hi and BAPH_hi).
- RD = SDI / 923 (population lqmm SDImax, koa_brms_sdimax_20261102). share = BAL / BAPH (0 if BAPH = 0).
- **Note:** with a single population SDImax, RD is a constant multiple of SDI, so ln(RD) = ln(SDI) - ln(923) and RD = SDI/923. Replacing ln(SDI) by
  ln(RD) (Stage 1, Stage 2) or a linear SDI/RD term by RD (ingrowth, whose RD = SDI/500) gives the same model (identical likelihood, only the
  intercept or slope is rescaled). Those substitutions are NOT fitted; only the C2 additions are screened in those components.

## Deployed forms (baselines, refitted on the same rows as each candidate)
- Eq. 2 height (v105b partial): ht = (a0 + a1 C2/100) (1 - exp(-b DBH))^c exp(g1 ln(BAPH+1) + g2 rDBH); a0, a1 free, b, c, g1, g2 at v104;
  nlme random a0 ~ 1 | source/installation (repair_v105b/height_refit_v105b.R). 8,914 records.
- Eq. 3 HCB (HCB_P, hard coded, not refitted): HCB = HT / (1 + exp(-eta)), eta = b0 + b1 sqrt(HT/100) + b2 ln(HT/DBH) + b3 sqrt(BAL BAPH + 1)
  + b4 ln(BAPH+1) + b5 ln(BYI/100), HCB_P = (0.1684, 1.0146, -0.376, -0.0078, -0.3734, -0.221); evaluated with C2 and the live-list BAL (BALl) and
  BAPH_hi (engine BAL definition l). 360 FIA crown records.
- Stage 1: cloglog any_mort ~ ln(SDI) + planted, offset ln(YIP), on a2/mort/v104/plot_intervals_origin.csv minus removal rows.
- Stage 2: lm ln(m_ann) ~ ln(SDI) + planted on the intervals with mortality.
- Stage 3: cloglog dead ~ ln(DBH) + rHT + ln(BAPH+1) + ln(BAL+1), offset ln(YIP), on frames/final/surv_recovered_ii_v103.csv (4,223 records);
  gate: refit equals STAGE3_COEF.
- Eq. 6 ingrowth: quasi-Poisson ing_tph ~ RD(=SDI/500) + planted_new (PSP origin recode), 357 plot-periods.
Gates (reported): each deployed-form refit is compared with the deployed vector (Stage 1/2 with out/v105_constants.json STAGE1; if the specified
frame does not reproduce it, the stage1_garcia_v103.R sample is tried and the reproducing sample is used; Stage 3 with STAGE3_COEF; ingrowth with
ING_B0 3.383783, ING_B_SDI -0.005379672; height a0 28.990422, a1 1.142886).

## Candidates
- Height H1a: deployed partial form with ln(BAPH+1) replaced by ln(RD); a0, a1, g1 free (b, c, g2 at v104). H1b: same with RD (linear in the
  exponent). H1full: all six parameters free with ln(RD) (convergence reported; enters the rule only if it converges). Diagnostic, not a candidate:
  H0g = deployed form with a0, a1, g1 free (separates the effect of freeing g1 from that of RD).
- HCB C1: deployed form refitted by nls with ln(C2/100) (all six coefficients). C2h: C1 with ln(BAPH+1) -> ln(RD+1)... no: ln(BAPH+1) replaced by
  RD-based term ln(RD) and sqrt(BAL BAPH + 1) replaced by sqrt(share RD + 1).
- Stage 1 M1: deployed + ln(C2/100). Stage 2 M2: deployed + ln(C2/100).
- Stage 3 M3a: ln(BAPH+1) -> ln(RD), ln(BAL+1) -> ln(share RD + 1). M3b: M3a + ln(C2/100). M3c: deployed + ln(C2/100).
- Ingrowth I1: deployed + ln(C2/100).

## Metrics
- Common rows: every candidate and its baseline are fitted on identical rows.
- Height: held-out RMSE by leave-one-installation-out, population-average (level 0) prediction of the held-out installation; fallback if one
  full-data fit takes more than 60 s: leave-one-source-out (stated in RUN.md). ΔAIC (ML) vs the deployed partial refit.
- HCB: leave-one-installation-out RMSE (36 FIA installations; the deployed HCB_P has no fitted parameters, so its held-out RMSE = its RMSE);
  ΔAIC Gaussian (deployed: k = 1, sigma only).
- Stage 1: LOIO AUC and Brier of the interval probability (offset included); plot-cluster bootstrap of each new coefficient (B 1,000, seed 20261102).
- Stage 2 (continuous response, AUC/Brier not defined): LOIO RMSE of ln(m_ann) and ΔAIC; plot-cluster bootstrap of the C2 coefficient (B 1,000, seed 20261102).
- Stage 3: LOIO within-interval AUC (pairs compared inside a plot interval, the registry metric that matches how Stage 3 allocates) and LOIO
  Brier (interval probability); pooled LOIO AUC reported. Installation-cluster bootstrap (B 1,000, seed 20261102) of the C2 coefficient (M3b, M3c).
- Ingrowth: deviance and quasi-AIC difference ΔQAIC = (D_cand - D_dep)/phi_cand + 2 Δk; LOIO Poisson deviance of held-out rows; plot-cluster
  bootstrap (B 1,000, seed 20261102) of the C2 coefficient.
- HCB C1 and C2h: plot-cluster bootstrap (B 1,000, seed 20261102) of the BYI coefficient.
- Sign checks: height a0 > 0, a1 > 0, g1 > 0; HCB b1 > 0, b2 < 0, b5 < 0 (non-competition slopes with the HCB_P signs; competition judged by the
  monotonicity check; the strict all-coefficient HCB_P sign match is also reported); Stage 1 ln(SDI) > 0; Stage 3 ln(DBH) < 0, rHT < 0, both
  competition terms > 0; ingrowth RD < 0. No prior sign for ln(C2/100) in mortality or ingrowth.
- Monotonicity (over the observed range, grid of 50 values from the 1st to 99th percentile, at the 10th, 50th, 90th percentiles of the other
  covariates): height non-decreasing in stand density (BAPH or RD) at fixed DBH; HCB non-decreasing in stand density (BAPH or RD at fixed share);
  Stage 1 occurrence non-decreasing in SDI; Stage 2: expected annual mortality P1(YIP = 1) x exp(eta2) (deployed Stage 1 with M2) non-decreasing
  in SDI; Stage 3 death probability non-decreasing in RD (or BAPH) at fixed share and in share (or BAL) at fixed RD (or BAPH); ingrowth
  non-increasing in RD.

## Rule (verbatim)
"A candidate replaces the deployed form of its component only if signs pass, the monotonicity check passes, its held-out metric improves on the
deployed form (lower RMSE, or higher AUC and lower Brier, or lower held-out deviance), its ΔAIC (or deviance-based equivalent) is at most −4, and,
if it adds or changes a BYI term, that term's bootstrap interval excludes zero. Otherwise the deployed form stays and the candidate is reported as a
sensitivity."
If two candidates of one component pass, the one with the lower AIC is carried. Compute order: point fits and held-out metrics for all candidates;
bootstraps for every candidate with a BYI term (run regardless of the other conditions, since they are cheap).

## Erratum (appended 2026-11-02 before any fit; wording only)
The C2h line above contains an editing slip ("ln(RD+1)... no:"). The intended and used definition is: C2h = C1 with ln(BAPH+1) replaced by ln(RD)
and sqrt(BAL BAPH + 1) replaced by sqrt(share RD + 1); all six coefficients refitted by nls.
