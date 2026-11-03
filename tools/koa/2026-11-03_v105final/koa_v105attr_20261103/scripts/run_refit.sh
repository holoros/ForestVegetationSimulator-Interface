cd ~/jobs/koa_v105attr_20261103; export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
SDIMAX_POP=923 OUTDIR=prep/out923 Rscript --vanilla scripts/refit_compscreen_pop.R > logs/refit_923.log 2>&1; echo "refit923 $?"
SDIMAX_POP=741.996871565 OUTDIR=prep/out742 Rscript --vanilla scripts/refit_compscreen_pop.R > logs/refit_742.log 2>&1; echo "refit742 $?"
echo REFIT DONE $(date)
