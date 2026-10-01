#!/usr/bin/env bash
# run_ceiling.sh (v103 registry): a2_ceiling.py unchanged on the registry copy of engine_v103.
set -u
J=$HOME/jobs/koa_v103_20260930; R=$J/a2/registry; cd $R/ceiling; mkdir -p v103
KOA_ENG=$R/engine KOA_OUT=$R/ceiling/v103 python3 a2_ceiling.py > v103/a2_ceiling.log 2>&1
echo "CEILING DONE $(date)"
