#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/jobs/koa_fig1_20260926"
SRC=hi_landcover_wimperv_9-30-08_se5.img
# panel a: whole archipelago, ~440 m cells
gdalwarp -q -overwrite -t_srs EPSG:4326 -te -160.35 18.80 -154.70 22.35 -tr 0.004 0.004 \
  -r mode -ot Byte -dstnodata 0 "$SRC" lc_arch.tif
# panel b: Hawaii Island, ~165 m cells
gdalwarp -q -overwrite -t_srs EPSG:4326 -te -156.15 18.85 -154.70 20.35 -tr 0.0015 0.0015 \
  -r mode -ot Byte -dstnodata 0 "$SRC" lc_isl.tif
for f in arch isl; do gdal_translate -q -of XYZ lc_$f.tif lc_$f.xyz; done
wc -l lc_arch.xyz lc_isl.xyz
