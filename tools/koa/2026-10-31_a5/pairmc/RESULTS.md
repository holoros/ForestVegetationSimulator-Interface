# RESULTS: a5/pairmc, paired Monte Carlo of BYI ordering (1,000 replicates per variant)

All numbers from out/prob_ordering.csv, out/intervals.csv, out/paired_P_vs_table4.csv, out/byi_truncation.csv, out/summary.json.
Levels: low 100, medium 264, high 450 BYI (Mg ha-1). Variants: P parameter only (paired); PP + process; PPB + process + BYI (decision);
B BYI error only. MCSE = sqrt(p(1-p)/1000).

## Preregistered verdict (variant PPB): WEAK for every comparison, age and origin (0.50 < P < 0.90); none SUPPORTED, none NOT SUPPORTED.

| Origin | Age | P(high>low) | P(med>low) | P(high>med) |
|---|---|---|---|---|
| natural | 20 | 0.659 (0.015) | 0.600 (0.016) | 0.553 (0.016) |
| natural | 30 | 0.659 (0.015) | 0.598 (0.016) | 0.557 (0.016) |
| natural | 40 | 0.662 (0.015) | 0.598 (0.016) | 0.558 (0.016) |
| planted | 20 | 0.669 (0.015) | 0.605 (0.016) | 0.541 (0.016) |
| planted | 30 | 0.685 (0.015) | 0.614 (0.015) | 0.553 (0.016) |
| planted | 40 | 0.703 (0.014) | 0.623 (0.015) | 0.571 (0.016) |

## Decomposition (age 40 shown; all ages in prob_ordering.csv)
- P (parameter only, paired): P(high>low) 1.000 natural and planted; every comparison at every age >= 0.998 (SUPPORTED).
- B (BYI error only): high>low 0.991 natural, 0.996 planted; med>low 0.956, 0.963 (SUPPORTED); high>med 0.855, 0.843 (WEAK).
- PP (parameter + process): high>low 0.667 natural, 0.726 planted; med>low 0.603, 0.632; high>med 0.558, 0.587 (WEAK).
- Process error (installation random intercept, independent per stand) is the dominant source; adding BYI error to PP moves P by at most 0.023.

## Volume at age 40, median and 95% interval (m3 ha-1)
| Variant | Natural 100 | Natural 264 | Natural 450 | Planted 100 | Planted 264 | Planted 450 |
|---|---|---|---|---|---|---|
| P | 116.5 (51.8-181.5) | 146.7 (63.0-217.8) | 168.1 (70.9-248.2) | 364.2 (246.0-456.0) | 415.8 (285.8-508.3) | 456.9 (317.1-548.9) |
| PP | 87.0 (20.2-290.3) | 110.8 (23.9-295.6) | 130.2 (29.6-328.1) | 317.6 (93.5-515.4) | 383.0 (133.8-545.4) | 416.7 (142.2-583.4) |
| PPB | 85.9 (20.0-292.4) | 108.9 (24.1-296.0) | 125.4 (27.9-329.7) | 320.1 (90.7-516.3) | 376.6 (133.2-549.7) | 406.4 (137.5-588.8) |
| B | 123.3 (103.6-145.3) | 151.7 (126.0-177.0) | 171.9 (145.0-195.4) | 367.3 (335.5-405.7) | 417.5 (375.3-467.1) | 456.5 (398.2-506.2) |
Ages 20 and 30, and BAPH and QMD, in intervals.csv. The process multipliers are mean preserving, so PP medians sit below P medians.

## Sanity gate
Published-scheme reproduction: 3,000 replicate-scenarios equal reps_evenaged_M1.csv exactly (max |diff| 0.0) and 12 of 12 Table 4 VOL
ranges match to 2 decimals (gate1_table4_ranges.csv). PASS. The paired 1,000-replicate P ranges differ from the published 500-replicate ranges
by different draws and alpha pairing (e.g. natural 40 yr low 51.8-181.5 vs published 52.55-180.85; paired_P_vs_table4.csv).

## BYI error
Multiplicative (log ratio) scale; first-draw truncation rate: low 0.5%, medium 0.9 to 1.2%, high 6.0 to 7.4% (byi_truncation.csv).
True BYI 95% range: low 43 to 206, medium 106 to 470, high 180 to 668.

## Caveats
- Process error draws the installation effect independently for each BYI level (different stands). A same-stand design (shared installation
  draw) was not preregistered or run; it would isolate the BYI contrast from stand-to-stand variation.
