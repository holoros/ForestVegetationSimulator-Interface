# after the attempt-1 C742 joint-draw gate stop (KOA_DHT_FORM not exported): C742 alongside the running D742, then the two remaining pairs
J=~/jobs/koa_v105attr_20261103
bash $J/scripts/run_pipeline2.sh C742 > $J/logs/pipeline_C742.log 2>&1
while pgrep -f "run_pipeline.sh D742" > /dev/null; do sleep 30; done; echo "D742 C742 done $(date)"
for pair in "R_dHT R_HT" "R_HCB R_S3"; do
  for R in $pair; do bash $J/scripts/run_pipeline2.sh $R > $J/logs/pipeline_$R.log 2>&1 & done; wait; echo "pair $pair done $(date)"
done
echo DRIVER DONE $(date)
