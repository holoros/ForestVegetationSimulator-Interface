# koa v104 A5 LOIO results (31 Oct 2026)

Full-chain leave-one-installation-out evaluation of the 17 plot-level benchmark plots. Preregistration: PREREG.md (written 14:21:48 ADT, before any fold was fit).
Error = projected minus observed at the final measurement (one comparison per plot; the validation script makes no per-measurement comparisons).
Intervals: 90 percent, installation-cluster bootstrap, 2,000 draws, seed 20261031 (same cluster draws for both frames of a group). Bias region = 25 percent of mean observed; slope region 0.75 to 1.25.
Published = Table C2 of a2/closeout/validation/tableC2_v104_plotlevel.csv (plot bootstrap, 5,000 draws, seed 20260917).

## Preregistered outcome (pooled 17 plots, primary)

| variable | in-sample bias | held-out bias | held-out 90% CI | region | decision |
|---|---|---|---|---|---|
| survival | 0.0434 | 0.0448 | -0.0200 to 0.0976 | +/- 0.1553 | **SUPPORTS** |
| QMD_cm | -1.2129 | -1.1176 | -2.3996 to 0.2192 | +/- 6.0899 | **SUPPORTS** |
| BA_m2ha | -1.2888 | -1.2194 | -6.7088 to 2.9042 | +/- 6.7708 | **SUPPORTS** |

## Table R1. Held-out vs in-sample, all groups

| group | variable | frame | n plots | n inst | mean obs | bias | RMSE | bias 90% CI | TOST bias | slope | slope 90% CI | TOST slope | decision | published bias CI (plot boot) | published slope CI |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| all | survival | in-sample v104 | 17 | 14 | 0.621 | 0.0434 | 0.1449 | -0.0201 to 0.0941 | pass | 0.969 | 0.819 to 1.091 | pass |  | -0.0103 to 0.1007 (pass) | 0.829 to 1.148 (pass) |
| all | survival | held-out LOIO | 17 | 14 | 0.621 | 0.0448 | 0.1452 | -0.0200 to 0.0976 | pass | 0.968 | 0.819 to 1.100 | pass | SUPPORTS |  |  |
| all | QMD_cm | in-sample v104 | 17 | 14 | 24.360 | -1.2129 | 3.0818 | -2.2792 to -0.2679 | pass | 0.851 | 0.601 to 1.172 | fail |  | -2.2730 to 0.0082 (pass) | 0.591 to 1.160 (fail) |
| all | QMD_cm | held-out LOIO | 17 | 14 | 24.360 | -1.1176 | 3.8029 | -2.3996 to 0.2192 | pass | 0.743 | 0.487 to 1.177 | fail | SUPPORTS |  |  |
| all | BA_m2ha | in-sample v104 | 17 | 14 | 27.083 | -1.2888 | 13.3495 | -6.6920 to 2.7314 | pass | 0.606 | -0.137 to 2.191 | fail |  | -6.3084 to 4.2577 (pass) | -0.129 to 2.315 (fail) |
| all | BA_m2ha | held-out LOIO | 17 | 14 | 27.083 | -1.2194 | 14.0613 | -6.7088 to 2.9042 | pass | 0.460 | -0.237 to 2.116 | fail | SUPPORTS |  |  |
| natural | survival | in-sample v104 | 6 | 4 | 0.333 | 0.0624 | 0.0992 | -0.0191 to 0.1047 | fail | 0.863 | -0.078 to 1.858 | fail |  | 0.0102 to 0.1145 (fail) | 0.342 to 0.979 (fail) |
| natural | survival | held-out LOIO | 6 | 4 | 0.333 | 0.0735 | 0.1226 | -0.0251 to 0.1247 | fail | 0.842 | -0.020 to 1.997 | fail | INCONCLUSIVE |  |  |
| natural | QMD_cm | in-sample v104 | 6 | 4 | 27.317 | -1.3134 | 1.7131 | -2.4056 to -0.7673 | pass | 1.253 | 0.672 to 1.646 | fail |  | -2.0427 to -0.5599 (pass) | 0.949 to 1.713 (fail) |
| natural | QMD_cm | held-out LOIO | 6 | 4 | 27.317 | -1.5497 | 2.0636 | -2.2067 to -1.2212 | pass | 0.984 | 0.008 to 1.066 | fail | SUPPORTS |  |  |
| natural | BA_m2ha | in-sample v104 | 6 | 4 | 25.068 | 0.6268 | 9.2290 | -10.2720 to 6.2932 | fail | 2.221 | -20.357 to 4.640 | fail |  | -5.8246 to 6.6030 (fail) | -0.268 to 5.316 (fail) |
| natural | BA_m2ha | held-out LOIO | 6 | 4 | 25.068 | 0.5946 | 10.1293 | -11.0871 to 6.6756 | fail | 0.685 | -5.744 to 4.237 | fail | INCONCLUSIVE |  |  |
| planted | survival | in-sample v104 | 11 | 11 | 0.778 | 0.0330 | 0.1645 | -0.0440 to 0.1120 | pass | 0.998 | -0.822 to 1.550 | fail |  | -0.0464 to 0.1131 (pass) | -0.828 to 1.572 (fail) |
| planted | survival | held-out LOIO | 11 | 11 | 0.778 | 0.0292 | 0.1562 | -0.0439 to 0.1039 | pass | 0.967 | -0.830 to 1.407 | fail | SUPPORTS |  |  |
| planted | QMD_cm | in-sample v104 | 11 | 11 | 22.747 | -1.1581 | 3.6163 | -2.7517 to 0.6214 | pass | 0.809 | 0.558 to 1.281 | fail |  | -2.7516 to 0.6664 (pass) | 0.554 to 1.283 (fail) |
| planted | QMD_cm | held-out LOIO | 11 | 11 | 22.747 | -0.8819 | 4.4752 | -2.8222 to 1.4729 | pass | 0.695 | 0.458 to 1.292 | fail | SUPPORTS |  |  |
| planted | BA_m2ha | in-sample v104 | 11 | 11 | 28.182 | -2.3337 | 15.1312 | -9.5333 to 5.6301 | fail | 0.553 | -0.234 to 2.288 | fail |  | -9.4554 to 5.4589 (fail) | -0.252 to 2.312 (fail) |
| planted | BA_m2ha | held-out LOIO | 11 | 11 | 28.182 | -2.2089 | 15.7988 | -9.6480 to 6.0641 | fail | 0.451 | -0.269 to 2.308 | fail | INCONCLUSIVE |  |  |

