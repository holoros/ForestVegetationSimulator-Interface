# koa v104, analysis A5 (31 October 2026)

Scripts and run notes for A5 on the koa (Acacia koa) growth and yield system, v104. This builds on
`tools/koa/2026-10-30_v104/` (PR 15). Only code and notes are here. Data, CSV outputs, logs and engine copies are not.

## What A5 is

1. **Stage 3 vector fix** (`stage3fix/`, `engine_fix/`). `run_candidates.project` and `regen_figS4S5` still used a
   hard-coded Stage 3 ordering vector (the old 4,911-record fit). `stage3fix/patch_stage3_rc.py` makes both read
   `koa_params.STAGE3_COEF`, the A4-D3 vector, and keeps backups named `*_PREV_20261031`. `stage3fix/run_a5.sh` then reruns
   chain 1, chain 2, the figures, figS34 and the sensitivities. `engine_fix/` holds the current patched
   `run_candidates.py` and `regen_figS4S5.py`, plus `stage3_vector_fix.diff` (a unified diff against the backups).
2. **Full-chain leave-one-installation-out evaluation** (`loio/`). The 17 plot-level benchmark plots are each held
   out with their whole installation. For each fold the full calibration chain is refit (`fit_folds.R`,
   `run_chain_fold.sh`, `calib_mort_loio.py`) and the plot is scored against prespecified equivalence regions
   (`PREREG.md`). Before the folds run, a sanity gate checks that the v104 constants reproduce
   `val_v104_plotlevel.csv` exactly.
3. **Paired Monte Carlo of BYI levels** (`pairmc/`). This tests the BYI ordering with paired joint draws
   (`joint_draws_pairmc.R`) and BYI residual process error (`pairmc.py`, `pairmc_a5.py`, `summarize*.py`).
4. **Reruns of preliminary results** (`rerun/`). The supplement results that were computed on the preliminary
   covariate assembly are rerun on the final frames and v104. They are the Eq. 2 height bootstrap (`h/`), S26 coverage (`cov/`),
   S21 Stage 1 and 2 (`s21/`), S28 mortality holdout and local calibration (`s28/`), S11 (`s11/`) and the quantile
   regression containment (`qr/`). `rerun/RUN.md` maps each preliminary script to its rerun script.
5. **Figure scripts** (`figs/`). `fig_main_v104.R` and `figS_v104.R` as changed on 31 October 2026. The gray
   beyond-the-data field now starts at 33 yr for natural stands and 18 yr for planted stands.

Each track has a `PREREG.md` (where one was written), a `RUN.md` (order of work, timings, gates) and a `RESULTS.md`.

## Where outputs live

Outputs stay on firebreather under `~/jobs/koa_v104_20261030/a5/` (`loio/`, `pairmc/`, `rerun/`, `stage3fix/`).
Plot-key CSVs never leave firebreather, and no script reads coordinate columns. The Zenodo 1.11.0 deposit will
hold the shareable outputs.
