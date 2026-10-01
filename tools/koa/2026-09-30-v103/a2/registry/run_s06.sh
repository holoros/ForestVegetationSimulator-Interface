#!/usr/bin/env bash
# run_s06.sh (v103 registry, 2026-09-30): 06_survival_respec.R unchanged, on the v103 frames (frames/final).
set -u
J=$HOME/jobs/koa_v103_20260930; R=$J/a2/registry; O=$HOME/jobs/koa_origin_20260916; F=$J/frames/final
cd $R/s06/rt
export KOA_DEPOSIT=$O/s06/deposit KOA_NBOOT=5000
echo "== v103 06 $(date)"
KOA_OUT=$R/s06/v103 KOA_SURV=$F/surv_baseline_rebuilt_v103.csv KOA_SURV_RECOVERED=$F/surv_recovered_ii_v103.csv Rscript 06_survival_respec.R
echo "S06 DONE $(date)"
