# Red team review, koa v103 Stage A1 close-out and Stage A2 (engine patch, validation, MC, Aviva grid)

Reviewer: adversarial red team, read only. Job reviewed: ~/jobs/koa_v103_20260930 (RUN.md, STAGE1_REPORT.md sections 1 to 8, a2/). Date: 30 September 2026. Every number below was recomputed on firebreather from the job's own inputs unless it is labelled "as reported". Scratch work in ~/jobs/rt_koa_v103_scratch/ (engine runs on a copy of engine_v103, never on the original); scripts and result tables copied to a2/redteam/. No coordinate column was read. Aaron's settled decisions are taken as given; where they have consequences, the consequence is reported, not the decision.

## Overall verdict

NOT READY to carry into v105 as it stands. The A1 gate arithmetic is honest and its l margin is robust to Monte Carlo noise, but the premise the gate rests on is false: the engine's "percentile" BAL path is the live list percentile (l) only in the first projected year. Because the engine never drops a record (expf is floored at 1e-5) and ranks records unweighted, the BAL fraction of the surviving stems decays from about 0.52 to 0.09 to 0.15 over the long DOFAW validation spans and to 0.19 to 0.28 by year 100 in the Table 8 trajectories, while the true expf-weighted l fraction stays at 0.48 to 0.50. The origin constants were solved under l (natural c 0.820), so the engine runs with l-sized multipliers and d-sized or smaller competition. That single mismatch explains essentially all of the DOFAW natural QMD over-prediction (+3.18 cm becomes -0.37 cm with a weighted percentile). The remainder of the natural validation failure (-6.0 cm obs minus pred) is four 1/24 acre subplots of one FIA plot (15-1-1-2628) that lost 78 percent of its koa stems and 60 percent of its koa basal area between 2010 and 2019, where the engine's from-below allocation produces predicted QMD up to 53 cm. The natural "validation" is also mostly in-sample (all six DOFAW natural plots are in the MORT_CAL calibration set and supply 950 of the 1,071 natural rows the dDBH constant is solved on). Fix the engine BAL path, rebuild the natural validation, and regenerate; everything downstream (Table 8, MC, Aviva grid, Bakuzis) moves by amounts comparable to the v102 to v103 change itself.

## Severity table

