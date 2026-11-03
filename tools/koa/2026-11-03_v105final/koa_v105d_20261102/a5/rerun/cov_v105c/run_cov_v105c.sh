# v105d job: Table S26 coverage of the v105c engine (koa_v105c_20261102/engine_v103 with its own v105c joint draws, read only), same scripts and inputs as a5/rerun/cov
cd ~/jobs/koa_v105d_20261102/a5/rerun/cov_v105c && PYTHONDONTWRITEBYTECODE=1 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 python3 cov_mc.py ~/jobs/koa_v105c_20261102/engine_v103 v104 500 && python3 cov_summ.py
