cd ~/jobs/koa_formscreen_20261103
( until grep -q CHAIN_DDBH_DONE logs/run_inc.out; do sleep 20; done
  for s in ing_fit s12_fit s3_fit; do Rscript $s.R > logs/$s.log 2>&1; echo "$s exit $? $(date +%T)"; done; echo CHAIN_CSA_DONE ) &
( until grep -q CHAIN_DHT_DONE logs/run_inc.out; do sleep 20; done
  for s in hcb_fit ht_fit; do Rscript $s.R > logs/$s.log 2>&1; echo "$s exit $? $(date +%T)"; done; echo CHAIN_CSB_DONE ) &
wait; echo RUN_CS_DONE $(date)
