# STAGE1_REPORT, koa v103 Stage A1: repair of the stand covariates (D1) and the carried forward Keauhou records (D2), frames and refits

Job ~/jobs/koa_v103_20260930 on firebreather, 30 September 2026. R 4.5.1 (nlme), python3 (pandas, numpy). Only this directory was written. Every input is a copy with its md5 in logs/md5_inputs.txt, commands and timings are in RUN.md. No coordinate column was read into any frame, and the absence of lat, lon, long, latitude, longitude, x and y was asserted on every frame written.

## 1. Repair rules (preregistered in RUN.md before any repair or fit)

D1. For every plot-year of the koa tree table, BAPH, TPH, QMD and SDI (summation form, sum EXPF x (DBH/25.4)^1.605) are recomputed from live stems (Status live, DBH > 0, EXPF > 0) of all species in the deduplicated all species list; BA.AK and pBA.AK from the live koa stems. The all species list is TREE.ALL.csv deduplicated with the v102 rulings A3 and A1' (A2' is the same keep rule). FIA plot-years are rebuilt from HI_TREE.csv (STATUSCD 1, all species, per subplot expansion TPA_UNADJ x 4 x 2.47105 per ha). BAL is carried in three definitions: d, the deposited form recomputed on the repaired list, (1 - DBH rank percentile over every koa record of the plot-year) x repaired BAPH; l, the live list percentile, (1 - rank percentile over live koa stems) x repaired BAPH; c, conventional, expansion weighted basal area of live stems of all species strictly larger than the subject.

D2. A visit whose live trees shared with the previous visit are at least 90 percent identical in DBH and HT is removed; a visit with 50 to 90 percent identical trees loses the identical tree-visits; under 50 percent everything is kept (real zero growth). Stand variables are computed on the full visit. The refit2 removal screen (Thin_Yr and removal_t1_years strictly inside the interval) is applied to every increment and survival frame.

## 2. Gates

- G0 deduplicated TREE.ALL koa subset equals AK_TREE_v102 (17,074 records, every key, DBH, HT, Age, EXPF, Status and deposited stand cell): GATE G0 deduplicated TREE.ALL koa subset equals AK_TREE_v102 on keys, DBH, HT, Age, EXPF, Status and deposited stand columns: PASS | koa rows 17074 v102 17074
- FIA mapping to HI_TREE (667 koa records, SPCD 6006, DBH to 0.02 cm, status): GATE FIA mapping AK_TREE (Install = STATECD-UNITCD-COUNTYCD-PLOT, Plot = SUBP, Tree = TREE, Measure = INVYR) to HI_TREE: PASS | koa FIA records 667 matched 667 | SPCD {6006.0: 667} | EXPF / TPA_UNADJ [2.48]
- FIA cross check, TREE.ALL rescaled vs HI_TREE rebuild: FIA check: TREE.ALL live all species BAPH rescaled to the subplot expansion vs HI_TREE rebuild, plot-years 1838 | max abs diff 0.0
- G1 single species plot-years, rebuilt BAPH equals the live koa sum to 1e-6: GATE G1 single species plot-years (sources ['KMR PSP', 'Kualoa', 'Mauka', 'PSP'] ) rebuilt BAPH equals the live koa sum to 1e-6: max abs diff 0.0 over 406 plot-years: PASS
- Tree table uniqueness: AK_TREE_v103 rows 16914 (v102 17074 ) | GATE one record per (Data, Install, Plot, Tree, Measure): PASS
- Builder reproduction on the v102 inputs (7 frames identical on every cell): dDBH_v102.csv 4790 PASS; dHT_v102.csv 3857 PASS; AK_SURV_v102.csv 4869 PASS; surv_baseline_rebuilt_v102.csv 4869 PASS; surv_recovered_ii_v102.csv 4298 PASS; surv_recovered_i_v102.csv 4114 PASS; plot_interval_pairs_DATA_v102.csv 415 PASS
- Uniqueness gates on every v103 frame: dDBH_CS_v103 4792 PASS; dHT_CS_v103 3857 PASS; surv_baseline_rebuilt_v103 4871 PASS; surv_recovered_ii_v103 4223 PASS; surv_recovered_i_v103 4051 PASS; AK_SURV_v103 4871 PASS; plot_interval_pairs_DATA_v103 407 PASS; static_height_frame_v103 9137 PASS; plot_intervals_v103 318 PASS; plot_intervals_origin_v103 286 PASS; koa_ingrowth_byi_obs_v103 (rows with an inferred interval) 347 PASS; AK_HCB_v103 360 PASS

G2 physical credibility. Rebuilt BAPH over 862 koa plot-years: G2 rebuilt BAPH distribution (plot-years 862 ): {0.0: 0.0, 0.5: 11.993, 0.9: 46.679, 0.95: 57.712, 0.99: 94.184, 1.0: 164.233} | deposited: {0.0: 0.0, 0.5: 9.122, 0.9: 39.784, 0.95: 50.015, 0.99: 74.489, 1.0: 256.645}. The bound I can justify is 100 m2/ha for a stand level value: it is close to the 99th percentile of the rebuilt plot-years (94.2) and above every non FIA value (largest 91.4, a 7 stem Kap plot; largest PSP 68.9; largest DOFAW 47.0), and above the largest deposited value the engine documents as observed (76.06, which was itself a doubled Kulani 23 1994 value, now 38.2). Result: G2 FLAGS 5 FIA subplot-years above 100 (164.2, 147.3, 131.6, 125.0, 102.3). They are not data errors. Each is one 1/24 acre (0.0169 ha) subplot whose expansion puts a single large tree at 59.5 stems/ha (the 158 cm ohia on 15-1-1-2291 subplot 2 alone is 116 m2/ha); the tree lists were checked against HI_TREE. They are kept under the preregistered x4 rule, and their effect is counted in G4. All deposited FIA values were one quarter of the subplot value (whole plot TPA applied to one subplot), which is why FIA medians rise from 9.5 to 25.3 m2/ha.

Top 10 plot-years after the repair

| Data | Install | Plot | Measure | BAPH_dep | BAPH | TPH_dep | TPH | QMD | nlive_all | nlive_koa |
|---|---|---|---|---|---|---|---|---|---|---|
| FIA | 15-1-1-2291 | 2 | 2019 | 41.2070 | 164.2331 | 1063.8923 | 4240.2113 | 22.2071 | 14.0000 | 1.0000 |
| FIA | 15-1-1-2291 | 2 | 2010 | 36.9610 | 147.3103 | 848.1289 | 3380.2724 | 23.5557 | 11.0000 | 1.0000 |
| FIA | 15-1-1-2307 | 1 | 2019 | 33.2396 | 131.6320 | 223.8713 | 832.7700 | 44.8614 | 14.0000 | 1.0000 |
| FIA | 15-1-9-1853 | 1 | 2019 | 33.1571 | 125.0197 | 1882.1717 | 6522.6104 | 15.6219 | 18.0000 | 3.0000 |
| FIA | 15-1-1-2742 | 4 | 2010 | 26.0587 | 102.2526 | 967.5269 | 3796.6573 | 18.5179 | 18.0000 | 3.0000 |
| FIA | 15-1-1-2444 | 2 | 2019 | 26.6866 | 99.6493 | 1057.0754 | 3975.1081 | 17.8656 | 21.0000 | 1.0000 |
| FIA | 15-1-1-4695 | 1 | 2019 | 26.3290 | 99.3797 | 1555.1181 | 6079.0564 | 14.4273 | 22.0000 | 0.0000 |
| FIA | 15-1-1-4695 | 1 | 2010 | 25.3901 | 99.2647 | 1614.8171 | 6376.4743 | 14.0787 | 27.0000 | 1.0000 |
| FIA | 15-1-1-2742 | 4 | 2019 | 26.4639 | 98.5410 | 409.7852 | 773.2864 | 40.2803 | 13.0000 | 3.0000 |
| Kap | K01 | 102 | 2020 | 91.3987 | 91.3987 | 2053.9700 | 2053.9700 | 23.8028 | 7.0000 | 3.0000 |

Top 10 plot-years before the repair (deposited)

