cd ~/jobs/koa_formscreen_20261103
until grep -q RUN_CS_DONE logs/run_cs.out; do sleep 20; done
Rscript hcb_hc2_port.R > logs/hcb_hc2_port.log 2>&1 & Rscript t2_extra.R > logs/t2_extra.log 2>&1 & wait; Rscript gate_s3_923.R > logs/gate_s3_923.log 2>&1; Rscript ing_fit.R > logs/ing_fit_rerun.log 2>&1; echo RUN_EXTRA_DONE $(date)