| # | Severity | Finding | Key numbers | Source file |
|---|---|---|---|---|
| 1 | Critical | Engine "percentile" BAL is not BAL l after year 0: records are never removed (expf floor 1e-5) and are ranked unweighted, so dead weight stays in the rank and the survivors' BAL fraction collapses; constants were solved under l | Stand mean BAL fraction, engine vs expf-weighted l: Kulani 23 0.52 to 0.14 vs 0.50; Laupahoehoe 41 0.53 to 0.15 vs 0.50; Waikamoi 25 0.51 to 0.09 vs 0.50; Table 8 year 100: 0.19 to 0.28 vs 0.48 to 0.49. Weighted BAL moves DOFAW natural QMD bias (pred minus obs) +3.18 to -0.37 cm; year 100 QMD -6 to -12 percent, VOL +0.1 to -7.7 percent; planted QMD at 40 yr -6 to -10 percent | engine_v103/koa_projector.py (project_psp, BAL and expf lines), run_candidates.py L91, koa_equations.bal_percentile_fraction; a2/redteam/rt_bal_log.csv, rt_val_decomp.csv, rt_traj_EW.csv, rt_traj_ballog.csv |
| 2 | Major | Natural validation is largely in-sample and dominated by one disturbed FIA plot; the QMD failure is mostly mortality allocation, not growth | Natural QMD bias pred minus obs +6.00 cm = growth +1.46 + mortality/selection +4.54. DOFAW (6 plots) +3.18 (growth +0.99, mortality +2.18); FIA (6 subplots) +8.82 (growth +1.93, mortality +6.89). 2628 subplots 3 and 4: +25.9 and +13.8 cm, of which +23.4 and +13.4 is selection. All 6 DOFAW natural plots are in MORT_CAL (24 intervals, 7 plots) | a2/out/val_v103.csv, a2/mort/v103/H_mort_intervals_natural_mult.csv; a2/redteam/rt_val_decomp.csv |
| 3 | Major | Natural c rise 0.555 to 0.820 is a definitional artifact (the d to l switch), not a growth signal; the species mismatch is small | v102 engine c 0.555 (CF 1.36869 x CAL 0.40548); v103 NO frame d 0.615 (+11 percent, repair plus solve method); l 0.820 (+33 percent over d); engine consistent koa only BAPH and BAL (k) 0.797 (-2.9 percent vs l). CS frame: d 0.613, l 0.783, c 0.939, k 0.763 | a2/redteam/rt_c_by_bal.csv, rt_koa_share_frames.csv |
| 4 | Major | FIA subplots are not a defensible validation unit, and the observed survival metric is count based while predicted survival is expf weighted | Subplot 0.0169 ha; microplot saplings carry 741 stems/ha each (63 percent of TPH on 2628 subplot 1). Obs survival count vs weighted: 2628-1 0.18 vs 0.08, 2628-2 0.34 vs 0.26, 2628-3 0.15 vs 0.10. Plot level 2628 (4 subplots, x1): obs survival 0.215 vs pred 0.113, QMD 22.3 vs 31.9 cm; BA 25.8 vs 27.8 m2/ha | a2/redteam/rt_fia_plotlevel.csv, rt_val_decomp.csv |
| 5 | Major | Joint MC resamples only 4 sources (33 distinct source sets), so the multiplier intervals are between-source heterogeneity, not sampling uncertainty | cal_dd_nat set by 19 PSP natural rows in 25 draws with no DOFAW or FIA (median 1.19 to 1.74 vs base 0.599); cal_dh_plt set by DOFAW planted rows in 26 draws (0.14 to 0.19 vs base 1.19); cal_dh_nat sd_log 0.81 (v102 0.59); cal_dh_plt 95 percent 0.16 to 4.60 (v102 0.44 to 7.81). CAL_DDBH_SE_LOG in the engine is 0.030 while the joint draws imply 0.40 | a2/mc/out/K_joint_draws.csv, K_joint_summary.csv, a2/joint_draws_v103.R |
| 6 | Major | Aviva RLF grid changes are within MC uncertainty but will move again by similar size once finding 1 is fixed; the prior grid caveats are all still present | Ages 40 to 52: BA -6.3 to +6.9 percent, QMD +3.5 to +5.9 percent, stems -1.8 to -16.2 percent, VOL -7.3 to +8.1 percent. Age 1 row has QMD 7.2 cm, HT 5.7 m, DBHMAX 16.4 cm (age offset); DBHMAX 69.2 cm by age 40 against the 69.7 cm cap; BA peaks at 64 to 94 yr then falls 31 to 46 percent by 200 yr; VOL column is m3/ha in an imperial table | a2/fin/out/yield_grid_compare.csv, koa_yield_grid_200yr.csv, koa_yield_grid_diagnostics.csv |
| 7 | Major | Natural trajectories cannot reach observed natural densities; external anchors are missed on stems and BA | Natural peak SDI 433 to 437 (planted 883 to 895; observed DOFAW natural plot SDI up to 812 to 924). Year 24 natural: TPH 303 to 400, QMD 20.8 to 29.6 cm, BA 13.6 to 20.9 m2/ha vs Scowcroft et al. (2007) UNVERIFIED about 1000 stems/ha, 18 cm, 25.7 m2/ha. v103 moves QMD away from the anchor (v102 17.7 to 24.0 cm) | a2/out/traj_v103.csv, traj_gate.csv |
| 8 | Major | Planted domain: the pooled planted multiplier is PSP dominated and does not describe older DOFAW plantings | dDBH planted c by source: DOFAW 0.96, PSP 2.19, KMR PSP 3.03; dHT: 0.43, 2.90, 4.71. Kulani 12 (planted 1949, BYI 25, 52 yr): pred BA 44.9 vs obs 13.6 m2/ha, pred survival 0.52 vs obs 0.19 | a2/out/diag_c_by_source.csv, a2/out/val_v103.csv |
| 9 | Minor | A1 gate: the l margin is robust to MC spread and the CS vs NO frame choice is immaterial, but the gate is in-sample | 30 seeds: NO intercept region 0.218 (sd 0.006, max 0.228), slope 0.177 (max 0.188); CS 0.218 (max 0.226), 0.170 (max 0.179); 0 of 60 fail. c fails 10 of 10 (0.264). Natural c CS 0.783 vs NO 0.820 (4.7 percent), planted 2.159 vs 2.193 (1.6 percent) | a2/redteam/rt_equiv_seed_summary.csv, rt_c_by_bal.csv |
| 10 | Minor | Bakuzis Reineke slopes steepen; one more cell now flags | Natural -1.33/-1.51/-1.64 to -1.52/-1.83/-2.00; planted -1.86/-2.19/-2.46 to -2.06/-2.46/-2.78; FLAG count 1 to 2 (planted 264 now flags) | engine_v103/out_m1/bakuzis_slopes_M1.csv vs out_m1_v102copy |
| 11 | Minor | Stale supplementary outputs in out_m1 | FigS4_natural_M1.png, figS4_point_nat_M1.csv, figS5_point_plt_M1.csv, FigS5_planted_M1.png dated 11:57, md5 identical to the v102 copy | engine_v103/out_m1 vs out_m1_v102copy |
| 12 | Minor | Table labels and sign conventions | Tables A and D say "v102 minus deployed" but report (v103 - v102)/v102 (natural Low 20 VOL 35.1 to 51.6 printed +46.9). C1 bias is pred minus obs, C2 is obs minus pred. Observed validation BA changed (natural mean 16.0 to 26.5 m2/ha) because FIA observed BA is now x4, so v102 and v103 BA rows are not like for like | a2/out/tables_v103.md |
| 13 | Minor | MC point path sits at the edge of the natural intervals (inherited) | Natural QMD point at 0.16 to 0.40 of the 95 percent interval, TPH at 0.49 to 0.94; v102 0.14 to 0.29. kmort draws mean 2.71 vs base 2.47; cal_dd_nat mean 0.72 vs base 0.60 | engine_v103/out_m1/table8_evenaged_M1.csv, K_joint_summary.csv |
| 14 | Minor | Weakly identified site and height terms (consequences of settled decisions) | dHT b8 ln(BYI) 0.091, bootstrap 95 percent -0.147 to 0.834; dHT size ratio 1.36 at 20 to 30 m (obs/pred); Eq. 5 v103 ln(cr) flips +14.30 to -11.01 and LOIO annual AUC 0.813 to 0.633 with FIA crowns under x4 | STAGE1_REPORT.md 5.3, 5.6 |