| Data | Install | Plot | Measure | BAPH_dep | BAPH | TPH_dep | TPH | nlive_all |
|---|---|---|---|---|---|---|---|---|
| PSP | 106 | 6 | 2021 | 256.6454 | 50.8724 | 1486.8000 | 743.4000 | 15.0000 |
| PSP | 104 | 4 | 2021 | 129.1300 | 65.3811 | 1288.5600 | 644.2800 | 13.0000 |
| Kap | K01 | 102 | 2020 | 91.3987 | 91.3987 | 2053.9700 | 2053.9700 | 7.0000 |
| Kap | K03 | 608 | 2020 | 89.3927 | 89.3927 | 2172.4100 | 2172.4100 | 6.0000 |
| PSP | 105 | 5 | 2021 | 88.2175 | 45.3027 | 1040.7600 | 545.1600 | 11.0000 |
| PSP | 108 | 8 | 2021 | 88.0205 | 44.4881 | 1387.6800 | 693.8400 | 14.0000 |
| Kap | K01 | 205 | 2019 | 82.3590 | 82.3590 | 1247.2900 | 1247.2900 | 6.0000 |
| PSP | 107 | 7 | 2021 | 79.0644 | 38.3922 | 1040.7600 | 495.6000 | 10.0000 |
| DOFAW | Kulani | 23 | 1994 | 76.0621 | 38.1564 | 1537.6000 | 768.8000 | 31.0000 |
| PSP | 102 | 2 | 2021 | 73.4831 | 37.5588 | 892.0800 | 446.0400 | 9.0000 |

G3 before and after by source (median and max)

| Data | plotyears | changed_gt1pct | BAPH_med_before | BAPH_med_after | BAPH_max_before | BAPH_max_after | TPH_med_before | TPH_med_after | TPH_max_before | TPH_max_after | QMD_med_before | QMD_med_after | QMD_max_before | QMD_max_after | SDI_med_before | SDI_med_after | SDI_max_before | SDI_max_after |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| DOFAW | 35 | 4 | 19.7376 | 18.7965 | 76.0621 | 46.9817 | 818.4000 | 793.6000 | 6100.8000 | 6100.8000 | 19.0800 | 19.0800 | 31.9528 | 31.9528 | 411.8094 | 386.0891 | 1453.4673 | 880.4284 |
| FIA | 171 | 171 | 9.5087 | 25.3425 | 41.2070 | 164.2331 | 476.3011 | 1308.6385 | 5012.8584 | 1.986e+04 | 17.1492 | 16.8330 | 66.0400 | 66.0400 | 194.7418 | 566.6125 | 551.1663 | 2091.3841 |
| KMR CAR | 34 | 0 | 5.3691 | 5.3691 | 34.3109 | 34.3109 | 148.6800 | 148.6800 | 743.4000 | 743.4000 | 17.5737 | 17.5737 | 59.3793 | 59.3793 | 112.1746 | 112.1746 | 391.1551 | 391.1551 |
| KMR PSP | 54 | 0 | 3.7352 | 3.7352 | 12.6650 | 12.6650 | 396.4800 | 396.4800 | 693.8400 | 693.8400 | 10.3773 | 10.7632 | 19.9862 | 19.9862 | 103.3063 | 103.3063 | 288.0254 | 288.0254 |
| Kahikinui | 64 | 4 | 8.6906 | 8.6906 | 59.1612 | 58.7032 | 1674.0000 | 1674.0000 | 8184.0000 | 8060.0000 | 6.7808 | 6.8252 | 20.5045 | 20.5045 | 264.8021 | 264.8021 | 939.6505 | 939.5307 |
| Kap | 53 | 0 | 41.1726 | 41.1726 | 91.3987 | 91.3987 | 311.5500 | 311.5500 | 5636.6300 | 5636.6300 | 35.4865 | 35.4865 | 121.3000 | 121.3000 | 553.9848 | 553.9848 | 1739.0287 | 1739.0287 |
| Kualoa | 6 | 0 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | 0.0000 | NA | NA | NA | NA | 0.0000 | 0.0000 | 0.0000 | 0.0000 |
| Mauka | 37 | 1 | 2.0047 | 2.0047 | 14.0111 | 14.0111 | 6.9600 | 6.8400 | 118.7300 | 118.7300 | 78.1197 | 78.1197 | 167.5000 | 167.5000 | 31.5962 | 31.5962 | 225.6221 | 225.6221 |
| PSP | 408 | 44 | 10.3335 | 10.2268 | 256.6454 | 68.9371 | 594.7200 | 520.3800 | 3568.3200 | 2527.5600 | 18.8303 | 19.7780 | 46.8808 | 40.1254 | 252.1023 | 241.0160 | 3177.2943 | 1167.9880 |

plot-years whose BAPH or TPH changed (1e-6): 282 of 862 | BAPH ratio deposited/rebuilt in 1.9 to 2.1: 22 | above 1.1: 48 | below 0.9: 164. no live stem with EXPF > 0: 100 | of which no live stem with DBH > 0 (set to 0): 94 by source {'KMR CAR': 1, 'KMR PSP': 1, 'PSP': 92} deposited BAPH max on them 6.439 | live stems with DBH > 0 but EXPF 0 on all (deposited kept, flagged): 6 {'Kualoa': 6} deposited BAPH max 0.0 live stems with DBH > 0 and EXPF 0 or missing (excluded from the stand sums): 111 by source {'Kualoa': 111}. Fallback count: 6 plot-years kept deposited (Kualoa, no expansion factor, deposited BAPH 0). Species composition by source (the single species sources are the only ones where G1 applies):

| Data | rows | koa_rows | other_rows | species | plotyears | plotyears_with_other | single_species |
|---|---|---|---|---|---|---|---|
| DOFAW | 4239 | 4181 | 58 | 2 | 35 | 13 | False |
| FIA | 21557 | 667 | 20890 | 8 | 1884 | 1852 | False |
| KMR CAR | 420 | 271 | 149 | 7 | 75 | 52 | False |
| KMR PSP | 430 | 430 | 0 | 1 | 54 | 0 | True |
| Kahikinui | 1214 | 1068 | 146 | 3 | 72 | 19 | False |
| Kap | 277 | 80 | 197 | 6 | 98 | 89 | False |
| Kualoa | 133 | 133 | 0 | 1 | 6 | 0 | True |
| Mauka | 76 | 76 | 0 | 1 | 37 | 0 | True |
| PSP | 10168 | 10168 | 0 | 1 | 416 | 0 | True |

G4 fitting-frame rows whose covariates changed by more than 5 percent (common keys v103 vs v102)

| frame | rows_v103 | rows_v102 | common_keys | rows_v103_not_in_v102 | changed_gt5pct_any | share_changed | changed_BAPH.0 | changed_BAPH.1 | changed_BAL.0 | changed_BAL.1 | changed_CR.0 | changed_CR.1 | changed_baph | changed_bal | changed_cr | changed_sdi | changed_qmd | changed_BAPH | changed_SDI0 | changed_QMD0 | changed_BAPH0 | changed_H40_0 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| dDBH CS | 4792 | 4790 | 4670 | 122 | 1452 | 0.3109 | 631.0000 | 610.0000 | 790.0000 | 801.0000 | 412.0000 | 500.0000 | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA |
| dHT CS | 3857 | 3857 | 3812 | 45 | 1144 | 0.3001 | 523.0000 | 420.0000 | 654.0000 | 545.0000 | 355.0000 | 325.0000 | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA |
| survival baseline (Eq5) | 4871 | 4869 | 4749 | 122 | 1150 | 0.2422 | NA | NA | NA | NA | NA | NA | 698.0000 | 856.0000 | 479.0000 | 698.0000 | 510.0000 | NA | NA | NA | NA | NA |
| survival recovered ii (Eq5a) | 4223 | 4298 | 4148 | 75 | 1004 | 0.2420 | NA | NA | NA | NA | NA | NA | 566.0000 | 736.0000 | 368.0000 | 566.0000 | 469.0000 | NA | NA | NA | NA | NA |
| static height | 9137 | 9282 | 9137 | 0 | 1262 | 0.1381 | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | 1262.0000 | NA | NA | NA | NA |
| M1 pairs | 407 | 415 | 399 | 8 | 122 | 0.3058 | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | NA | 98.0000 | 47.0000 | 98.0000 | 17.0000 |

## 3. Copied visits (D2)

D2 scan: visits with a previous visit 416 | copied (>= 0.90) 8 | partial (0.50 to 0.90) 0 | visits with 0 < share < 0.50 33. D2 copied visits removed: 8 | all species records removed 160 | koa records removed 160. No visit fell in the 50 to 90 percent band, so no partial copy tree-visit was removed. The 2017 and 2019 partial copies named by the red team are below 50 percent and are kept by the rule (zero growth kept as real).

