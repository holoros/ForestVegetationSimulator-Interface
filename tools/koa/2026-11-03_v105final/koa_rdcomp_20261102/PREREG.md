# PREREG: koa_rdcomp_20261102, preregistered screen of relative-density (RD) weighted competition terms in the koa Eq. 4 increment equations (engine v105b)

Written on firebreather before any candidate was fitted; freeze timestamp (server clock) on the last line, md5 in RUN.md.
Work done before this file, none of it a model fit: reading RUN_v105.md / RESULTS_v105.md (incl. the v105b repair section) of ~/jobs/koa_v105_20261102, its
track2/inc/inc_v103.R, scripts/repair_v103.py (how the frames' stand variables are built), ~/jobs/koa_byi2_20261101/v2 (lib.R, 03_fit.R, 04_boot.R, PREREG.md), and
~/jobs/koa_brms_sdimax_20261102/RESULTS.md; and two data-preparation scripts (00_stand.R, 01_rd_join.R; logs/00_stand.log, logs/01_rd_join.log) that build SDI and RD and check
the joins. Those logs show (disclosed): the joined BAPH equals the frame BAPH.0 and BAPH.1 to 1.1e-13 on every row; SDI is available at t.0 and t.1 on every frame row;
plot SDImax exists for 4,962 of 4,992 dDBH frame rows (FIA 93 of 123 rows; 30 FIA rows on 4 plots get the population value 923); cor(BAPH.0, RD with population SDImax)
= 0.966 (dDBH frame) and cor(ln(BAPH.0+1), RD plot) = 0.823.

## Brief (verbatim parts)
Candidates (Eq. 4 L_NO form, all else identical; only the competition terms change):
- K0: deployed v105b (ln(BAL+1) live-list, ln(BAPH+1) or whatever Eq. 4 uses; quote the exact deployed terms).
- K1: BAPH term replaced by RD (RD = SDI / SDImax, plot-specific lqmm SDImax where available, population SDImax 923 otherwise), entered in the same functional form slot (e.g., ln(RD) or RD; choose the form that mirrors the deployed BAPH term and state it).
- K2: BAL and BAPH each multiplied by RD (RD-weighted), same functional forms.
- K3: relative competition: BAL/BAPH (the tree's share) times RD in place of BAL, BAPH term replaced by RD.
- K1p, K2p, K3p: same with population SDImax for all plots (because plot-specific SDImax is not available for projected stands; the simulator would have to use a population or origin-specific SDImax).
Metrics (dDBH and dHT): sign checks (competition should reduce growth); coefficient bootstrap intervals; ΔAIC on common rows; leave-one-source-out RMSE on the 4 sources with re-solved origin constants; evaluation strata ratios by size class (the 40 to 60 cm class ratio, currently 1.70) and BAL quintile; whether the BYI (C2) site coefficient stays identified (bootstrap interval excludes zero).
Adoption rule (verbatim): "A candidate replaces K0 for dDBH only if signs pass, it is better than K0 on at least 3 of 4 held-out sources, its ΔAIC is at most −4, the C2 site coefficient interval still excludes zero, and it is a population-SDImax variant (K1p, K2p or K3p) or the plot-specific variant's advantage is retained by its population variant (same 3-of-4 test against K0), so it can be projected. Same rule for dHT, adopted independently. If none passes, K0 stays and the result is reported as a sensitivity."

## Exact deployed Eq. 4 L_NO (K0), from track2/inc/inc_v103.R gr.hat2g / gr.hat3 (v105b, coefficients out/inc/coefficients_v103.csv)
Annual step, size S = DBH (dDBH, GUARD 45 cm) or HT (dHT, GUARD 20 m), iterated YIP times with BAL, BAPH and CR linearly interpolated between t.0 and t.1:
  g = exp(b0 + b9 Planted + b1 ln(S+1) + b2 S + b3 BAL^2 / ln(S+5) + b4 ln(BAL+1) + b5 ln(CR) + b6 sqrt(BAPH x S) + b7 Planted min(S, GUARD) + b8 ln(BYI))
BAL = BALl (live-list percentile BAL of Eq. 7: (1 - percentile rank of DBH among live koa) x BAPH), BAPH = live all-species BA (m2/ha), CR = CRl (engine HCB_P under BALl),
BYI = C2 (v105b) site index. So the deployed competition terms are b3 BAL^2/ln(S+5), b4 ln(BAL+1) and b6 sqrt(BAPH x S); there is no ln(BAPH+1) term.
Deployed vectors: dDBH_L_NO b0 -0.541411 b1 0.362175 b2 -0.022055 b3 -0.001445 b4 -0.339160 b5 0.839662 b6 -0.017221 b7 -0.017816 b8 0.277934 b9 0.245527;
dHT_L_NO b0 -2.248861 b1 1.161651 b2 -0.151805 b3 -0.000155 b4 -0.181776 b5 0.211620 b6 0.064256 b7 -0.119570 b8 0.075488 b9 0.693040.

## Operational definitions, fixed now
SDI (each plot-year, t.0 and t.1): Reineke form SDI = TPH (QMD/25.4)^1.605, with TPH and QMD the frames' own stand columns (inputs/AK_TREE_v103.csv, rebuilt by
scripts/repair_v103.py from the live all-species list, the same list and code that give the frames' BAPH: TPH = sum EXPF, QMD = sqrt(BAPH / TPH / 0.00007854)).
The repair code also writes a summation SDI (sum EXPF (DBH/25.4)^1.605); the QMD form is used because the brief names it and because it is the "SDI" column of the brms job's
RD (07_post_lqmm.R). Plot-years with no live stem (TPH 0): SDI = 0. (00_stand.R: cor(QMD form, summation form) 0.984, median ratio 1.029.)
SDImax: K1, K2, K3 plot SDImax = column SDImax (LQMM tau 0.95) of growth_plot_sdimax_lqmm.csv matched on Data/Install/Plot (FIA growth plot = subplot; the FIA plot's value),
population 923 where missing; K1p, K2p, K3p 923 for every plot. RD = SDI / SDImax at t.0 and at t.1 (the end value is needed because Eq. 4 interpolates its stand terms
between t.0 and t.1 within the recursion; RD is treated exactly as BAPH).
Functional forms (each mirrors the deployed slot; the recursion code is unchanged and only the BAL and BAPH input columns are substituted, start and end values both):
- K1/K1p: BAL unchanged; BAPH -> RD, i.e. b6 sqrt(RD x S) (mirrors sqrt(BAPH x S)).
- K2/K2p: BAL -> BAL x RD in both the b3 and b4 terms; BAPH -> BAPH x RD in the b6 term.
- K3/K3p: BAL -> (BAL/BAPH) x RD in the b3 and b4 terms (BAL/BAPH := 0 where BAPH = 0); BAPH -> RD in the b6 term.
Held fixed for every candidate (deliberate): CRl.0/CRl.1 (computed with BALl through HCB_P), the BYI (C2) column, random b0 ~ 1 | Data/Install/TreeID, varPower(0.2, ~DBH.0),
ML, nlmeControl of inc_v103.R, NO frame frames/final/<resp>_NO_v103_model.csv after model_cols(d, "l").
Common rows: the model_cols rows (expected dDBH 4,971, dHT 4,033) with finite RD at t.0 and t.1 for every candidate (expected: all of them; stated in RESULTS).
Starts: K0 from START[[resp]] of inc_v103.R. K1 to K3p: two starts, (a) the K0 fitted vector with b3, b4, b6 rescaled so that each term's standard deviation over the common
rows at t.0 equals K0's, and (b) the K0 fitted vector unchanged; the converged fit with the higher logLik is kept (both logged).
Gate G1 (before any candidate result is used): K0 refit reproduces the deployed dDBH_L_NO and dHT_L_NO vectors above with every |diff| < 1e-5, and the K0 NO-frame
40-60 cm dDBH ratio reproduces 1.7013 (out/inc/evaluation_strata_v103.csv).
Sign checks (the established inc_byi_x_v104.R set, competition reduces growth): dDBH b1 > 0, b4 < 0, b5 > 0, b6 < 0; dHT b1 > 0, b4 < 0. (Deployed dHT b6 is positive, so
the dHT stand term is not sign-checked, as in every earlier screen; b3 and the dHT b6 are reported.)
ΔAIC = AIC(candidate) - AIC(K0), both on the common rows (same parameter count, so ΔAIC = -2 ΔlogLik).
LOSO: as v2 03_fit.R: for DOFAW, FIA, KMR PSP, PSP, refit on the other three from the candidate's full-data vector, re-solve the origin constants on the training frame
(solve_c with the non-finite guard), predict the held-out source, RMSE of log annual increment. Better = RMSE strictly below K0's; a failed fit counts as not better.
Strata: observed/predicted ratio of summed annual increment (as score() of inc_v103.R) with the full-data fit and its solve_c constants on the common rows, by size class
(dDBH 0-5, 5-10, 10-20, 20-30, 30-40, 40-60, 60+ cm; dHT 0-5, ..., 30+ m) and by quintile of the ORIGINAL BALl.0 (the same quintiles for every candidate).
Bootstrap: v2 04_boot.R scheme (installations resampled with replacement within source, copies distinct clusters, refit from the candidate's full-data vector),
B = 200, draws generated once per response with set.seed(20261101) on the common rows and shared by all candidates; 95% percentile intervals over converged draws.
C2 site coefficient = b8; "identified" = its bootstrap 95% interval excludes zero.
Projection clause: a plot-specific candidate (K1, K2, K3) that passes the other criteria is adopted only if its population variant is itself better than K0 on >= 3 of 4 sources;
the adopted equation is then the population variant (its own signs, ΔAIC and b8 interval must also pass, i.e. the population variant passes the rule on its own).
Tie (two or more pass for a response): more sources better, then lower AIC.
Compute order (max 3 cores; a brms job holds 4): main fits + LOSO + strata for all 7 candidates x 2 responses first (3 at a time, 1 core each); then bootstraps on 3 cores,
dDBH before dHT, K0 first, then candidates that pass signs, 3-of-4 and ΔAIC (rule-relevant), then the rest. Any bootstrap not finished when the report is written is listed as
not run; a candidate that fails signs, 3-of-4 or ΔAIC fails the rule regardless of its bootstrap.

Frozen: 2026-11-02 16:49:36 AST

## Amendment 1 (2026-11-02 16:54:24 AST, before any candidate other than K0 was fitted)
The first K0 dDBH refit, on the frame read back from frames/final/dDBH_NO_v103_model.csv, gave logLik -9584.775 (= deployed) but b0 -0.541519 vs -0.541411 and b8 0.277950
vs 0.277934 (|diff| 1.1e-4), so it would fail G1 at 1e-5 (logs/02_fit_K0_csvframe_abandoned.log; the run was stopped there). The deployed fit used the frame held in memory.
00b_frames_mem.R rebuilds the NO frames in memory with inc_v103.R lines 148-197 (write.csv masked, nothing written to the v105 job; the CSV and in-memory frames differ by at most
3.4e-13 with identical keys) and saves them as RDS; every fit in this screen uses those frames. With them the K0 dDBH refit reproduces the deployed vector to 5e-16
(logs/k0test.log). Nothing else changes.
