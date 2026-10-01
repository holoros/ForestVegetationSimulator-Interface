# Koa v103 plot-level validation (A2 close-out, red team must-change item 2)

Bias is PREDICTED MINUS OBSERVED in every table and column (survival fraction, QMD cm, basal area m2/ha of the surviving initial cohort). survW: observed survival expf weighted (same definition as predicted). survCount: old count based observed survival, kept for the record. FIA units are whole plots (4 subplots pooled, x1 expansion), minimum 20 live koa records at the first measurement; FIA 15-1-1-2628 is the disturbance case and is excluded from every aggregate except its own row. in-sample: plots in the natural MORT_CAL calibration set (a2/mort/v103/H_mort_intervals_natural_mult.csv). The 'before' frames are the 23 unit files as deployed (FIA subplots, count survival), re-expressed pred minus obs.

### Table C1. Validation aggregates

| frame | group | n | survW_bias | survW_RMSE | survCount_bias | QMD_bias | QMD_RMSE | QMD_r | BA_bias | BA_RMSE | BA_r | mean_obsQMD | mean_obsBA |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| v103 plot level | all (excl. 2628) | 17 | 0.040 | 0.167 | 0.040 | -0.700 | 2.092 | 0.953 | -0.957 | 11.939 | 0.511 | 24.360 | 27.083 |
| v103 plot level | natural (excl. 2628) | 6 | 0.060 | 0.116 | 0.060 | -0.279 | 1.706 | 0.891 | 0.596 | 8.928 | 0.622 | 27.317 | 25.068 |
| v103 plot level | natural excl. in-sample | 0 | nan | nan | nan | nan | nan | nan | nan | nan | nan | nan | nan |
| v103 plot level | planted | 11 | 0.030 | 0.189 | 0.030 | -0.930 | 2.275 | 0.954 | -1.804 | 13.298 | 0.522 | 22.747 | 28.182 |
| v103 plot level | 2628 disturbance case | 1 | -0.112 | 0.112 | -0.184 | 9.795 | 9.795 | nan | -0.111 | 0.111 | nan | 22.271 | 25.754 |
| v102 plot level | all (excl. 2628) | 17 | 0.049 | 0.175 | 0.049 | -1.943 | 3.022 | 0.933 | -2.896 | 12.638 | 0.467 | 24.360 | 27.083 |
| v102 plot level | natural (excl. 2628) | 6 | 0.088 | 0.149 | 0.088 | -2.187 | 3.376 | 0.795 | -1.151 | 9.046 | 0.569 | 27.317 | 25.068 |
| v102 plot level | natural excl. in-sample | 0 | nan | nan | nan | nan | nan | nan | nan | nan | nan | nan | nan |
| v102 plot level | planted | 11 | 0.027 | 0.187 | 0.027 | -1.810 | 2.809 | 0.951 | -3.848 | 14.219 | 0.475 | 22.747 | 28.182 |
| v102 plot level | 2628 disturbance case | 1 | -0.097 | 0.097 | -0.169 | 7.975 | 7.975 | nan | 0.327 | 0.327 | nan | 22.271 | 25.754 |
| v103 before (a2/out/val_v103.csv) | all | 23 | nan | nan | -0.044 | 2.034 | 6.925 | 0.638 | -1.238 | 12.315 | 0.457 | 23.599 | 27.301 |
| v103 before (a2/out/val_v103.csv) | natural | 12 | nan | nan | -0.111 | 4.751 | 9.336 | 0.354 | -0.720 | 11.339 | 0.390 | 24.381 | 26.492 |
| v103 before (a2/out/val_v103.csv) | planted | 11 | nan | nan | 0.030 | -0.930 | 2.275 | 0.954 | -1.804 | 13.298 | 0.522 | 22.747 | 28.182 |
| v102 before (a2/out/val_gate.csv) | all | 23 | nan | nan | 0.116 | -1.668 | 2.936 | 0.911 | 0.305 | 12.432 | 0.550 | 23.599 | 21.845 |
| v102 before (a2/out/val_gate.csv) | natural | 12 | nan | nan | 0.198 | -1.539 | 3.047 | 0.817 | 4.113 | 10.531 | 0.578 | 24.381 | 16.036 |
| v102 before (a2/out/val_gate.csv) | planted | 11 | nan | nan | 0.027 | -1.810 | 2.809 | 0.951 | -3.848 | 14.219 | 0.475 | 22.747 | 28.182 |

### Table C1 sensitivity. FIA minimum record count 15 instead of 20

| frame | group | n | survW_bias | survW_RMSE | survCount_bias | QMD_bias | QMD_RMSE | QMD_r | BA_bias | BA_RMSE | BA_r | mean_obsQMD | mean_obsBA |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| v103 plot level, FIA min 15 (+2 plots) | natural (excl. 2628) | 8 | -0.000 | 0.138 | -0.000 | 0.752 | 2.519 | 0.898 | 1.051 | 7.908 | 0.701 | 24.623 | 22.258 |
| v103 plot level, FIA min 15 (+2 plots) | natural excl. in-sample | 2 | -0.181 | 0.187 | -0.181 | 3.846 | 4.081 | nan | 2.414 | 3.318 | nan | 16.542 | 13.827 |
| v102 plot level, FIA min 15 (+2 plots) | natural (excl. 2628) | 8 | 0.036 | 0.142 | 0.036 | -1.338 | 3.073 | 0.857 | -0.998 | 7.950 | 0.674 | 24.623 | 22.258 |
| v102 plot level, FIA min 15 (+2 plots) | natural excl. in-sample | 2 | -0.119 | 0.121 | -0.119 | 1.209 | 1.890 | nan | -0.539 | 2.708 | nan | 16.542 | 13.827 |

