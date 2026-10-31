#!/bin/bash
# A5-D1 rerun after the Stage 3 vector fix in run_candidates: chain 1, chain 2, figures, figS34, sensitivities.
cd ~/jobs/koa_v104_20261030; L=a5/stage3fix/run_a5.log; echo "start $(date)" > $L
bash a4/run_chain1_v104.sh > a5/stage3fix/chain1.out 2>&1; echo "chain1 $? $(date)" >> $L; cat a4/logs/chain1.log >> $L
bash a4/run_chain2_v104.sh > a5/stage3fix/chain2.out 2>&1; echo "chain2 $? $(date)" >> $L; cat a4/logs/chain2.log >> $L
bash a4/run_figs_v104.sh > a5/stage3fix/figs.out 2>&1; echo "figs $? $(date)" >> $L
Rscript --vanilla a4/figs/figS34_v104.R > a5/stage3fix/figS34.out 2>&1; echo "figS34 $? $(date)" >> $L
python3 a4/sens/sens_v104.py > a5/stage3fix/sens.out 2>&1; echo "sens $? $(date)" >> $L
echo "A5 DONE $(date)" >> $L
