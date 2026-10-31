# PREREG: paired Monte Carlo of BYI ordering in the koa v104 yield tables (a5/pairmc)

Written 31 October 2026 (about 14:25 ADT), before any projection, residual extraction or probability was computed.
Job ~/jobs/koa_v104_20261030, working directory a5/pairmc only. Engine: a byte copy of engine_v103 (= engine_v104) in a5/pairmc/engine
(out_m1* directories, AK_PLT_GEO.csv and koa_regen.tgz not copied). Nothing outside a5/pairmc is modified.

## Question
Does projected stand volume at a higher BYI (Biomass Yield Index, Mg ha-1) level exceed volume at a lower level once parameter,
process and BYI (map) error are all propagated?

## Design
- Stands: the Table 4 even-aged natural and planted stands, built and projected exactly as regen_m1.py does
  (run_candidates.wlist(planted, byi) Weibull tree list, run_candidates.project(..., "M0") under the regen_m1 M1 gated mortality wrapper),
  projected 40 years. Outputs at ages 20, 30, 40: volume VOL (m3 ha-1), basal area BAPH (m2 ha-1), QMD (cm).
- BYI levels: nominal 100 (low), 264 (medium), 450 (high), from run_candidates.SCEN.
- Replicates: R = 1,000 (minimum 500 if runtime forces fewer; any reduction will be stated). Joint parameter rows 0 to 999 come from a copy of
  a4/joint_draws_v104.R run with KOA_NJOINT = 1000, the same seed 20261030, 3 cores, output a5/pairmc/jointmc/out. Because the draws are
  generated sequentially from the seed, rows 0 to 499 must equal the published 500-row table a4/jointmc/out/K_joint_draws.csv (gate J).

## Error sources per replicate r
a. Parameter uncertainty (shared by all three BYI levels of an origin in replicate r: the pairing). Exactly the regen_m1 parameter set:
   joint row r (height vector, dDBH and dHT vectors, origin multipliers, Stage 1, natural mortality level), the CF_DDBH draw r of the
   dedicated CF generator (seed 42 + CF_DDBH_MC_SEED_OFFSET, clipped as in regen_m1), and the Garcia alpha draw r of the seed 42 stream
   (scenario 0 stream position, i.e. the 7th normal of each replicate). The published run gives each scenario its own alpha stream offset
   (scenario index x 500); the paired run shares the scenario-0 alpha draw across levels and origins. Everything else regen_m1 draws from the
   seed 42 stream is overwritten by the joint row and therefore has no effect.
b. Process error. The engine projects deterministic means. The increment equations dDBH_L_NO and dHT_L_NO (out/inc/fits_v103.rda) are
   log-linear (gr.hat3: exp(b0 + ...)) with random intercepts on b0 for Data source, Installation and TreeID, plus an additive within-tree
   residual with varPower. Faithful stand-level process error that the engine can carry:
   - installation random intercept, one draw per stand (replicate x origin x BYI level, independent across levels, because stands on
     different sites are different installations): multiplier exp(tau_I z - tau_I^2/2), tau_I = 0.7764691 (dDBH) and 0.2255650 (dHT),
     z standard normal, dDBH and dHT independent (separate fits, no estimated correlation);
   - TreeID random intercept, one draw per cohort record (20 records per stand), carried with the record through the annual re-sorting:
     exp(tau_T z - tau_T^2/2), tau_T = 0.2763890 (dDBH) and 0.2917907 (dHT);
   both persistent over the projection and mean preserving, so they add variance without moving the engine mean.
   Omitted, with reasons: (1) the within-tree annual residual, because each cohort record stands for n0/20 trees and independent tree-year
   residuals average out within a record; applying a tree residual to a record would overstate stand variance by treating its trees as
   perfectly correlated; (2) the Data-source random intercept, because it is a protocol and network effect that the engine marginalizes
   through CF (CF_DDBH_MARGINAL, CF_DHT) rather than a property of a new stand; (3) mortality stochasticity, because the engine's mortality
   is an expectation (M1 gate, expectation preserving) with no fitted stand-level random component; (4) height-diameter and crown residuals.
c. BYI (map) error. The Kona BYI forest refitted on its 235 BYI > 0 Hawaii Island plots (ranger, the stored arguments, seed 42, exactly as
   koa_rv_byi_20260928/04_rf_cv.R object rn) gives out-of-bag predictions; the residuals e = observed - predicted (n = 235) are written without
   coordinates or plot keys. Gate B: refit OOB RMSE must equal 217.611 (out_T3_rf_cv_summary.csv). Spatially blocked residuals cannot be
   regenerated because the blocks are built from FIA true coordinates, which this track must not read; the OOB residuals are therefore
   inflated about their mean by k = RMSE(20 km blocks) / RMSE(OOB) = 227.938 / 217.611 from out_T3_rf_cv_summary.csv (Kona trained on BYI > 0),
   so their spread matches the blocked error.
   Scale rule (decided from the residual pattern, before any projection): compute Spearman rho between |e| and the prediction (additive scale)
   and between |ln(obs/pred)| and the prediction (multiplicative scale); use the scale with the smaller |rho|.
   Additive: true BYI = nominal + e*, e* resampled from the inflated residuals. Multiplicative: true BYI = nominal x exp(l*), l* resampled from
   the inflated log ratios.
   Truncation: true BYI must lie in [25.147, 691.244], the BYI range of the increment calibration frames (frames/final/dDBH_NO_v103_model.csv
   and dHT_NO_v103_model.csv), beyond which the engine extrapolates; an out-of-range draw is redrawn (truncated distribution). The share of
   first draws that fall outside is reported per level. Draws are independent across levels and of the process draws. The true BYI drives
   both the initial tree list and the projection.

