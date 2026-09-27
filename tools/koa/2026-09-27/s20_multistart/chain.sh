#!/usr/bin/env bash
cd "$HOME/jobs/koa_s20fix_20260927"
echo "S1 start $(date)" > chain.log
Rscript S1_producer_repro.R V102 > S1.log 2>&1
echo "S1 exit $? $(date)" >> chain.log
CORES=7 Rscript S2_multistart_S20.R > S2.log 2>&1
echo "S2 exit $? $(date)" >> chain.log
