# two runs at a time (2 cores each), three pairs in sequence
J=~/jobs/koa_v105attr_20261103
for pair in "D742 C742" "R_dHT R_HT" "R_HCB R_S3"; do
  for R in $pair; do bash $J/scripts/run_pipeline.sh $R > $J/logs/pipeline_$R.log 2>&1 & done; wait; echo "pair $pair done $(date)"
done
echo DRIVER DONE $(date)