## Evidence by question

### Q1. Is the v102 vector gate honest, is the l margin robust, and does NO vs CS matter?

Reproduction. With the inc_v103.R machinery (sourced exactly as a1close_v103.R does) I re-solved the origin constants of the v102 dDBH vector on both v103 frames under d, l and c: NO frame natural and planted c = 0.6147 and 2.0011 (d), 0.8203 and 2.1935 (l), 0.9956 and 2.3896 (c); CS frame 0.6127 and 1.9656, 0.7833 and 2.1595, 0.9389 and 2.3600. These reproduce out/inc/a1close_v102vector_by_bal.csv to the printed digits.

Monte Carlo robustness. I reran the installation cluster equivalence bootstrap (1,000 resamples) with 30 independent seeds for l on each frame and 10 for d and c on NO (a2/redteam/rt_equiv_seed_summary.csv):

| frame | BAL | seeds | intercept region mean (sd) | max | slope region mean (sd) | max | share failing 0.25 |
|---|---|---|---|---|---|---|---|
| CS | l | 30 | 0.218 (0.005) | 0.226 | 0.170 (0.004) | 0.179 | 0 |
| NO | l | 30 | 0.218 (0.006) | 0.228 | 0.177 (0.004) | 0.188 | 0 |
| NO | d | 10 | 0.198 (0.008) | 0.216 | 0.146 (0.004) | 0.154 | 0 |
| NO | c | 10 | 0.264 (0.004) | 0.271 | 0.222 (0.002) | 0.225 | 1.0 |

The report's claim of about 0.01 MC spread is conservative (sd 0.005 to 0.006); the l margin to 0.25 is 0.022 at the worst of 60 seeds, about four sd. The pass under l and the fail under c are both robust. The size gate under l (max |obs/pred - 1| 0.142 at 40 to 60 cm, n 95) is deterministic.

