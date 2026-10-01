#!/bin/bash
# build_frames_v103.sh: v102 builder chain run twice, first on the v102 inputs (reproduction gate against ~/jobs/koa_v102_20260918/frames),
# then on the v103 repaired inputs. Then post_frames_v103.py adds the removal screen and BAL definition columns and runs the uniqueness gates.
set -e
cd ~/jobs/koa_v103_20260930
V2=~/jobs/koa_v102_20260918
for TAG in v102 v103; do
  T0=$(date +%s)
  mkdir -p frames/$TAG inputs/raw_$TAG
  python3 scripts/build_incr.py inputs/AK_TREE_${TAG}.csv inputs/AK.TREE.incr_${TAG}.csv > logs/build_incr_${TAG}.log 2>&1
  Rscript builders/build_frames_incr.R inputs/AK.TREE.incr_${TAG}.csv inputs/PLT.GEO.V2_v102.csv frames/$TAG $TAG > logs/build_frames_incr_${TAG}.log 2>&1
  cp inputs/AK.TREE.incr_${TAG}.csv inputs/raw_$TAG/AK.TREE.incr.csv; cp inputs/PLT.GEO.V2_v102.csv inputs/raw_$TAG/PLT.GEO.V2.csv
  python3 builders/rebuild_surv_origin_2026-09-16_REFERENCE_COPY.py inputs/raw_$TAG frames/$TAG inputs/psp_origin_thinning_2026-09-16_DATA.csv > logs/rebuild_surv_${TAG}.log 2>&1
  PLTF=inputs/AK_PLT.csv; [ "$TAG" = v103 ] && PLTF=inputs/AK_PLT_v103.csv
  Rscript builders/build_pairs_m1.R inputs/AK_TREE_${TAG}.csv $PLTF frames/$TAG/plot_interval_pairs_DATA_${TAG}.csv > logs/build_pairs_m1_${TAG}.log 2>&1
  echo "$TAG builders done in $(( $(date +%s) - T0 )) s" >> logs/timings.txt
done
echo BUILD_DONE > logs/build_frames.done