## Variants (each R replicates, levels paired by parameter draw where parameters vary)
- P: parameter only (paired). PP: parameter + process. PPB: parameter + process + BYI (the decision variant). B: BYI error only (base
  parameters, no process error), to show the BYI share. The BYI draws of B and PPB are the same numbers; the process draws of PP and PPB are
  the same numbers.

## Outputs
P(V_high > V_low), P(V_med > V_low), P(V_high > V_med) per age (20, 30, 40), origin and variant, strict inequality, Monte Carlo
SE sqrt(p(1 - p)/R); 2.5 and 97.5 percent volume (and BAPH, QMD) per level, age, origin and variant.

## Sanity gate (stop if it fails)
Gate 1: with the published (unpaired) alpha offsets and joint rows 0 to 499, the reproduction must equal reps_evenaged_M1.csv
(engine_v103/out_m1) per replicate at years 20, 30 and 40 (max |diff| < 1e-6 on VOL, BAPH, QMD), and its 2.5 and 97.5 percent VOL at
ages 20 and 40 must equal table8_evenaged_M1.csv (the Table 4 ranges) to the published 2 decimals. The paired 1,000 replicate P intervals
are reported beside the published ranges but are not a gate (different draws by design).

## Decision rule (verbatim)
"Ordering is SUPPORTED at an age if P(V_high > V_low) ≥ 0.90, WEAK if 0.50 < P < 0.90, NOT SUPPORTED if P ≤ 0.50; the same for medium vs low and high vs medium."
Applied to variant PPB for each comparison, age and origin.

## ADDENDUM A5 (written 31 October 2026 15:04 ADT, before any A5 or BOOT projection)
Trigger: the Stage 3 ordering fix (a5/stage3fix/patch_stage3_rc.py; run_candidates.project now reads koa_params.STAGE3_COEF) and the
coordinator's request for a bootstrap-covariance parameter variant.
- Engine: a fresh copy of the fixed engine_v103 (taken after a5/stage3fix/run_a5.log reports "A5 DONE" with chain 1 and chain 2 exit 0) in
  a5/pairmc/engine_a5 (same exclusions as before). Outputs to a5/pairmc/out_a5; the v104 outputs in a5/pairmc/out are kept unchanged.
- Variants P, PP, PPB, B rerun exactly as preregistered above (same 1,000-row joint table, same streams, same prep draws out/prep_draws.npz).
- Sanity gate: as above, against the regenerated engine_v103/out_m1/reps_evenaged_M1.csv and table8_evenaged_M1.csv. Gate J rechecks rows
  0 to 499 of the 1,000-row table against the regenerated a4/jointmc/out/K_joint_draws.csv.
- New variant BOOT (parameter uncertainty with installation-bootstrap coefficient draws), paired across BYI levels and origins as P:
  replicate r uses joint row r for Stage 1 (s1_int, s1_lnsdi, s1_pl, pbar) and the natural mortality level (kmort), the CF_DDBH draw r and the
  Garcia alpha draw r (scenario-0 stream), exactly as P; it replaces
  (i) the dDBH vector b0 to b9 and CAL_DDBH by bootstrap replicate k = (r mod 400) + 1 of out/inc/boot_v103_dDBH_L_NO.csv (400 of 400
      converged; installation-cluster bootstrap within source, seed 20260930 + k), CAL_DDBH = (c_natural, c_planted) / CF_DDBH_MARGINAL (1.50128),
      the same cal = c / CF convention as the joint draws;
  (ii) the dHT vector and CAL_DHT by replicate k of out/inc/boot_v103_dHT.csv (dHT_L_NO, 400 of 400 converged, same seed rule, so dDBH and dHT
      replicate k share the seed), CAL_DHT = (c_natural, c_planted) / CF_DHT (2.41982);
  (iii) the height vector HT_P (a0, a1, b, c, g1, g2) by the converged draws of the installation bootstrap on the final height frame
      (a5/rerun/h/draws, still running): the converged draws present at launch are snapshotted to a5/pairmc/boot_inputs/h_draws_snapshot.csv,
      their count is reported, and replicate r uses converged draw (r mod n_h) in draw order.
  Variant BOOT_PPB adds the same process and BYI draws as PPB. Decision rule unchanged (verbatim above); the preregistered verdict remains
  the PPB variant, with BOOT_PPB reported beside it under the same rule.

## AMENDMENT A5-B (written 31 October 2026 15:43 ADT, after the first BOOT run, before the BOOT rerun)
The first BOOT run produced NaN basal area and volume for 40 of 1,000 replicates (all stands, all ages) in BOOT and BOOT_PPB. Cause: 14 of the
400 rows of out/inc/boot_v103_dDBH_L_NO.csv have ok = TRUE but NA re-solved constants c_natural and c_planted (solve_c failed); all 14 have
b2 > 0 (7 of the 386 complete rows also have b2 > 0). A NaN calibration cannot be projected. Change: BOOT and BOOT_PPB use only bootstrap
draws whose dDBH and dHT constants are both finite (386 draws; dHT has 400 of 400), keeping dDBH and dHT paired by draw number; replicate r
uses the (r mod 386)-th of these draws in draw order. Everything else as in addendum A5 (same 25 snapshotted height draws, same joint rows,
streams, process and BYI draws). The first-attempt outputs are kept as out_a5/prob_ordering_BOOT_attempt1_NaN.csv and in out_a5/raw_w*.csv;
the rerun writes out_a5/raw_boot_w*.csv, and the summary takes BOOT and BOOT_PPB from the rerun only. The exclusion removes 14 of the 21
bootstrap draws with b2 > 0, so BOOT slightly understates the bootstrap spread; this is reported.