What the gate does not show. (i) It is in-sample: the vector was fit on the v102 frame, which shares every tree with the v103 frame, and the origin constants are solved on the frame being scored, so the intercept test largely checks the root solve (overall obs/pred ratio 1.028). (ii) Its justification is that l is "engine computable". It is only at the first projection year (finding 1, Q2).

NO vs CS. Natural c 0.820 (NO) vs 0.783 (CS), +4.7 percent; planted 2.193 vs 2.159, +1.6 percent. Both sit inside the reported bootstrap interval of natural c (0.781 to 0.870) and are immaterial next to finding 1. The NO frame is the frame the dHT fit was deployed on, so using it is internally consistent.

### Q2. Engine BAL vs frame BAL l; what drives the natural c rise?

Frame vs engine definitions. The frame's l is (1 - unweighted rank percentile over the live koa stems of the plot-year) x all species repaired BAPH. The engine (koa_projector.project_psp and run_candidates.project, PSP_BAL_MODE "percentile") computes stand_bal(baph = koa BA of the simulated list, dbh = every record in the list), with bal_percentile_fraction an unweighted minimum-tie rank over records. Mortality is applied as expf = max(expf x ps, 1e-5); records are never removed (the list is only binned above 300 records, which none of the validation plots or the 20-class harness reach). The code comment in project_psp already concedes a "known residual" against d; the A1 close-out then reasons the opposite way ("the engine's percentile path runs on the live simulated list, so it computes l"). Neither is right after year 0: the engine ranks decayed records with the same weight as live ones.

Magnitude. I instrumented the engine copy to log, every year, the expf-weighted stand mean of the engine fraction and of a weighted live percentile (the fraction of live expf in stems at least as large, excluding self; identical to l when all live stems carry equal expf).

| case | year 0 engine / weighted | final engine / weighted | mean ratio engine/weighted over the run |
|---|---|---|---|
| DOFAW Kulani 23 (33 yr) | 0.523 / 0.523 | 0.144 / 0.499 | 0.59 |
| DOFAW Laupahoehoe 41 (27 yr) | 0.533 / 0.533 | 0.152 / 0.501 | 0.62 |
| DOFAW Waikamoi 25 (33 yr) | 0.514 / 0.514 | 0.094 / 0.496 | 0.41 |
| DOFAW Waiakea 24 (33 yr) | 0.516 / 0.516 | 0.360 / 0.499 | 0.87 |
| PSP planted (4 to 10 yr) | 0.50 to 0.54 | 0.47 to 0.50 / 0.50 | 0.98 to 1.00 |
| Table 8 natural, year 100 | 0.50 / 0.50 | 0.19 to 0.28 / 0.48 to 0.49 | |
| Table 8 planted, year 100 | 0.50 / 0.50 | 0.20 to 0.22 / 0.48 | |

On the FIA subplots the engine fraction at year 0 is 0.63 to 0.80 against a weighted 0.52 to 0.55, because one microplot record (741 stems/ha) ranks like one subplot record (59.5 stems/ha). The frame's l is also unweighted, so at year 0 engine and frame agree; the weighted value is the physically meaningful one.

Consequence for projections. Replacing only the BAL fraction with the weighted one (everything else deployed, M1 gate on):

| output | effect of weighted BAL |
|---|---|
| DOFAW natural validation QMD bias (pred minus obs, 6 plots) | +3.18 to -0.37 cm (Kulani 23 +5.99 to -0.22; Laupahoehoe 41 +5.48 to +0.20; Waikamoi 25 +9.64 to +1.00) |
| DOFAW natural survival bias (weighted, pred minus obs) | +0.045 to +0.064 |
| Table 8 natural QMD at 40 / 100 yr | -2.0 to -4.8 / -6.4 to -9.5 percent |
| Table 8 planted QMD at 40 / 100 yr | -6.3 to -10.3 / -10.1 to -11.8 percent |
| Table 8 VOL at 100 yr | natural -3.9 to -5.7, planted -7.7 to +0.1 percent |
| Planted TPH at 40 yr | +10 to +20 percent |

The planted effect at 40 yr is larger than the whole v102 to v103 change in planted QMD (Table A, +5.0 to +5.7 percent).

