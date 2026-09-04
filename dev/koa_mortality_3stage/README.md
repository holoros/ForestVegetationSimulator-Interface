# Three-stage mortality track, September 4, 2026

Script: `koa_mortality_3stage_FINAL_2026-09-04.R` (base R, seed 20260904). Inputs `AK_TREE.csv`, `AK_PLT.csv` (deposit 1.4.0 copies in the Koa manuscript folder `outputs/`). Ran on firebreather as job `koa_mort3`; outputs are pulled into `output/` here when the B = 2,000 bootstrap finishes (`fire_download koa_mort3 output`).

Memo: `outputs/2026-09/koa-mortality-3stage-memo_DRAFT_2026-09-04.md` in CRSF-Cowork.

Failed repair, do not retry: the August 28 García fits used `AK_PLT.TPH` (ingrowth included) and an L-BFGS-B start grid whose reported optima were the starting values. Use the survivor cohort and irregular-interval screen in this script instead.
