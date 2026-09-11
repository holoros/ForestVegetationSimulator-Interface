# HiGy.R 0.4.0 port, parity report

**Date.** September 9, 2026.
**Scope.** Ports `ben-package-2026-09-08/HiGy.R` from the fitted H40 arm (`KOA_GARCIA_BETA = 0.117`,
`koa_h40()`, no floor) onto the Zenodo deposit's deployed arm of record, `garcia_qmd_anchored`
(beta anchored at 0.16019053617304435, driven by `H_QMD` via the new `koa_h_qmd()`, with the A1
background mortality floor, 0.003 yr⁻¹ natural and 0.006 yr⁻¹ planted). The bounded edit is the
beta constant, the height variable driving the Garcia (2009) step, and the floor. Stage 1
(`koa_irregular_event`) and Stage 3 (`koa_renormalize_to_stand_rate`, `koa_alloc_frac`,
`koa_allocate_mortality`) are unchanged. `koa_mortality_step()`, the standalone wrapper documented
as not on the production path, keeps the fitted H40, unfloored arm by explicit default, so the two
arms stay separately reproducible from the same file.

## What changed in HiGy.R (0.3.0 to 0.4.0)

1. New constants: `KOA_GARCIA_BETA_ANCHORED`, `KOA_GARCIA_ALLOM_A`, `KOA_GARCIA_ALLOM_K_HD`,
   `KOA_BASE_NAT`, `KOA_BASE_PLT`, transcribed from the deposit's `figshare_v66/koa_params.py`
   (`GARCIA_BETA_ANCHORED`, `GARCIA_ALLOM_A`, `GARCIA_ALLOM_K_HD`, `BASE_NAT`, `BASE_PLT`).
2. New function `koa_h_qmd(qmd, a, k_hd)`, ported line for line from
   `figshare_v66/koa_mortality_garcia.py:h_from_qmd()`.
3. `koa_regular_survival()` gains `base_nat`/`base_plt` arguments (default `KOA_BASE_NAT`,
   `KOA_BASE_PLT`, i.e. the floor is on by default) and its `beta` default changes from
   `KOA_GARCIA_BETA` to `KOA_GARCIA_BETA_ANCHORED`. The Garcia recursion itself (the
   `S0^alpha - (beta H0)^alpha + (beta H1)^alpha` algebra) is untouched; only the floor step
   after it is new, matching the deposit's `background_mortality()`/`mort_garcia()`.
4. `koa_mortality_step()` (the standalone, non-production wrapper) now passes
   `base_nat = NA, base_plt = NA` explicitly, so it keeps reproducing the unfloored fitted-H40
   arm exactly as it did on September 8, unaffected by the new defaults above.
5. `calc_mortality()`'s `garcia` branch now computes end-of-step QMD (`qmd.1.koa`, mirroring the
   existing `qmd.koa`) and `h_qmd.0`/`h_qmd.1` via `koa_h_qmd()`, and feeds those into
   `koa_step_deaths()` in place of `h40.0`/`h40.1`. `h40.0`/`h40.1` are still computed (harmless,
   kept for diagnostics) but no longer drive the step.
6. `VersionTag` moves to `"HiGyV0.4.0"`; a 0.4.0 entry is added to the update summary.

Full diff-by-anchor is reproducible from `_ben_port_20260909/patch_higy.py` (not itself part of
the package; a record of exactly what changed and why, string-anchored against the September 8
file so a bad match fails loudly rather than silently).

## Cross-language parity against the deployed Python source

Both sides ran on firebreather (R 4.5.1, Python 3 with numpy 2.0.2), the R side sourcing the
ported `HiGy.R` unmodified and the Python side importing `figshare_v66/koa_mortality_garcia.py`
and `koa_params.py` unmodified, staged directly from the certified 1.7.0 deposit tree. Seven test
cases spanning growth, flat height, rising QMD under planted and natural origin, mid-range and
small QMD, and a falling-QMD case were run through `koa_h_qmd()` / `h_from_qmd()` and
`koa_regular_survival()` / `stand_mortality("garcia_qmd_anchored", ...)` on each side.

| label | N0 | QMD0 | QMD1 | H_QMD0 (R) | H_QMD0 (Py) | m_step (R) | m_step (Py) | match |
|---|---|---|---|---|---|---|---|---|
| A_grow_nat | 1500 | 15 | 20 | 11.64196357 | 11.64196357 | 0.206310839562 | 0.206310839562 | exact |
| B_flat_nat | 1500 | 15 | 15 | 11.64196357 | 11.64196357 | 0.003000000000 | 0.003000000000 | exact |
| C_flat_plt | 1500 | 15 | 15 | 11.64196357 | 11.64196357 | 0.006000000000 | 0.006000000000 | exact |
| D_grow_mid | 800 | 25 | 30 | 18.00219571 | 18.00219571 | 0.171031619056 | 0.171031619056 | exact |
| E_grow_small_plt | 300 | 40 | 41 | 26.88419940 | 26.88419940 | 0.017855357795 | 0.017855357795 | exact |
| F_grow_smallqmd | 2000 | 8 | 8.5 | 6.80894046 | 6.80894046 | 0.013136649261 | 0.013136649261 | exact |
| G_fall_nat | 1500 | 20 | 19 | 14.88106594 | 14.88106594 | 0.003000000000 | 0.003000000000 | exact |

Every printed digit agrees (12 decimal places on `m_step`, 8 on `H_QMD`, 6 on `deaths`) across all
seven cases, including the floor binding (B, C, G) and not binding (A, D, E, F), and both stand
origins. Raw harness output: `parity_python.py` / `parity_r.R` and their stdout, retained in
`_ben_port_20260909/` on firebreather job `koa_ben_port_20260909` and downloaded alongside this
report.

## Self-test

`koa_mortality_selftest_2026-09-09.R` (built from the September 8 version) sources the ported
`HiGy.R` and runs against `plot_interval_pairs_DATA.csv`. Section 1 and the section 3 in-sample
check are pinned explicitly to the fitted H40 arm (`beta = KOA_GARCIA_BETA, base_nat = NA,
base_plt = NA`) since they test properties of that arm's original fit; the beta-sensitivity block
is kept for continuity with September 8 and annotated as the frame mismatch the September 9
changelog correction describes. New section 1b and the section 5 additions exercise the ported
arm directly: cycle-length invariance holds on it too, a flat H_QMD returns the natural or planted
A1 floor rather than zero, a growing stand's raw Garcia step exceeds the floor and is not clamped
to it, and `calc_mortality()`'s production output now differs from what the pre-port fitted-H40
arm would have given on the same tree list (6.568 vs 1.755 deaths ha⁻¹ on the worked example). The
missing-`ddbh`/`dht` guard check was updated to expect the A1 floor rather than zero, since a flat
or unknown step floors identically under the deployed arm (confirmed against the Python source's
`stand_mortality()`, which returns the background rate whenever `h_prev is None` or the step shows
no growth). Full output: `selftest_output_2026-09-09.txt`. **Result: self-test PASSED, every
check.**

## What this does and does not establish

This confirms the R port reproduces the deployed Python arm's core mortality step (`H_QMD`
allometry, the Garcia recursion, and the A1 floor) exactly on the test cases run, and that the
port did not disturb Stage 1, Stage 3, or the retired `cloglog` path. It does not re-run the
deposit's own gate harness (that harness certifies the Python deposit, not this R package) and it
does not re-validate the anchored beta's fit statistics (35.1 percent above observed, RMSE 96.1
trees ha⁻¹, tree-year-weighted bias −0.0031 yr⁻¹), which are unchanged from the September 9
changelog and were not re-derived here.
