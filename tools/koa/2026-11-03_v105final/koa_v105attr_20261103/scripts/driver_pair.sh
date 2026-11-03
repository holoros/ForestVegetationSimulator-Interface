J=~/jobs/koa_v105attr_20261103
bash $J/scripts/make_pair.sh P_HT_HCB > $J/logs/make_pair_P_HT_HCB.log 2>&1
bash $J/scripts/run_pipeline3.sh P_HT_HCB > $J/logs/pipeline_P_HT_HCB.log 2>&1
echo PAIR DONE $(date)