| Data | Install | Plot | Measure | prev | n_common | n_ident_dbh | n_ident_dbh_ht | share | class |
|---|---|---|---|---|---|---|---|---|---|
| PSP | 101 | 1 | 2015 | 2014 | 17 | 17 | 17 | 1.0000 | copied |
| PSP | 102 | 2 | 2015 | 2014 | 22 | 22 | 22 | 1.0000 | copied |
| PSP | 103 | 3 | 2015 | 2014 | 18 | 18 | 18 | 1.0000 | copied |
| PSP | 104 | 4 | 2015 | 2014 | 19 | 19 | 19 | 1.0000 | copied |
| PSP | 105 | 5 | 2015 | 2014 | 20 | 20 | 20 | 1.0000 | copied |
| PSP | 106 | 6 | 2015 | 2014 | 17 | 17 | 17 | 1.0000 | copied |
| PSP | 107 | 7 | 2015 | 2014 | 11 | 11 | 11 | 1.0000 | copied |
| PSP | 108 | 8 | 2015 | 2014 | 21 | 21 | 21 | 1.0000 | copied |

Largest shares below the 50 percent threshold (kept)

| Data | Install | Plot | Measure | prev | n_common | n_ident_dbh_ht | share |
|---|---|---|---|---|---|---|---|
| FIA | 15-1-1-4895 | 3 | 2019 | 2010 | 6 | 2 | 0.333 |
| FIA | 15-1-1-2764 | 4 | 2019 | 2010 | 16 | 4 | 0.250 |
| FIA | 15-1-1-2291 | 2 | 2019 | 2010 | 10 | 2 | 0.200 |
| PSP | 111 | 11 | 2015 | 2014 | 6 | 1 | 0.167 |
| FIA | 15-1-1-2406 | 3 | 2019 | 2010 | 6 | 1 | 0.167 |
| PSP | 118 | 18 | 2024 | 2023 | 7 | 1 | 0.143 |
| PSP | 112 | 12 | 2015 | 2014 | 8 | 1 | 0.125 |
| PSP | 103 | 3 | 2025 | 2024 | 8 | 1 | 0.125 |
| FIA | 15-1-1-2400 | 4 | 2019 | 2010 | 9 | 1 | 0.111 |
| DOFAW | Kulani | 23 | 1977 | 1973 | 103 | 11 | 0.107 |
| PSP | 107 | 7 | 2024 | 2023 | 10 | 1 | 0.100 |
| FIA | 15-1-7-1095 | 3 | 2019 | 2010 | 10 | 1 | 0.100 |

Effect on each frame: plot_intervals rows 326 | rows touching a copied visit removed 16 | merged intervals added 8 | rows now 318 | rows whose sdi changed by more than 5 percent 11; plot_intervals_origin rows 294 | rows touching a copied visit removed 16 | merged intervals added 8 | rows now 286 | rows whose sdi changed by more than 5 percent 11; ingrowth v103: rows 357 | covariates repaired at the inferred start visit 347 | kept deposited (no inferred start visit) 10 | rows touching a copied visit removed 2 merged added 1 | RD changed > 5 percent 47. The M1 pair table goes from 415 to 407 intervals, the dDBH consecutive frame gains 2 rows (4,790 to 4,792) because the 2014 to 2015 zero growth rows were already screened out and each 2015 to 2016 row becomes a true 2014 to 2016 row, dHT stays at 3,857, the static height frame loses 145 records.

## 4. Frames, v102 vs v103

| frame | v102 | v103 |
|---|---|---|
| dDBH consecutive (CS) | 4790 | 4792 |
| dHT consecutive (CS) | 3857 | 3857 |
| dDBH NO (consecutive plus first to last) | 4,969 (refit2) | 4992 |
| dHT NO | 4,033 (refit2) | 4044 |
| AK_SURV deposit table | 4869 | 4871 |
| Eq5 baseline survival | 4,869 (79 deaths) | 4871 (79 deaths) |
| Eq5a recovered ii | 4,298 (877 deaths) | 4223 (877 deaths) |
| recovered i | 4,114 (798) | 4051 |
| static height frame | 9282 | 9137 |
| height fit records | 9059 | 8914 |
| M1 pair table | 415 | 407 |
| plot_intervals (Stage 1 input) | 326 | 318 |
| Stage 1 fitting intervals | 290 | 282 |
| ingrowth | 358 | 357 |
| FIA crown frame | 360 | 360 |

The removal screen removed 0 rows from the consecutive and survival frames (no consecutive interval spans an interior removal year) and 78 candidate pairs from the NO frame.

## 5. Component refits

Reproduction gates, each run before the v103 fit: HEIGHT REPRODUCTION v102 max abs diff 2.842171e-14 PASS ; SURVIVAL REPRODUCTION v102 max abs coef diff 4.263256e-14 PASS ; INGROWTH REPRODUCTION v102 (estimate, se, bootstrap interval) max abs diff 4.440892e-15 PASS ; STAGE 1 REPRODUCTION on plot_intervals_origin_v102 ( 290 intervals ): max abs diff S1 4.44e-15 S2 1.33e-15 pbar 2.22e-16 PASS ; ALLOMETRY REPRODUCTION on the record pair table: A -0.1686307 K_HD 1.171947 n 360 abs diff 3.69e-15 PASS ; GARCIA CHECK REPRODUCTION v102 max abs diff 1.24e-14 PASS ; GATE beta anchor record form reproduced: z99 389696.3068245182 n 471 beta 0.16019053617304485 PASS; REPRO R1 dDBH _c_NO on refit2 frames2 (read back from CSV): rows 4969 max abs fixef diff 3.35e-05 max diff in SE units 5.68e-05 logLik diff 1.73e-05 PASS ( 106 s) ; REPRO R1 dHT _c_NO on refit2 frames2 (read back from CSV): rows 4033 max abs fixef diff 1.22e-06 max diff in SE units 5.06e-06 logLik diff 1.66e-06 PASS ( 103 s) ; REPRO R2 dDBH v102 vector on frames/ dDBH _v102.csv rows 4790 max abs fixef diff 4.66e-15 max diff in SE units 1.59e-14 PASS ( 56 s) ; REPRO R2 dHT v102 vector on frames/ dHT _v102.csv rows 3857 max abs fixef diff 4.66e-15 max diff in SE units 4.96e-14 PASS ( 36 s) ; COHORT REPRODUCTION on refit2 bal_treevisit2: max abs diff 4.440892e-16 PASS . R1 differs from the refit2 vector by 3.4e-5 at most (5.7e-5 SE, logLik 1.7e-5) because refit2 fitted its in-memory frame and this run reads it back from CSV; that is accepted as reproduction at 1e-3 SE and is stated here.

### 5.1 Eq. 2 static height (HT_P)

| parameter | estimate_v102 | se_v102 | estimate_v103 | se_v103 | change in v102 SE |
|---|---|---|---|---|---|
| a0 | 32.19822 | 1.51906 | 28.92883 | 1.44687 | -2.15224 |
| a1 | 1.20851 | 0.15130 | 0.96679 | 0.14051 | -1.59765 |
| b | 0.01658 | 0.00095615 | 0.01703 | 0.00098515 | 0.46805 |
| c | 0.80489 | 0.01141 | 0.79225 | 0.01197 | -1.10838 |
| g1 | 0.06208 | 0.00541 | 0.07684 | 0.00646 | 2.73010 |
| g2 | -0.37326 | 0.01627 | -0.34331 | 0.01689 | 1.84123 |

| frame | n | n_inst | logLik | AIC | tau_inst | sigma | r2_cond | r2_pa | rmse_pa | bias_pa | bias_pa_natural | bias_pa_planted | loio_r2 | loio_rmse | loio_bias |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| v102 | 9059 | 143 | -1.902e+04 | 3.806e+04 | 5.8768 | 1.9380 | 0.8606 | 0.7864 | 2.3843 | 0.2228 | 0.0455 | 0.8993 | 0.7923 | 2.3515 | 0.0503 |
| v103 | 8914 | 143 | -1.871e+04 | 3.745e+04 | 5.2701 | 1.9366 | 0.8621 | 0.7878 | 2.3878 | 0.3948 | 0.2320 | 1.0032 | 0.7976 | 2.3319 | 0.0527 |

The asymptote falls (a0 -2.2 SE, a1 -1.6 SE) and the density term strengthens (g1 +2.7 SE), because the repaired BAPH halves the doubled PSP and DOFAW values and quadruples FIA. LOIO (143 folds) improves slightly.

### 5.2 Eq. 3 crown (HCB_P)

The FIA crown frame (360 trees, 69 subplots, 36 plots) was matched to HI_TREE (all 360 matched by DBH, 203 at the same INVYR, the rest 1 to 5 yr earlier by measurement year) and BAPH and BAL rebuilt from the live all species subplot list with the x4 expansion.

