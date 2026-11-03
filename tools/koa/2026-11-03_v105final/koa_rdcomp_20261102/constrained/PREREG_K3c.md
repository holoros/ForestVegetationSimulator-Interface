# PREREG_K3c: biologically constrained versions of K3p for the koa dDBH Eq. 4 (engine v105b), koa_rdcomp_20261102/constrained

Written on firebreather before any K3c candidate was fitted; freeze timestamp (server clock) on the last line, md5 in RUN_K3c.md.
Work done before this file, none of it a K3c fit: reading ../PREREG.md (incl. Amendment 1), ../RUN.md, ../RESULTS.md, ../lib.R, ../02_fit.R, ../03_boot.R,
../04_results.R, ../05_diag_turn.R, ../g1.R and inc_v103.R lines 1-112 of ~/jobs/koa_v105_20261102 (read only).

## Why
K3p (BAL -> (BAL/BAPH) x RD in both BAL terms, BAPH -> RD in the b6 term, RD = SDI/923) passed the parent rule for dDBH (dAIC -103.74; better on FIA, KMR PSP,
PSP; b8 0.2595, bootstrap 0.066 to 0.499), but its squared term b3 = 2.21 > 0, so the competition effect f(x) = b3 x^2/ln(S+5) + b4 ln(x+1) (x = share x RD)
turns upward for suppressed trees at large x (../out/diag_bal_turning.csv). The two candidates below remove that reversal by construction or by a sign check.

## Candidates (dDBH only; dHT is not screened, v105b dHT stays)
Frames, rows, random effects, variance function, nlmeControl, GUARD 45 cm, the annual recursion with linear interpolation of stand terms between t.0 and t.1,
CRl, the C2 BYI column and RD = SDI(QMD Reineke form)/923 are exactly those of the K3p screen (../lib.R frameK("dDBH", "K3p")). Only the b3 slot changes:
- K0 (baseline, v105b): b3 BAL^2/ln(S+5) + b4 ln(BAL+1) + b6 sqrt(BAPH x S) with BAL = BALl, BAPH = live BA.
- K3p (reference, not a candidate here): x = share x RD; b3 x^2/ln(S+5) + b4 ln(x+1) + b6 sqrt(RD x S).
- K3c1: K3p with b3 fixed at 0 (squared term dropped; 9 fixed effects): b4 ln(x+1) + b6 sqrt(RD x S).
- K3c2: K3p with the squared term replaced by b3 x/ln(S+5) (10 fixed effects), b3 fitted unconstrained; it must be <= 0 (sign check, below).

## Code path
lib_c.R sources ../lib.R unchanged and adds one recursion gr.hat3c that is gr.hat2g of inc_v103.R with the b3 term selected by a mode flag:
"sq" b3 x^2/ln(S+5) (identical expression to gr.hat2g), "lin" b3 x/ln(S+5), "none" no b3 term (formula without b3). Gate G0 before any candidate result
is used: (i) K0 refit through gr.hat3c (mode "sq", frameK K0, START) reproduces the deployed v105b dDBH_L_NO vector (../lib.R DEP) with max |diff| < 1e-5,
logLik -9584.775 and 40-60 cm ratio 1.701321; (ii) K3p refit through gr.hat3c (mode "sq", from its stored vector) reproduces ../out/fit_K3p.rds dDBH with
max |diff| < 1e-4. K0's LOSO RMSEs used for the rule are recomputed through gr.hat3c and must equal ../out/fit_K0.rds to 1e-6 (else the recomputed ones are used and the
difference is reported).

## Starts
K3c1: (a) the K3p fitted vector without b3; (b) the K0 vector with b4, b6 rescaled as ../lib.R rescale_start (term SDs at t.0 equal to K0's), without b3.
K3c2: (a) the K3p fitted vector with b3 = 0; (b) the K0 vector rescaled as above, with b3 rescaled so that sd(b3 x/ln(S+5)) at t.0 equals sd(K0 b3 BAL^2/ln(S+5)).
Both starts are fitted; the converged fit with the higher logLik is kept (both logged).

## Metrics (as the parent screen)
- Signs (inc_byi_x_v104.R set): b1 > 0, b4 < 0, b5 > 0, b6 < 0; and for K3c2 also b3 <= 0. b3, b5 and b6 Wald and bootstrap intervals reported.
- Monotonicity check (new, required): d ln g / d x <= 0 for x = share x RD on a grid x = 0, 0.01, ..., 2, at DBH 2.5, 10, 25, 40, 60 cm, at the 5th, 50th and 95th
  percentile (over the common dDBH rows at t.0) of each other covariate (RD, CRl, C2 BYI; all three set to the same percentile level), for Planted 0 and 1.
  Evaluated on the actual ln g expression of gr.hat3c (central finite difference, h = 1e-6) and analytically (K3c1 b4/(x+1); K3c2 b3/ln(S+5) + b4/(x+1));
  pass = every grid value <= 0 (tolerance 1e-10). The full grid is written to out/monotonicity_grid.csv. The same grid is computed for K0 (x = BALl, informational)
  and K3p (reference) but is not part of their status.
- dAIC = AIC(candidate) - AIC(K0) on the common 4,971 rows (AIC counts the 9 vs 10 fixed effects).
- LOSO: DOFAW, FIA, KMR PSP, PSP held out in turn; refit on the other three from the candidate's full-data vector; origin constants re-solved on the training frame
  (solve_cK); RMSE of log annual increment on the held-out source; better = strictly below K0's; a failed fit is not better.
- Strata: observed/predicted summed annual increment ratios with solve_cK constants by size class (key 40-60 cm) and by quintile of the original BALl.0.
- Bootstrap: ../03_boot.R scheme, B = 200, the shared draw file ../out/boot_draws_dDBH.rds (generated with set.seed(20261101) on the same common rows),
  95% percentile intervals over converged draws; C2 site coefficient = b8. Compute order: candidates that pass signs, monotonicity, 3 of 4 and dAIC first;
  a candidate failing any of those fails regardless of its bootstrap, and its bootstrap is run only if cores and time allow (reported as not run otherwise).
  At most 3 cores (other jobs hold 5 of 8).

## Adoption rule (verbatim)
"A constrained candidate replaces K0 for dDBH only if signs pass, the monotonicity check passes, it is better than K0 on at least 3 of 4 held-out sources, ΔAIC ≤ −4, and the C2 site coefficient's installation-bootstrap 95% interval (B = 200, seed 20261101) excludes zero. If both pass, prefer more sources better, then lower AIC. If none passes, K0 (v105b) stays."

Frozen: 2026-11-02 18:31:26 AST
