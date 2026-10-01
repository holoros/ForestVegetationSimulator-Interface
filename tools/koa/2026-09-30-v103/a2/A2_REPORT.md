# A2_REPORT, koa v103 Stage A2: engine patch, weighted BAL fix, validation, Monte Carlo, Aviva grid

Job ~/jobs/koa_v103_20260930 on firebreather, 30 September 2026. Settled decisions carried without change: BYI in index units; option A; dDBH is the v102 vector with origin constants re-solved on the v103 NO frame under the live list percentile BAL (A1-D6); dHT_L_NO (A1-D1); Garcia beta 0.1480 from live koa stems; HCB_P kept; Eq. 5 at v102 (A1-D2) and Eq. 5a at v103; engine BAL percentile weighted by expf (BAL_PERCENTILE_WEIGHTED = True). Bias is predicted minus observed throughout. Percent differences are (v103 - v102)/v102. Two red team passes bracket this stage: a2/redteam/2026-09-30_koa-v103-A1A2_REDTEAM_REVIEW.md (RT1, NOT READY) and a2/redteam2/2026-09-30_koa-v103-postfix_REDTEAM2_REVIEW.md (RT2, READY WITH DISCLOSURES once its five must-change items are done; all five are closed below).

## 1. Weighted BAL fix and rerun chain

RT1 finding 1 showed that the engine percentile BAL equalled the live list percentile only in the first projected year, because records are never dropped (expf floored at 1e-5) and were ranked unweighted; the survivors' BAL fraction fell to 0.09 to 0.28 while the frame definition stays near 0.5. The fix, koa_equations.bal_percentile_fraction_weighted, returns (W_ge,i - w_i)/(W - w_i), the expf share of the other stems at least as large as the subject. It reduces to the rule of record (1 - (r_min - 1)/(n - 1)) when expf is equal within a plot, which holds for every source except the FIA microplot records (102 of 1,071 natural dDBH rows), so the A1 gate that justified the constants is unaffected for all equal-expf sources. RT2 confirmed it against a hand computation (2,000 random lists, maximum difference 3.6e-10) and found it on every Python path that builds a tree list BAL; the fraction now holds at 0.48 to 0.50 over 100 years.

a2/run_balfix_chain.sh ran 13:24 to 13:55 ADT, every step exit 0. Switch-off gate (False on a copy) reproduced the pre-fix trajectories and validation exactly (WORST 0.000e+00 twice). MORT_CAL (natural) re-solved 2.46620 to 2.54275, SE of log 0.24335, 24 intervals. The HiGy.R mirror now implements the same weighted percentile (koa_bal_percentile_weighted, switch KOA_BAL_PERCENTILE_WEIGHTED = TRUE, conventional calc_bal kept): new BAL parity cases (3 hand cases, 4 edge cases, 200 random lists with 3,052 tied records, and 10 yr projections on PSP 202 and Waiakea 24) agree to 1.4e-15, and the 18 mortality parity cases are byte identical before and after the edit (a2/higy/PARITY_BAL_REPORT.md). The stale "known residual" comment in project_psp was removed; executable code md5 unchanged.

## 2. Post-fix results against the pre-fix run and v102

Validation on the 23 units as built in A2 (before the rebuild in section 3), QMD bias in cm:

| Group | v102 | Pre-fix v103 | Post-fix v103 |
|---|---|---|---|
| DOFAW natural (6) | -2.19 | +3.18 | -0.28 |
| FIA subplots (6) | -0.89 | +8.82 | +9.78 |
| Planted (11) | -1.81 | -0.74 | -0.93 |

The fix removed the DOFAW over-prediction (RT1 predicted -0.37) and left the natural failure confined to the FIA subplots.

Table 8 point path. Natural QMD at 100 yr is 47.3, 60.0 and 65.4 cm on BYI 100, 264 and 450 (pre-fix 50.3, 65.1, 71.8), removing the High site natural over planted crossover. Planted QMD at 40 yr is 37.8, 44.5 and 47.0 cm (pre-fix 40.3, 48.7, 52.4) and planted TPH at 40 yr rises 10 to 20 percent. Against v102, planted stands now sit below from age 40 (QMD -1.0 to -5.8 percent and VOL -2.6 to -12.4 percent at 40 yr; VOL -13.5 to -14.3 percent at 100 yr). Natural stands remain above v102 (QMD +14 to +21 percent, VOL +20 to +45 percent at 20 to 40 yr), which follows from the d to l constant change and the D1 repair rather than the fix. Planted MAI culminates at 12, 8 and 7 yr (13.2, 20.3, 26.2 m³ ha⁻¹ yr⁻¹), natural at 37, 25 and 20 yr. Uneven-aged Table D is the largest version change: QMD +21.5 to +38.2 percent and TPH -19.6 to -35.9 percent against v102.

