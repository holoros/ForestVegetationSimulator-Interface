# koa v102 red team and Figure 1 rebuild, 26 September 2026

Scripts behind the 26 September corrections to the koa growth and yield manuscript (v102)
and supplement (s100). Run on firebreather. No data, no coordinates and no tokens are in
this directory; every script reads inputs that stay server side.

## Coordinate provenance

`cmp_coords.R`, `fuzzsig.R`, `direction.R`, `reproduce.R`

Established which of two coordinate sets for the same 320 plots is the original.
`AK_GEO.shp` reproduces the stored rainfall covariate to within 1 mm at 193 of 267 plots
and the stored temperature to within 0.01 C at 189, against 20 and 18 for the LAT and LON
columns of the figshare copy, so the shapefile is the original and the figshare copy is a
fuzzed derivative offset by a median of 436 m and rounded to four decimals. Land cover at
the two position sets did not discriminate (43.4 against 41.9 percent forest, McNemar
p = 0.52) and is recorded so the test is not repeated.

## Figure 1

`fig1.R`, `warp.sh`, `lc_at_plots.R`

Rebuilds the plot network figure over NLCD Hawaii 2001, reclassified to five display
classes. Positions are fuzzed within a 500 m disc. The seed is held in the script for
internal reproducibility and is deliberately not printed in the published caption, because
the offset set plus digitized positions would otherwise allow the true positions to be
recovered. `warp.sh` prepares the rasters with the GDAL CLI rather than terra, which would
not install on this host.

## Red team verification

`regen_s13.py`, `culm.R`, `eqv.R`

`regen_s13.py` regenerates supplemental Table S13 from the engine trajectories. Of 288
cells, 22 differed from the printed table and were corrected: 11 uneven-aged heights left
on an earlier engine run, 2 even-aged heights and 9 point or interval values wrong in the
last digit.

`culm.R` computes net mean annual increment culmination ages per Monte Carlo replicate, so
the rotation ages carry intervals rather than travelling as bare point estimates.

`eqv.R` runs the bootstrap equivalence tests at the plot level, 5,000 resamples, and reports
the smallest region at which each test still passes rather than a pass or fail verdict.

## Note on intervals

A first regeneration of Table S13 used Python's quantile estimator and appeared to show all
72 interval cells disagreeing with the printed table. R's type 7 estimator, which is what
the generator uses, reproduced them exactly. Use R's estimator when checking these.
