# utils.R  shared helpers for the koa final equations run
suppressMessages({library(data.table)})
set.seed(20261110)

# Grouped 10-fold by installation, stratified by origin (A2). DOFAW installations are placed first so each lands in a different fold.
make_folds <- function(dt, k = 10, seed = 20261110) {
  inst <- unique(dt[, .(inst = paste(Data, Install), Data, planted)])[, .(planted = round(mean(planted)), dofaw = any(Data == "DOFAW")), by = inst]
  set.seed(seed)
  inst <- inst[order(-dofaw, planted, sample(.N))]
  inst[, fold := NA_integer_]
  for (p in c(0, 1)) { idx <- inst[planted == p, which = TRUE]; ord <- c(inst[idx][dofaw == TRUE, which = TRUE], inst[idx][dofaw == FALSE, which = TRUE])
    inst[idx[ord], fold := ((seq_along(ord) - 1 + if (p == 1) 5 else 0) %% k) + 1L] }
  inst[, .(inst, fold)]
}

# Bootstrap equivalence test of observed on predicted, plot-cluster resampling (principle 16)
equiv_boot <- function(obs, pred, cluster, region = 0.25, nboot = 2000, seed = 1) {
  set.seed(seed)
  d <- data.table(obs, pred, cluster); cl <- split(seq_len(nrow(d)), d$cluster); nm <- names(cl)
  fit1 <- function(ix) { m <- mean(d$obs[ix]); f <- lm(obs ~ pred, data = d[ix]); c(b0c = mean(d$obs[ix] - d$pred[ix]) / m, b1 = coef(f)[[2]]) }
  est <- fit1(seq_len(nrow(d)))
  bs <- t(replicate(nboot, fit1(unlist(cl[sample(nm, length(nm), TRUE)], use.names = FALSE))))
  ci_b0 <- quantile(bs[, 1], c(.05, .95), na.rm = TRUE); ci_b1 <- quantile(bs[, 2], c(.05, .95), na.rm = TRUE)
  # smallest passing region (two one-sided tests at alpha 0.05 via 90% interval)
  smin_b0 <- max(abs(ci_b0)); smin_b1 <- max(abs(ci_b1 - 1))
  data.table(n = nrow(d), clusters = length(nm), bias_rel = est[["b0c"]], b0_lo = ci_b0[[1]], b0_hi = ci_b0[[2]],
             slope = est[["b1"]], b1_lo = ci_b1[[1]], b1_hi = ci_b1[[2]],
             pass_int = smin_b0 <= region, pass_slope = smin_b1 <= region,
             min_region_int = smin_b0, min_region_slope = smin_b1)
}

metrics <- function(obs, pred) data.table(n = length(obs), bias = mean(obs - pred), mae = mean(abs(obs - pred)), rmse = sqrt(mean((obs - pred)^2)))