Decomposition of the natural c rise (dDBH, NO frame, v102 vector, recursion consistent solve_c): v102 engine 0.555 -> v103 frame under d 0.615 (+10.8 percent: repair plus the change from ratio of means to the recursion solve) -> under l 0.820 (+33.5 percent) -> engine consistent covariates k, BAPH = live koa BA of the plot-year and BAL = BALl x BA.AK/BAPH with CR from HCB_P, 0.797 (-2.9 percent). The equivalence regions under k are 0.216 and 0.175 (NO), the same as under l. So: the rise is almost entirely the d to l switch; the all-species vs koa-only mismatch (median koa share 1.00 for DOFAW, 0.91 for FIA natural rows) is small for the constants; the repair contributes about a third of the rise. The d to l switch would be defensible if the engine then computed l. It does not, which is why the high constant shows up as over-growth in exactly the stands that self-thin hardest.

### Q3. Why does the natural validation over-predict QMD? Growth vs mortality; FIA x4

Reproduction. My engine copy reproduces a2/out/val_v103.csv exactly (max |QMD diff| 3.6e-15, survival 1.1e-16) once regen_m1's gated M1 mortality is loaded, as run_engine.py does.

Decomposition. V3 replaces engine mortality with each tree's observed fate (trees that died are removed at mid-interval; growth deployed). Growth contribution = V3 minus observed; mortality (selection) contribution = deployed minus V3.

| group | n | QMD bias pred minus obs | growth | mortality/selection | with weighted BAL |
|---|---|---|---|---|---|
| DOFAW natural | 6 | +3.18 | +0.99 | +2.18 | -0.37 |
| FIA natural subplots | 6 | +8.82 | +1.93 | +6.89 | +9.41 |
| all natural | 12 | +6.00 | +1.46 | +4.54 | +4.52 |
| planted | 11 | -0.74 | -0.48 | -0.26 | -0.93 |

Per plot the extremes are FIA 2628-3 (+25.86 cm: growth +2.48, selection +23.38; predicted survival 0.059 against 0.095 weighted observed), 2628-4 (+13.77: +0.33 and +13.44; predicted survival 0.094 against 0.479) and Waikamoi 25 (+9.64: +6.23 and +3.40). So two thirds of the natural bias is who dies, not how fast trees grow, and the FIA share of it is a from-below allocation meeting a disturbance.

FIA 15-1-1-2628. Aggregated to the plot (4 subplots, 115 koa records, expansion x1): koa TPH 3,073, BA 64.9 m2/ha, SDI 1,561 in 2010; in 2019 the survivors hold 25.8 m2/ha and 21.5 percent of the initial stems (weighted). That is a mortality event, not self-thinning (koa BA fell 60 percent in 9 years). At plot level the engine predicts survival 0.113 and QMD 31.9 cm vs 22.3 observed; BA is right (27.8 vs 25.8). Aggregation removes the 53 cm subplot artefact but not the bias. Four subplots of one plot are also four pseudo-replicates in a 12-unit natural sample.

Is x4 legitimate? The arithmetic is right: TPA_UNADJ is a per-acre expansion for the four-subplot plot, so a single subplot treated as a stand needs x4 (G1 and the HI_TREE cross check confirm the rebuild). The problem is the unit. A 0.0169 ha subplot whose sapling records come from a 0.0013 ha microplot is not a stand: on 2628-1 four microplot saplings carry 63 percent of the 4,689 stems/ha; five subplot-years exceed 100 m2/ha (G2); the engine's Garcia and M1 terms then see SDI 1,422 to 1,853 on the 2628 subplots. For validation, aggregate FIA to the plot with x1, require a minimum number of koa records, and report 2628 as a disturbance case outside the density-dependent domain. The same argument applies to the FIA H40 in the Garcia pair table and the FIA crown frame that broke Eq. 5.

Metric consistency. validate() computes obs_surv as a tree count fraction and pr_surv as an expf-weighted fraction. They differ wherever expansion factors differ: 2628-1 0.182 count vs 0.076 weighted, 2628-2 0.342 vs 0.263, 2628-3 0.150 vs 0.095; natural mean 0.428 vs 0.409. Use the weighted observed survival.

