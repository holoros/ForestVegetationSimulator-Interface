#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/jobs/koa_fig2_20260926"
SRC=BYI_all.tif
# panel a: whole archipelago, same extent as Figure 1 panel a
gdalwarp -q -overwrite -t_srs EPSG:4326 -te -160.35 18.80 -154.70 22.35 -tr 0.0025 0.0025 \
  -r average -ot Float32 -srcnodata nan -dstnodata -9999 "$SRC" byi_arch.tif
# panel b: Hawaii Island, same extent as Figure 1 panel b
gdalwarp -q -overwrite -t_srs EPSG:4326 -te -156.15 18.85 -154.70 20.35 -tr 0.001 0.001 \
  -r average -ot Float32 -srcnodata nan -dstnodata -9999 "$SRC" byi_isl.tif
for f in arch isl; do
  gdal_translate -q -of XYZ byi_$f.tif byi_$f.xyz
done
wc -l byi_arch.xyz byi_isl.xyz
ls -l byi_arch.xyz byi_isl.xyz
echo WARP_DONE