## Table R2. Fold constants (refit dDBH_L_NO, re-solved c, CF, natural level)

| fold | status | training rows | rows dropped | b8 (ln BYI) | CF | c natural | c planted | CAL natural | CAL planted | natural level | level intervals | plots scored |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| DOFAW\|Kulani | ok/ok | 4544 | 427 | 0.0317 | 1.3915 | 0.3641 | 1.0806 | 0.2617 | 0.7766 | 2.8687 | 18 | 2 |
| DOFAW\|Laupahoehoe | ok/ok | 4680 | 291 | 0.1904 | 1.3939 | 0.3410 | 1.1112 | 0.2447 | 0.7972 | 2.5645 | 18 | 1 |
| DOFAW\|Waiakea | ok/ok | 4789 | 182 | 0.2670 | 1.3327 | 0.3942 | 1.1117 | 0.2958 | 0.8341 | 2.3241 | 15 | 3 |
| DOFAW\|Waikamoi | ok/ok | 4820 | 151 | 0.1924 | 1.3712 | 0.3483 | 1.1414 | 0.2540 | 0.8324 | 2.3181 | 20 | 1 |
| PSP\|103 | ok/ok | 4810 | 161 | 0.1409 | 1.4964 | 0.3862 | 1.4595 | 0.2581 | 0.9753 | 2.5182 | 23 | 1 |
| PSP\|104 | ok/ok | 4767 | 204 | 0.1257 | 1.4970 | 0.3857 | 1.4306 | 0.2576 | 0.9556 | 2.5117 | 23 | 1 |
| PSP\|105 | ok/ok | 4827 | 144 | 0.1308 | 1.5012 | 0.3848 | 1.4770 | 0.2563 | 0.9839 | 2.5194 | 23 | 1 |
| PSP\|106 | ok/ok | 4823 | 148 | 0.1368 | 1.5059 | 0.3840 | 1.4531 | 0.2550 | 0.9650 | 2.5174 | 23 | 1 |
| PSP\|107 | ok/ok | 4872 | 99 | 0.1335 | 1.5018 | 0.3846 | 1.4668 | 0.2561 | 0.9767 | 2.5161 | 23 | 1 |
| PSP\|108 | ok/ok | 4819 | 152 | 0.1335 | 1.5061 | 0.3837 | 1.4747 | 0.2548 | 0.9791 | 2.5203 | 23 | 1 |
| PSP\|123 | ok/ok | 4953 | 18 | 0.1403 | 1.5078 | 0.3829 | 1.4555 | 0.2540 | 0.9653 | 2.5154 | 23 | 1 |
| PSP\|202 | ok/ok | 4816 | 155 | 0.1494 | 1.5136 | 0.3819 | 1.4793 | 0.2523 | 0.9773 | 2.5233 | 23 | 1 |
| PSP\|203 | ok/ok | 4815 | 156 | 0.1149 | 1.5440 | 0.3722 | 1.5037 | 0.2410 | 0.9739 | 2.5207 | 23 | 1 |
| PSP\|204 | ok/ok | 4828 | 143 | 0.1451 | 1.5112 | 0.3828 | 1.4667 | 0.2533 | 0.9706 | 2.5211 | 23 | 1 |

