# RESULTS_K3c: biologically constrained K3p for koa dDBH (Eq. 4, engine v105b)

PREREG_K3c.md frozen 2026-11-02 18:31:26 AST before any fit. Every number is in out/results_K3c.csv, coefficients_K3c.csv, strata_K3c.csv, gate_G0.csv,
monotonicity_summary.csv, monotonicity_grid.csv or boot_dDBH_K3c1.csv.

## Verdict
**K3c1 passes the adoption rule and replaces K0 (v105b) for dDBH.** K3c1 = K3p with the squared term dropped: b4 ln(x + 1) + b6 sqrt(RD x DBH), x = (BAL/BAPH) x RD,
RD = SDI/923, b3 fixed at 0. Signs pass; monotonicity passes (largest d ln g/dx on the grid -1.033); better than K0 on 4 of 4 held-out sources; ΔAIC -43.51;
C2 site coefficient b8 0.2873, installation bootstrap 95% 0.100 to 0.518 (200 of 200 converged), excludes zero. K3c2 fails (b3 = 1.977 > 0, sign check), so there
is no tie.

## Gate G0 (out/gate_G0.csv)
- K0 refit through the new recursion vs deployed v105b vector: max abs diff 5.0e-16; logLik -9584.775; 40-60 cm ratio 1.701321; K0 LOSO RMSEs equal the parent's (diff 0). PASS.
- K3p through the new recursion from the parent's kept start (K0 vector): max abs diff 0 (logs/g0b_k3p_startb.log). From its own stored vector as start (K3pc) it
  stops 1.75e-4 away (b5) at the same logLik -9532.906, i.e. above the preregistered 1e-4: a start-dependent optimizer tolerance, not a code difference.

## Table (dDBH, common rows 4,971, 60 installations)

| cand | df | logLik | ΔAIC vs K0 | signs | monotone (max d ln g/dx) | b3 | b4 | b5 | b6 | b8 (C2) | b8 boot 95% | LOSO RMSE DOFAW / FIA / KMR PSP / PSP | better (of 4) | ratio 40-60 cm | ratio BAL Q1..Q5 | verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| K0 (v105b) | 15 | -9584.775 | 0.00 | pass | yes (-0.114) | -0.00144 | -0.3392 | 0.8397 | -0.0172 | 0.2779 | not run | 1.0529 / 2.4145 / 0.6108 / 0.9857 | - | 1.701 | 1.011 / 1.027 / 1.071 / 1.038 / 1.163 | baseline |
| K3p (parent, reference) | 15 | -9532.906 | -103.74 | pass | **no (+3.150; positive from x = 0.90)** | 2.2116 | -3.7228 | 0.7952 | -0.0795 | 0.2595 | 0.066 to 0.499 (parent) | 1.0635 / 1.7630 / 0.6053 / 0.9823 | 3 | 1.701 | 1.047 / 0.996 / 1.040 / 1.072 / 1.225 | reference |
| **K3c1** | 14 | -9564.022 | **-43.51** | pass | **yes (-1.033)** | 0 (fixed) | -3.0978 | 0.4772 | -0.0547 | 0.2873 | **0.100 to 0.518 (200/200)** | 1.0379 / 1.8918 / 0.6068 / 0.9762 | **4** | 1.757 | 1.061 / 0.998 / 1.027 / 1.043 / 1.248 | **PASS** |
| K3c2 | 15 | -9562.816 | -43.92 | **fail (b3 = 1.977 > 0)** | yes (-0.324) | 1.9765 | -3.9157 | 0.4124 | -0.0450 | 0.2930 | not run (fails signs) | 1.0462 / 1.9007 / 0.6062 / 0.9789 | 4 | 1.729 | 1.061 / 0.997 / 1.027 / 1.047 / 1.238 | FAIL |

K3c1 coefficients (estimate; Wald 95%; installation bootstrap 95%, 200/200): b0 -0.5589 (-2.128, 1.010; -2.249, 1.037); b1 0.2915 (0.226, 0.357; 0.139, 0.512);
b2 -0.03083 (-0.0379, -0.0238; -0.0625, -0.0113); b4 -3.0978 (-3.341, -2.855; -4.049, -2.610); b5 0.4772 (0.042, 0.912; -0.448, 1.564); b6 -0.0547 (-0.104, -0.005;
-0.257, 0.188); b7 -0.01414 (-0.0187, -0.0096; -0.0308, -0.0008); b8 0.2873 (0.078, 0.497; 0.100, 0.518); b9 0.0758 (-0.439, 0.590; -0.350, 0.712).
Origin constants (solve_c) natural 0.3718, planted 1.2058.

## Monotonicity grid (out/monotonicity_grid.csv; x = share x RD from 0 to 2 by 0.01, DBH 2.5/10/25/40/60 cm, other covariates RD, CRl, C2 at their p5/p50/p95, Planted 0/1)
Largest d ln g/dx over x, by DBH (the same at p5, p50 and p95 of the other covariates and for both origins, because the derivative does not involve them):

| DBH cm | K3c1 | K3c2 | K3p (reference) |
|---|---|---|---|
| 2.5 | -1.033 | -0.324 | +3.150 |
| 10 | -1.033 | -0.575 | +2.026 |
| 25 | -1.033 | -0.724 | +1.360 |
| 40 | -1.033 | -0.786 | +1.083 |
| 60 | -1.033 | -0.832 | +0.878 |

K3c1: d ln g/dx = b4/(x + 1), negative everywhere (-3.098 at x = 0, -1.033 at x = 2). K3c2: b3/ln(DBH + 5) + b4/(x + 1) stays negative on the grid but b3 itself is
positive (fails the sign rule). K3p: 2,388 of 6,030 grid points positive, from x = 0.90. Finite-difference and analytic derivatives agree to 1.7e-7.

## What changes and what does not
- In-sample, K3c1 keeps 42% of K3p's AIC gain (ΔAIC -43.5 vs -103.7) and is better than K0 on every held-out source, including DOFAW (1.0379 vs 1.0529), where K3p was worse.
- Crown ratio (b5) and the RD size term (b6) are not identified by the bootstrap (intervals span zero); b4 (the relative-competition term) and b8 (site) are.
- **The large-tree bias is not fixed and gets slightly worse**: 40-60 cm ratio 1.757 (K0 1.701) and top BAL quintile 1.248 (K0 1.163). The 30-40 cm ratio improves
  slightly (1.332 vs 1.362). These strata ratios are not part of the adoption rule.
