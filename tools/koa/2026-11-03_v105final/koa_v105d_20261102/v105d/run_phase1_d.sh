#!/bin/bash
# v105d phase 1 (after stage_b_d.sh and the dHT bootstraps): CAL SE, chain 1, chain 2, tables, figures, sens, way-B scripts, registry rebuild.
# As v105c/run_phase1_c.sh. Registry s01/s02 (accounting, height) are not rerun: the v105d Eq. 2 statistics are in track3_s02/v105d (track3_rt/02_height_refit_v105d.R).
# At most 3 cores in the chains (other jobs hold 4 of 8).
set -u; cd ~/jobs/koa_v105d_20261102; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1
B=v105d/backup_d.sh; L=v105d/logs
echo "start $(date)"
python3 v105d/set_calse_v105d.py > $L/set_calse_v105d.log 2>&1; echo "set_calse $?"; cat $L/set_calse_v105d.log
bash a4/run_chain1_v104.sh; cat a4/logs/chain1.log
bash a4/run_chain2_v104.sh; cat a4/logs/chain2.log
python3 a2/closeout/validation/make_tables_v104.py > $L/make_tables_v105d.log 2>&1; echo "make_tables $?"
bash a4/run_figs_v104.sh; cat a4/logs/figs.log
Rscript --vanilla a4/figs/figS34_v104.R > $L/figS34_v105d.out 2>&1; echo "figS34 $?"
python3 a4/sens/sens_v104.py > $L/sens_v105d.out 2>&1; echo "sens $?"
( cd a4/sens && python3 years_grid_v104.py > ../../$L/years_grid_v105d.out 2>&1; echo "years_grid $?" )
python3 a2/figs/scripts/lt_v103.py a2/registry/engine_nocal v104nocal a4/lt/nocal > $L/lt_nocal_v105d.out 2>&1; echo "lt nocal $?"
Rscript a4/diag_c_by_source_v104.R > $L/diag_c_v105d.out 2>&1; echo "diag_c $?"
python3 a4/redteam/mc_v104.py > a4/redteam/mc.out 2>&1; echo "redteam mc $?"
bash $B a2/registry/numbers_v105.json a2/registry/build/gate_v105.csv; bash a2/registry/make_md.sh; echo "registry $?"; cp -p a2/registry/numbers_v104.json a2/registry/numbers_v105.json; cp -p a2/registry/build/gate_v104.csv a2/registry/build/gate_v105.csv
python3 -c "import pandas as pd; D=pd.read_csv('a2/registry/build/gate_v104.csv'); print('GATE', int(D.agree.sum()), 'of', len(D)); print(D[~D.agree].to_string())"
echo "PHASE1 DONE $(date)"
