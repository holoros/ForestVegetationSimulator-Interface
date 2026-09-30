## bal_recal.R (koa_bal_recal_20260929). Resolve the BAL definition question without refitting Eq. 4.
## Coefficients of the deployed Eq. 4 are held fixed. The origin multipliers k are recomputed exactly as the deployed ones
## (k = sum obs annual / sum (level-0 annual prediction x CFX) within origin) but with the prediction evaluated on
##   dep  : the fitting (deposited) BAL, reproduces the deployed constants (gate)
##   live : the engine / HiGy 0.4.1 live-list count-percentile BAL
##   conv : conventional BAL (expansion-weighted basal area of larger live trees), as FVS computes natively
## Reported: k with 2,000-draw installation-cluster percentile intervals, calibrated PA R2 and RMSE, and the obs/pred ratio
## overall, by origin and by quintile of live-list BAL (intervals conditional on coefficients). Seed 20260929.
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
OUT2 <- file.path(Sys.getenv("HOME"), "jobs/koa_bal_recal_20260929/out"); dir.create(OUT2, showWarnings = FALSE)
REF <- load_ref()
KDEP <- list(dDBH = c(natural = 0.40548, planted = 1.43606), dHT = c(natural = 0.51917, planted = 2.64739))
bootr <- function(num, den, cl, B = 2000) { ids <- unique(cl); sp <- split(seq_along(cl), cl)
  est <- sum(num) / sum(den); bs <- replicate(B, { i <- unlist(sp[sample(ids, replace = TRUE)], use.names = FALSE); sum(num[i]) / sum(den[i]) })
  c(est = est, lo = unname(quantile(bs, 0.025)), hi = unname(quantile(bs, 0.975))) }
K <- list(); RAT <- list()
for (resp in c("dDBH", "dHT")) {
  m0 <- REF[[resp]]; d <- prep(resp)
  b <- read.csv(file.path(OUT, sprintf("bal_%s.csv", resp))); stopifnot(all(b$TreeID == d$TreeID))
  pr <- function(bal0, bal1) { x <- d; x$BAL.0 <- bal0; x$BAL.1 <- bal1; predict(m0, newdata = x, level = 0) }
  for (v in c("dep", "live", "conv")) {
    p0 <- switch(v, dep = pr(d$BAL.0, d$BAL.1), live = pr(b$BALl.0, b$BALl.1), conv = pr(b$BALc.0, b$BALc.1))
    ok <- is.finite(p0)
    km <- kmult(d[ok, ], p0[ok], resp, B = 2000, seed = 20260929)
    K[[paste(resp, v)]] <- data.frame(resp = resp, bal = v, n = sum(ok), k_nat = km$k[["natural"]], lo_nat = km$lo[["natural"]], hi_nat = km$hi[["natural"]],
      k_plt = km$k[["planted"]], lo_plt = km$lo[["planted"]], hi_plt = km$hi[["planted"]], r2_cal = km$r2_cal, rmse_cal = km$rmse_cal)
    ## ratios: deployed k with this BAL, and recalibrated k with this BAL
    pa <- p0 / d$YIP * CFX[[resp]]
    pdep <- pa * KDEP[[resp]][d$org]; prec <- pa * km$k[d$org]
    q <- cut(b$BALl.0, unique(quantile(b$BALl.0, 0:5 / 5, na.rm = TRUE)), include.lowest = TRUE, labels = FALSE)
    grp <- list(all = rep("all", nrow(d)), origin = d$org, quintile = paste0("Q", q))
    for (g in names(grp)) for (lv in sort(unique(grp[[g]]))) { i <- which(grp[[g]] == lv & ok); cl <- d$InstID[i]
      a <- bootr(d$ann[i], pdep[i], cl); r <- bootr(d$ann[i], prec[i], cl)
      RAT[[paste(resp, v, g, lv)]] <- data.frame(resp = resp, bal = v, group = g, level = lv, n = length(i),
        obs_over_pred_deployedk = a[["est"]], lo_d = a[["lo"]], hi_d = a[["hi"]], obs_over_pred_recalk = r[["est"]], lo_r = r[["lo"]], hi_r = r[["hi"]]) }
    logm(resp, v, "k", round(km$k, 5), "r2", round(km$r2_cal, 4))
  }
}
K <- do.call(rbind, K); RAT <- do.call(rbind, RAT)
write.csv(K, file.path(OUT2, "k_by_bal.csv"), row.names = FALSE); write.csv(RAT, file.path(OUT2, "ratio_by_bal.csv"), row.names = FALSE)
options(width = 220); print(K, digits = 4); print(RAT[RAT$group != "quintile" | TRUE, ], digits = 3)
logm("BALRECAL DONE")