In-sample status. MORT_CAL natural 2.466 is solved on 24 intervals from 7 plots: Kulani 23, Laupahoehoe 41, Waiakea 11, 14 and 24, Waikamoi 25 and PSP 122 (H_mort_intervals_natural_mult.csv). Those are all six DOFAW natural validation plots. The dDBH natural constant is solved on 1,071 natural rows, 950 of them DOFAW. Table C should say so, or natural c and MORT_CAL should be solved leave-one-installation-out for the validation run.

### Q4. Biological realism of the v103 trajectories

From a2/out/traj_v103.csv (point path, M1 gate) against traj_gate.csv (v102):

| origin, BYI | year 24 QMD / TPH / BA | year 100 QMD / TPH / BA / VOL / HT | peak SDI (year) | MAI culmination (MAI) |
|---|---|---|---|---|
| natural 100 | 20.8 / 400 / 13.6 | 50.3 / 141 / 28.0 / 221 / 19.7 | 433 (88) | 40 (2.76) |
| natural 264 | 26.0 / 345 / 18.3 | 65.1 / 90 / 30.0 / 279 / 23.2 | 436 (57) | 27 (4.38) |
| natural 450 | 29.6 / 303 / 20.9 | 71.8 / 74 / 29.9 / 299 / 25.0 | 437 (45) | 22 (5.76) |
| planted 100 | 30.8 / 610 / 45.4 | 59.0 / 210 / 57.3 / 488 / 21.3 | 883 (40) | 12 (13.49) |
| planted 264 | 37.5 / 463 / 51.2 | 64.6 / 170 / 55.7 / 505 / 22.7 | 890 (27) | 9 (20.74) |
| planted 450 | 41.9 / 391 / 53.8 | 66.5 / 154 / 53.7 / 515 / 24.0 | 895 (22) | 8 (26.74) |

Site ordering holds for QMD, HT, VOL and TPH at every age; it is inverted for planted BA at 100 yr (57.3 > 55.7 > 53.7, Low highest) and flat for natural BA (30.0 vs 29.9). Natural QMD at 100 yr on High site (71.8 cm) now exceeds planted (66.5 cm), a crossover v102 did not have (57.5 vs 64.6). The natural stand never exceeds SDI 437, half the planted peak and half the observed natural DOFAW plot SDI (Kulani 23 812, Laupahoehoe 41 623, Waikamoi 25 924); natural TPH at 20 to 24 yr (303 to 420) sits below the DOFAW natural plots at similar ages (595 to 1,463 stems/ha at age 22 in Waiakea 24, Laupahoehoe 41 and Kulani 23) and the Scowcroft et al. (2007) anchor (UNVERIFIED: 24 yr secondary stand, about 1000 stems/ha, 18 cm, 25.7 m2/ha). v103 fits the anchor BA slightly better than v102 (13.6 to 20.9 vs 10.0 to 16.0 m2/ha) but QMD worse (20.8 to 29.6 vs 17.7 to 24.0 cm, anchor 18). The FIA Hawaii all-forest mean of about 166 Mg/ha (UNVERIFIED) is only a loose check: natural VOL 221 to 299 m3/ha at 100 yr, with an assumed koa density near 0.55 Mg/m3 and a 1.3 expansion to total aboveground biomass, gives roughly 160 to 215 Mg/ha, plausible for a mature stand; planted 488 to 515 m3/ha implies roughly 350 Mg/ha, high but not impossible for managed koa. Reineke slopes after peak SDI (100 yr window, my fit) are -2.02 to -2.10 in v103 vs -2.15 to -3.77 in v102; the out_m1 Bakuzis slopes steepen (finding 10). MAI culminates earlier on natural sites (22 to 40 yr, v102 10 to 39) with higher MAI max (+40 to +45 percent). Natural volume at 20 to 60 yr is +19 to +50 percent over v102 (Table A), mostly finding 1 plus the higher c. Note that every natural number here moves when finding 1 is fixed (year 100 QMD -6 to -10 percent).

out_m1 (regen_m1 finished, 1,210 s, 500 of 500 replicates ok, no CF clipping): point values in table8_evenaged_M1.csv equal the traj_v103 point path.

### Q5. Monte Carlo

