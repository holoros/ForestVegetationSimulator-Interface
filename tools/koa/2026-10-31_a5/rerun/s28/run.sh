cd ~/jobs/koa_v104_20261030/a5/rerun/s28
export PYTHONDONTWRITEBYTECODE=1 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
python3 b1_mort_holdout.py > ../logs/s28_B1.log 2>&1; echo "B1 exit $?" >> ../logs/s28_B1.log
python3 b2_local_calib.py > ../logs/s29_B2.log 2>&1; echo "B2 exit $?" >> ../logs/s29_B2.log