### Table C2. 25 percent equivalence (TOST): 90 percent plot bootstrap interval (5000 draws, seed 20260917) of mean predicted minus mean observed inside +/- 25 percent of mean observed, and slope of observed on predicted inside 0.75 to 1.25

| frame | group | quantity | n | mean_obs | bias_pred_minus_obs | bias_lo | bias_hi | region_bias | pass_bias | min_region_bias | slope | slope_lo | slope_hi | pass_slope | note |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| v103 plot level | all (excl. 2628) | surv (weighted) | 17 | 0.621 | 0.040 | -0.023 | 0.109 | 0.155 | True | 0.175 | 0.942 | 0.794 | 1.146 | True |  |
| v103 plot level | all (excl. 2628) | qmd | 17 | 24.360 | -0.700 | -1.511 | 0.081 | 6.090 | True | 0.062 | 0.898 | 0.755 | 1.000 | True |  |
| v103 plot level | all (excl. 2628) | ba | 17 | 27.083 | -0.957 | -5.456 | 3.933 | 6.771 | True | 0.201 | 0.883 | 0.113 | 2.043 | False |  |
| v103 plot level | natural (excl. 2628) | surv (weighted) | 6 | 0.333 | 0.060 | -0.006 | 0.128 | 0.083 | False | 0.384 | 0.844 | 0.238 | 0.996 | False |  |
| v103 plot level | natural (excl. 2628) | qmd | 6 | 27.317 | -0.279 | -1.666 | 0.638 | 6.829 | True | 0.061 | 0.719 | 0.106 | 1.104 | False |  |
| v103 plot level | natural (excl. 2628) | ba | 6 | 25.068 | 0.596 | -5.733 | 6.376 | 6.267 | False | 0.254 | 2.610 | -0.038 | 5.192 | False |  |
| v103 plot level | natural excl. in-sample | surv (weighted) | 0 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v103 plot level | natural excl. in-sample | qmd | 0 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v103 plot level | natural excl. in-sample | ba | 0 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v103 plot level | planted | surv (weighted) | 11 | 0.778 | 0.030 | -0.061 | 0.124 | 0.195 | True | 0.159 | 0.826 | -0.762 | 1.767 | False |  |
| v103 plot level | planted | qmd | 11 | 22.747 | -0.930 | -1.982 | 0.094 | 5.687 | True | 0.087 | 0.930 | 0.780 | 1.102 | True |  |
| v103 plot level | planted | ba | 11 | 28.182 | -1.804 | -8.141 | 5.016 | 7.046 | False | 0.289 | 0.817 | -0.005 | 1.956 | False |  |
| v103 plot level | 2628 disturbance case | surv (weighted) | 1 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v103 plot level | 2628 disturbance case | qmd | 1 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v103 plot level | 2628 disturbance case | ba | 1 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v102 plot level | all (excl. 2628) | surv (weighted) | 17 | 0.621 | 0.049 | -0.016 | 0.120 | 0.155 | True | 0.193 | 0.947 | 0.802 | 1.160 | True |  |
| v102 plot level | all (excl. 2628) | qmd | 17 | 24.360 | -1.943 | -2.905 | -1.045 | 6.090 | True | 0.119 | 0.893 | 0.699 | 1.037 | False |  |
| v102 plot level | all (excl. 2628) | ba | 17 | 27.083 | -2.896 | -7.568 | 2.161 | 6.771 | False | 0.279 | 0.806 | 0.037 | 2.090 | False |  |
| v102 plot level | natural (excl. 2628) | surv (weighted) | 6 | 0.333 | 0.088 | 0.010 | 0.171 | 0.083 | False | 0.513 | 0.802 | 0.204 | 0.960 | False |  |
| v102 plot level | natural (excl. 2628) | qmd | 6 | 27.317 | -2.187 | -4.083 | -0.606 | 6.829 | True | 0.149 | 0.558 | -0.099 | 1.328 | False |  |
| v102 plot level | natural (excl. 2628) | ba | 6 | 25.068 | -1.151 | -7.551 | 4.614 | 6.267 | False | 0.301 | 2.177 | 0.014 | 5.161 | False |  |
| v102 plot level | natural excl. in-sample | surv (weighted) | 0 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v102 plot level | natural excl. in-sample | qmd | 0 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v102 plot level | natural excl. in-sample | ba | 0 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v102 plot level | planted | surv (weighted) | 11 | 0.778 | 0.027 | -0.063 | 0.121 | 0.195 | True | 0.156 | 0.875 | -0.750 | 1.884 | False |  |
| v102 plot level | planted | qmd | 11 | 22.747 | -1.810 | -2.883 | -0.736 | 5.687 | True | 0.127 | 0.934 | 0.768 | 1.137 | True |  |
| v102 plot level | planted | ba | 11 | 28.182 | -3.848 | -10.414 | 3.307 | 7.046 | False | 0.370 | 0.745 | -0.074 | 2.052 | False |  |
| v102 plot level | 2628 disturbance case | surv (weighted) | 1 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v102 plot level | 2628 disturbance case | qmd | 1 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
| v102 plot level | 2628 disturbance case | ba | 1 |  |  |  |  |  |  |  |  |  |  |  | n < 3, not tested |
