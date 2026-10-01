#!/usr/bin/env bash
# run_s01_s02.sh (v103 registry, 2026-09-30): copy of track3/run_s01_s02.sh of koa_v102_20260918. 01_accounting.R and
# 02_height_refit.R unchanged (md5 identical to v102 track3/rt), run on the v103 tree join and survival frames (frames/final).
set -u
J=$HOME/jobs/koa_v103_20260930; R=$J/a2/registry; F=$J/frames/final
cd $R/rt
export KOA_NBOOT=5000 KOA_LOIO=TRUE
echo "== v103 01 $(date)"
KOA_DEPOSIT=$R/s01/deposit_v103 KOA_OUT=$R/s01/v103 KOA_TREE=$F/tree_join_v103.csv KOA_SURV=$F/surv_baseline_rebuilt_v103.csv \
  KOA_SURV_RECOVERED=$F/surv_recovered_ii_v103.csv Rscript 01_accounting.R
echo "== v103 02 $(date)"
KOA_DEPOSIT=$R/s01/deposit_v103 KOA_OUT=$R/s02/v103 KOA_TREE=$F/tree_join_v103.csv Rscript 02_height_refit.R
echo "S01 S02 DONE $(date)"
