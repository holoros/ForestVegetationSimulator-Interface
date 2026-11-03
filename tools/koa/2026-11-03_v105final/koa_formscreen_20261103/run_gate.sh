cd ~/jobs/koa_formscreen_20261103
KOA_POP=923 Rscript inc_fit.R dDBH B > logs/gate_dDBH_B_pop923.log 2>&1 &
KOA_POP=923 Rscript inc_fit.R dHT B > logs/gate_dHT_B_pop923.log 2>&1 &
wait; echo GATE_RUN_DONE $(date)
