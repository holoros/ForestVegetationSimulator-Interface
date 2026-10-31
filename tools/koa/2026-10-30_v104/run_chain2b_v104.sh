#!/bin/bash
set -u; cd ~/jobs/koa_v104_20261030; L=a4/logs/chain2b.log; echo "start $(date)" > $L; R=a2/registry
bash $R/run_mort_planted.sh > $R/logs/run_mort_planted_v104.log 2>&1; echo "mort_planted $?" >> $L
bash $R/run_proto.sh > $R/logs/run_proto_v104.log 2>&1; echo "proto $?" >> $L
bash $R/make_md.sh; echo "registry $?" >> $L
echo "CHAIN2B DONE $(date)" >> $L
