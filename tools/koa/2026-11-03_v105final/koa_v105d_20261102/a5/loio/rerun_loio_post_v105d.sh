# v105d: the phase-2 LOIO gates (V105EXACT, NONE) ran with the v105c patch_fold.py (regex matched LineageA and LineageB DDBH, n = 2, AssertionError, chain failed);
# patch_fold.py fixed (count=1) while run_folds.sh was fitting, so all 14 fold chains ran with the fix. Rerun here: gate chains, gate check, analysis, results.
cd ~/jobs/koa_v105d_20261102/a5/loio
bash run_gates.sh > logs/gates_v105d.log 2>&1
python3 gate_check.py > logs/gate_check_v105d.log 2>&1
python3 analyze_loio.py > logs/analyze_v105d.log 2>&1
python3 make_results.py > logs/make_results_v105d.log 2>&1
echo LOIO_POST_V105D_DONE $(date)
