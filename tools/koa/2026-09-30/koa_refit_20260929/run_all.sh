#!/bin/bash
cd ~/jobs/koa_refit_20260929
T0=$(date +%s)
python3 run_engine.py engine_refit refit > logs/run_refit.log 2>&1; echo "run_engine refit exit $? $(( $(date +%s) - T0 )) s" >> logs/timings.txt
T1=$(date +%s)
python3 uneven_point.py engine_refit refit > logs/run_uneven_refit.log 2>&1; echo "uneven_point refit exit $? $(( $(date +%s) - T1 )) s" >> logs/timings.txt
T2=$(date +%s)
python3 run_engine.py engine_refit_live refit_live > logs/run_refit_live.log 2>&1; echo "run_engine refit_live exit $? $(( $(date +%s) - T2 )) s" >> logs/timings.txt
echo ALLDONE > logs/run_all.done
