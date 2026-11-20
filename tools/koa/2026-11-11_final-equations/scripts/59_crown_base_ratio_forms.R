# Koa height to crown base: alternative forms with biologically expected signs.
# Frame: the 360 US Forest Service FIA koa trees with a measured crown (36 installations, 69 subplots),
# rebuilt from HI_TREE.csv with live-koa and all-species stand values per subplot visit.
# Form for every candidate: HCB = HT / (1 + exp(eta)). A larger eta gives a lower crown base (longer crown).
# Expected signs on eta: competition and density negative (crown base rises), dominance and taper positive.
# Rule (as for script 34): among forms whose fitted signs meet expectation, fewest terms within 2% of the
# lowest held-out RMSE (installations held out, 10 folds); then a 2,000-resample plot-cluster bootstrap.
args <- commandArgs(TRUE); frame <- args[1]; out <- args[2]; NB <- as.integer(if (length(args) > 2) args[3] else 2000)
d <- read.csv(frame)
sdimax <- exp(5.64535004933422 + 0.267708773204307 * log(d$BYI))                # S1, natural stands
d <- within(d, {
  lH <- log(HT); dh <- DBH / HT
  x <- BAL_k / pmax(BA_k, 1e-6) * SDI_k / sdimax                                     # competition of record (koa only)
  rbal_all <- BAL_all / pmax(BA_all, 1e-6)                                           # relative position, all species
  lba_all <- log(BA_all + 1); lba_k <- log(BA_k + 1)
  bal_all <- BAL_all; rh <- pmin(HT / HTmax, 1); lb <- log(BYI)
  rd_k <- SDI_k / sdimax
  lrain <- log(rain); elev_km <- ELEV * 0.3048 / 1000
  inst <- Install; pid <- paste(Install, Plot)
})
set.seed(20261120); ui <- sort(unique(d$inst)); fold <- setNames(sample(rep(1:10, length.out = length(ui))), ui); d$fold <- fold[d$inst]

