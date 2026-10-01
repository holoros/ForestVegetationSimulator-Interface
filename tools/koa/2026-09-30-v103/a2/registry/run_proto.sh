#!/usr/bin/env bash
# run_proto.sh (v103 registry): proto_mort.py unchanged, on engine_nocal (v103 constants, MORT_CAL (1,1)) with the v103 levels.
set -u
J=$HOME/jobs/koa_v103_20260930; R=$J/a2/registry; cd $R; mkdir -p proto/v103
cp -p $J/a2/mort/v103/H_mort_level_natural.csv $J/a2/mort/v103/H_mort_loio_natural.csv proto/v103/
cp -p mort/v103_planted/H_mort_level_planted.csv proto/v103/
echo "== proto v103 $(date)"
KOA_OUTDIR=proto/v103 python3 proto/proto_mort.py $R/engine_nocal $R > proto/v103/proto.log 2>&1
echo "PROTO DONE $(date)"
