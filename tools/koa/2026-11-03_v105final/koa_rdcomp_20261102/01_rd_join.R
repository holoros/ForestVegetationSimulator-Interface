## 01_rd_join.R: attach SDI and SDImax to the v105b NO model frames (read only), check that the joined BAPH equals the frame BAPH at t.0 and t.1.
suppressPackageStartupMessages(library(data.table))
W <- path.expand("~/jobs/koa_v105_20261102"); OB <- path.expand("~/jobs/koa_rdcomp_20261102/out")
S <- fread(file.path(OB, "stand_plotyear.csv"), colClasses = list(character = c("Install", "Plot")))
G <- fread(path.expand("~/jobs/koa_brms_sdimax_20261102/out/growth_plot_sdimax_lqmm.csv"), colClasses = list(character = c("Install", "Plot")))
cat("growth_plot_sdimax rows", nrow(G), "| fitted", sum(G$fitted), "| dup keys", sum(duplicated(G[, .(Data, Install, Plot)])), "\n"); print(G[, .N, by = .(Data, fitted)])
POP <- 923
for (resp in c("dDBH", "dHT")) {
  d <- fread(file.path(W, sprintf("frames/final/%s_NO_v103_model.csv", resp)), colClasses = list(character = c("Install", "Plot")))
  stopifnot(!any(tolower(names(d)) %in% c("lat", "lon", "long", "latitude", "longitude", "x", "y")))
  for (k in 0:1) { tk <- paste0("t.", k)
    m <- S[d, on = c("Data", "Install", "Plot", Measure = tk), .(BAPH, SDI_qmd, SDI_sum, TPH, QMD)]
    d[, (paste0(c("BAPHs", "SDI", "SDIsum", "TPH", "QMD"), ".", k)) := m] }
  cat(resp, "rows", nrow(d), "| SDI.0 NA", sum(is.na(d$SDI.0)), "SDI.1 NA", sum(is.na(d$SDI.1)),
      "| max|BAPH.0 - joined|", signif(max(abs(d$BAPH.0 - d$BAPHs.0), na.rm = TRUE), 3), "max|BAPH.1 - joined|", signif(max(abs(d$BAPH.1 - d$BAPHs.1), na.rm = TRUE), 3), "\n")
  g <- G[d, on = c("Data", "Install", "Plot"), .(SDImax, fitted)]
  d[, SDImax_plot := fifelse(!is.na(g$SDImax), g$SDImax, POP)]; d[, sdimax_src := fifelse(!is.na(g$SDImax), "plot", "population")]
  print(d[, .(rows = .N, plots = uniqueN(paste(Install, Plot)), plot_sdimax_rows = sum(sdimax_src == "plot")), by = Data])
  d[, RD.0 := SDI.0 / SDImax_plot][, RD.1 := SDI.1 / SDImax_plot][, RDp.0 := SDI.0 / POP][, RDp.1 := SDI.1 / POP]
  cat(" RD.0 (plot) quantiles", round(quantile(d$RD.0, c(0, .05, .5, .95, 1), na.rm = TRUE), 3), "| RDp.0", round(quantile(d$RDp.0, c(0, .05, .5, .95, 1), na.rm = TRUE), 3), "\n")
  cat(" cor(ln BAPH+1, RD.0)", round(cor(log(d$BAPH.0 + 1), d$RD.0, use = "complete"), 3), "cor(BAPH.0, RDp.0)", round(cor(d$BAPH.0, d$RDp.0, use = "complete"), 3), "\n")
}
