## 03b_origin_lines.R  containment against origin-specific QR lines (natural trajectories vs Natural line,
## planted vs Planted line) with their cluster-bootstrap upper bands, and the ratio of each trajectory to the
## engine's own limiting line. Descriptive; not part of the pre-stated PASS/FAIL rule.
suppressPackageStartupMessages(library(data.table))
J <- path.expand("~/jobs"); O <- file.path(J, "koa_selfthin_qr_20260927/out")
R <- readRDS(file.path(O, "qr_results.rds")); TAB <- R$TAB; ENG <- R$ENG
BT <- fread(file.path(O, "bootstrap_coefs.csv")); d <- fread(file.path(O, "analysis_frame_DATA.csv"))
options(width = 250)
TR <- fread(file.path(J, "koa_v102_20260918/track3/derived/engine_v102_out_m1/trajectories.csv"))[rep == 0 & age <= 100]
TR <- TR[, .(source = "deployed", scenario, site, age, QMD, TPH)]
G <- fread(file.path(J, "koa_prereg_B_beta_20260926/out/GRID_trajectories.csv"))[year <= 100]
G <- G[arm == "C3_fitted", .(source = "C3_beta0.117", scenario = fifelse(origin == "nat", "Even-aged natural", "Even-aged planted"),
           site, age = year, QMD, TPH)]
T2 <- rbind(TR, G); T2[, oset := fifelse(grepl("planted", scenario), "Planted", "Natural")]
cat(sprintf("observed QMD range: Natural %.1f to %.1f cm (%.1f without Mauka); Planted %.1f to %.1f cm\n",
  d[Origin == "Natural", min(QMD)], d[Origin == "Natural", max(QMD)], d[Origin == "Natural" & Data != "Mauka", max(QMD)],
  d[Origin == "Planted", min(QMD)], d[Origin == "Planted", max(QMD)]))
out <- list()
for (ta in c(0.95, 0.99)) for (o in c("Natural", "Planted")) {
  p <- TAB[set == o & tau == ta]; bt <- BT[set == o & tau == ta]
  z <- T2[oset == o]; x <- log(z$QMD); lim <- exp(p$b0 + p$b1 * x)
  hi <- exp(sapply(x, function(v) quantile(bt$b0 + bt$b1 * v, .975)))
  z[, `:=`(ratio = TPH / lim, ratio_hi = TPH / hi, exN = TPH - lim)]
  out[[paste(ta, o)]] <- z[, { k <- which.max(ratio); .(line = paste(o, ta), frac_above = mean(ratio > 1), frac_above_upper = mean(ratio_hi > 1),
    max_ratio = ratio[k], max_exN = exN[k], age = age[k], QMD = QMD[k], TPH = TPH[k]) }, by = .(source, scenario, site)]
}
print(rbindlist(out)[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 3) else v)])
cat("\nratio of trajectories to the engine's own limiting line (max over 1 to 100):\n")
T2[, eng := fifelse(source == "deployed", exp(ENG[1, 1] + ENG[1, 2] * log(QMD)), exp(ENG[2, 1] + ENG[2, 2] * log(QMD)))]
print(T2[, { k <- which.max(TPH / eng); .(max_ratio_engine_line = round(TPH[k] / eng[k], 3), age = age[k], QMD = round(QMD[k], 1)) }, by = .(source, scenario, site)])
