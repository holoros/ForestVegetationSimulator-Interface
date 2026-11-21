# 74_e2_site_terms_1150.R  koa 1.15.0: plot-cluster bootstrap (500 resamples, seed 20261121) of the five-parameter height curve
# HT = 1.37 + (a0 + a1 ln(BYI) + a2 planted)(1 - exp(-b DBH))^c on the E2 frame, for the a1 and a2 intervals of Table S13 row 9.
suppressMessages(library(data.table)); setwd("~/jobs/koa_1150_20261121")
f <- readRDS("frames/frames.rds"); hd <- copy(as.data.table(f$hd)); hd[, lbyi := log(BYI)]; hd[, pid := as.character(pid)]
f5 <- HT ~ 1.37 + (a0 + a1 * lbyi + a2 * planted) * (1 - exp(-b * DBH))^c; s5 <- list(a0 = 20, a1 = 0, a2 = 0, b = 0.04, c = 1)
m5 <- nls(f5, data = hd, start = s5, control = nls.control(maxiter = 500)); cat("E2 frame trees", nrow(hd), "plots", uniqueN(hd$pid), "\n"); print(summary(m5)$coefficients)
idx <- split(seq_len(nrow(hd)), hd$pid); pn <- names(idx); RNGkind("L'Ecuyer-CMRG"); set.seed(20261121)
bt <- do.call(rbind, parallel::mclapply(seq_len(500), function(i) { dd <- hd[unlist(idx[sample(pn, length(pn), TRUE)], use.names = FALSE)]
  tryCatch(coef(nls(f5, data = dd, start = as.list(coef(m5)), control = nls.control(maxiter = 200))), error = function(e) rep(NA_real_, 5)) }, mc.cores = 4))
cat("resamples converged:", sum(complete.cases(bt)), "of 500\n")
print(round(rbind(est = coef(m5), lo = apply(bt, 2, quantile, .025, na.rm = TRUE), hi = apply(bt, 2, quantile, .975, na.rm = TRUE)), 3))
cat("74 done\n")
