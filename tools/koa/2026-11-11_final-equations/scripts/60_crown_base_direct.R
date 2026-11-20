# Koa height to crown base fitted directly as a height (not through crown ratio).
# HCB = min(exp(eta), 0.98 HT), eta = b0 + b1 ln HT + further terms; least squares on HCB (m).
# Expected signs on eta: density and competition raise the crown base (+), taper DBH/HT and dominance lower it (-).
# Same frame (360 US Forest Service FIA koa trees), folds (10, installations held out) and rule as the crown ratio
# forms: among sign-consistent forms, fewest terms within 2% of the lowest held-out RMSE, then a plot-cluster bootstrap.
args <- commandArgs(TRUE); frame <- args[1]; out <- args[2]; NB <- as.integer(if (length(args) > 2) args[3] else 2000)
d <- read.csv(frame)
sdimax <- exp(5.64535004933422 + 0.267708773204307 * log(d$BYI))
d <- within(d, {
  lH <- log(HT); dh <- DBH / HT; lD <- log(DBH)
  lba_all <- log(BA_all + 1); lba_k <- log(BA_k + 1); bal_all <- BAL_all; bal_k <- BAL_k
  rbal_all <- BAL_all / pmax(BA_all, 1e-6); rh <- pmin(HT / HTmax, 1); lb <- log(BYI)
  x <- BAL_k / pmax(BA_k, 1e-6) * SDI_k / sdimax; rd_k <- SDI_k / sdimax
  lrain <- log(rain); elev_km <- ELEV * 0.3048 / 1000
  inst <- Install; pid <- paste(Install, Plot)
})
set.seed(20261120); ui <- sort(unique(d$inst)); fold <- setNames(sample(rep(1:10, length.out = length(ui))), ui); d$fold <- fold[d$inst]
F <- list(
  D0  = list(t = "lH",                              s = 0),
  D1  = list(t = c("lH", "lba_all"),                s = c(0, 1)),
  D2  = list(t = c("lH", "bal_all"),                s = c(0, 1)),
  D3  = list(t = c("lH", "lba_k"),                  s = c(0, 1)),
  D4  = list(t = c("lH", "bal_k"),                  s = c(0, 1)),
  D5  = list(t = c("lH", "x"),                      s = c(0, 1)),
  D6  = list(t = c("lH", "rd_k"),                   s = c(0, 1)),
  D7  = list(t = c("lH", "dh"),                     s = c(0, -1)),
  D8  = list(t = c("lH", "dh", "lba_all"),          s = c(0, -1, 1)),
  D9  = list(t = c("lH", "dh", "bal_all"),          s = c(0, -1, 1)),
  D10 = list(t = c("lH", "rh", "lba_all"),          s = c(0, -1, 1)),
  D11 = list(t = c("lH", "dh", "rbal_all", "lba_all"), s = c(0, -1, 1, 1)),
  D12 = list(t = c("lH", "lba_all", "lb"),          s = c(0, 1, 0)),
  D13 = list(t = c("lH", "lba_all", "lrain", "elev_km"), s = c(0, 1, 0, 0)),
  D14 = list(t = c("lH", "dh", "lba_all", "lb"),    s = c(0, -1, 1, 0))
)
pred <- function(b, dd, tm) pmin(exp(as.numeric(cbind(1, as.matrix(dd[, tm, drop = FALSE])) %*% b)), 0.98 * dd$HT)
fit <- function(dd, f) {
  lo <- c(-Inf, ifelse(f$s > 0, 0, -Inf)); hi <- c(Inf, ifelse(f$s < 0, 0, Inf))
  st <- c(log(mean(dd$HCB)) - log(mean(dd$HT)), 1, rep(0, length(f$t) - 1))
  o <- optim(st, function(b) sum((dd$HCB - pred(b, dd, f$t))^2), method = "L-BFGS-B", lower = lo, upper = hi, control = list(maxit = 5000, factr = 1e3))
  setNames(o$par, c("b0", f$t))
}
res <- do.call(rbind, lapply(names(F), function(nm) {
  f <- F[[nm]]; b <- fit(d, f)
  f0 <- f; f0$s <- f0$s * 0; bf <- fit(d, f0)
  cv <- do.call(rbind, lapply(1:10, function(k) { bb <- fit(d[d$fold != k, ], f); te <- d[d$fold == k, ]; data.frame(obs = te$HCB, p = pred(bb, te, f$t), HT = te$HT) }))
  data.frame(form = nm, k = length(b), terms = paste(f$t, collapse = "+"), coefs = paste(sprintf("%.4f", b), collapse = " "),
             free_coefs = paste(sprintf("%.4f", bf), collapse = " "),
             rmse = sqrt(mean((cv$obs - cv$p)^2)), bias = mean(cv$obs - cv$p), slope = unname(coef(lm(obs ~ p, cv))[2]),
             r2 = 1 - sum((cv$obs - cv$p)^2) / sum((cv$obs - mean(cv$obs))^2),
             at_bound = any(abs(b[-1][f$s != 0]) < 1e-8))
}))
res <- res[order(res$rmse), ]; print(res, row.names = FALSE)
ok <- res[!res$at_bound, ]; pick <- ok[ok$rmse <= min(ok$rmse) * 1.02, ]; pick <- pick[order(pick$k, pick$rmse), ][1, ]
cat("\nrule among sign-consistent forms: fewest terms within 2% of the lowest held-out RMSE ->", pick$form, "\n")
f <- F[[pick$form]]; b0 <- fit(d, f); idx <- split(seq_len(nrow(d)), d$pid); set.seed(20261121)
BO <- t(replicate(NB, { ix <- unlist(idx[sample(names(idx), length(idx), TRUE)], use.names = FALSE); fit(d[ix, ], f) })); if (nrow(BO) == 1) BO <- t(BO)
cat("\nplot-cluster bootstrap (", NB, "resamples) of", pick$form, "\n")
print(round(rbind(est = b0, se = apply(BO, 2, sd), lo = apply(BO, 2, quantile, .025), hi = apply(BO, 2, quantile, .975)), 4))
g <- data.frame(HT = 15, DBH = 30, BA_all = c(5, 20, 40, 60), BAL_all = c(2, 8, 16, 24), BYI = median(d$BYI))
g <- within(g, { lH <- log(HT); dh <- DBH / HT; lba_all <- log(BA_all + 1); bal_all <- BAL_all; rbal_all <- BAL_all / BA_all; rh <- 0.8; lb <- log(BYI)
  lba_k <- lba_all; bal_k <- BAL_all; x <- 0.3; rd_k <- 0.4; lrain <- log(median(d$rain)); elev_km <- median(d$ELEV) * 0.3048 / 1000 })
hc <- pred(b0, g, f$t); cat("\nHCB (m) and crown ratio of a 30 cm, 15 m tree at all-species BA 5, 20, 40, 60 m2/ha:", round(hc, 2), "|", round(1 - hc / 15, 3), "\n")
write.csv(res, file.path(out, "hcb_direct_forms_cv.csv"), row.names = FALSE)
write.csv(data.frame(term = names(b0), est = b0, se = apply(BO, 2, sd), lo = apply(BO, 2, quantile, .025), hi = apply(BO, 2, quantile, .975)),
          file.path(out, "hcb_direct_forms_pick.csv"), row.names = FALSE)
cat("done\n")