Failed folds: 0 of 14.

Fold-to-fold range (v104 of record: b8 0.1402549, c natural 0.3837, c planted 1.4575, CF 1.50128, level 2.51588; RUN.md / out/v104_constants.json):

- b8: 0.0317 to 0.2670 (min fold DOFAW|Kulani, max fold DOFAW|Waiakea)
- c_natural: 0.3410 to 0.3942 (min fold DOFAW|Laupahoehoe, max fold DOFAW|Waiakea)
- c_planted: 1.0806 to 1.5037 (min fold DOFAW|Kulani, max fold PSP|203)
- CF: 1.3327 to 1.5440 (min fold DOFAW|Waiakea, max fold PSP|203)
- mort_level: 2.3181 to 2.8687 (min fold DOFAW|Waikamoi, max fold DOFAW|Kulani)

## Table R3. Per-plot errors (projected minus observed)

| plot | origin | surv in | surv held-out | QMD in | QMD held-out | BA in | BA held-out |
|---|---|---|---|---|---|---|---|
| DOFAW\|Kulani\|12 | planted | 0.255 | 0.199 | 7.48 | 11.21 | 34.52 | 36.95 |
| DOFAW\|Kulani\|23 | natural | -0.029 | -0.043 | -2.72 | -2.09 | -13.74 | -15.85 |
| DOFAW\|Laupahoehoe\|41 | natural | -0.016 | -0.015 | -2.09 | -2.32 | -9.12 | -9.50 |
| DOFAW\|Waiakea\|11 | natural | 0.150 | 0.155 | 0.38 | 0.48 | 4.54 | 4.88 |
| DOFAW\|Waiakea\|14 | natural | 0.071 | 0.076 | -0.15 | -0.02 | 1.60 | 1.93 |
| DOFAW\|Waiakea\|24 | natural | 0.173 | 0.240 | -1.32 | -3.48 | 12.02 | 12.11 |
| DOFAW\|Waikamoi\|25 | natural | 0.025 | 0.028 | -1.98 | -1.86 | 8.46 | 10.00 |
| PSP\|103\|3 | planted | -0.057 | -0.055 | -1.58 | -1.69 | -6.69 | -6.88 |
| PSP\|104\|4 | planted | -0.134 | -0.126 | -6.38 | -6.74 | -30.96 | -31.61 |
| PSP\|105\|5 | planted | -0.003 | -0.003 | -2.88 | -2.89 | -7.97 | -8.00 |
| PSP\|106\|6 | planted | -0.183 | -0.180 | -1.43 | -1.55 | -10.04 | -10.24 |
| PSP\|107\|7 | planted | -0.127 | -0.126 | -2.77 | -2.86 | -8.83 | -8.96 |
| PSP\|108\|8 | planted | -0.077 | -0.076 | -0.31 | -0.34 | -3.52 | -3.58 |
| PSP\|123\|23 | planted | 0.310 | 0.310 | -4.84 | -4.89 | -0.67 | -0.70 |
| PSP\|202\|2 | planted | 0.177 | 0.176 | 1.31 | 1.34 | 8.29 | 8.38 |
| PSP\|203\|3 | planted | 0.036 | 0.036 | -0.10 | -0.04 | 0.47 | 0.63 |
| PSP\|204\|4 | planted | 0.166 | 0.166 | -1.24 | -1.25 | -0.26 | -0.28 |

## Sanity gate (gate_check.csv; max abs difference vs a2/closeout/validation/val_v104_plotlevel.csv over 18 units)

| run | column | max abs diff | pass (< 1e-3) |
|---|---|---|---|
| V104EXACT | obs_surv_w | 0.000e+00 | True |
| V104EXACT | pr_surv | 0.000e+00 | True |
| V104EXACT | obsQMD | 0.000e+00 | True |
| V104EXACT | prQMD | 0.000e+00 | True |
| V104EXACT | obsBAPH | 0.000e+00 | True |
| V104EXACT | prBAPH | 0.000e+00 | True |
| NONE | obs_surv_w | 0.000e+00 | True |
| NONE | pr_surv | 9.877e-06 | True |
| NONE | obsQMD | 0.000e+00 | True |
| NONE | prQMD | 6.139e-04 | True |
| NONE | obsBAPH | 0.000e+00 | True |
| NONE | prBAPH | 4.874e-04 | True |

V104EXACT = the pipeline (engine copy, patch, level re-solve, validation) with the v104 constants of record: exact reproduction, level re-solved 2.51588.
NONE = the pipeline with the dDBH refit on the full frame: fixed effects within 1.8e-4 of the vector of record (b0; b8 +2.5e-5), logLik -9587.67 (fits/fit_NONE.csv), level 2.51585, plot values within 6.2e-4.
