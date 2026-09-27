#!/bin/bash
J=$HOME/jobs/koa_prereg_B_beta_20260926
E=$HOME/jobs/koa_v102_20260918/track2/engine_v102
export PYTHONDONTWRITEBYTECODE=1
echo "START $(date -u +%FT%TZ)"
python3 -u $J/grid.py $E $J/out 2>&1
echo "EXIT_GRID=$?"
python3 -u $J/scen.py $E $J/out 2>&1
echo "EXIT_SCEN=$?"
echo "END $(date -u +%FT%TZ)"
