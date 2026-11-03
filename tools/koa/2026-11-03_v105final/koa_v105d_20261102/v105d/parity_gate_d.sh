#!/bin/bash
# v105d parity gate (before any refit): all v105d switches at "v105b" (= v105c forms). The patched engine must reproduce the v105c outputs exactly.
set -u; cd ~/jobs/koa_v105d_20261102; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
for s in HT_FORM HCB_FORM DHT_FORM STAGE3_FORM; do grep -q "^$s = \"v105b\"" engine_v103/koa_params.py || { echo "$s not v105b"; exit 1; }; done
( cd a2 && python3 run_engine.py ../engine_v103 parity_v105c > ../v105d/logs/run_engine_parity.log 2>&1; echo "run_engine $?" )
python3 - <<'P'
import os, sys, numpy as np, pandas as pd
J=os.path.expanduser('~/jobs/koa_v105d_20261102'); ENG=J+'/engine_v103'; sys.path.insert(0,ENG); os.chdir(ENG); os.environ.setdefault('MPLCONFIGDIR','/tmp/mpl')
src=open(J+'/a4/sens/years_grid_v104.py').read().replace("J+'/a4/sens/years_grid_v104.csv'", "J+'/v105d/out/years_grid_parity_v105c.csv'"); assert "v105d/out/years_grid_parity_v105c.csv" in src; exec(compile(src, 'years_grid_parity', 'exec'))
P
python3 v105d/parity_engine_d.py > v105d/logs/parity_engine.log 2>&1; echo "parity_engine $?"; tail -1 v105d/logs/parity_engine.log
echo PARITY_GATE_DONE $(date)
