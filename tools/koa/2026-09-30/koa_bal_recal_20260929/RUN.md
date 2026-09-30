# koa_bal_recal_20260929

Purpose: resolve the BAL definition mismatch (Eq. 4 fitted on BA.perc over all records; engine and HiGy 0.4.1 use the live list; Midgard HiGy 0.4.0 uses conventional FVS cumsum) without refitting, by recomputing origin multipliers k = sum(obs) / sum(level-0 pred x CF) within origin under each definition.

Run:
  Rscript bal_recal.R            # out/k_by_bal.csv, out/ratio_by_bal.csv (installation bootstrap intervals)
  python3 proj_klive.py          # engine_v102 / regen_m1 rerun with k_live: out/traj_klive.csv, validation

Checks: deployed k reproduced (0.4055, 1.4361); gate matched Table 5 after the natural list fix (RC.wlist(int(planted), byi)).
Server side only: out/validation_klive_KEYED_SERVERSIDE.csv (plot keys). Never push or download.
Push set: bal_recal.R, proj_klive.py, RUN.md.
