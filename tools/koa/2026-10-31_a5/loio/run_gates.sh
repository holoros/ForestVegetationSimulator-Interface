#!/bin/bash
cd ~/jobs/koa_v104_20261030/a5/loio
for f in V104EXACT NONE; do bash run_chain_fold.sh $f || echo "FOLD $f FAILED"; done; echo ALLDONE
