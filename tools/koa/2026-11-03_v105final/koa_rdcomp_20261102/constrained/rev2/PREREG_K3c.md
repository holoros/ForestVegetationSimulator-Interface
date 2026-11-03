# PREREG_K3c (rev2): biologically constrained K3p for the koa dDBH Eq. 4 (engine v105b), koa_rdcomp_20261102/constrained/rev2

Written on firebreather before any rev2 fit; freeze timestamp (server clock) on the last line, md5 in PREREG_K3c_md5.txt.
Placed in rev2/ so that the earlier frozen ../PREREG_K3c.md (18:31:26 AST, md5 588c1184...) is not overwritten.

## Disclosure (what exists before this file; this rev2 screen is NOT blind for K3c1)
An earlier session already ran a constrained screen under a different rule (../PREREG_K3c.md, ../RESULTS_K3c.md): K0c, K3c1 (b3 fixed 0), K3c2-lin
(b3 x/ln(S+5), unconstrained) and K3pc fits with LOSO and strata (../out/fit_*.rds, strata_K3c.csv), the K3c1 bootstrap (../out/boot_dDBH_K3c1.csv,
200/200, seed-20261101 draws) and a monotonicity grid over x = 0..2 at fixed DBH. I read those results before writing this file, including K3c1's
strata ratios (40-60 cm 1.7567 vs K0 1.7013; BAL Q5 1.2483 vs K0 1.1628), ΔAIC -43.51, 4 of 4 held-out sources better, b8 interval 0.100 to 0.518.
That earlier rule did not contain criterion (v) below; this rule supersedes it. The earlier session also started a v105c rebuild on K3c1 in a separate
copy (~/jobs/koa_v105c_20261102); it is not part of this screen and is neither used nor modified here.
Reused without refitting (same code path lib_c.R, same in-memory frames, gate G0 passed there): K0 (= K0c, reproduces deployed v105b to 5e-16),
K3c1, K3p (parent ../../out/fit_K3p.rds; K3pc for the code-path check). New fits in rev2: K3c3 and the K3c2 boundary profile (below).

## Candidates (dDBH only; dHT stays v105b K0). x = (BAL/BAPH) x RD, RD = SDI/923, SDI = TPH (QMD/25.4)^1.605 (parent definitions, ../../lib.R frameK K3p)
- K3c1: g = exp(b0 + b9 Pl + b1 ln(S+1) + b2 S + b4 ln(x+1) + b5 ln(CR) + b6 sqrt(RD x S) + b7 Pl min(S,45) + b8 ln(BYI)); b3 dropped (9 fixed effects).
- K3c2: K3p with b3 <= 0. nlme (the fitting machinery) has no box constraints, so the brief's fallback is used: K3p and K3c1 are fitted; because the
  unconstrained K3p b3 = 2.2116 > 0, K3c2 is K3c1 (constrained optimum at the boundary b3 = 0). Check (informational, not part of the rule): K3p with
  b3 fixed at -0.05 and -0.5 (x^2/ln(S+5) slot), all else free from the K3c1 vector; logLik must be below K3c1's for the boundary claim to be supported;
  if either is higher, K3c2 is refitted with b3 fixed at the better negative value and that fit is evaluated as K3c2 (reported).
- K3c3: K3c1 with b6 ln(RD) in place of b6 sqrt(RD x S): g = exp(b0 + b9 Pl + b1 ln(S+1) + b2 S + b4 ln(x+1) + b5 ln(CR) + b6 ln(RD) + b7 Pl min(S,45) + b8 ln(BYI)).
  Statement: this does NOT mirror the deployed slot better (deployed is b6 sqrt(BAPH x S), which K3c1 mirrors exactly); K3c3 is fitted anyway as the
  stated alternative so its verdict is reported. RD > 0 on every common row at t.0 and t.1 (min 0.00133), so ln(RD) needs no offset; in the engine RD > 0
  whenever a live tree exists. Starts: (a) K3c1 vector with b6 = K3c1 b6 x sd(sqrt(RD S))/sd(ln RD) at t.0; (b) same with b6 = 0; higher logLik kept.
  Recursion: gr.hat3c of ../lib_c.R with M3 = "none" and the b6 slot switched to ln(bapa) (mode flag M6 = "log"); interpolation of RD t.0 to t.1 unchanged.

## Metrics
- Signs: b1 > 0, b4 < 0, b5 > 0, b6 < 0 (K3c2 also b3 <= 0, satisfied by construction).
- Monotonicity (criterion i): annual ln g partial derivatives, by central finite difference (h 1e-6) on the actual recursion expression and analytically:
  (a) d ln g/dX holding RD; (b) d ln g/dRD holding the share (X moves with RD) including the b6 slot. Grid: size (DBH) 20 values spanning its 1st to 99th
  percentile (0.8 to 45.13 cm), CR (CRl) 5 values p1 to p99 (0.463 to 0.809), BYI 5 values p1 to p99 (28.98 to 395.3), Planted 0/1; for (a) X 31 values
  from its p1 (0) to max(p99, 1.5) = 1.5 with RD at 5 values p1..p99 and 1.5; for (b) RD 31 values from p1 (0.0075) to 1.5 and share 11 values 0..1.
  Pass = every grid derivative <= 1e-10. Also run for K3p (reported) and K0 (X = BALl, RD-free; informational). Values at the observed max X (3.245) reported.
- ΔAIC vs K0 on the 4,971 common rows (criterion iii). Held-out (ii): LOSO RMSE of log annual increment, DOFAW/FIA/KMR PSP/PSP, refit on the other three
  from the full vector, origin constants re-solved (solve_cK); better = strictly lower than K0. Strata (v): obs/pred summed annual increment ratios with
  solve_cK constants, 40-60 cm class and top quintile (Q5) of original BALl.0; "worse by more than 0.05" = |r_cand - 1| - |r_K0 - 1| > 0.05.
- C2 bootstrap (iv): b8, ../03_boot.R scheme, shared draws ../../out/boot_draws_dDBH.rds (seed 20261101), B = 200, percentile 95%. Run for K3c3 only if it
  passes (i), (ii), (iii) and (v); a candidate failing any of those fails regardless.

## Rule (verbatim)
"A constrained candidate replaces K0 for dDBH only if (i) signs pass and the predicted diameter increment is non-increasing in competition (X and RD) over the full observed range of every covariate, checked on a grid spanning the 1st to 99th percentiles of size, CR, BYI and X, and over X up to 1.5; (ii) better than K0 on at least 3 of 4 held-out sources; (iii) ΔAIC ≤ −4 vs K0; (iv) the C2 site coefficient bootstrap interval excludes zero (B = 200, seed 20261101); (v) the 40 to 60 cm class ratio and the top BAL quintile ratio are not worse than K0 by more than 0.05. If several pass, choose the one better on more held-out sources, then lowest AIC. If none passes, K0 stays."
Stage 2 (v105c rebuild in ~/jobs/koa_v105_20261102) runs only if a candidate passes. Cores: at most 1 to 2 (7 of 8 busy at freeze).

Frozen: 2026-11-02 21:37:53 AST
