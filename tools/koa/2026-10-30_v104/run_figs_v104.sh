#!/bin/bash
set -u; cd ~/jobs/koa_v104_20261030; L=a4/logs/figs.log; echo "start $(date)" > $L
Rscript --vanilla a4/figs/fig_main_v104.R fig3 fig4 fig5 fig6 > a4/logs/fig_main_v104.log 2>&1; echo "fig_main $?" >> $L
Rscript --vanilla a4/figs/figS_v104.R s5 s8 s67 > a4/logs/figS_v104.log 2>&1; echo "figS $?" >> $L
Rscript --vanilla a4/figs/figS12_v104.R > a4/logs/figS12_v104.log 2>&1; echo "figS12 $?" >> $L
echo "FIGS DONE $(date)" >> $L