Joint draws (K_joint_summary.csv). Height and vector draws are sane (MVN of the model vcov; ht_a0 sd 1.44, d_b4 sd 0.025). The multipliers are not a sampling distribution. The source bootstrap draws 4 sources from {DOFAW, FIA, KMR PSP, PSP} with replacement, rejecting sets without both origins; 33 multisets occur. Natural rows exist only in DOFAW (950), FIA (102) and PSP (19); planted in DOFAW (101), KMR PSP (366) and PSP (3,433). Consequences: in the 25 draws with neither DOFAW nor FIA the natural dDBH multiplier is solved on 19 PSP trees (source-set medians 1.19 to 1.74 vs base 0.599); in the 26 draws with neither KMR PSP nor PSP the planted dHT multiplier is solved on DOFAW plantings (0.14 to 0.19 vs 1.19). That is why cal_dh_nat has sd_log 0.81 (95 percent 0.038 to 0.862) and cal_dh_plt 0.16 to 4.60. The design is inherited (v102: 0.17 to 1.75 and 0.44 to 7.81). The pairing of vector and multiplier is correct (cor h_b0 with cal_dh_nat -0.49 and cal_dh_plt -0.59), so part of the width is compensating, but the tails are source identity. The engine constant CAL_DDBH_SE_LOG (0.030, vector fixed) and the joint draw spread (sd_log 0.40) describe different things; say which one Table 8 uses.

out_m1 vs v102 (table8_evenaged_M1.csv). Relative interval width v103/v102: natural QMD 0.58 to 0.99 (narrower at 100 yr), natural TPH 1.07 to 1.32 (wider), planted QMD 0.58 to 0.82, planted VOL 0.70 to 1.12. The point path still sits at the lower edge of the natural QMD interval (position 0.16 to 0.40; v102 0.14 to 0.29) and the upper part of the TPH interval (0.49 to 0.94), so the deterministic trajectory is not the MC centre for natural stands (kmort draw mean 2.71 against the point 2.47; cal_dd_nat mean 0.72 against 0.60). Bakuzis slopes: finding 10.

### Q6. Aviva grid (RLF)

yield_grid_compare.csv, all 16 site x density cells, ages 40, 45, 52: BA -6.3 to +6.9 percent, QMD +3.5 to +5.9 percent, stems -1.8 to -16.2 percent, VOL -7.3 to +8.1 percent; at 20 yr BA +2.8 to +8.7 percent; at 60 yr BA -7.2 to +5.0, stems -1.9 to -16.0; at 100 yr BA -10.7 to +2.7, stems -2.2 to -16.2. The pattern is systematic: low planting density and poor sites gain BA, high density and good sites lose BA and stems. Against the planted MC interval (BA at 40 yr roughly 36 to 61 m2/ha around 52) none of these is statistically distinguishable; for an RLF cash flow a 5 to 7 percent volume shift at 45 to 52 yr on 300 to 400 TPA Excellent/Good cells is material and worth a line. But finding 1 alone moves planted QMD at 40 yr by -6 to -10 percent and VOL by -5 to -6 percent, the same size as the v102 to v103 change, so the grid should not be reissued before the BAL fix. Prior caveats, all still present: (a) age offset, age 1 already carries QMD 2.85 in (7.2 cm), HT 18.6 ft and DBHMAX 16.4 cm, so grid age is years since harness start, not since planting; (b) the 69.7 cm DBH cap binds early, DBHMAX reaches 69.2 cm by age 40 and 69.6 by 60 on Excellent 200 TPA, inside the 40 to 52 yr decision window; capped stems stop growing while mortality continues; (c) BA plateau and decline, peak at 64 to 94 yr then down 31 to 46 percent by 200 yr, partly a cap artefact; (d) VOL is m3/ha in an imperial table (VBAR in ft3/ft2 alongside). None of these was changed in A2.

### Q7. What a hostile referee finds first

