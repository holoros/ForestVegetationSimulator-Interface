# Supplemental Table S20, start-sensitive refit cell: recomputation

Run 2026-09-27 on firebreather (ifm-kershaw), R 4.5.1, nlme 3.1.170. Job ~/jobs/koa_s20fix_20260927.
Nothing outside this folder was written. The increment frames carry no coordinate columns and both
scripts assert that before use; only origin-level aggregate multipliers and ratios are written.

## What the S20 cell is

The cell annotated "should be read as 1.407" is not a held-out ratio. In the supplement (v100) it sits
in the column "Multiplier, refit", which is k_train_b in the producer, track3/inc/loso_v102.R run with
FRAME = V102: the planted calibration multiplier computed on the TRAINING sources after refitting the
dDBH increment equation without KMR PSP, k_train_b = sum(obs, train, planted) / sum(p_fold, train,
planted), where obs = dDBH / YIP and p_fold = fitted(fold refit, level 0) / YIP x 1.36869. The held-out
ratio of the same row is the next column, "Ratio, refit" (ratio_b = sum(obs, held out) / sum(predict(fold
refit, held out, level 0) / YIP x 1.36869 x k_train_b)), printed as 1.81. Because ratio_b is built on the
same fold refit and on k_train_b, it is start-sensitive too, and the current caption does not flag it.
Both cells are recomputed here.

## Reproduction of the printed 0.914 (arm identification)

A copy of loso_v102.R, changed only in its two path lines so that it reads the same inputs and writes to
this folder (S1_producer_repro.R), was run with FRAME = V102 and the producer's own seed 20260916. All
three of its outputs are byte-identical to the producer outputs behind S20 (md5 of I_loso.csv
ccc2e3471d5be28b2bbb4aee88f3e09a, I_source_bootstrap.csv 28f6c1aed2de6afa7d63ce16f6f58dcb,
I_k_by_source.csv 11dbecf7be7ce46e668fd231a00315d9, in both places). The KMR PSP dDBH row gives
k_train_b = 0.913572314922967 (printed 0.914) and ratio_b = 1.811934438 (printed 1.81). The arm is the
producer's single start from the fixed effects of the V102 deployed-solution fit, which lands at
logLik -8979.3535.

## The four starts for the dDBH fold with KMR PSP held out

The fold was refitted from the four starting vectors of D_multistart.R (koa_loso_origin_20260926),
using the producer's own definitions of k_train_b and ratio_b (S2_multistart_S20.R).

  start                    logLik        iterations  k_train_b (planted)  ratio_b (held out)
  published record DEP     -8978.2905    6           1.407426             1.584412
  record fit fixef         -8979.3470    6           0.913470             1.811836
  published, b9 = 0        -8979.3499    4           0.913527             1.811946
  deployed fit fixef       -8979.3535    6           0.913572             1.811934

The best solution is 1.063 log-likelihood units above the other three, which agree with each other to
within 0.007 units. Its planted multiplier is 1.407426, which is the 1.407 the caption asks readers to
substitute, and it matches D_multistart.R's k_planted for this fold (1.40742559576375) to every printed
digit. So the annotated value is confirmed. The held-out ratio from the best solution is 1.584, not the
printed 1.81: KMR PSP grows at 1.58 times the diameter increment the refit, recalibrated on the other
sources, predicts for it, rather than 1.81 times. The bias on the held-out records moves from 1.314 to
1.081 cm per year.

## Interval

The producer reports no interval for any S20 cell. Its only resampling is the 2,000-draw source
bootstrap of the pooled full-sample multipliers (I_source_bootstrap.csv), which does not involve the
fold refits. No interval was therefore computed for the recomputed cells, to keep the column on the
producer's conventions. For context only, variant C's stage D gives the installation-cluster interval
of the planted multiplier in this fold, conditional on the same best solution, as 1.289 to 1.545
(5,000 unstratified resamples, seed 20260926, C4_loso_multistart.csv). A cluster interval for the
held-out ratio itself does not exist in any useful sense, since the held-out side is a single
installation.

## The other eleven rows

All twelve refit rows were recomputed from the four starts. The printed values are the producer's
single-start values, reproduced exactly above. At the best of four starts the held-out ratios round to
the printed two decimals in all eleven rows. Three refit multipliers move by one unit in the third
decimal, from starts that differ by less than 0.003 log-likelihood units, which is convergence
tolerance rather than a different solution:

  dDBH  DOFAW  natural  1.092 printed, 1.093 at best start (1.092536)
  dHT   DOFAW  natural  1.520 printed, 1.521 at best start (1.520732)
  dDBH  PSP    planted  2.862 printed, 2.863 at best start (2.862515)

One other fold, dHT with PSP held out, also has two solutions 1.02 log-likelihood units apart, but the
producer's start already lands in the better one, so its printed values stand. The caption's statement
that every fold other than dDBH with KMR PSP held out "is insensitive to the start" is therefore
slightly too strong: dHT with PSP held out is start-sensitive, it simply was not affected.

## Proposed replacement

In the row dDBH | KMR PSP | planted, replace "Multiplier, refit" 0.914 with 1.407 and "Ratio, refit"
1.81 with 1.58. If the caption is to say that the refit columns are the best of four starts literally,
also change the three third-decimal multipliers above (1.093, 1.521, 2.863); otherwise leave them.

Replace the two caption sentences beginning "The refit columns were recomputed" and ending "should be
read as 1.407." with:

"The refit columns are from the best log-likelihood of four starting vectors per fold. Two folds have a
second solution about one log-likelihood unit below the best, and a single start reached it only for
ΔDBH with KMR PSP held out, where it gives a planted multiplier of 0.914 and a held-out ratio of 1.81
instead of 1.407 and 1.58."

A shorter alternative that drops the history: "The refit columns are from the best log-likelihood of
four starting vectors per fold; only the ΔDBH fold with KMR PSP held out depends on the start."

The sentence on the DOFAW fold that follows can stay as it is. No other sentence of the supplement
quotes the KMR PSP refit multiplier or ratio (searched for 0.914, 1.407, 1.81 and 1.58).

## Files

  S1_producer_repro.R          loso_v102.R with its two path lines redirected here, the reproduction
  S2_multistart_S20.R          four-start refit of every S20 fold, producer definitions
  loso_v102_ORIGINAL_COPY.R, D_multistart_ORIGINAL_COPY.R   unmodified copies for the record
  out_repro/I_*.csv            reproduction outputs, byte-identical to track3/inc/out_V102
  out/S2_all_starts.csv        every fold x start x origin: logLik, k_train_b, bias_b, ratio_b
  out/S2_S20_refit_best.csv    best start per S20 row, with the producer's single-start values beside it
  S1.log, S2.log, chain.log, chain.sh   logs and launcher
