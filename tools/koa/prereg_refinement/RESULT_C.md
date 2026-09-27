# PREREG-KOA-01 variant C: origin transferability, leave-one-source-out

Run 2026-09-26 on firebreather (ifm-kershaw), R 4.5.1, seed 20260926.
Job: ~/jobs/koa_loso_origin_20260926. Nothing outside this folder was written.
No coordinates were read, printed or written; the frames carry no lat/lon columns and the
scripts assert that before use.

## VERDICT AGAINST THE PRE-REGISTERED CRITERION

The origin contrast does NOT survive leave-one-source-out, so under the criterion fixed on
2026-09-26 ("C changes the manuscript only if the origin contrast fails to survive
leave-one-source-out") variant C changes the manuscript, and the two-scenario presentation of
natural against planted as separate management regimes with separate rotation ages and separate
yield tables is not supported by the calibration it rests on.

The failure is not marginal and not an interval technicality. With DOFAW held out, the
best-fitting refit REVERSES the sign of the contrast in both responses: natural 1.09 against
planted 0.82 on diameter increment, natural 1.52 against planted 1.09 on height increment.

## What was anchored to what

The deployed v102 origin multipliers are reproduced exactly before anything is held out. The
producer is track3/inc/loso_v102.R FRAME=V102 and track2/inc_refit.R: the V102 increment frames,
the nlme fits in track2/inc/inc_fits.rda, CFX dDBH 1.36869 and dHT 1.030, so k is the engine
multiplier and not a rescaled quantity.

  resp  origin   recomputed here   koa_params.py (engine_v102)
  dDBH  natural  0.405479692       CAL_DDBH 0.40548
  dDBH  planted  1.436067291       CAL_DDBH 1.43606
  dHT   natural  0.519111048       CAL_DHT  0.51917
  dHT   planted  2.647610349       CAL_DHT  2.64739

Diameter reproduces to the fifth decimal. Height differs in the fifth and fourth decimal for a
reason that is provenance, not arithmetic, and is recorded under "Incidental findings" below.

## Resampling unit

The cluster is the installation within source (Data x Install), the same unit calib.R used for
the deployed CAL_*_SE_LOG. Installations are resampled with replacement, never records. Two
schemes are reported: unstratified over all training installations (primary, and the scheme the
deployed pipeline uses) and stratified by source (sensitivity). Stratification is the weaker
choice here because DOFAW-planted and KMR-planted each contain exactly ONE installation, so
stratifying forces their between-installation variance to zero by construction at precisely the
place where the planted multiplier's non-PSP support lives.

Installations behind each multiplier, whole sample: natural 28 (DOFAW 4, FIA 23, PSP 1),
planted 33 (PSP 31, DOFAW 1, KMR PSP 1).

## A. Multiplier only, deployed fit held fixed, 5,000 installation-cluster resamples

This is what the deployed pipeline does: the increment equations stay fixed and only k is
recomputed without the held-out source.

  resp  held out   k_nat   nat 95%          k_plt   plt 95%          ratio  ratio 95%       overlap
  dDBH  none       0.4055  0.3656 - 0.4893  1.4361  1.2910 - 1.5979  3.54   2.85 - 4.14     no
  dDBH  DOFAW      0.5243  0.2883 - 0.8117  1.4453  1.3035 - 1.6037  2.76   1.76 - 5.02     no
  dDBH  FIA        0.4084  0.3716 - 0.5091  1.4361  1.2915 - 1.5933  3.52   2.76 - 4.07     no
  dDBH  KMR PSP    0.4055  0.3672 - 0.5083  1.3888  1.2678 - 1.5270  3.43   2.73 - 3.94     no
  dDBH  PSP        0.3880  0.3532 - 0.4143  1.8635  0.5182 - 2.0510  4.80   1.28 - 5.76     no
  dHT   none       0.5191  0.3360 - 0.6147  2.6476  2.3971 - 2.8924  5.10   4.19 - 7.98     no
  dHT   DOFAW      0.4585  0.1939 - 0.7964  2.6699  2.4258 - 2.9160  5.82   3.30 - 13.94    no
  dHT   FIA        0.5413  0.3810 - 0.6910  2.6476  2.3956 - 2.8990  4.89   3.76 - 7.15     no
  dHT   KMR PSP    0.5191  0.3470 - 0.6122  2.5607  2.3457 - 2.7709  4.93   4.11 - 7.46     no
  dHT   PSP        0.5043  0.2617 - 0.5856  3.2581  0.5405 - 3.5974  6.46   0.98 - 13.52    YES

One fold of ten overlaps: height increment with PSP held out, ratio 95% interval 0.98 to 13.52,
share of resamples with ratio at or below 1 equal to 0.049. Under the stratified sensitivity no
fold overlaps, for the construction reason given above.

## D. Refit per fold, four starts, best log-likelihood kept, 5,000 cluster resamples

The equations and the multipliers are estimated from the same data, so the honest fold test
refits the increment equation without the held-out source. Each fold is fitted from four starting
vectors (the published record-frame vector with b9, the published vector with b9 = 0, and the
fixed effects of each of the two V102 fits of record) and the highest log-likelihood is kept.
This matters: the diameter equation has two local optima about 3.1 log-likelihood units apart
whose multiplier ratios are 3.54 and 1.89.

  resp  held out   best start        k_nat   nat 95%          k_plt   plt 95%          ratio  ratio 95%      P(ratio<=1)  overlap
  dDBH  none       published DEP     0.4055  0.3656 - 0.4893  1.4361  1.2910 - 1.5979  3.54   2.85 - 4.14    0.000        no
  dDBH  DOFAW      published b9=0    1.0925  0.5813 - 1.8445  0.8194  0.7400 - 0.9031  0.75   0.44 - 1.42    0.714        YES
  dDBH  FIA        published b9=0    0.4825  0.4220 - 0.6910  0.8725  0.7740 - 0.9942  1.81   1.24 - 2.18    0.012        no
  dDBH  KMR PSP    published DEP     0.5220  0.4745 - 0.6574  1.4074  1.2892 - 1.5450  2.70   2.12 - 3.09    0.000        no
  dDBH  PSP        record fit        0.4594  0.3906 - 0.5392  2.8625  0.5876 - 3.3145  6.23   1.16 - 8.36    0.000        no
  dHT   none       deployed fit      0.5191  0.3360 - 0.6147  2.6477  2.3971 - 2.8925  5.10   4.19 - 7.98    0.000        no
  dHT   DOFAW      published b9=0    1.5207  0.6289 - 2.7981  1.0944  1.0104 - 1.1701  0.72   0.39 - 1.75    0.663        YES
  dHT   FIA        deployed fit      0.3575  0.2534 - 0.4655  1.7055  1.5435 - 1.8667  4.77   3.66 - 6.94    0.000        no
  dHT   KMR PSP    deployed fit      0.7930  0.5255 - 0.9406  3.6564  3.3430 - 3.9620  4.61   3.82 - 7.03    0.000        no
  dHT   PSP        deployed fit      0.5851  0.3288 - 0.6671  4.5846  0.6250 - 5.2029  7.84   0.96 - 15.04   0.089        YES

Three folds of ten fail. Two of them reverse the sign.

## What this says about the multipliers themselves

Across folds the diameter natural multiplier runs 0.41 to 1.09 and the diameter planted
multiplier 0.82 to 2.86; the height natural multiplier runs 0.36 to 1.52 and the height planted
multiplier 1.09 to 4.58. Each spans roughly a factor of three to four. A multiplier that moves by
a factor of three when one of four sources is removed is a per-source correction, not a property
of stand origin.

FIA makes the point most sharply on diameter. FIA contributes 102 of 4,790 diameter records and
no planted records at all, yet removing it moves the PLANTED multiplier from 1.436 to 0.873 and
the ratio from 3.54 to 1.81. The origin coefficient is absorbing between-source level differences
through the shared mean function.

The planted multiplier's independence from PSP rests on two installations, one DOFAW and one KMR
PSP, whose within-source multipliers differ by a factor of four on diameter (0.518 against 2.051)
and by a factor of six point seven on height (0.540 against 3.597). That is why the PSP-held-out
fold has a two-atom bootstrap and an interval that reaches down to the natural range.

## Incidental findings, reported not acted on

1. The deployed dDBH and dHT multipliers come from two DIFFERENT fits of the same pair of
   equations. CAL_DDBH (0.40548, 1.43606) and CAL_DDBH_SE_LOG (0.07956, 0.05225) come from the
   V102 deployed-solution-start fit; CAL_DHT (0.51917, 2.64739) and CAL_DHT_SE_LOG (0.14862,
   0.04807) come from the V102 record-start fit. For height the two optima differ by 0.0004
   log-likelihood units and the numbers are interchangeable, so nothing downstream changes, but
   the provenance is inconsistent and should be made uniform.
2. Supplemental Table S20's refit column (k_train_b, ratio_b) is produced by loso_v102.R, which
   restarts every fold from ONE fixed-effect vector. On diameter that start lands in the worse of
   two optima, so S20's refit column compares a fold refit in one basin against a full-sample k
   from the other. Its refit numbers are reproduced here exactly and are not a transferability
   test as they stand. The multi-start table C5_start_sensitivity.csv replaces them.
3. The paper's own S20 source-cluster bootstrap already overlaps across origin, on both
   responses: natural diameter 0.376 to 0.993 against planted 0.518 to 2.051, natural height
   0.253 to 1.193 against planted 0.540 to 3.597. That is a coarser resampling unit than the one
   used here, but it points the same way.

## C. Refit inside every bootstrap draw, still running at the time of writing

A third stage propagates coefficient uncertainty by refitting the nlme inside every bootstrap
draw (200 draws per fold, installations resampled and relabelled so duplicated clusters stay
distinct grouping levels). It is slower than the rest by two orders of magnitude and was still
running when this file was written; it appends to out/C1_loso_multipliers.csv as
variant C_refit_in_bootstrap and saves the draws to out/C2_bootdraws_*.rds, fold by fold, so the
remaining folds will simply appear there.

Two folds had finished, both on diameter:

  resp  held out   nat 95%          plt 95%          overlap
  dDBH  none       0.2807 - 1.1305  0.7768 - 2.1699  YES
  dDBH  DOFAW      0.6246 - 1.5831  0.7541 - 1.4130  YES

Read these with one caveat: stage C starts every draw from a single fixed-effect vector, the
deployed fit's, which on diameter is in the worse of the two optima, so the diameter draws mix
basins and the intervals are part optimum-hopping and part sampling. That is a reason not to
quote them as the interval of record. It is not a reason to doubt the verdict, in either
direction: adding coefficient uncertainty widens intervals, and wider intervals can only produce
more overlap, never less, so stage C cannot move the verdict from "fails" to "survives". The
verdict above rests on stages A and D, which are complete.

## Files

  C_loso.R                     stages A (multiplier only), B (single-start refit) and C
                               (refit inside each bootstrap draw)
  D_multistart.R               stage D, the four-start fold refit, the headline refit result
  out/C0_reproduction_gate.csv reproduction of the deployed multipliers before any holdout
  out/C1_loso_multipliers.csv  stages A and B, both bootstrap schemes
  out/C3_refit_diagnostics.csv per-fold refit convergence, iterations and log-likelihood
  out/C4_loso_multistart.csv   stage D multiplier table with intervals and overlap flags
  out/C5_start_sensitivity.csv every fold by every start, with log-likelihood and ratio
  run.log, runD.log            run logs