| fit | bal | n | rmse | r2 | bias | signs_kept |
|---|---|---|---|---|---|---|
| HCB_P deployed, rebuilt covariates | d | 360 | 2.3615 | 0.2572 | -0.5107 | NA |
| HCB_P form refit (nls) | d | 360 | 2.1119 | 0.4059 | -0.0428 | False |
| HCB_P deployed, rebuilt covariates | l | 360 | 2.3819 | 0.2443 | -0.5445 | NA |
| HCB_P form refit (nls) | l | 360 | 2.1118 | 0.4060 | -0.0424 | False |
| HCB_P deployed, rebuilt covariates | c | 360 | 2.2286 | 0.3385 | -0.3834 | NA |
| HCB_P form refit (nls) | c | 360 | 2.0913 | 0.4175 | -0.0403 | False |

| bal | term | HCB_P | estimate | se_nls | boot_se | lo95 | hi95 | sign_kept | dz_boot |
|---|---|---|---|---|---|---|---|---|---|
| d | b0 | 0.1684 | -0.5323 | 0.2848 | 0.6238 | -1.5233 | 0.7800 | False | -1.1233 |
| d | b1 | 1.0146 | 0.5419 | 0.6662 | 1.2915 | -1.9699 | 3.1138 | True | -0.3660 |
| d | b2 | -0.3760 | -1.2807 | 0.1776 | 0.2628 | -1.8134 | -0.7887 | True | -3.4422 |
| d | b3 | -0.0078 | -3.594e-05 | 0.0017 | 0.0038 | -0.0074 | 0.0069 | True | 2.0571 |
| d | b4 | -0.3734 | -0.1394 | 0.0758 | 0.1496 | -0.4641 | 0.1162 | True | 1.5649 |
| d | b5 | -0.2210 | -0.5295 | 0.1444 | 0.2983 | -1.2218 | -0.0097 | True | -1.0345 |
| l | b0 | 0.1684 | -0.5136 | 0.2962 | 0.6130 | -1.5935 | 0.7338 | False | -1.1124 |
| l | b1 | 1.0146 | 0.5379 | 0.6626 | 1.2684 | -1.9590 | 2.9518 | True | -0.3758 |
| l | b2 | -0.3760 | -1.2826 | 0.1774 | 0.2526 | -1.7811 | -0.8262 | True | -3.5890 |
| l | b3 | -0.0078 | 0.0002927 | 0.0018 | 0.0037 | -0.0065 | 0.0076 | False | 2.1946 |
| l | b4 | -0.3734 | -0.1463 | 0.0759 | 0.1495 | -0.4416 | 0.1336 | True | 1.5196 |
| l | b5 | -0.2210 | -0.5319 | 0.1448 | 0.2786 | -1.1150 | -0.0261 | True | -1.1161 |
| c | b0 | 0.1684 | -0.2586 | 0.2932 | 0.5349 | -1.3234 | 0.8634 | False | -0.7982 |
| c | b1 | 1.0146 | -0.6383 | 0.7858 | 1.3193 | -3.3894 | 1.8940 | False | -1.2528 |
| c | b2 | -0.3760 | -0.9247 | 0.2169 | 0.3201 | -1.6214 | -0.3448 | True | -1.7140 |
| c | b3 | -0.0078 | -0.0081 | 0.0031 | 0.0052 | -0.0196 | -0.0002323 | True | -0.0634 |
| c | b4 | -0.3734 | 0.0001023 | 0.0835 | 0.1706 | -0.3343 | 0.3223 | False | 2.1891 |
| c | b5 | -0.2210 | -0.5046 | 0.1429 | 0.2899 | -1.2387 | 0.0188 | True | -0.9784 |

Decision: HCB_P is KEPT. Every refit improves RMSE (2.09 to 2.11 m against 2.23 to 2.38 for HCB_P on the same covariates) but none keeps every sign (terms that flip, by definition: d: b0; l: b0, b3; c: b0, b1, b4); the plot bootstrap intervals of b0, b1, b3, b4, b5 span zero under at least one definition. The rule requires both. All increment and survival crown ratios in v103 therefore use HCB_P (increments) or the frame builder's koa.HCB (survival), exactly as in v102.

### 5.3 Eq. 5 and Eq. 5a survival

Eq5

| term | v102 | v102_se_glm | v103 | v103_se_glm | v103_boot_lo | v103_boot_hi | change in v102 SE |
|---|---|---|---|---|---|---|---|
| (Intercept) | 14.1316 | 0.7167 | 9.7927 | 1.2309 | 0.8389 | 4.272e+15 | -6.0537 |
| ht | 0.1321 | 0.0301 | -0.0213 | 0.0497 | -2.36e+13 | 1.128e+14 | -5.0998 |
| log(ht) | -4.5706 | 0.3616 | -1.5079 | 0.6770 | -1.289e+15 | 1.5198 | 8.4706 |
| rht | 6.7211 | 0.4343 | 1.5618 | 0.5458 | -1.3923 | 1.494e+15 | -11.8799 |
| log(cr) | 14.3025 | 0.7223 | -11.0078 | 1.3637 | -2.059e+15 | 9.386e+14 | -35.0424 |
| log(ht/dbh) | -2.9140 | 0.1772 | 0.3256 | 0.2734 | -4.142e+14 | 1.596e+14 | 18.2831 |
| log(byi/100) | 2.5878 | 0.2091 | 7.5326 | 0.4081 | -7.056e+14 | 2.136e+15 | 23.6465 |
| I(byi/1000) | -20.9683 | 1.1941 | -47.1851 | 2.2580 | -1.341e+16 | 1.404e+15 | -21.9547 |

Eq5a

| term | v102 | v102_se_glm | v103 | v103_se_glm | v103_boot_lo | v103_boot_hi | change in v102 SE |
|---|---|---|---|---|---|---|---|
| (Intercept) | -1.5735 | 0.4173 | 0.0651 | 0.4904 | -3.5125 | 2.7883 | 3.9269 |
| ht | -0.0013 | 0.0277 | 0.0305 | 0.0268 | -0.1141 | 0.1016 | 1.1456 |
| log(ht) | 0.0211 | 0.2468 | -0.5106 | 0.2524 | -1.1228 | 0.7186 | -2.1540 |
| rht | -2.3104 | 0.2812 | -1.4682 | 0.3060 | -4.8679 | -0.3834 | 2.9952 |
| log(cr) | 1.6645 | 0.6256 | 5.0224 | 0.8164 | -3.6898 | 12.1162 | 5.3671 |
| log(ht/dbh) | 1.0095 | 0.1252 | 0.7170 | 0.1335 | -0.1680 | 1.8341 | -2.3358 |
| log(byi/100) | -0.2542 | 0.1918 | -0.2684 | 0.1952 | -2.5357 | 4.1576 | -0.0743 |
| I(byi/1000) | 3.4008 | 1.0441 | 2.1222 | 1.0713 | -15.6134 | 12.0569 | -1.2246 |

| eq | frame | n | deaths | installations | aic | converged_both | auc_apparent | auc_loio_pooled | auc_loio_annual | auc_within_interval | loio_folds_converged | expected_deaths |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Eq5 | v102 | 4869 | 79 | 62 | 866.3698 | True | 0.8887 | 0.4907 | 0.8134 | 0.3405 | 62 | 139.4362 |
| Eq5 | v103 | 4871 | 79 | 62 | 1110.1190 | True | 0.8753 | 0.3078 | 0.6328 | 0.2959 | 55 | 87.6008 |
| Eq5a | v102 | 4298 | 877 | 51 | 3080.0023 | True | 0.8559 | 0.8204 | 0.7282 | 0.7766 | 51 | 876.8490 |
| Eq5a | v103 | 4223 | 877 | 51 | 3042.9691 | True | 0.8584 | 0.8281 | 0.7672 | 0.7761 | 51 | 877.6952 |

Eq. 5a (death response, recovered ii frame, 4,223 rows, 877 deaths) is refit cleanly: AIC 3,080.0 to 3,043.0, LOIO annual AUC 0.728 to 0.767, within interval AUC unchanged at 0.776; ln(cr) moves +5.4 SE (1.66 to 5.02) because crown ratio is the covariate the repaired BAL and BAPH feed. Eq. 5 (Table 6 vector, 79 deaths, most of them FIA: 67 of 79 in the record table) does NOT survive the repair: AIC rises from 866.4 to 1,110.1 on two more rows with the same deaths, LOIO annual AUC falls from 0.813 to 0.633, 7 of 62 LOIO folds fail to converge, ln(cr) changes sign (14.30 to -11.01, -35 SE) and the bootstrap is degenerate. The FIA crown ratios computed by koa.HCB with the quadrupled FIA BAPH no longer separate the FIA deaths. Decision: the v103 Eq. 5 vector is NOT deployable; Eq. 5 is off the production path (the M1 gated Garcia rate projects mortality), so the engine keeps the v102 Eq. 5 vector with this failure disclosed, and Eq. 5a v103 is reported as the replacement specification.

