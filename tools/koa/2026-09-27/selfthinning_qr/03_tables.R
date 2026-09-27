## 03_tables.R  summaries for RESULT.md from the step 2 outputs (no refitting): boundary-defining
## installations, crossing points of engine and QR lines, relative closest approach, other sets/horizons.
suppressPackageStartupMessages(library(data.table))
J <- path.expand("~/jobs"); O <- file.path(J, "koa_selfthin_qr_20260927/out")
R <- readRDS(file.path(O, "qr_results.rds")); TAB <- R$TAB; ENG <- R$ENG; RES <- R$RES
options(width = 250)
d <- fread(file.path(O, "analysis_frame_DATA.csv")); d[, `:=`(x = log(QMD), y = log(N))]
cat("rank-inversion bounds reported by summary.rq as +-1.797693e308 are unbounded\n")
print(TAB[, .(set, tau, n, n_inst, b0 = round(b0, 4), b1 = round(b1, 4), b1_boot = sprintf("%.3f to %.3f", b1_lo, b1_hi),
  b0_boot = sprintf("%.3f to %.3f", b0_lo, b0_hi),
  b1_rank = sprintf("%s to %s", ifelse(abs(b1_rank_lo) > 1e300, "-Inf", sprintf("%.3f", b1_rank_lo)), ifelse(abs(b1_rank_hi) > 1e300, "Inf", sprintf("%.3f", b1_rank_hi))),
  b0_rank = sprintf("%s to %s", ifelse(abs(b0_rank_lo) > 1e300, "-Inf", sprintf("%.3f", b0_rank_lo)), ifelse(abs(b0_rank_hi) > 1e300, "Inf", sprintf("%.3f", b0_rank_hi))),
  n_above, n_on, p_b1_gt_reineke, p_b1_gt_engine, reineke_in_boot, engine_in_boot)])

cat("\nboundary-defining plot-measures (on or above each ALL line):\n")
for (ta in c(0.95, 0.99)) { p <- TAB[set == "ALL" & tau == ta]; r <- d$y - (p$b0 + p$b1 * d$x)
  s <- d[r >= -1e-9]; cat(sprintf("tau %.2f: %d plot-measures on/above, %d plots, %d installations; by source/origin:\n",
    ta, nrow(s), uniqueN(s$plot), uniqueN(s$inst)))
  print(s[, .(pm = .N, plots = uniqueN(plot), inst = uniqueN(inst), QMD = paste(round(range(QMD), 1), collapse = "-")), by = .(Data, Origin)]) }

cat("\nN of the lines at QMD 10, 25, 40, 60 cm:\n")
L <- rbind(TAB[set %in% c("ALL", "B1", "B2", "Natural", "Planted"), .(line = paste(set, tau), b0, b1)],
           data.table(line = rownames(ENG), b0 = ENG[, 1], b1 = ENG[, 2]))
for (q in c(10, 25, 40, 60)) L[, paste0("N_Q", q) := round(exp(b0 + b1 * log(q)), 0)]
print(L)
cat("\ncrossing QMD (cm) of engine-implied lines with the ALL QR lines:\n")
for (e in rownames(ENG)) for (ta in c(0.95, 0.99)) { p <- TAB[set == "ALL" & tau == ta]
  cat(sprintf("  %s vs ALL tau %.2f: QMD %.1f cm (engine line above the QR line below this QMD)\n", e, ta,
      exp((p$b0 - ENG[e, 1]) / (ENG[e, 2] - p$b1)))) }
cat("\nobserved plot-measures above the engine-implied lines:\n")
for (e in rownames(ENG)) { a <- d$y > ENG[e, 1] + ENG[e, 2] * d$x
  cat(sprintf("  %s: %d of %d (%.2f%%), %d installations\n", e, sum(a), nrow(d), 100 * mean(a), uniqueN(d$inst[a]))) }

cat("\nrelative closest approach to the ALL lines (max over trajectory of TPH / N_line), rep 0:\n")
TR <- fread(file.path(J, "koa_v102_20260918/track3/derived/engine_v102_out_m1/trajectories.csv"))[rep == 0 & age <= 100]
TR <- TR[, .(source = "deployed", scenario, site, age, QMD, TPH)]
G <- fread(file.path(J, "koa_prereg_B_beta_20260926/out/GRID_trajectories.csv"))
G <- G[, .(source = paste0("B_", arm), scenario = fifelse(origin == "nat", "Even-aged natural", "Even-aged planted"),
           site, age = year, QMD, TPH)]
T2 <- rbind(TR, G[source == "B_C3_fitted"])
cat("trajectory SDI NA check: deployed rows with NA QMD or TPH:", TR[is.na(QMD) | is.na(TPH), .N], "\n")
for (ta in c(0.95, 0.99)) { p <- TAB[set == "ALL" & tau == ta]
  z <- T2[, .(ratio = TPH / exp(p$b0 + p$b1 * log(QMD)), age, QMD, TPH), by = .(source, scenario, site, h = fifelse(age <= 100, "1-100", "101-200"))]
  cat(sprintf("tau %.2f\n", ta))
  print(z[, .SD[which.max(ratio)], by = .(source, scenario, site, h)][order(source, h, scenario, site),
        .(source, h, scenario, site, max_ratio = round(ratio, 3), age, QMD = round(QMD, 1), TPH = round(TPH, 1))]) }

cat("\nvariant B C3, years 1 to 200, ALL lines:\n")
print(RES[source == "variantB_C3_fitted" & set == "ALL", .(horizon, scenario, site, tau, frac_above = round(frac_above, 3),
  frac_above_upper = round(frac_above_upper, 3), max_exN = round(max_exN, 1), max_exSDI = round(max_exSDI, 1), age_at_max,
  to_upper = round(max_exN_to_upper, 1))])
cat("\nB1 and B2 lines, rep 0, 1 to 100 (deployed and C3):\n")
print(RES[set %in% c("B1", "B2") & horizon == "1-100" & source != "variantB_C5_anchored",
  .(set, tau, source, scenario, site, frac_above = round(frac_above, 3), frac_above_upper = round(frac_above_upper, 3),
    max_exN = round(max_exN, 1), max_exSDI = round(max_exSDI, 1), age_at_max, to_upper = round(max_exN_to_upper, 1))])
