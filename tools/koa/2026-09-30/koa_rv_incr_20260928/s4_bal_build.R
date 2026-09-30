## s4_bal_build.R (R1 c5). Recompute competition on the dDBH and dHT frames from the v102 tree table (AK_TREE_v102.csv).
## For every plot-year (Data, Install, Plot, Measure):
##  BALd  deposited rule, check only: (1 - BA.perc) x BAPH with BA.perc = (rank(DBH, "min") - 1) / (n - 1) over EVERY record
##  BALl  simulator tree-list rule: the same count percentile but over the LIVE list only (Status live, DBH > 0), x recorded BAPH
##        (koa_equations.stand_bal exact path, bal_percentile_fraction over the projected list)
##  BALc  conventional: basal area per ha of live trees strictly larger than the subject tree. Primary form is the expansion-weighted
##        basal-area share of the live list above the subject, times recorded BAPH (equal to the direct sum wherever the live list
##        rebuilds recorded BAPH; weights set to 1 in plot-years whose live EXPF are all zero). The direct sum BALc_sum is kept too.
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
T <- read.csv(file.path(IN, "AK_TREE_v102.csv"), stringsAsFactors = FALSE)
T$key <- paste(T$Data, T$Install, T$Plot, T$Measure, sep = "|"); T$tkey <- paste(T$key, T$Tree, sep = "|")
logm("tree rows", nrow(T), "unique tree-visit keys", length(unique(T$tkey)), "plot-years", length(unique(T$key)))
T$live <- T$Status == "live" & is.finite(T$DBH) & T$DBH > 0
T$BAd <- NA; T$BALl <- NA; T$BALc <- NA; T$BALc_sum <- NA; T$rebuild <- NA
for (g in split(seq_len(nrow(T)), T$key)) {
  x <- T[g, ]; n <- nrow(x)
  T$BAd[g] <- if (n > 1) (rank(x$DBH, ties.method = "min") - 1) / (n - 1) else 0
  L <- which(x$live); nL <- length(L)
  if (nL > 0) {
    dl <- x$DBH[L]; w <- x$EXPF[L]; w[!is.finite(w)] <- 0; wz <- all(w == 0); if (wz) w <- rep(1, nL)
    ba <- 0.00007854 * dl^2 * w
    larger <- sapply(dl, function(v) sum(ba[dl > v])); share <- larger / sum(ba)
    T$BALc[g[L]] <- share * x$BAPH[L]
    T$BALc_sum[g[L]] <- if (wz) NA else larger
    T$BALl[g[L]] <- (1 - (if (nL > 1) (rank(dl, ties.method = "min") - 1) / (nL - 1) else 0)) * x$BAPH[L]
    T$rebuild[g] <- if (wz) FALSE else abs(sum(ba) - x$BAPH[1]) <= 0.01 * max(x$BAPH[1], 1e-9)
  }
}
T$BALd <- (1 - T$BAd) * T$BAPH
logm("deposited BA.perc reproduced to 1e-6 on", round(mean(abs(T$BAd - T$BA.perc) < 1e-6, na.rm = TRUE) * 100, 1), "% of tree rows")
S <- list()
for (resp in c("dDBH", "dHT")) {
  d <- prep(resp)
  k0 <- paste(d$Data, d$Install, d$Plot, d$t.0, d$Tree, sep = "|"); k1 <- paste(d$Data, d$Install, d$Plot, d$t.1, d$Tree, sep = "|")
  i0 <- match(k0, T$tkey); i1 <- match(k1, T$tkey)
  logm(resp, "rows", nrow(d), "unmatched t0", sum(is.na(i0)), "t1", sum(is.na(i1)))
  out <- data.frame(TreeID = d$TreeID, t.0 = d$t.0, org = d$org, BAL.0 = d$BAL.0, BAL.1 = d$BAL.1, BAPH.0 = d$BAPH.0,
    BALd.0 = T$BALd[i0], BALl.0 = T$BALl[i0], BALl.1 = T$BALl[i1], BALc.0 = T$BALc[i0], BALc.1 = T$BALc[i1],
    BALcsum.0 = T$BALc_sum[i0], rebuild.0 = T$rebuild[i0])
  ## fall back to the frame's own value only where a key is missing (logged)
  for (v in c("BALl.0", "BALl.1", "BALc.0", "BALc.1")) { miss <- is.na(out[[v]]); if (any(miss)) logm(resp, v, "missing", sum(miss)) }
  write.csv(out, file.path(OUT, sprintf("bal_%s.csv", resp)), row.names = FALSE)
  S[[resp]] <- data.frame(resp = resp, n = nrow(out), check_BALd_eq_frame = mean(abs(out$BALd.0 - out$BAL.0) < 1e-6, na.rm = TRUE),
    mean_BAL_deposited = mean(out$BAL.0), mean_BAL_livelist = mean(out$BALl.0, na.rm = TRUE), mean_BAL_conv = mean(out$BALc.0, na.rm = TRUE),
    mean_BAL_conv_directsum = mean(out$BALcsum.0, na.rm = TRUE), share_rebuild = mean(out$rebuild.0, na.rm = TRUE),
    cor_dep_conv = cor(out$BAL.0, out$BALc.0, use = "complete"), cor_dep_live = cor(out$BAL.0, out$BALl.0, use = "complete"),
    mean_BAPH = mean(out$BAPH.0), mean_BAL_nat_dep = mean(out$BAL.0[out$org == "natural"]), mean_BAL_nat_conv = mean(out$BALc.0[out$org == "natural"], na.rm = TRUE),
    mean_BAL_pl_dep = mean(out$BAL.0[out$org == "planted"]), mean_BAL_pl_conv = mean(out$BALc.0[out$org == "planted"], na.rm = TRUE))
}
S <- do.call(rbind, S); print(t(S)); write.csv(S, file.path(OUT, "bal_summary.csv"), row.names = FALSE)
logm("BAL BUILD DONE")
