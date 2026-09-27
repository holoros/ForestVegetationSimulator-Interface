# Koa self-thinning: quantile regression limiting line as an independent containment target

Run 27 September 2026 on firebreather, job `~/jobs/koa_selfthin_qr_20260927/`. Rules for the boundary subsets,
the primary data set and the PASS/FAIL criterion were written to `PREREG_boundary_rule.md` after the data
reproduction step and before any quantile regression was fitted. Provenance, commands and md5 sums are in `RUN.md`.

## Pre-flight

Every input was checked for coordinate-like columns and none carries any; the analysis frame written here carries
none either. The observed data are the plot-measures the deployed beta was anchored on: live trees with DBH above
zero in `track2/engine_v102/AK_TREE.csv`, KeyDupFlag 0, plot-years with at least five stem records, N as the sum of
live expansion factors and QMD as the recorded plot-year column. This gives 471 plot-measures on 147 plots in 101
installations (Data by Install); 66 plot-measures in 17 installations are natural and 405 in 85 installations are
planted (one PSP installation holds plots of both origins). Installations are unbalanced: Kahikinui contributes 50
single-plot installations and PSP 31, while the largest natural QMD values (above 32 cm, up to 69.7 cm) all come
from one installation (Mauka, four plot-measures). The model is ln N = b0 + b1 ln QMD fitted with `quantreg::rq`
(method br) at tau 0.95 and 0.99, in the Reineke orientation, because the engine's own limiting line
N = 10000 / (beta H_QMD)^2 with H_QMD = exp((ln QMD - a) / k_HD) is a line in that space with slope -2 / k_HD =
-1.7066 and intercept 12.5853 at the deployed beta, so all three slopes (fitted, Reineke -1.605, engine) are directly
comparable. With n = 471 one expects about 24 points above the tau 0.95 line and about 5 above the tau 0.99 line;
the fits have 23 and 4, with two points on each line. The recorded plot-year QMD column is an all-status value
(Open Item OI-3 of the deposit); a sensitivity fit on live-only QMD is reported. The engine's SDI column in the
deployed trajectories file has missing values in some rows, so SDI is recomputed everywhere as N (QMD / 25)^1.605,
the engine's `sdi_of`.

## The envelope Section 6 uses, reproduced

The Section 6 envelope is produced by `envelope_check_v82.py` (maxima over plot-years with at least five stem
records, KeyDupFlag 0, recorded plot-year columns). Re-derived in R from the v102 AK_TREE.csv it gives 547
plot-years with QMD 69.6787 cm, basal area 76.0621 m2 ha-1 and SDI 1453.4673, identical to the values of record
to machine precision. The deployed beta is produced by `fit_allometry.py` as 100 / sqrt(z99), z99 the 99th percentile
of N H_QMD^2 over the 471 live plot-measures. Re-derived here, z99 = 389696.30682452 and beta =
0.16019053617304435, identical to `koa_params.GARCIA_BETA_ANCHORED` and `beta_anchored_v102.json`. The comparison
below therefore uses exactly the observations that fixed beta, but tests the projections against a different
object: a limiting line whose slope and level are both estimated, with an interval, without reference to beta or
to the engine allometry. The independence is in the estimator and the criterion, not in the data; a held-out
set of plot-measures would be the stronger test and does not exist in these frames.

## Fitted limiting lines

On all 471 plot-measures the tau 0.99 line is ln N = 11.631 - 1.4265 ln QMD, with installation-cluster bootstrap
95 percent intervals (B = 2,000, seed 20260927, no failed fits) of -1.676 to -1.204 on the slope and 10.931 to
12.211 on the intercept; rank-inversion intervals are -1.573 to -0.696 and 10.764 to 12.819. The tau 0.95 line is
ln N = 10.671 - 1.1824 ln QMD, slope interval -1.459 to -0.921 (rank inversion -1.276 to -0.955), intercept 9.807
to 11.434. Reineke's -1.605 lies inside the tau 0.99 interval (92.2 percent of bootstrap slopes are shallower) but
outside the tau 0.95 interval. The engine-implied slope of -1.7066 lies outside both (98.95 and 99.95 percent of
bootstrap slopes are shallower). The engine line and the tau 0.99 line cross at QMD 30.2 cm: below it the engine
line permits more stems (5,744 against 4,213 stems ha-1 at 10 cm), above it fewer (270 against 327 at 60 cm).
Five plot-measures in two installations lie above the deployed engine line (1.06 percent, as the anchoring
implies); none lies above the beta 0.117 line. Live-only QMD leaves the tau 0.99 line unchanged and moves the
tau 0.95 slope to -1.1855, so OI-3 does not affect this result.