### 5.4 Eq. 6 ingrowth

| frame | term | estimate | se | lo95 | hi95 | n | n_plots | dispersion | b_SDI_engine | change in v102 SE |
|---|---|---|---|---|---|---|---|---|---|---|
| v102 | d0 (intercept) | 3.51049 | 2.25256 | -9.44833 | 5.64684 | 358 | 54 | 556.11971 | NA | 0.00000 |
| v102 | d1 (RD) | -2.69244 | 0.67398 | -4.90108 | -1.63315 | 358 | 54 | 556.11971 | -0.00538 | 0.00000 |
| v102 | d2 (planted) | 1.56966 | 2.23753 | -0.41500 | 14.59651 | 358 | 54 | 556.11971 | NA | 0.00000 |
| v103 | d0 (intercept) | 3.38378 | 2.31620 | -9.57531 | 5.54945 | 357 | 54 | 591.01415 | NA | -0.05625 |
| v103 | d1 (RD) | -2.68984 | 0.69059 | -4.85699 | -1.59572 | 357 | 54 | 591.01415 | -0.00538 | 0.00386 |
| v103 | d2 (planted) | 1.63983 | 2.30364 | -0.37458 | 14.68055 | 357 | 54 | 591.01415 | NA | 0.03136 |

The v103 frame repairs BAPH, SDI, RD (= SDI/500) and pBA at the inferred start visit for 347 of 357 rows (10 rows without an identified start visit keep the deposited values) and merges the 2014 to 2015 to 2016 Keauhou periods. The vector moves by at most 0.06 SE; the ingrowth frame is still the key deduplicated record, not a rebuild (v102 deviation D4 stands).

### 5.5 Stage 1 mortality gate, Stage 2, and the Garcia inputs

Stage 1 and 2 are refit with fitB of origin_refit_span.R on plot_intervals with sdi (its own form TPH x (QMD/25)^1.605, reproduced on 288 of 326 deposited rows and scaled on the rest) recomputed from the repaired stand table and the 2015 Keauhou intervals merged; the refit2 Thin_Yr screen removed no further interval.

| term | v102 | v102_lo | v102_hi | v103 | v103_boot_se | v103_lo | v103_hi | v102_se_approx | dz |
|---|---|---|---|---|---|---|---|---|---|
| s1_intercept | -1.6786 | -2.6864 | 0.3350 | -1.6681 | 0.7287 | -2.6477 | 0.3575 | 0.7708 | 0.0135 |
| s1_lnSDI | 0.1619 | 0.0133 | 0.3152 | 0.1656 | 0.0756 | 0.0185 | 0.3176 | 0.0770 | 0.0483 |
| s1_planted | -0.1910 | -2.1144 | 0.2222 | -0.2192 | 0.5793 | -2.1620 | 0.1976 | 0.5961 | -0.0473 |
| s2_intercept | -2.2047 | -3.2916 | -0.8190 | -2.0604 | 0.6556 | -3.1859 | -0.6585 | 0.6307 | 0.2287 |
| s2_lnSDI | -0.0447 | -0.2591 | 0.1110 | -0.0688 | 0.0981 | -0.2843 | 0.0929 | 0.0944 | -0.2549 |
| s2_planted | -0.0179 | -0.3983 | 0.4204 | -0.0548 | 0.2138 | -0.4376 | 0.3862 | 0.2088 | -0.1772 |
| pbar | 0.3131 | NA | NA | 0.3127 | 0.0304 | 0.2592 | 0.3754 | NA | NA |

Stage 1 n 290 -> 282, plots 54 -> 54, with mortality 118 -> 117, duan 1.56293 -> 1.56145. Every Stage 1 and Stage 2 term moves by less than 0.26 SE.

Garcia allometry ln QMD0 = A + k_HD ln H40_0 on the regular intervals of the M1 pair table

| table | A | K_HD | se_A | se_K | n | plots | r2 | rmse |
|---|---|---|---|---|---|---|---|---|
| record | -0.1686 | 1.1719 | 0.0989 | 0.0405 | 360 | 103 | 0.7008 | 0.4610 |
| v102 | 0.0413 | 1.0920 | 0.0976 | 0.0395 | 350 | 103 | 0.6870 | 0.4262 |
| v103 | 0.1680 | 1.0411 | 0.0942 | 0.0381 | 344 | 103 | 0.6853 | 0.4140 |

The allometry moves materially: A from -0.1686 to 0.1680 (+3.4 record SE) and k_HD from 1.1719 to 1.0411 (-3.2 SE). Most of the move is already in v102 (the deduplicated pair table), and the rest is the repaired QMD0 plus the FIA H40 change (EXPF x4 means fewer FIA trees make up the top 40 per ha).

Anchored beta (100 / sqrt(z99 of N x H_QMD^2))

| version | z99 | n | beta | note |
|---|---|---|---|---|
| record | 3.897e+05 | 471 | 0.16019 |  |
| v103_record_form | 4.8994e+05 | 463 | 0.14287 | record form (all records incl. dead, KeyDupFlag 0) on the v103 koa list, v103 allometry |
| v103_deployed | 7.4222e+05 | 602 | 0.11607 | repaired live all species TPH and QMD, plot-years with >= 5 live stems, v103 allometry |
| v103_koa_live | 4.5633e+05 | 483 | 0.14803 | live koa stems only, >= 5, v103 allometry |

The record anchor counted every record of the plot-measure, dead stems included (the gate reproduces 389,696.3 and n 471 only in that form). The v103 value deployed is the live koa form, 0.14803, because the Garcia step acts on the simulated koa stand; the all species form (0.11607, driven by the FIA subplot densities of up to 19,860 stems/ha) is given as a sensitivity and is a decision for Aaron.

Garcia alpha check fit (H40 form), not deployed, as in v102 D6

| frame | set | alpha | beta | gamma | n_regular | alpha_lo | alpha_hi |
|---|---|---|---|---|---|---|---|
| v102 | published_set | 3.4510 | 0.1324 | 3.4510 | 350 | NA | NA |
| v102 | removals_excluded | 3.4755 | 0.1332 | 3.4755 | 342 | 1.8968 | 13.0462 |
| v103 | published_set | 3.8269 | 0.1356 | 3.8269 | 344 | NA | NA |
| v103 | removals_excluded | 3.8603 | 0.1365 | 3.8603 | 336 | 2.1181 | 19.9468 |

GARCIA_ALPHA 2.96 of record stays deployed; the v103 check fit moves it to 3.86 (bootstrap 2.12 to 19.95), so the rate is still weakly identified.

### 5.6 Eq. 4 increments, preregistered selection

| fit | sign_pass | sign_fail | eq_int_CS | eq_slope_CS | eq_int_NO | eq_slope_NO | equiv_pass_both | max_eq_region | size_max_dev_NO | size_worst_class | rmse_CS | rmse_NO | slope_CS | slope_NO | eligible |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| dDBH_P_CS | True | NA | 0.2600 | 0.1971 | 0.2634 | 0.1948 | False | 0.2634 | 0.7758 | 40-60 | 1.3118 | 1.2981 | 0.9293 | 0.9388 | False |
| dDBH_C_CS | False | b6_neg | 0.1961 | 0.1427 | 0.1924 | 0.1450 | True | 0.1961 | 0.4263 | 40-60 | 1.2848 | 1.2695 | 0.9744 | 0.9808 | False |
| dDBH_C_NO | False | b6_neg | 0.1787 | 0.1569 | 0.1735 | 0.1545 | True | 0.1787 | 0.4198 | 40-60 | 1.2640 | 1.2523 | 0.9386 | 0.9464 | False |
| dDBH_L_CS | False | b6_neg | 0.1848 | 0.1367 | 0.1874 | 0.1369 | True | 0.1874 | 0.6341 | 40-60 | 1.2783 | 1.2647 | 0.9751 | 0.9826 | False |
| dDBH_L_NO | True | NA | 0.1587 | 0.1189 | 0.1549 | 0.1184 | True | 0.1587 | 0.7031 | 40-60 | 1.2745 | 1.2607 | 1.0116 | 1.0194 | False |
| dHT_P_CS | True | NA | 0.2920 | 0.1720 | 0.2824 | 0.1593 | False | 0.2920 | 0.4012 | 20-30 | 1.0921 | 1.0766 | 0.9918 | 0.9990 | False |
| dHT_C_CS | True | NA | 0.3682 | 0.2704 | 0.3424 | 0.2465 | False | 0.3682 | 0.3322 | 15-20 | 1.0994 | 1.0828 | 0.9183 | 0.9277 | False |
| dHT_C_NO | True | NA | 0.2463 | 0.1751 | 0.2406 | 0.1568 | True | 0.2463 | 0.3161 | 20-30 | 1.0925 | 1.0762 | 0.9985 | 1.0055 | False |
| dHT_L_CS | True | NA | 0.3348 | 0.2221 | 0.3170 | 0.1926 | False | 0.3348 | 0.3810 | 20-30 | 1.0924 | 1.0764 | 0.9458 | 0.9547 | False |
| dHT_L_NO | True | NA | 0.2453 | 0.1606 | 0.2297 | 0.1551 | True | 0.2453 | 0.3576 | 20-30 | 1.0908 | 1.0751 | 1.0062 | 1.0128 | False |