Bakuzis. Reineke slopes after peak SDI: natural -1.55, -1.85, -2.03 (pre-fix -1.52, -1.83, -2.00; v102 -1.33, -1.51, -1.64), planted -2.03, -2.32, -2.56 (pre-fix -2.06, -2.46, -2.78). Planted 264 and 450 still flag (2 flags against 1 in v102). BA site ordering holds to year 92 (natural) and 80 (planted), VOL to 149 and 167; both inversions predate the fix and fall outside a 40 to 52 yr rotation.

Aviva grid (16 cells against the 24 September grid), range across cells:

| Age (yr) | BA % | QMD % | Stems % | VOL % |
|---|---|---|---|---|
| 20 | -0.3 to +8.0 | +0.6 to +4.3 | -3.2 to -0.1 | -1.3 to +9.3 |
| 40 | -7.4 to +5.7 | -3.7 to +3.6 | -5.4 to -0.1 | -10.6 to +6.6 |
| 45 | -8.2 to +5.4 | -4.4 to +3.4 | -5.8 to +0.3 | -11.5 to +6.2 |
| 52 | -9.3 to +3.3 | -5.2 to +2.5 | -5.9 to +0.9 | -12.6 to +2.1 |
| 60 | -9.9 to +2.9 | -5.6 to +2.2 | -6.0 to +1.3 | -13.4 to +1.7 |
| 100 | -10.9 to +0.2 | -6.2 to +1.0 | -6.0 to +1.7 | -14.0 to -1.1 |

The change matters for the RLF model. It is density driven: in the 45 to 52 yr window VOL changes -3.5 to +6.6 percent at 100 TPA and -12.6 to -2.2 percent at 400 TPA, and the 300 and 400 TPA Excellent and Good cells, which carry most of the revenue, lose 8.7 to 12.6 percent (Excellent 400 TPA at 52 yr: BA 263.7 to 239.2 ft² ac⁻¹). The fix itself removed the pre-fix stems loss (to -16 percent). The age offset, the 69.7 cm DBH cap binding at ages 27 to 34, the VOL unit and the Low Feasibility domain note are now in a2/fin/out/README_grid.md. Nothing has been sent.

## 3. Red team must-change items

Validation (RT1 item 2, RT2 item 3). a2/closeout/validation/ rebuilds the validation with FIA plots pooled from their four subplots at x1 expansion (EXPF/4 of the subplot rebuild, which returns TPA_UNADJ per ha), a minimum of 20 live koa records at the first measurement, observed survival weighted by expf like predicted survival, and FIA 15-1-1-2628 reported as a disturbance case (koa BA down about 60 percent in 9 years). Units fall from 23 to 17 plus 2628: 2647 and 4895 hold 19 records each and drop out, and 15-1-7-1076 has no BYI. Every remaining unit is in the dDBH NO fitting frame (new column in_fit_frame, 13 to 326 rows per unit) and the six natural units also set MORT_CAL (in_sample), so Table C is a stand level goodness of fit check over 4 to 52 yr spans, not an independent validation of either origin.

| Unit set | n | Survival bias (weighted) | QMD bias (RMSE), cm | BA bias (RMSE), m² ha⁻¹ |
|---|---|---|---|---|
| v103 natural | 6 | +0.060 | -0.28 (1.71) | +0.60 (8.93) |
| v103 planted | 11 | +0.030 | -0.93 (2.28) | -1.80 (13.30) |
| v103 all | 17 | +0.040 | -0.70 (2.09) | -0.96 (11.94) |
| v102 natural | 6 | +0.088 | -2.19 (3.38) | -1.15 (9.05) |
| v102 planted | 11 | +0.027 | -1.81 (2.81) | -3.85 (14.22) |
| 2628, v103 (v102) | 1 | -0.112 (-0.097) | +9.80 (+7.98) | -0.11 (+0.33) |

TOST at 25 percent passes QMD for all three groups and survival for all and planted; BA passes only for all. With a 15 record minimum the two dropped FIA plots return as the only out of sample natural units, and v103 does worse than v102 on them (QMD bias +3.85 against +1.21 cm, survival -0.181 against -0.119); this sensitivity belongs in the main text beside Table C. The natural BA errors are large and cancel (Kulani 23 predicted 28.0 against 41.5 observed; Waiakea 24 24.4 against 13.6).

Table hygiene and figures (RT1 item 3). Table A and D headers read (v103 - v102)/v102 with the v102 value in parentheses in D; C1 and C2 report predicted minus observed (compare_v103.py, backup _PREV_20260930). FigS4 and FigS5 in out_m1 were regenerated twice, after the fix and after the MC promotion (exit 0; the stale 11:57 files are kept in a2/closeout/).

