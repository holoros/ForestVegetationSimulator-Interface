#!/usr/bin/env bash
cd $HOME/jobs/koa_v103_20260930/a2/registry
bash run_lt.sh > logs/run_lt.log 2>&1
bash run_ceiling.sh > logs/run_ceiling.log 2>&1
bash run_mort_planted.sh > logs/run_mort_planted.log 2>&1
bash run_proto.sh > logs/run_proto.log 2>&1
echo CHAIN DONE > logs/chain.done