The boundary is thin. The tau 0.99 line is defined by six plot-measures on or above it in five installations
(three single-plot Kahikinui plantings at QMD 7.5 to 15.3 cm, one DOFAW natural plot at 7.7 cm, one PSP planted
plot at 28.6 to 29.5 cm); the tau 0.95 line by 25 plot-measures in 15 installations (11 Kahikinui, 2 DOFAW, 2 PSP),
none with QMD above 38.3 cm. Above about 40 cm, where the planted projections come closest, the line is the linear
form carried beyond its defining points. The pre-stated boundary subsets confirm this. B1 (top decile of SDI within
ten QMD bins, 50 plot-measures, 22 installations) gives slopes of -1.465 (-1.748 to -1.144) at tau 0.95 and
-1.204 (-1.940 to -1.006) at tau 0.99. B2 (installation maxima, 101) gives -1.319 (-1.666 to -1.050) and -1.204
(-1.678 to -0.930). At tau 0.99 both subsets reduce to the line through their two most extreme points, identical
for B1 and B2, with unbounded rank-inversion intervals, so they are not informative at that quantile.

Planted and natural stands probably should not share a line, but the natural boundary is poorly determined. In a
pooled model with an origin shift and slope interaction, the planted minus natural difference in ln N at the median
QMD (16.6 cm) is -0.052 (-0.183 to 0.538) at tau 0.95 and +0.212 (0.046 to 0.800) at tau 0.99, and the slope
difference is +0.726 (0.104 to 1.398) at tau 0.95 and +0.408 (-0.213 to 1.002) at tau 0.99. Fitted separately, the
natural line is steep (tau 0.95 slope -1.800, tau 0.99 -1.726, bootstrap interval -2.419 to -1.344 for both, from
17 installations) and the planted line shallow (-1.073, -1.416 to -0.843; and -1.319, -1.676 to -1.039).

## Containment: deployed engine (beta 0.16019)

Under the pre-stated rule the deployed engine PASSES. Across all nine projection cells (natural and planted
even-aged, uneven-aged natural; Low, Medium and High site classes; point projections, ages 1 to 100), no projected
point lies above the tau 0.99 line, the tau 0.95 line, or either upper bootstrap band. Planted stands come closest
in relative terms, at 73 to 74 percent of the tau 0.99 limiting density (High site, age 24: 435.9 stems ha-1 at QMD
39.6 cm) and 80 to 81 percent of the tau 0.95 density (age 14 to 25, QMD about 30 cm). The smallest absolute margin
to the tau 0.99 line is 100.1 stems ha-1 below it, or 421 SDI units (planted High, age 77, QMD 61.2 cm, 217.9
against 318.0 stems ha-1), and 169.6 stems ha-1 below its upper band. Even-aged natural stands reach at most 35
percent and uneven-aged natural stands at most 47 percent of the tau 0.99 density. Of the Monte Carlo replicates
(500 per even-aged cell, 300 per uneven-aged cell) none crosses the tau 0.99 line (closest 37.5 stems ha-1 below);
two of 500 planted Low and High replicates and one of 500 planted Medium replicates cross the tau 0.95 point line
by at most 20.0 stems ha-1, and none crosses its upper band. Against origin-specific lines the deployed projections
also stay under tau 0.99 (natural at most 0.92 of the natural line, planted at most 0.69 of the planted line);
uneven-aged natural Medium and High stands touch the natural tau 0.95 point line at age 100 (by 4.4 and 9.2 stems
ha-1, at QMD 64.6 and 72.4 cm, beyond all natural data except the one Mauka installation) but not its band.

## Containment: variant B fitted beta 0.117