Size class obs/pred on the NO frame

| fit | size_ratios_NO |
|---|---|
| dDBH_P_CS | 0-5:1.04 5-10:1.03 10-20:1.07 20-30:1.14 30-40:1.38 40-60:1.78 |
| dDBH_C_CS | 0-5:1.05 5-10:0.98 10-20:1.06 20-30:1.20 30-40:1.39 40-60:1.43 |
| dDBH_C_NO | 0-5:0.97 5-10:0.97 10-20:1.03 20-30:1.10 30-40:1.29 40-60:1.42 |
| dDBH_L_CS | 0-5:1.06 5-10:0.99 10-20:1.05 20-30:1.15 30-40:1.36 40-60:1.63 |
| dDBH_L_NO | 0-5:1.03 5-10:0.99 10-20:1.06 20-30:1.16 30-40:1.38 40-60:1.70 |
| dHT_P_CS | 0-5:1.08 5-10:1.09 10-15:1.06 15-20:1.28 20-30:1.40 |
| dHT_C_CS | 0-5:1.08 5-10:1.06 10-15:1.07 15-20:1.33 20-30:1.29 |
| dHT_C_NO | 0-5:1.10 5-10:1.05 10-15:1.03 15-20:1.24 20-30:1.32 |
| dHT_L_CS | 0-5:1.09 5-10:1.06 10-15:1.06 15-20:1.31 20-30:1.38 |
| dHT_L_NO | 0-5:1.10 5-10:1.05 10-15:1.03 15-20:1.24 20-30:1.36 |

Benchmark not in the candidate set (red team item 4): the v102 vector of record in engine form with BAL d, its origin constants re-solved on each v103 frame

| fit | eval_frame | slope | min_region_int | min_region_slope | pass_int_25 | pass_slope_25 |
|---|---|---|---|---|---|---|
| dDBH_V102recal_CS | CS | 0.9893 | 0.1807 | 0.1318 | 1 | 1 |
| dDBH_V102recal_NO | NO | 0.9791 | 0.1811 | 0.1390 | 1 | 1 |
| dHT_V102recal_CS | CS | 0.9429 | 0.3466 | 0.2386 | 0 | 1 |
| dHT_V102recal_NO | NO | 0.9457 | 0.3368 | 0.2232 | 0 | 1 |

| fit | eval_frame | strat | level | n | ratio | rmse_ann |
|---|---|---|---|---|---|---|
| dDBH_V102recal_NO | NO | all | all | 4971 | 1.046 | 1.294 |
| dDBH_V102recal_NO | NO | size | 0-5 | 949 | 1.101 | 1.706 |
| dDBH_V102recal_NO | NO | size | 5-10 | 1165 | 1.076 | 1.377 |
| dDBH_V102recal_NO | NO | size | 10-20 | 1517 | 1.027 | 1.217 |
| dDBH_V102recal_NO | NO | size | 20-30 | 920 | 0.935 | 0.873 |
| dDBH_V102recal_NO | NO | size | 30-40 | 321 | 1.028 | 0.996 |
| dDBH_V102recal_NO | NO | size | 40-60 | 95 | 1.184 | 0.914 |
| dHT_V102recal_NO | NO | all | all | 4033 | 1.078 | 1.083 |
| dHT_V102recal_NO | NO | size | 0-5 | 1048 | 1.007 | 1.063 |
| dHT_V102recal_NO | NO | size | 5-10 | 1604 | 1.066 | 1.071 |
| dHT_V102recal_NO | NO | size | 10-15 | 912 | 1.137 | 1.193 |
| dHT_V102recal_NO | NO | size | 15-20 | 367 | 1.405 | 0.928 |
| dHT_V102recal_NO | NO | size | 20-30 | 102 | 1.631 | 0.940 |

Decision

| resp | deployed | rule | reasons |
|---|---|---|---|
| dDBH | dDBH_L_NO | DEVIATION: no candidate eligible, smallest maximum equivalence region | no eligible candidate; dDBH_L_NO has the smallest max region 0.159 | benchmark P_CS RMSE CS 1.3118 NO 1.2745 vs chosen CS 1.2981 NO 1.2607 |
| dHT | dHT_L_NO | DEVIATION: no candidate eligible, smallest maximum equivalence region | no eligible candidate; dHT_L_NO has the smallest max region 0.245 | benchmark P_CS RMSE CS 1.0921 NO 1.0908 vs chosen CS 1.0766 NO 1.0751 |

No candidate is eligible for either response. Every dDBH candidate over-predicts the large tree classes on the NO frame (obs/pred 1.29 to 1.78 in 30 to 60 cm) and three of the four conventional and live list fits fail the b6 < 0 check (b6 +0.0015 to +0.0175, stand basal area raising growth); every dHT candidate under-predicts trees above 15 m by 24 to 40 percent. Under the fallback of the rule the candidate with the smallest maximum equivalence region is deployed: dDBH_L_NO (0.159; it passes signs and equivalence on both frames and fails only the size gate at 0.70) and dHT_L_NO (0.245, a tie with dHT_C_NO at 0.246). This is DEVIATION A1-D1 and it is recorded, not hidden. Two facts should weigh on it. First, the incumbent benchmark P_CS does not beat the deployed fits (RMSE 1.3118 vs 1.2981 CS and 1.2745 vs 1.2607 NO for dDBH, 1.0921 vs 1.0908 and 1.0766 vs 1.0751 for dHT), so the 1 percent override does not fire. Second, the v102 dDBH vector recalibrated on the v103 frame, which is not a candidate, would be eligible under every criterion (signs pass, equivalence passes on both frames at 0.18 and 0.14, size max deviation 0.18 at 40 to 60 cm, n 95) at an NO RMSE 2.6 percent above dDBH_L_NO; its re-solved constants are in the JSON as an alternate, and choosing it would be a rule change for Aaron to make. For dHT the recalibrated v102 vector fails the intercept at 0.34 and the size gate (1.63 at 20 to 30 m), so no alternate is offered.

dDBH deployed vector dDBH_L_NO against the v102 vector of record (v102 model SE)

| term | v102 | v102_se | v103 | v103_model_se | v103_boot_se | boot_lo95 | boot_hi95 | change in v102 SE |
|---|---|---|---|---|---|---|---|---|
| b0 | -1.15094 | 0.67643 | 0.28798 | 0.68780 | 0.95407 | -1.79358 | 2.05051 | 2.12723 |
| b1 | 0.33712 | 0.03727 | 0.36076 | 0.03410 | 0.11356 | 0.16890 | 0.61026 | 0.63427 |
| b2 | -0.01435 | 0.00390 | -0.02237 | 0.00442 | 0.01810 | -0.06383 | 0.00455 | -2.06048 |
| b3 | -0.00177 | 0.00048341 | -0.00145 | 0.00019294 | 0.00043105 | -0.00241 | -0.00081056 | 0.65672 |
| b4 | -0.43065 | 0.02537 | -0.33770 | 0.01786 | 0.05033 | -0.45491 | -0.26207 | 3.66445 |
| b5 | 1.28094 | 0.29418 | 0.84118 | 0.22896 | 0.47571 | 0.06609 | 1.84123 | -1.49487 |
| b6 | -0.01760 | 0.00349 | -0.01678 | 0.00406 | 0.01740 | -0.04464 | 0.02221 | 0.23661 |
| b7 | -0.01762 | 0.00245 | -0.01770 | 0.00234 | 0.00872 | -0.03582 | -0.00552 | -0.03013 |
| b8 | 0.30452 | 0.08300 | 0.14025 | 0.08591 | 0.13816 | -0.16698 | 0.41713 | -1.97917 |
| b9 | 0.41035 | 0.23896 | -0.01590 | 0.24090 | 0.32440 | -0.27373 | 0.95352 | -1.78376 |

