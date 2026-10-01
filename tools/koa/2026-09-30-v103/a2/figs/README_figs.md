# koa v103 figures

Figs 3 to 6 and S1 to S8 in the v104 style, rebuilt on engine_v103 (BAL_PERCENTILE_WEIGHTED True, MORT_CAL 2.54275) after the 15:44 Monte Carlo promotion. deliver/ holds a 600 dpi TIFF and a PNG embed (150 dpi main, 300 dpi supplement, v104 sizes) of each, contact_sheet_v103.png and MD5SUMS.txt. Supplement numbering is s102: S1 height, HCB and survival diagnostics; S2 increment diagnostics; S3 survival recovery; S4 survival deployability; S5 long-term validation; S6 natural and S7 planted projections; S8 Bakuzis matrix.

## Map (script, data)

Fig 3 to 6: fig_main_v103.R. Engine constants; track3_s02/v103 height fit; out/inc bootstraps; frames/final/tree_join_v103; out_m1 reps and traj files; data/LT_v103 (lt_v103.py) and data/SC (sc_v103.py).
S1, S2: figS12_v103.R. frames/final (tree_join, AK_HCB, AK_SURV, d*_NO_model); out/inc/fits_v103.rda.
S3, S4: figS34_v103.R, a v104 copy with paths only changed. frames/final/surv_*_v103; a2/mort/v103; traj_M1.
S5, S6 to S8: figS_v103.R. val_v103_plotlevel.csv; reps_evenaged_M1 plus traj_M1; koa_bakuzis_input_M1.

## Visible changes against v104

Fig 3: 95% bootstrap bands added to the increment curves (dDBH bands vary only the origin constants, since the v102 vector is deployed); height n 8,914.
Fig 4, S6, S7: out_m1 reps are global draw indices with no point run, so bands span all draws (500 even-aged, 300 uneven-aged) and lines come from the traj files. SDI is the QMD form.
Fig 5: bias is predicted minus observed (v104 was reversed); comparison series is the v102 engine; horizon means carry 95% plot bootstrap intervals.
Fig 6: v103 trajectories only.
S1: v103 frames (HCB 360, survival 4,871 records, 79 deaths).
S2: panels a to f show the deployed prediction; the v103 origin constants (dHT 0.44 natural, 2.89 planted) leave the uncalibrated scale uninformative. The caption needs rewording.
S3: turning points 157, 235, 216. The baseline ML fit departs from glm and 5 of 62 jackknife folds failed.
S4: level 2.54275 on 24 intervals; unit label now trees ha⁻¹.
S5: plot-level units with 2628 marked separately; Clopper-Pearson and bootstrap intervals; r 0.87 without 2628.
S8: post-promotion input. Planted Reineke slopes at BYI 264 and 450 are flagged.

## Not regenerated or without v103 equivalent

Figs 1 and 2 are out of scope. The v102 F_s11 composition file has no v103 equivalent, so S3 logs NA for that check. The PSP 105 to 108 visits of 2009 are coded all dead, which puts Fig 5 points near +0.99 (as in v104). Bakuzis panels have no uncertainty because the input holds point runs only.
