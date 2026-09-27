# Origin-calibration multiplier uncertainty, koa v102 planted projection

Date: 2026-09-26
Host: ifm-kershaw (firebreather), Debian 11
Python: system python3 (numpy, pandas); no R used
Engine: ~/jobs/koa_v102_20260918/track2/engine_v102 (read-only, nothing edited)
Driver: run_calint.py in this folder
Wall time: under 60 s

## How the multipliers were selected

Through the engine's own configuration point, not by copying or editing the engine.
koa_equations.LineageA.CAL_DDBH and .CAL_DHT are class attributes read at call time
by _cal() inside LineageA.dDBH and .dHT; koa_equations.cal_draw() writes exactly
these two attributes for the joint Monte Carlo. The driver writes the same two
attributes, varying only the PLANTED element of each pair and leaving the natural
element at its deployed value (0.40548, 0.51917). State is returned to the deployed
base and checked with KE.joint_assert_clean() before and after every cell.

## Engine of record

regen_m1.py is imported as a module, which applies the engine of record at module
level: P.ALLOC_MODE = "tree_eq" and koa_mortality_garcia.stand_mortality replaced by
the M1-gated, mortality-calibrated _gated(). MORT_ENGINE is garcia_qmd_anchored.
The projection call is the deployed main-grid call, identical to regen_m1's point
estimate: RC.project(RC.wlist(1, byi), byi, True, n_years, "M0").

## Verification

Deployed setting reproduces out_m1/table8_evenaged_M1.csv planted rows at ages 40
and 100 exactly: max |diff| over QMD, BAPH, TPH, VOL, MAI = 0.000000.
HT_FALLBACK_CALLS = 0.

## Settings (planted element only)

deployed  dDBH 1.43606  dHT 2.64739
lower     dDBH 0.518    dHT 0.541    (Table S20 95% interval lower bounds, PSP held out)
upper     dDBH 2.051    dHT 3.597    (Table S20 95% interval upper bounds, PSP held out)

## Nature of the output

Deterministic engine evaluations. They carry no sampling interval. The 95% interval
under test is on the origin-calibration multiplier, not on the projection.

## Outputs

out/traj_calint_planted.csv                    full 250-year trajectories, 9 cells
out/table_calint_points.csv                    QMD BA TPH HT VOL MAI at ages 40, 100
out/table_calint_culmination.csv               literal global argmax of net MAI
out/table_calint_culmination_excl_yr1.csv      argmax over years 2 and later
out/table_calint_culmination_interior.csv      growth culmination after the year-1 transient
out/table_calint_gates.csv                     BAPH, SDI, QMD vs the observed maxima
out/check_deployed_vs_deposited.csv            reproduction check
run.log                                        full console output

Zenodo: not applicable. This is an interval-propagation diagnostic for the
manuscript's planted-scenario relabelling, not a citable standalone product.
GitHub: not pushed. The github-manager close-out needs Aaron's explicit yes for the
PAT and a named owning repo; both are pending.
