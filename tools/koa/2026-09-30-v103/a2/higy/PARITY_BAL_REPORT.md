# BAL parity, HiGy.R weighted percentile, v103 (30 September 2026)

Work is in the copy a2/higy/engine. engine_v103 was not touched.

## Change

HiGy.R gains koa_bal_percentile_weighted(dbh, expf), which mirrors bal_percentile_fraction_weighted. Ties count as at least as large, the fraction is (W_ge - w_i)/(W - w_i), n < 2 or W <= 0 gives 0, and the clips and the cumsum match numpy's sequential double sum. It also gains koa_bal_percentile_fraction() (unweighted), calc_bal_percentile() (BAL = plot BA x fraction), the KOA_BAL_PERCENTILE_WEIGHTED = TRUE switch and calc_bal_koa(). HiGYOneStand() routes both BAL calls through calc_bal_koa(). The conventional calc_bal() is kept and documented. The docstring covers the R12 single live record case. No mortality code changed.

## Results (out/parity_bal_compare.txt: PASSED, tolerance 1e-10)

- Lists: 3 hand, 4 edge (R12, n = 1, W = 0, equal expf) and 200 random lists (3,052 tied records, expf 1e-5 to 741). The largest fraction difference is 5.6e-16, and all hand values match to 4 dp.
- R rule on the project_psp states, 10 years, for PSP|202|2 (planted) and DOFAW|Waiakea|24 (natural), 1,030 tree-years: 4.0e-16. The Python rule on the HiGYOneStand states: 1.4e-15.
- The 18 mortality cases pass, and their CSVs are byte identical to the unedited baseline.

## HiGYOneStand vs project_psp (not fixed)

BAL per tree agrees exactly in year 1, and the trajectories diverge after that. By year 10 the planted list differs by 5.0 cm DBH, with TPH 1,423 (Python) vs 1,212 (R). Four causes:
1. project_psp resets CR from predict_HCB every year. HiGy.R keeps the input CR, with 2.5 percent a year recession. This accounts for all of the year 1 dDBH gap (verified).
2. calc_dht passes the tree ba, not ba.plot, into b6 (verified).
3. Mortality: HiGy.R uses the Stage 1 gate, tree_eq allocation and the in-step QMD change. project_psp uses no gate, size allocation and a one year lag.
4. The crown recession BAL reuses the stale start-of-step ba column (up to 5.9 m2/ha).

## md5

- engine/HiGy.R 81639e2fc2ebbeb159dffdae6790e9e2 (original 73595fda9422610a9f9ad0c1603e80ff)
- HiGy_v103_weightedbal.diff 66dd133baa5e04b84c4ef1a7cfe6f02b
- koa_parity_bal_v103.json 6d7b0e91ff32583e56ac3f6013f80932
- engine/koa_projector.py 462c0dd31e729cffc67fe20022907549. Only the comment changed, and the code-token md5 87cb1f857a90d9dc1a281dff96317aba is identical to the original.
