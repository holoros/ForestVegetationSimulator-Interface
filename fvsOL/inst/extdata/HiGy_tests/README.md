# HiGy_tests: fixture set for the HiGy.R 0.4.0 mortality component

Checks the three stage mortality of HiGy.R against the Python engine of record
on 18 synthetic cases. The tree lists are written for this harness and contain
no plot coordinates, no plot identifiers and no field observation.

## Run the check (R only)

```
cd fvsOL/inst/extdata/HiGy_tests
Rscript parity_r.R ../HiGy.R koa_parity_cases.json   # writes out_r_stand.csv, out_r_tree.csv
Rscript check_parity.R                               # compares with expected_python_*.csv
```

Needs dplyr, purrr and jsonlite. The check passes when every stand and tree
quantity agrees with the expected values to a relative tolerance of 1e-10.
On 23 September 2026 the worst relative difference was 1.7e-14 over 18 cases
and 126 tree rows.

## What is compared

For each case: H_QMD at the start and end of the step, the Stage 2 Garcia
(2009) rate with the A1 floor, the Stage 1 occurrence probability, the gated
and calibrated stand rate, stand deaths, and the Stage 3 allocation to every
tree under the respecified weight of record and the relative size weight. The
harness drives koa_step_deaths() and koa_alloc_frac() directly and feeds the
same H_QMD pair to both sides, so it does not compare the one year lag of the
Python projector. The cases cover low, medium and high density,
natural and planted origin, a stand with no height growth, two surge cases and
three cases that bind the 0.95 cap, a case with no SDI (gate passes the rate
through) and one ungated case.

The harness can fail. With the 12 September Stage 1 constants it fails on the
16 gated cases; with the origin level factor set to 1 it fails on the 9 natural
cases the factor reaches; with the Eq. 5 weight in place of the respecified
weight it fails on the 10 tree weight cases.

## Files

* `koa_parity_cases.json`: the 18 cases, read by both sides.
* `parity_r.R`, `check_parity.R`: R side and comparison.
* `smoke_higyonestand.R`: five year HiGYOneStand() run, natural and planted.
* `expected_python_stand.csv`, `expected_python_tree.csv`: values written by
  `parity_python.py` from the engine of record.
* `parity_python.py`: Python side. Run with `KOA_ENGINE` pointing at the
  Python engine of record (engine_v102), which needs koa_params.py,
  koa_equations.py, koa_mortality_garcia.py and koa_survival_calibrated_py.py
  from the Zenodo deposit (concept DOI 10.5281/zenodo.21081014).
* `threestage.py`, `out_stage1/stage1_fit.json`: the Python reference for
  Stage 1 and the gate, byte identical to engine_v102. It imports koa_params
  from the engine of record and is kept here as the reference the R port was
  written against.