1. The natural validation is calibration data plus four subplots of one disturbed plot (Q3). This is the first thing a Forest Ecosystems referee will see in Table C.
2. The FIA x4 finding cuts both ways: v102 validated FIA at one quarter of the true subplot density and looked good; v103 validates at the true subplot density and fails. The honest statement is that subplot scale FIA lists are outside the model's domain. FIA also drove the Eq. 5 collapse (LOIO AUC 0.813 to 0.633), the Garcia H40 shift and the all-species beta 0.116 that was not deployed.
3. BYI identification: dHT b8 has a bootstrap interval spanning zero (-0.147 to 0.834); site ordering in height rests on HT_P and on the dDBH b8 of the v102 vector (0.30). With BYI in index units (settled), say plainly that height growth has no identified site effect.
4. Planted domain: 88 percent of planted dDBH rows (3,433 of 3,900) are PSP rows with a median interval of 1 yr; the planted multiplier by source ranges 0.96 to 3.03 (dDBH) and 0.43 to 4.71 (dHT). Kulani 12 (the only old planting in the validation) is over-predicted 3.3x in BA. Projecting planted stands to 100 yr extrapolates far beyond the ages and interval lengths that dominate the planted fit.
5. dHT under-predicts height growth of trees above 15 m (obs/pred 1.24 at 15 to 20 m and 1.36 at 20 to 30 m, settled). HT at 100 yr is 19.7 to 25.0 m; VOL = BAPH x mean HT x form factor, so volume of old stands is biased low by the same mechanism.
6. Table hygiene (finding 12) and stale S4/S5 files (finding 11) will be caught at proof stage.

## Must change before v105

1. Make the engine compute the BAL the constants were solved under. Either rank on live weight (expf-weighted percentile, or drop records whose expf falls below a small threshold) in koa_projector.project_psp, run_candidates.project and the HiGy.R mirror, or solve the constants under an engine-emulating definition. Then re-solve MORT_CAL, rerun parity, and regenerate Table 8, validation, out_m1, uneven-aged, Bakuzis and the Aviva grid.
2. Rebuild the natural validation: FIA at plot level with x1 expansion and a minimum record count; 15-1-1-2628 reported separately as a disturbance case; observed survival expf-weighted; state that the DOFAW natural plots are calibration data or rerun with MORT_CAL and natural c solved leave-one-installation-out.
3. Regenerate or delete the stale FigS4/FigS5 files in out_m1, correct the Table A and D headers ((v103 - v102)/v102), use one sign convention for bias, and flag that observed validation BA changed with the FIA repair.
4. Do not reissue the Aviva grid until item 1 is done; when reissued, fix or state the age offset and the 69.7 cm cap in the header of the file the client sees, and put VOL in ft3/ac or label it.
5. Joint MC: either resample installations within source (as the constants bootstrap does) or report the source-set sensitivity explicitly; say which multiplier SE feeds Table 8.

## Can be disclosed

- A1 gate: robust to MC seed (0 of 60 seeds fail under l) but in-sample; CS vs NO constants differ by 4.7 percent (natural) and 1.6 percent (planted).
- The all-species vs koa-only BAPH mismatch: -2.9 percent on natural c, no change in the equivalence regions, small effect in validation (Waiakea 14 and FIA 4895 only).
- Natural density envelope (peak SDI 437) and the miss on the UNVERIFIED Scowcroft stems and QMD anchor.
- Planted source heterogeneity and the extrapolation of young PSP plantations; Kulani 12.
- Bakuzis: planted 264 and 450 FLAG (Reineke slope -2.46, -2.78).
- MC point path at the edge of the natural intervals (inherited).
- dHT size gate failure, dHT site term not identified, Eq. 5 v102 retained (settled decisions; consequences stated above).

## Reproducibility

Scripts (a2/redteam/): rt_q1q2_c_equiv.R (Q1, Q2 constants and seed robustness), rt_q3_val_decomp.py (validation decomposition, BAL instrumentation; runs on a copy of engine_v103 in ~/jobs/rt_koa_v103_scratch/eng with the M1 gate loaded, reproduces val_v103.csv to 1e-14), rt_q3b_fia_plot.py (FIA plot-level projections), rt_q4_traj.py (Table 8 trajectories with engine vs weighted BAL, reproduces traj_v103.csv to 1e-13). Result tables: rt_c_by_bal.csv, rt_equiv_seeds.csv, rt_equiv_seed_summary.csv, rt_koa_share_frames.csv, rt_val_decomp.csv, rt_bal_log.csv, rt_fia_plotlevel.csv, rt_traj_EW.csv, rt_traj_ballog.csv. Nothing under ~/jobs/koa_v103_20260930 was modified outside a2/redteam/.
