cd ~/jobs/koa_formscreen_20261103
( for c in B D1 D2 D3; do Rscript inc_fit.R dDBH $c > logs/inc_dDBH_$c.log 2>&1; echo "dDBH $c exit $? $(date +%T)"; done; echo CHAIN_DDBH_DONE ) &
( for c in B T1 T2 T3 T4; do Rscript inc_fit.R dHT $c > logs/inc_dHT_$c.log 2>&1; echo "dHT $c exit $? $(date +%T)"; done; echo CHAIN_DHT_DONE ) &
wait; echo RUN_INC_DONE $(date)
