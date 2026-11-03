# RESULTS_K3c (rev2): biologically constrained K3p for koa dDBH under the rev2 rule (engine v105b)

PREREG_K3c.md (this folder) frozen 2026-11-02 21:37:53 AST (md5 35f5fa3b2ba1d3137a898cd2869261c6) before any rev2 fit (first fit 21:38:33 AST).
Not blind for K3c1 (its fits, strata and bootstrap existed from the earlier screen in ../; disclosed in the PREREG). Every number below is in
out/results_K3c_rev2.csv, out/monotonicity_summary_rev2.csv (grid: out/monotonicity_grid_rev2.csv.gz), out/strata_rev2.csv, out/k3c2_profile.csv,
../out/boot_dDBH_K3c1.csv and logs/.

## Verdict
**No constrained candidate passes; K0 stays for dDBH and v105b remains the system of record. Stage 2 (v105c) was not run.**
- K3c1 (b3 dropped) passes (i) to (iv) but fails (v): 40-60 cm ratio 1.7567 vs K0 1.7013 (worse by 0.0554 > 0.05) and BAL Q5 ratio 1.2483 vs 1.1628 (worse by 0.0855).
- K3c2 (b3 <= 0) = K3c1: nlme cannot bound b3, so the brief's fallback applies (unconstrained K3p b3 = 2.2116 > 0). Profile check supports the boundary:
  logLik -9564.022 at b3 = 0, -9564.688 at b3 = -0.05, -9570.419 at b3 = -0.5 (out/k3c2_profile.csv). Same verdict as K3c1: FAIL (v).
- K3c3 (b6 ln(RD) instead of b6 sqrt(RD x DBH); does not mirror the deployed slot better): FAIL (i): b1 -0.0289, b5 -1.3677, b6 +0.2568 (signs fail), and growth increases
  with RD (d ln g/dRD up to +34.3, positive at 94,000 of 341,000 grid points). Its bootstrap was not run (fails (i)).
- K3p itself (reference) fails the monotonicity check: d ln g/dX > 0 at 39,000 of 186,000 grid points from X = 0.85 (max +2.285 at DBH 0.8 cm; +0.206 at 45.1 cm),
  and d ln g/dRD > 0 at 9,750 of 341,000 from X = 0.84.

## Table (dDBH, 4,971 common rows, 60 installations)

| cand | df | ΔAIC vs K0 | signs | monotone X / RD (max d ln g) | b4 | b5 | b6 | b8 (C2) | b8 boot 95% (B 200, seed 20261101) | LOSO RMSE DOFAW / FIA / KMR PSP / PSP | better of 4 | 40-60 cm ratio (Δ worse) | BAL Q5 ratio (Δ worse) | verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| K0 (v105b) | 15 | 0 | pass | yes / yes (-0.031 / -0.0010) | -0.3392 | 0.8397 | -0.0172 | 0.2779 | (v105 B 400: 0.052 to 0.532) | 1.0529 / 2.4145 / 0.6108 / 0.9857 | - | 1.7013 | 1.1628 | baseline |
| K3p (reference) | 15 | -103.74 | pass | **no / no** (+2.285 / +2.256) | -3.7228 | 0.7952 | -0.0795 | 0.2595 | 0.066 to 0.499 (parent) | 1.0635 / 1.7630 / 0.6053 / 0.9823 | 3 | 1.7008 (-0.001) | 1.2253 (+0.063) | fails (i), (v) |
| K3c1 | 14 | -43.51 | pass | yes / yes (-1.239 / -0.020) | -3.0978 | 0.4772 | -0.0547 | 0.2873 | **0.100 to 0.518** (200/200) | 1.0379 / 1.8918 / 0.6068 / 0.9762 | 4 | 1.7567 (**+0.055**) | 1.2483 (**+0.086**) | **FAIL (v)** |
| K3c2 (= K3c1) | 14 | -43.51 | pass | yes / yes | as K3c1 | | | | 0.100 to 0.518 | as K3c1 | 4 | 1.7567 (+0.055) | 1.2483 (+0.086) | **FAIL (v)** |
| K3c3 | 14 | -95.22 | **fail** (b1, b5, b6) | yes / **no** (-1.107 / +34.28) | -2.7670 | -1.3677 | +0.2568 | 0.4318 | not run | 1.0386 / 1.7891 / 0.6269 / 0.9747 | 3 | 1.6213 (-0.080) | 1.2046 (+0.042) | **FAIL (i)** |

Δ worse = |r_cand - 1| - |r_K0 - 1| (PREREG). K3c1/K3c2 origin constants natural 0.3718, planted 1.2058; K3c3 0.3767, 1.2219.

## Monotonicity grid (criterion i)
One annual step of the actual recursion; DBH 20 values 0.8 to 45.13 cm (p1 to p99), CRl 5 values 0.463 to 0.809, BYI 5 values 28.98 to 395.35, Planted 0/1;
d ln g/dX with X 31 values 0 to 1.5 (p99 0.903) at RD p1..p99 and 1.5; d ln g/dRD (share held, X = share x RD) with RD 31 values 0.0075 to 1.5 and share 0 to 1.
Finite-difference and analytic derivatives agree to 3.1e-6. At the observed maximum X (3.245): K3c1 d ln g/dX max -0.730 (still decreasing); K3p +7.29.

## Interpretation
Removing the upturn (K3c1) keeps a real in-sample and held-out gain (ΔAIC -43.5; better on all four held-out sources, FIA 1.89 vs 2.41) and a well-identified site
term, but shifts more of the large-tree and heavily-suppressed underprediction onto the model: obs/pred rises in the 40-60 cm class and the top BAL quintile beyond
the 0.05 tolerance. Under the rev2 rule K0 stays. The ln(RD) form fits well in-sample but only by reversing the RD and crown-ratio effects, so it is not usable.

## Deviations and notes
1. Not blind for K3c1: reused fits/bootstrap from the earlier screen (../), whose rule lacked criterion (v); disclosed before freezing.
2. K3c2 fitted by the brief's fallback (nlme has no bounds); boundary supported by a two-point profile.
3. K3c3 was fitted although the PREREG states it does not mirror the deployed slot better.
4. An earlier session started a v105c rebuild on K3c1 in a separate copy, ~/jobs/koa_v105c_20261102 (master_c.sh, running at 21:36 AST, 3 boot_v103 cores).
   It was not used, stopped or modified here; under this rule it builds on a candidate that does not pass. ~/jobs/koa_v105_20261102 was not written.
