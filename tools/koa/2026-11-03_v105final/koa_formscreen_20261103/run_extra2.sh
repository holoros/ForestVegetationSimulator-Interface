cd ~/jobs/koa_formscreen_20261103
for s in hcb_hc2_port t2_extra gate_s3_923 ing_fit; do Rscript $s.R > logs/${s}_x.log 2>&1; echo "$s exit $? $(date +%T)"; done; echo RUN_EXTRA2_DONE
