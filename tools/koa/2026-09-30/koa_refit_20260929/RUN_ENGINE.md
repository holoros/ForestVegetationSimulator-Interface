# RUN_ENGINE.md, koa_refit_20260929 (29 to 30 September 2026)

Host firebreather, 8 cores, load average about 10 from other users' jobs during the run. All commands from ~/jobs/koa_refit_20260929.

| Step | Command | Wall time |
|---|---|---|
| copy engine | cp -r ~/jobs/koa_v102_20260918/track2/engine_v102 engine_refit; cp track2/run_engine.py, track2/uneven_point.py | seconds |
| gate | python3 run_engine.py engine_refit gate; python3 compare_gate.py out/traj_gate.csv .../traj_v102.csv | about 45 s, PASS 0.000e+00 |
| BAL switch | python3 patch_bal_switch.py engine_refit; cp -r engine_refit engine_refit_live | seconds |
| gate 2 (switch at percentile) | python3 run_engine.py engine_refit gate2; compare_gate.py | about 45 s, PASS 0.000e+00 |
| constants | python3 patch_engine_refit.py engine_refit c; python3 patch_engine_refit.py engine_refit_live l | seconds |
| mortality level | ./run_mort.sh (KOA_OUTDIR=. python3 mort/calib_mort.py engine_<arm> mort/<arm> natural; python3 mort/solve_mort.py mort/<arm> natural) | about 30 s both arms |
| write MORT_CAL | python3 patch_mortcal_refit.py | seconds |
| production | ./run_all.sh | run_engine refit exit 0 6 s; uneven_point refit exit 0 2 s; run_engine refit_live exit 0 6 s; run_engine refit2 exit 0 5 s; uneven_point refit2 exit 0 1 s; run_engine refit2_live exit 0 5 s |
| compare | python3 compare_refit.py | about 40 s (5,000 draw equivalence bootstraps) |
| report | python3 write_report.py | seconds |
| pending | python3 patch_selog_refit.py (after refit_addendum.R writes out/c_bootstrap.csv) | |

Outputs in out/: traj_gate.csv, val_gate.csv, traj_gate2.csv, val_gate2.csv, traj_refit.csv, val_refit.csv, uneven_refit.csv, traj_refit_live.csv, val_refit_live.csv, table5_compare.csv, culmination_compare.csv, validation_compare.csv, validation_equiv_compare.csv, patch_values_engine_refit.csv, patch_values_engine_refit_live.csv, patch_values_mortcal_refit.csv. Mortality solve outputs in mort/refit and mort/refit_live (H_mort_level_natural.csv and companions). Logs in logs/.

md5sums of the patched files and scripts:

```
4cda47488f502ff2985ce33e284f4f25  engine_refit/koa_params.py
1846d8c906810ca51a55ae6648851791  engine_refit/koa_equations.py
f61ab34b2a6f1cbaa87e8c9f3a3f5acc  engine_refit/koa_projector.py
7306dc1f4995a18f732a397b63c2a35a  engine_refit/run_candidates.py
c24672a09e54ad768949116a431b4431  engine_refit/regen_figS4S5.py
d385b465f8e27f4e4b718322d29cee23  engine_refit/HiGy.R
23116d2613abad98a9da2e65cd6fa5ca  engine_refit_live/koa_params.py
f098a87caade6a0dea57896fe0baa537  engine_refit_live/koa_equations.py
75405af9a216e3bf9326b9995c534c73  engine_refit_live/HiGy.R
feaa8ea1ebe2d91424ac68af0565504c  patch_bal_switch.py
ba3706b7f838ea1024b60cb4bf382b67  patch_engine_refit.py
b78a1104f1caa8ea492d9b2e5e64c557  patch_mortcal_refit.py
275b467af79feff5ea9d1411914a2403  run_engine.py
befe1531c6ce3631f118913bc1b8e8c6  uneven_point.py
311c2b8350eef69442e1c3bc2b81ef7a  compare_refit.py
aa5f6ba9dbbb0b0f3715cf2e6f950fea  compare_gate.py
eb6b928e0c8fa59381fdb2b000819f6c  engine_refit2/koa_params.py
180f0210def5bb8d05f07a366a4647f2  engine_refit2/koa_equations.py
f61ab34b2a6f1cbaa87e8c9f3a3f5acc  engine_refit2/koa_projector.py
7306dc1f4995a18f732a397b63c2a35a  engine_refit2/run_candidates.py
3c922babcacf383e8bf0c79c8d88851e  engine_refit2/HiGy.R
83ce8ec0077608acbde227002d42af39  engine_refit2_live/koa_params.py
e1aa6c3c49e6ce05ecbe796bbf10dc13  engine_refit2_live/koa_equations.py
42e9ce713b8223e50ddaeb938793754c  engine_refit2_live/HiGy.R
0a0a24bc14dd0874d68ab21fa6a483d9  patch_engine_refit2.py
35674e4ff2015541606a2ab26299a188  patch_mortcal_refit2.py
a2e8620710d33db9752f875ba011be5c  check_observed_repair.py
d73213a5f830b9b9508388fe6dd0217f  fin/run_yield_grid_refit2.py
b16197faba3677976becf179b9129d99  fin/compare_yield_grid.py
b93c6dd8820f928b66a8be5abc6a33f0  compare_refit.py
```


