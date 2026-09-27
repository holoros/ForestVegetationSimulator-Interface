# PREREG-KOA-01: three-variant staged refinement of the koa v102 system

Pre-registered 26 September 2026. `PREREG.md` fixes the criteria, gates and stopping rules; it was written
and committed before any variant ran, and carries a dated amendment recording a correction made after
reading code and before seeing any result. The three result files report each variant against those
criteria as written.

## Variants and outcomes

**A, the yield-density sign.** `RESULT_A.md`. Quadratic mean diameter at age 100 rises with initial density,
which inverts the yield-density relationship. The pre-registered release mechanism was falsified: the dense
arm grows faster from age 11 and its stem count never falls below the sparse arm's, so it is never released.
Decomposing the engine's own output, the growth component of the change in quadratic mean diameter falls with
density while the selection component rises fourteen-fold. Removing small stems raises the survivors' mean
arithmetically, so this is not a model defect and no configuration repairs it. Dominant diameter does not
escape it either. Ran against the existing `track3/lt/out/SC_trajectories.csv`; no new engine run.

**B, self-thinning beta.** `B_grid.py`, `B_scen.py`, `B_run.sh`, `RESULT_B.md`. The deployed Garcia beta is
anchored to the observed density envelope (0.16019) rather than fitted (0.117), and Section 6 of the
supplement then validates containment against the same envelope. Both arms were run. The fitted beta leaves
the envelope by up to 42.5 percent on basal area and 14.4 percent on stand density index, entirely in planted
rows, so under the pre-registered criterion it is reported as a sensitivity and not adopted. Beta was not
tuned. The result also records that this cannot break the circularity, and names the independent test that
would: a limiting line fitted to the boundary plots by quantile regression with its own interval.

**C, origin transferability.** `C_loso.R`, `C_multistart.R`, `C_RUN.md`, `RESULT_C.md`. Leave-one-source-out
on the origin calibration multipliers, clustered at installation within source, 5,000 resamples. The contrast
does not survive: with DOFAW held out and a multi-start refit the sign reverses in both responses. Origin and
source are near-perfectly confounded, since of eight sources only DOFAW, FIA and PSP carry both origins and in
each the minority origin is a handful of plot-years. Under the pre-registered criterion this changes the
manuscript.

**Propagation.** `D_run_calint.py`, `D_RUN.md`. The planted multiplier interval was carried through the
deployed engine. The deployed setting reproduces the deposited table exactly and every gate comparison passes.
The interval does not bracket the deployed projection, because a larger multiplier reaches the per-tree
diameter ceiling sooner and volume is therefore not monotone in the multiplier, so the planted rows cannot be
reported as a band. Net mean annual increment culmination moves from 8 to 13 years to 7 to 32.

## What the manuscript took

Relabelling rather than restructuring. Table 5 now states that the planted scenario is a PSP and KMR network
scenario rather than a plantation scenario, Section 4.3 replaces the claim that the calibration holds under
holdout with the source-holdout result and the confounding, and the planted culmination carries the 7 to 32
year range.

## Known limits of this work

Variant C's sign reversal depends on a multi-start refit finding a better optimum than Supplemental Table S20's
own producer uses, which means S20 as published is not a transferability test. The DOFAW fold's intervals are
wide, 0.581 to 1.845, so that fold is weakly informative on its own; the identifiability argument rather than
that fold is what carries C.

## Data handling

No plot coordinates are read, printed or written by any script here, and `AK_GEO.shp` is never opened. The C
scripts assert the increment frames carry no coordinate columns before use and emit only origin-level
aggregates, interval bounds and cluster counts. Job folders on firebreather:
`koa_prereg_B_beta_20260926`, `koa_loso_origin_20260926`, `koa_calint_20260926`.