- dDBH installation SD 0.776 (log scale) is large; it carries most of the PP and PPB spread.
- Table 4 path uses the pre-A4-D3 Stage 3 vector (see RUN.md).

# A5 SECTION: rerun on the Stage 3 fixed engine, plus BOOT (31 October 2026, 15:25 to 15:48 ADT)

Sources: out_a5/prob_ordering.csv, out_a5/intervals.csv, out_a5/paired_P_vs_table4.csv, out_a5/gate1_table4_ranges.csv, out_a5/summary.json;
regenerated engine_v103/out_m1/table8_evenaged_M1.csv. The v104 section above is unchanged. 1,000 replicates per variant.
Precondition: a5/stage3fix/run_a5.log reported chain1 0, chain2 0, figs 0, figS34 0, sens 0, "A5 DONE" 15:24:07.

## Gates (all PASS)
Engine copy engine_a5 reads STAGE3_COEF in run_candidates.py. pm_project vs run_candidates.project max |diff| 0.0; reproduction of the regenerated
reps_evenaged_M1.csv max |diff| 0.0 (VOL, BAPH, QMD, 3,000 replicate-scenarios); 12 of 12 regenerated Table 4 VOL ranges match to 2 decimals;
rows 0 to 499 of the 1,000-row joint table equal the regenerated a4/jointmc/out (max |diff| 0.0).

## Regenerated Table 4, age 40 volume (m3 ha-1), point (95% range)
Natural: low 123.59 (52.10 to 179.37), medium 152.35 (60.64 to 220.25), high 173.48 (72.25 to 251.85).
Planted: low 367.22 (253.66 to 447.92), medium 418.50 (270.13 to 500.48), high 460.16 (304.12 to 539.30).

## Preregistered verdict (PPB) on the fixed engine: WEAK everywhere (P 0.539 to 0.703), as in v104
P(high>low) natural 0.659 / 0.660 / 0.663 (ages 20 / 30 / 40), planted 0.669 / 0.685 / 0.703; P(med>low) natural 0.599 / 0.598 / 0.597,
planted 0.605 / 0.612 / 0.624; P(high>med) natural 0.553 / 0.558 / 0.557, planted 0.539 / 0.553 / 0.568. MCSE 0.014 to 0.016.

## BOOT (installation-bootstrap coefficients; PREREG addendum A5 and amendment A5-B)
Inputs: 386 of 400 dDBH_L_NO bootstrap draws (14 with NA re-solved constants excluded, all with b2 > 0), dHT draws paired by draw number
(400 of 400 complete), 25 converged height draws of 45 present in a5/rerun/h/draws at 15:25 (boot_inputs/h_draws_snapshot.csv).
- BOOT (parameter only): natural all comparisons SUPPORTED at every age (high>low 0.969 / 0.965 / 0.961; med>low 0.973 / 0.972 / 0.970;
  high>med 0.954 / 0.944 / 0.933). Planted high>low 0.940 / 0.925 / 0.911 and med>low 0.955 / 0.947 / 0.942 SUPPORTED; high>med 0.898 / 0.859 / 0.832 WEAK.
- BOOT_PPB (+ process + BYI): WEAK everywhere, P 0.525 to 0.650 (high>low natural 0.639 / 0.637 / 0.641, planted 0.639 / 0.637 / 0.650).
- Compared with P (Wald joint draws, P >= 0.998 everywhere), bootstrap coefficient uncertainty lowers the parameter-only probabilities by up to
  0.17 (planted high>med at 40 yr) but does not by itself overturn the ordering except for planted high>med; with process and BYI error it lowers
  the full-error probabilities by 0.006 to 0.053 relative to PPB.
- Age 40 volume medians (95%), BOOT: natural 113.8 (52.6 to 186.7), 142.4 (61.5 to 221.8), 158.1 (64.0 to 249.9); planted 367.7 (253.3 to 491.4),
  413.8 (284.0 to 513.6), 441.1 (298.1 to 553.4).

## Run notes
First BOOT attempt gave NaN for 40 of 1,000 replicates (the 14 incomplete bootstrap rows); kept as out_a5/prob_ordering_BOOT_attempt1_NaN.csv
and not used. The 240 renormalize_to_stand_rate "failed to bracket" warnings in logs/a5_main_w*.log are attributed to that attempt (not proven per replicate): the BOOT rerun
(logs/a5_boot_w*.log) and a check of P, PP, PPB and B on replicates 0, 3, 6 and 9 (diag_warn.py, logs/diag_warn.log) produced none.
The height bootstrap was still running, so BOOT height uncertainty rests on 25 draws cycled over 1,000 replicates.