## Second pass (refit2), 30 September 2026

| Step | Command | Wall time |
|---|---|---|
| copy and switch | cp -r .../engine_v102 engine_refit2; python3 patch_bal_switch.py engine_refit2 | seconds |
| gate 3 | python3 run_engine.py engine_refit2 gate3; compare_gate.py | about 45 s, PASS 0.000e+00 |
| constants | cp -r engine_refit2 engine_refit2_live; python3 patch_engine_refit2.py engine_refit2 c; python3 patch_engine_refit2.py engine_refit2_live l | seconds |
| observed value check | python3 check_observed_repair.py | seconds |
| mortality level | ./run_mort2.sh; python3 patch_mortcal_refit2.py | about 40 s |
| production | ./run_all2.sh | run_engine refit2 exit 0 5 s; uneven_point refit2 exit 0 1 s; run_engine refit2_live exit 0 5 s |
| compare | python3 compare_refit.py | about 60 s |
| yield grid | python3 fin/run_yield_grid_refit2.py; python3 fin/compare_yield_grid.py | about 35 s |
| report | python3 write_report.py; python3 write_report2.py | seconds |

Outputs added: out/traj_gate3.csv, val_gate3.csv, traj_refit2.csv, val_refit2.csv, uneven_refit2.csv, traj_refit2_live.csv, val_refit2_live.csv, patch_values_engine_refit2.csv, patch_values_engine_refit2_live.csv, patch_values_mortcal_refit2.csv, observed_repair_check.csv, observed_repair_intervals.csv; fin/out/koa_yield_grid_200yr.csv, koa_yield_grid_diagnostics.csv, yield_grid_compare.csv; mort/refit2, mort/refit2_live. The four compare CSVs now carry refit2 and refit2_live columns or rows alongside v102, refit and refit_live.

md5sums (full list including second pass files):

```
4cda47488f502ff2985ce33e284f4f25  engine_refit/koa_params.py
1846d8c906810ca51a55ae6648851791  engine_refit/koa_equations.py
f61ab34b2a6f1cbaa87e8c9f3a3f5acc  engine_refit/koa_projector.py
7306dc1f4995a18f732a397b63c2a35a  engine_refit/run_candidates.py
c24672a09e54ad768949116a431b4431  engine_refit/regen_figS4S5.py
d385b465f8e27f4e4b718322d29cee23  engine_refit/HiGy.R
23116d2613abad98a9da2e65cd6fa5ca  engine_refit_live/koa_params.py
f098a87caade6a0dea57896fe0baa537  engine_refit_live/koa_equations.py
75405af9a216e3bf9326b9995c534c73  engine_refit_live/HiGy.R
feaa8ea1ebe2d91424ac68af0565504c  patch_bal_switch.py
ba3706b7f838ea1024b60cb4bf382b67  patch_engine_refit.py
b78a1104f1caa8ea492d9b2e5e64c557  patch_mortcal_refit.py
275b467af79feff5ea9d1411914a2403  run_engine.py
befe1531c6ce3631f118913bc1b8e8c6  uneven_point.py
311c2b8350eef69442e1c3bc2b81ef7a  compare_refit.py
aa5f6ba9dbbb0b0f3715cf2e6f950fea  compare_gate.py
eb6b928e0c8fa59381fdb2b000819f6c  engine_refit2/koa_params.py
180f0210def5bb8d05f07a366a4647f2  engine_refit2/koa_equations.py
f61ab34b2a6f1cbaa87e8c9f3a3f5acc  engine_refit2/koa_projector.py
7306dc1f4995a18f732a397b63c2a35a  engine_refit2/run_candidates.py
3c922babcacf383e8bf0c79c8d88851e  engine_refit2/HiGy.R
83ce8ec0077608acbde227002d42af39  engine_refit2_live/koa_params.py
e1aa6c3c49e6ce05ecbe796bbf10dc13  engine_refit2_live/koa_equations.py
42e9ce713b8223e50ddaeb938793754c  engine_refit2_live/HiGy.R
0a0a24bc14dd0874d68ab21fa6a483d9  patch_engine_refit2.py
35674e4ff2015541606a2ab26299a188  patch_mortcal_refit2.py
a2e8620710d33db9752f875ba011be5c  check_observed_repair.py
d73213a5f830b9b9508388fe6dd0217f  fin/run_yield_grid_refit2.py
b16197faba3677976becf179b9129d99  fin/compare_yield_grid.py
b93c6dd8820f928b66a8be5abc6a33f0  compare_refit.py
```