dHT deployed vector dHT_L_NO against the v102 vector of record (v102 model SE)

| term | v102 | v102_se | v103 | v103_model_se | v103_boot_se | boot_lo95 | boot_hi95 | change in v102 SE |
|---|---|---|---|---|---|---|---|---|
| b0 | -3.61154 | 0.74700 | -2.37494 | 0.87322 | 1.42944 | -7.88848 | -0.63329 | 1.65542 |
| b1 | 1.12069 | 0.09516 | 1.16067 | 0.08163 | 0.21911 | 0.79794 | 1.65661 | 0.42016 |
| b2 | -0.11555 | 0.01289 | -0.15128 | 0.01074 | 0.03396 | -0.22712 | -0.09789 | -2.77195 |
| b3 | -0.00091209 | 0.00030212 | -0.00015779 | 9.4645e-05 | 0.00028161 | -0.00089863 | 0.00032313 | 2.49667 |
| b4 | -0.13309 | 0.02791 | -0.18177 | 0.02039 | 0.04414 | -0.26998 | -0.10181 | -1.74405 |
| b5 | -0.52531 | 0.27813 | 0.21791 | 0.25869 | 0.39394 | -0.49892 | 1.09289 | 2.67227 |
| b6 | 0.03799 | 0.00489 | 0.06392 | 0.00597 | 0.01968 | 0.02551 | 0.09992 | 5.30598 |
| b7 | -0.12411 | 0.00727 | -0.11955 | 0.00657 | 0.02266 | -0.17471 | -0.08426 | 0.62598 |
| b8 | 0.22322 | 0.06854 | 0.09077 | 0.07277 | 0.19056 | -0.14695 | 0.83437 | -1.93237 |
| b9 | 1.06822 | 0.20477 | 0.75749 | 0.20748 | 1.29757 | 0.03216 | 3.88719 | -1.51745 |

Deployed fit statistics (c is the recursion consistent origin constant; the engine multiplier is c = CF x CAL)

| fit | n | n_trees | n_inst | logLik | aic | sigma | varpower | tau_source | tau_inst | tau_tree | cf_source_inst | c_natural | c_planted | cal_natural | cal_planted | r2_cond_period |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| dDBH_L_NO | 4971 | 1337 | 60 | -9587.67487 | 19205 | 1.97863 | -0.12411 | 0.45797 | 0.77647 | 0.27639 | 1.50128 | 0.38370 | 1.45753 | 0.25558 | 0.97085 | 0.83364 |
| dHT_L_NO | 4033 | 1167 | 58 | -6931.92494 | 13894 | 1.01428 | 0.07738 | 1.31016 | 0.22556 | 0.29179 | 2.41982 | 0.43617 | 2.88648 | 0.18025 | 1.19285 | 0.75617 |

Bootstrap summary dDBH (installation cluster, within source, B 400)

| fit | term | estimate | boot_se | lo95 | hi95 | se_log | n_ok | B |
|---|---|---|---|---|---|---|---|---|
| dDBH_L_NO | b0 | 0.28798 | 0.95407 | -1.79358 | 2.05051 | NA | 400 | 400 |
| dDBH_L_NO | b1 | 0.36076 | 0.11356 | 0.16890 | 0.61026 | NA | 400 | 400 |
| dDBH_L_NO | b2 | -0.02237 | 0.01810 | -0.06383 | 0.00455 | NA | 400 | 400 |
| dDBH_L_NO | b3 | -0.00145 | 0.00043105 | -0.00241 | -0.00081056 | NA | 400 | 400 |
| dDBH_L_NO | b4 | -0.33770 | 0.05033 | -0.45491 | -0.26207 | NA | 400 | 400 |
| dDBH_L_NO | b5 | 0.84118 | 0.47571 | 0.06609 | 1.84123 | NA | 400 | 400 |
| dDBH_L_NO | b6 | -0.01678 | 0.01740 | -0.04464 | 0.02221 | NA | 400 | 400 |
| dDBH_L_NO | b7 | -0.01770 | 0.00872 | -0.03582 | -0.00552 | NA | 400 | 400 |
| dDBH_L_NO | b8 | 0.14025 | 0.13816 | -0.16698 | 0.41713 | NA | 400 | 400 |
| dDBH_L_NO | b9 | -0.01590 | 0.32440 | -0.27373 | 0.95352 | NA | 400 | 400 |
| dDBH_L_NO | c_natural | 0.38370 | 0.07265 | 0.24264 | 0.53155 | 0.19339 | 400 | 400 |
| dDBH_L_NO | c_planted | 1.45753 | 0.13487 | 0.99678 | 1.53319 | 0.10799 | 400 | 400 |
| dDBH_L_NO | cal_natural | 0.25558 | 0.07498 | 0.14480 | 0.42738 | 0.27916 | 400 | 400 |
| dDBH_L_NO | cal_planted | 0.97085 | 0.12308 | 0.60938 | 1.13127 | 0.14755 | 400 | 400 |
| dDBH_L_NO | cf | 1.50128 | 0.16596 | 1.18881 | 1.79685 | 0.11198 | 400 | 400 |

Bootstrap summary dHT (installation cluster, within source, B 400)

| fit | term | estimate | boot_se | lo95 | hi95 | se_log | n_ok | B |
|---|---|---|---|---|---|---|---|---|
| dHT_L_NO | b0 | -2.37494 | 1.42944 | -7.88848 | -0.63329 | NA | 400 | 400 |
| dHT_L_NO | b1 | 1.16067 | 0.21911 | 0.79794 | 1.65661 | NA | 400 | 400 |
| dHT_L_NO | b2 | -0.15128 | 0.03396 | -0.22712 | -0.09789 | NA | 400 | 400 |
| dHT_L_NO | b3 | -0.00015779 | 0.00028161 | -0.00089863 | 0.00032313 | NA | 400 | 400 |
| dHT_L_NO | b4 | -0.18177 | 0.04414 | -0.26998 | -0.10181 | NA | 400 | 400 |
| dHT_L_NO | b5 | 0.21791 | 0.39394 | -0.49892 | 1.09289 | NA | 400 | 400 |
| dHT_L_NO | b6 | 0.06392 | 0.01968 | 0.02551 | 0.09992 | NA | 400 | 400 |
| dHT_L_NO | b7 | -0.11955 | 0.02266 | -0.17471 | -0.08426 | NA | 400 | 400 |
| dHT_L_NO | b8 | 0.09077 | 0.19056 | -0.14695 | 0.83437 | NA | 400 | 400 |
| dHT_L_NO | b9 | 0.75749 | 1.29757 | 0.03216 | 3.88719 | NA | 400 | 400 |
| dHT_L_NO | c_natural | 0.43617 | 0.46393 | 0.33469 | 1.70494 | 0.55809 | 400 | 400 |
| dHT_L_NO | c_planted | 2.88648 | 0.95432 | 1.02484 | 3.83997 | 0.49103 | 400 | 400 |
| dHT_L_NO | cal_natural | 0.18025 | 0.52992 | 0.09398 | 1.60793 | 0.97095 | 400 | 400 |
| dHT_L_NO | cal_planted | 1.19285 | 0.11329 | 0.88288 | 1.28013 | 0.10674 | 400 | 400 |
| dHT_L_NO | cf | 2.41982 | 0.83323 | 1.02839 | 3.72881 | 0.43041 | 400 | 400 |

### 5.7 Cohort BAL fraction (BAL_COHORT_LIN_B form)

| version | bal | n_plotyears | n_plots | a0 | a1 | se_a0_cluster | se_a1_cluster | r2 | mean_frac |
|---|---|---|---|---|---|---|---|---|---|
| refit2_repro | d | 410 | 118 | 0.5338 | -0.0675 | 0.0306 | 0.0120 | 0.0941 | 0.3549 |
| refit2_repro | l | 410 | 118 | 0.4978 | -0.0151 | 0.0280 | 0.0109 | 0.0091 | 0.4576 |
| refit2_repro | c | 410 | 118 | 0.7437 | -0.0509 | 0.0318 | 0.0123 | 0.0929 | 0.6087 |
| v103 | d | 406 | 119 | 0.5414 | -0.0743 | 0.0272 | 0.0112 | 0.1300 | 0.3442 |
| v103 | l | 406 | 119 | 0.4470 | 0.0003372 | 0.0226 | 0.0088 | 5.656e-06 | 0.4479 |
| v103 | c | 406 | 119 | 0.7077 | -0.0339 | 0.0215 | 0.0083 | 0.0707 | 0.6177 |

