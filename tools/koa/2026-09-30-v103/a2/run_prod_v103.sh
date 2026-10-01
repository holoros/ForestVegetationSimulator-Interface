#!/bin/bash
cd ~/jobs/koa_v103_20260930/a2
T0=$(date +%s); python3 run_engine.py ../engine_v103 v103 > logs/run_v103.log 2>&1; echo "run_engine v103 exit $? $(( $(date +%s) - T0 )) s" >> logs/timings.txt
T1=$(date +%s); python3 uneven_point.py ../engine_v103 v103 > logs/run_uneven_v103.log 2>&1; echo "uneven_point v103 exit $? $(( $(date +%s) - T1 )) s" >> logs/timings.txt
echo ALLDONE >> logs/timings.txt
