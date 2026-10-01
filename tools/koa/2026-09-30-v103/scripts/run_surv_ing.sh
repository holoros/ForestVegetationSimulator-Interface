#!/bin/bash
cd ~/jobs/koa_v103_20260930/track2
T0=$(date +%s); Rscript ingrowth_refit_v103.R > ../logs/ingrowth_refit_v103.log 2>&1; echo "ingrowth_refit_v103.R exit $? $(( $(date +%s) - T0 )) s" >> ../logs/timings.txt
T0=$(date +%s); Rscript surv_refit_v103.R > ../logs/surv_refit_v103.log 2>&1; echo "surv_refit_v103.R exit $? $(( $(date +%s) - T0 )) s" >> ../logs/timings.txt
echo done > ../logs/surv.done