# name = terms; sgn = expected sign of each term on eta (+1, -1, or 0 for free)
F <- list(
  C1   = list(t = "lH",                                   s = c(0)),
  C2   = list(t = c("lH", "dh"),                          s = c(0, 1)),
  C5   = list(t = c("lH", "x"),                           s = c(0, 0)),            # system of record, sign free
  K1   = list(t = c("lH", "lba_k"),                       s = c(0, -1)),
  K2   = list(t = c("lH", "rd_k"),                        s = c(0, -1)),
  A1   = list(t = c("lH", "lba_all"),                     s = c(0, -1)),
  A2   = list(t = c("lH", "bal_all"),                     s = c(0, -1)),
  A3   = list(t = c("lH", "rbal_all", "lba_all"),         s = c(0, -1, -1)),
  A4   = list(t = c("lH", "dh", "lba_all"),               s = c(0, 1, -1)),
  A5   = list(t = c("lH", "dh", "bal_all"),               s = c(0, 1, -1)),
  A6   = list(t = c("lH", "rh", "lba_all"),               s = c(0, 1, -1)),
  A7   = list(t = c("lH", "dh", "rbal_all", "lba_all"),   s = c(0, 1, -1, -1)),
  A8   = list(t = c("lH", "dh", "lba_all", "lb"),         s = c(0, 1, -1, 0)),
  H1   = list(t = c("lH", "dh", "rh", "lba_all"),         s = c(0, 1, 1, -1)),      # Hann (2005)-type: size, taper, dominance, density
  S1   = list(t = c("lH", "lba_all", "lrain"),            s = c(0, -1, 0)),         # density with rainfall held constant
  S2   = list(t = c("lH", "lba_all", "elev_km"),          s = c(0, -1, 0)),         # density with elevation held constant
  S3   = list(t = c("lH", "lba_all", "lrain", "elev_km"), s = c(0, -1, 0, 0))
)
pred <- function(b, dd, tm) dd$HT / (1 + exp(as.numeric(cbind(1, as.matrix(dd[, tm, drop = FALSE])) %*% b)))
fit <- function(dd, f) {
  lo <- c(-Inf, ifelse(f$s > 0, 0, -Inf)); hi <- c(Inf, ifelse(f$s < 0, 0, Inf))
  st <- c(1, rep(0, length(f$t)))
  o <- optim(st, function(b) sum((dd$HCB - pred(b, dd, f$t))^2), method = "L-BFGS-B", lower = lo, upper = hi,
             control = list(maxit = 5000, factr = 1e3))
  setNames(o$par, c("b0", f$t))
}
res <- do.call(rbind, lapply(names(F), function(nm) {
  f <- F[[nm]]; b <- fit(d, f)
  cv <- do.call(rbind, lapply(1:10, function(k) { bb <- fit(d[d$fold != k, ], f); te <- d[d$fold == k, ]; data.frame(obs = te$HCB, p = pred(bb, te, f$t), HT = te$HT) }))
  sl <- coef(lm(obs ~ p, cv))[2]
  onb <- any(abs(b[-1][f$s != 0]) < 1e-8)                                             # a constrained term sits on its bound
  data.frame(form = nm, k = length(b), terms = paste(f$t, collapse = "+"), coefs = paste(sprintf("%.4f", b), collapse = " "),
             rmse = sqrt(mean((cv$obs - cv$p)^2)), bias = mean(cv$obs - cv$p), slope = sl,
             r2 = 1 - sum((cv$obs - cv$p)^2) / sum((cv$obs - mean(cv$obs))^2),
             rmse_cr = sqrt(mean(((1 - cv$obs / cv$HT) - (1 - cv$p / cv$HT))^2)), at_bound = onb)
}))
res <- res[order(res$rmse), ]; print(res, row.names = FALSE)
F0 <- lapply(F, function(f) { f$s <- f$s * 0; f })
cat('\nunconstrained coefficients (same terms):\n'); for (nm in names(F0)) cat(sprintf('%-4s %s\n', nm, paste(sprintf('%s=%.4f', names(fit(d, F0[[nm]])), fit(d, F0[[nm]])), collapse = ' ')))
ok <- res[!res$at_bound & res$form != "C5", ]
pick <- ok[ok$rmse <= min(ok$rmse) * 1.02, ]; pick <- pick[order(pick$k, pick$rmse), ][1, ]
cat("\nrule among sign-consistent forms: fewest terms within 2% of the lowest held-out RMSE ->", pick$form, "\n")
f <- F[[pick$form]]; b0 <- fit(d, f); idx <- split(seq_len(nrow(d)), d$pid); set.seed(20261121)
BO <- t(replicate(NB, { ix <- unlist(idx[sample(names(idx), length(idx), TRUE)], use.names = FALSE); fit(d[ix, ], f) }))
if (nrow(BO) == 1) BO <- t(BO)
cat("\nplot-cluster bootstrap (", NB, "resamples) of", pick$form, "\n")
print(round(rbind(est = b0, se = apply(BO, 2, sd), lo = apply(BO, 2, quantile, .025), hi = apply(BO, 2, quantile, .975)), 4))
# behaviour: crown ratio across all-species basal area for a mid-size tree (DBH 30 cm, HT 15 m), BYI at the median
g <- data.frame(HT = 15, DBH = 30, lH = log(15), dh = 2, BA_all = c(5, 20, 40, 60), BAL_all = c(2, 8, 16, 24), BYI = median(d$BYI))
g <- within(g, { lba_all <- log(BA_all + 1); bal_all <- BAL_all; rbal_all <- BAL_all / BA_all; rh <- 0.8; lb <- log(BYI); x <- 0.3; lba_k <- lba_all; rd_k <- 0.4; lrain <- log(median(d$rain)); elev_km <- median(d$ELEV) * 0.3048 / 1000 })
cat("\ncrown ratio of a 30 cm, 15 m tree at all-species BA 5, 20, 40, 60 m2/ha:", round(1 - pred(b0, g, f$t) / g$HT, 3), "\n")
write.csv(res, file.path(out, "hcb_alt_forms_cv.csv"), row.names = FALSE)
write.csv(data.frame(term = names(b0), est = b0, se = apply(BO, 2, sd), lo = apply(BO, 2, quantile, .025), hi = apply(BO, 2, quantile, .975)),
          file.path(out, "hcb_alt_forms_pick.csv"), row.names = FALSE)
cat("done\n")
