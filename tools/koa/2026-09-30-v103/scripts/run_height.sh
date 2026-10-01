#!/bin/bash
cd ~/jobs/koa_v103_20260930/track2; T0=$(date +%s)
Rscript height_refit_v103.R > ../logs/height_refit_v103.log 2>&1
echo "height_refit_v103.R exit $? $(( $(date +%s) - T0 )) s" >> ../logs/timings.txt
cd ../track3_rt; J=$HOME/jobs/koa_v102_20260918; W=$HOME/jobs/koa_v103_20260930
export KOA_NBOOT=5000 KOA_LOIO=TRUE
for TAG in v102 v103; do T0=$(date +%s); TJ=$J/track2/height/tree_join_v102.csv; [ $TAG = v103 ] && TJ=$W/frames/final/tree_join_v103.csv
  mkdir -p $W/track3_s02/$TAG; KOA_DEPOSIT=$J/track3/s01/deposit_v102 KOA_OUT=$W/track3_s02/$TAG KOA_TREE=$TJ Rscript 02_height_refit.R > $W/logs/02_height_$TAG.log 2>&1
  echo "02_height_refit.R $TAG exit $? $(( $(date +%s) - T0 )) s" >> $W/logs/timings.txt; done
echo done > $W/logs/height.done