The variant B C5 arm reproduces the deployed trajectories exactly (600 rows, max |dTPH| 2.3e-13), so the contrast
isolates beta. With beta 0.117 the natural projections stay under both lines, but the planted projections cross
them. Against the tau 0.99 line, 64, 76 and 80 percent of years 1 to 100 on the Low, Medium and High site classes
lie above it, by up to 61.9, 64.2 and 68.6 stems ha-1 (10.8 to 13.9 percent, SDI 135 to 176) at ages 64, 52 and 51
and QMD 40.6 to 45.0 cm; they stay 8.6 to 11.6 stems ha-1 inside its upper band, so under the pre-stated rule the
result is INDETERMINATE rather than FAIL. Against the tau 0.95 line 80 to 89 percent of years lie above it, by up to
96.2 to 99.5 stems ha-1 (16 percent, SDI 182 to 188) at ages 29 to 52, and 16 to 24 percent of years lie above its
upper bootstrap band. The test therefore separates the two arms: the anchored beta keeps planted projections a
quarter below the independent tau 0.99 line, while the fitted beta carries them through it.

A caution on interpretation. The deployed projections stay well inside their own engine line as well (planted at
most 0.84, natural at most 0.41 of it), so the margin reported here reflects the whole Stage 2 mortality dynamics,
not beta alone, and the result shows that the deployed engine is conservative relative to the observed boundary
rather than that it reproduces it.

## Proposed replacement paragraph for Supplemental Section 6

Because the self-thinning parameter of the Stage 2 mortality (García 2009) was anchored so that the engine's
limiting line passes through the 99th percentile of N·H_QMD² in the observed plot-measures, containment of the
projections within the observed density envelope does not test the mortality model. We therefore also compared the
projections with a maximum size-density line estimated from the same plot-measures without reference to β. The line
ln N = b₀ + b₁ ln QMD was fitted by linear quantile regression at τ = 0.95 and τ = 0.99 to the 471 live
plot-measures (147 plots, 101 installations), with 95% intervals from an installation-cluster bootstrap
(B = 2,000). At τ = 0.99 the slope was −1.43 (95% interval −1.68 to −1.20), consistent with Reineke's −1.605 and
shallower than the −1.71 implied by the engine's diameter-height allometry; at τ = 0.95 it was −1.18 (−1.46 to
−0.92). No point projection of the deployed engine, for natural or planted, even-aged or uneven-aged stands on any
site class over 100 years, exceeded either line. Planted stands approached the τ = 0.99 line most closely, reaching
74% of its density (436 stems ha⁻¹ at a QMD of 39.6 cm, high site class, age 24), with a smallest absolute margin of
100 stems ha⁻¹ (421 SDI units) at age 77; natural stands reached at most 47% of it. None of the Monte Carlo
replicates crossed the τ = 0.99 line. The comparison discriminates between parameterizations: with the fitted
β = 0.117, planted projections exceeded the τ = 0.99 line by up to 69 stems ha⁻¹ (14%) and lay above the upper
95% bootstrap limit of the τ = 0.95 line in 16% to 24% of years. The boundary is defined by few installations (five
at τ = 0.99), none with QMD above 38 cm, so above 40 cm, where planted projections come closest, the comparison
relies on the linear form of the line.

Suggested main-text sentence: Projections from the deployed engine remained below a maximum size-density line
fitted to the observed plot-measures by quantile regression (τ = 0.99, slope −1.43, 95% interval −1.68 to −1.20),
with planted stands reaching at most 74% of the limiting density (Supplemental Section 6).

## Figure

`out/Fig_selfthinning_QR.png` (600 dpi) and `out/Fig_selfthinning_QR.pdf`, 174 by 118 mm. Suggested caption:
Stand density against quadratic mean diameter (log axes) for 471 observed *Acacia koa* plot-measures (circles
natural, triangles planted), the quantile regression limiting lines at τ = 0.95 (solid) and τ = 0.99 (dashed) with
installation-cluster bootstrap 95% bands, the engine's own limiting line (dotted), and even-aged projections over 100
years by site class (markers at ages 20, 40, 60 and 100; circles natural, triangles planted). (a) Deployed engine,
β = 0.160; (b) variant B, β = 0.117.

## What was not verified

The manuscript and supplement text of Section 6 were not read in this job; "the envelope Section 6 uses" is taken to
be the envelope of `envelope_check_v82.py` (the source named for those values in the deposit's SOURCE_OF_TRUTH.md)
together with the beta anchor, both reproduced exactly. The containment test uses the six-cell variant B grid and
the deployed long-term trajectory file; the 13 density and thinning scenarios of variant B were not tested against
the line. No held-out data were available, so the fitted line is not data-independent of the anchoring.