Joint Monte Carlo (RT1 item 5, RT2 item 4). The draws resampled the four sources with replacement (33 source sets), so multiplier tails were source identity: the natural dDBH multiplier median was 1.44 against 0.599 in the 25 draws without DOFAW or FIA, and the planted dHT multiplier 0.161 against 1.193 in the 26 draws without either PSP source (a2/closeout/jointmc/source_set_sensitivity.csv). The replacement keeps every source and resamples installations within it, reproduces the engine constants to 2.4e-6, and is now the MC of record (a2/joint_draws_v103.R; the source set script and outputs are kept with _srcset_PREV_20260930). sd of log: cal_dd_nat 0.401 to 0.351, cal_dd_plt 0.388 to 0.365, cal_dh_nat 0.806 to 0.648, cal_dh_plt 0.808 to 0.644. Point values are identical (maximum difference 0.0). Interval widths are 0.56 to 0.91 of the previous widths for natural QMD, 0.63 to 0.78 for planted QMD and 0.58 to 1.05 for VOL, and the natural QMD point now sits at 0.31 to 0.42 of its interval (0.17 to 0.33 before). Table 8 takes its multiplier spread from the joint draws: koa_equations.cal_draw sets CAL_DDBH, CAL_DHT and MORT_CAL_LIVE from one draw per replicate, and the CAL_*_SE_LOG constants are not read by any engine file. Regressing log multiplier on the drawn vector gives R² 0.96 to 0.99 with residual sd of log 0.035 to 0.126, the same size as the vector-fixed bootstrap SE of log c, so almost all of the multiplier width is the re-solve compensating the vector draw. cal_draw also overwrites the increment vectors and HT_P, so the separate b8 and HT_P perturbations in regen_m1.set_params are inert. The KMR PSP and natural PSP cells hold one installation each and cannot vary. The uneven-aged MC uses 300 replicates.

## 4. Planted domain

The planted rows are dominated by PSP one year intervals (3,433 of 3,900 dDBH rows), almost all under age 18, over BYI 158 to 561 for PSP; KMR PSP extends to BYI 109 and Kulani 12 (planted 1949, BYI 25, 52 yr) is the only old planting. Kulani 12 is out of domain on both axes and is over-predicted (BA 43.8 against 13.6 m² ha⁻¹, survival 0.54 against 0.19). Planted output beyond about age 18, and at BYI 100 (Table 8 Low) or 120 (grid Low Feasibility), is extrapolation. The pooled planted multiplier hides source heterogeneity (dDBH c by source: DOFAW 0.96, PSP 2.19, KMR PSP 3.03).

## 5. Parallel tracks

Figures (a2/figs/): Figs 3 to 6 and S1 to S8 rebuilt on engine_v103 in the v104 style, TIFF 600 dpi and PNG embeds, contact sheet and md5s. S5 now shows the 18 plot level units with 2628 marked separately; Fig 5 bias flips sign to predicted minus observed; Fig 3 gains bootstrap bands; S2 plots the deployed prediction because the dHT constants (0.44 natural, 2.89 planted) make the uncalibrated scale meaningless, which needs a caption change. Number registry (a2/registry/numbers_v103.json): 106 keys (93 carried, 13 new), 4 null with reasons, 21 of 21 gate numbers agree when derived two ways; 65 of the 93 carried keys move more than 5 percent. Second red team: section 3 and RT2.

## 6. Deviations, open items and new defects

A2-D1 validation unit changed from FIA subplot to FIA plot with a 20 record minimum; A2-D2 joint MC resampling changed from sources to installations within source; A2-D3 HiGy.R BAL path changed to the weighted percentile.

O1: HiGy.R HiGYOneStand and project_psp still differ beyond BAL (found by the parity work, not fixed): HiGy.R keeps input crown ratio with 2.5 percent recession where project_psp resets from HCB_P; calc_dht uses tree ba in the b6 term instead of ba.plot; HiGy.R applies the Stage 1 gate and tree_eq allocation; the crown recession BAL reuses a start of step ba (up to 5.9 m² ha⁻¹ off). By year 10 the planted test list differs by up to 5.0 cm DBH. This matters for the HiGy 0.5.0 release and the note to Ben Rice. O2: no out of sample validation unit remains for either origin. O3: dHT site term not identified (b8 95 percent -0.147 to 0.834) and dHT under-predicts above 15 m (settled). O4: the Stage 1 json conditional weighted mean (0.10961) equals v102 while a rerun gives 0.10861, so that field looks carried over. O5: PSP 105 to 108 2009 visits are coded all dead (inherited), which puts those Fig 5 points near +0.99. O6: the S3 baseline ML fit is unstable (5 of 62 jackknife folds failed). O7: Origin label in the frames reads Natural on PSP rows whose Planted flag is 1 (recoded in inc_v103.R; label only).
