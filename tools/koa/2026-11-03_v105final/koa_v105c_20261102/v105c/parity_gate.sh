#!/bin/bash
# v105c parity gate (before any refit): DDBH_FORM v105b everywhere.
set -u; cd ~/jobs/koa_v105c_20261102; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1; mkdir -p v105c/out
grep -q '^DDBH_FORM = "v105b"' engine_v103/koa_params.py || { echo "DDBH_FORM not v105b"; exit 1; }
bash v105c/backup_c.sh frames/final/*_v103_model.csv
KOA_DDBH_FORM=v105b Rscript --vanilla track2/inc/inc_v103.R frames > v105c/logs/frames_v105c.log 2>&1; echo "frames $?"
Rscript --vanilla v105c/parity_frames.R > v105c/logs/parity_frames.log 2>&1; echo "parity_frames $?"; tail -1 v105c/logs/parity_frames.log
( cd a2 && python3 run_engine.py ../engine_v103 parity_v105b > ../v105c/logs/run_engine_parity.log 2>&1; echo "run_engine $?" )
python3 - <<'P'
import os, sys, numpy as np, pandas as pd
J=os.path.expanduser('~/jobs/koa_v105c_20261102'); ENG=J+'/engine_v103'; sys.path.insert(0,ENG); os.chdir(ENG); os.environ.setdefault('MPLCONFIGDIR','/tmp/mpl')
src=open(J+'/a4/sens/years_grid_v104.py').read().replace("J+'/a4/sens/years_grid_v104.csv'", "J+'/v105c/out/years_grid_parity_v105b.csv'"); exec(compile(src, 'years_grid_parity', 'exec'))
P
python3 v105c/parity_engine.py > v105c/logs/parity_engine.log 2>&1; echo "parity_engine $?"; tail -1 v105c/logs/parity_engine.log
echo PARITY_GATE_DONE $(date)