Under the selected live list definition the fraction is flat in QMD (a1 0.0003, SE 0.009, r2 0.00001), mean 0.448; the engine constant should be a0 0.44703, a1 0.00034 (or a constant 0.448).

## 6. What changes downstream

- The engine patch must switch the increment BAL input to the live list percentile (l) for both dDBH and dHT and use the vectors, CF and CAL of out/v103_constants.json; the conventional BAL (HiGy 0.4.0) path is not the deployed definition.
- CF_DHT is now the fitted value (not 1.030), as in refit2; the per step multipliers are c_natural and c_planted.
- HT_P moves (a0 28.93, a1 0.967, g1 0.0768); Table 3 and every height derived quantity move.
- HCB_P unchanged.
- Stage 1 and 2: tiny moves, patch the json and the HiGy.R mirror (the v102 parity deviation D2 still applies until HiGy.R is synchronised).
- GARCIA_ALLOM_A, GARCIA_ALLOM_K_HD and GARCIA_BETA_ANCHORED change; GARCIA_ALPHA stays.
- Eq. 5 stays v102 (v103 refit fails); Eq. 5a v103.
- Ingrowth moves negligibly.
- MORT_CAL (natural level) must be re-solved on the patched engine; it is not a Stage A1 output.
- Everything in Table 5, Table 8, the validation and the MC registry must be regenerated on the patched engine; nothing downstream of the constants was run here.
- The FIA subplot densities are now per subplot (x4); every FIA derived stand quantity (validation of FIA plots, the M1 H40 of FIA plots) moves with them.

## 7. Deviations and open items

- A1-D1 (increments): no candidate eligible; fallback deployed for both responses (above).
- A1-D2 (Eq. 5): v103 refit fails and is not deployed.
- A1-D3 (G2): 5 FIA subplot-years exceed the 100 m2/ha bound; kept (real single subplot expansions), flagged.
- A1-D4 (reproduction tolerance): the refit2 R1 gate reproduces to 5.7e-5 SE rather than 1e-6 absolute (CSV round trip).
- A1-D5 (beta anchor form): deployed on live koa stems; record form counted dead stems.
- The ingrowth frame and plot_intervals remain repaired copies of the record tables, not rebuilds (builders not on firebreather); Stage 1 sdi on 38 plot_intervals rows was scaled rather than recomputed.
- The engine simulates a koa only stand while the fitted BAPH and BAL are all species; for the single species sources (PSP, KMR PSP, Kualoa, Mauka) this is immaterial, for DOFAW, FIA and the mixed sources it is a known mismatch the engine patch should state.

## 8. Stage A1 close-out (Aaron's decisions of 30 September 2026)

Decision taken: deploy the v102 dDBH vector with origin constants re-solved on the v103 frame, as a stated deviation from the preregistered rule, provided it scores as reported under a BAL definition the engine can compute. The engine's percentile path runs on the live simulated list, so it computes the live list percentile (l); conventional BAL (c) is the other engine computable form. The dead inclusive percentile (d) is not engine computable. Script track2/inc/a1close_v103.R (md5 in RUN.md), seed 20260930.

The v102 vector of record scored on the v103 frames under each BAL definition, origin constants re-solved per frame (engine form recursion, HCB_P crown ratio under the same BAL). Eligibility as preregistered: signs, equivalence regions at most 0.25 on both frames, NO frame size max |obs/pred - 1| at most 0.25.

| resp | BAL | eq int CS | eq slope CS | eq int NO | eq slope NO | size max NO | worst class | RMSE CS | RMSE NO | c natural NO | c planted NO | eligible |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| dDBH | d | 0.1859 | 0.1356 | 0.1941 | 0.1492 | 0.184 | 40-60 | 1.3044 | 1.2937 | 0.6147 | 2.0011 | True |
| dDBH | l | 0.2113 | 0.1618 | 0.2141 | 0.1823 | 0.142 | 40-60 | 1.2743 | 1.2632 | 0.8203 | 2.1935 | True |
| dDBH | c | 0.2685 | 0.2137 | 0.2636 | 0.2213 | 0.107 | 30-40 | 1.2839 | 1.2719 | 0.9956 | 2.3896 | False |
| dHT | d | 0.3313 | 0.2283 | 0.3168 | 0.2376 | 0.631 | 20-30 | 1.1008 | 1.0826 | 0.5019 | 2.4500 | False |
| dHT | l | 0.3650 | 0.2741 | 0.3617 | 0.2976 | 0.746 | 20-30 | 1.1025 | 1.0841 | 0.5737 | 2.5352 | False |
| dHT | c | 0.4259 | 0.3266 | 0.4080 | 0.3157 | 0.707 | 20-30 | 1.1102 | 1.0915 | 0.6205 | 2.6237 | False |

Gate result: the v102 dDBH vector is eligible under the live list percentile (equivalence regions 0.211 and 0.162 CS, 0.214 and 0.182 NO; size max 0.142 at 40-60 cm) and not under conventional BAL (intercept regions above 0.25). It is therefore deployed under l, the same definition as dHT_L_NO, so both increments and HCB_P see one BAL. Its NO frame RMSE under l, 1.2632, is within 0.3 percent of the refit dDBH_L_NO (1.2607).
Reproduction of the section 5.6 benchmark under d: origin constants 0.6147 and 2.0011 and size max 0.184 reproduce exactly; the equivalence regions (0.1941, 0.1492 NO) differ from the reported 0.1811 and 0.1390 by about 0.01 because the 1,000 resample equivalence bootstrap draws from a different RNG stream in this run. That Monte Carlo spread (about 0.01 to 0.015) is the precision of every equivalence region in this report, and the l margins to 0.25 exceed it.

Deployed constants (NO frame, l):

| quantity | dDBH (v102 vector) | dHT (dHT_L_NO) |
|---|---|---|
| c natural | 0.82034 | 0.43617 |
| c planted | 2.19349 | 2.88648 |
| CF | 1.36869 (v102 fit, kept with the vector) | 2.41982 |
| CAL natural, planted | 0.59936, 1.60262 | 0.18025, 1.19285 |
| SE of log c (natural, planted), vector fixed, 400 installation resamples within source | 0.0296, 0.0538 | 0.1293, 0.0695 |
| SE of log c with the vector refit on every resample | not applicable (vector fixed by decision) | 0.5581, 0.4910 |
| c 95 percent bootstrap interval | natural 0.7806 to 0.8696; planted 1.9711 to 2.4325 | see section 5.6 bootstrap summary |

CAL_*_SE_LOG use the vector fixed definition for both responses, the definition the engine Monte Carlo applies to the origin multiplier alone (vector uncertainty enters through the joint draws). The full refit dHT values show that the natural dHT multiplier is weakly identified once the vector is free (95 percent interval of c natural 0.33 to 1.70); that is disclosed, not used as the engine SE.

Both bootstraps: the dDBH_L_NO coefficient bootstrap finished (400 of 400) and is kept as out/inc/boot_v103_dDBH_summary.csv for the candidate table; the v102 vector constants bootstrap is out/inc/boot_v103_dDBH_v102recal_summary.csv.

Deviations added: A1-D6, the deployed dDBH is not a preregistered candidate (Aaron's decision; full candidate table in section 5.6). A1-D1 now applies to dHT only. out/v103_constants.json carries deploy flags for every block; the A1 json is kept as out/v103_constants_A1_PREV_20260930.json.


### 8.1 Correction after Stage A2 (30 September 2026)

The statement above that the engine's percentile path "computes l" held only in the first projected year. The engine kept decayed records (expf floored at 1e-5) and ranked them unweighted, so the survivors' BAL fraction fell to 0.09 to 0.28 over long projections (red team A1A2 finding 1). The engine now ranks on expf (BAL_PERCENTILE_WEIGHTED = True, koa_equations.bal_percentile_fraction_weighted, mirrored in HiGy.R). The weighted form equals the frame definition l wherever expf is equal within a plot, which covers every source except the FIA microplot records (102 of 1,071 natural dDBH rows), so the gate table above and the deployed constants stand. MORT_CAL was re-solved on the patched engine, 2.46620 to 2.54275 (SE of log 0.24335, 24 intervals). Details, the switch-off gate and the rerun chain are in RUN.md (Stage A2) and a2/A2_REPORT.md.
