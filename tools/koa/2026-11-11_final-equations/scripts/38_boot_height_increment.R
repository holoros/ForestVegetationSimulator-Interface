# 38_boot_height_increment.R  Plot-cluster bootstrap of the adopted height increment equation (B2 of script 33b): whole plots resampled with
# replacement, the same estimator as the full fit (three passes of the variance power), warm start at the full-frame estimates.
# Results are saved after every chunk so the number of completed resamples is always known. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_final_eq_20261110/scripts/33b_height_increment_round2.R"); eval(parse(text = L[5:34]))
NB <- as.integer(Sys.getenv("KOA_NBOOT", "500")); NC <- as.integer(Sys.getenv("KOA_CORES", "4")); RNGkind("L'Ecuyer-CMRG"); set.seed(20261138)
R <- readRDS("out/height_increment_33b.rds"); th0 <- R$FH$B2$th; print(round(th0, 5))
t0 <- Sys.time(); chk <- fith("B2", seq_len(n), th0); cat("refit from the estimates: max abs change", signif(max(abs(chk$th - th0)), 3), "; seconds", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "\n")
pl <- split(seq_len(n), prs$pid); np <- length(pl); cat("plots resampled:", np, "\n")
idx <- lapply(seq_len(NB), function(b) sample.int(np, np, replace = TRUE)); B <- NULL; CH <- split(seq_len(NB), ceiling(seq_len(NB) / (NC * 5)))
for (ch in CH) { r <- parallel::mclapply(ch, function(b) { ix <- unlist(pl[idx[[b]]], use.names = FALSE); f <- tryCatch(fith("B2", ix, th0), error = function(e) NULL); if (is.null(f)) rep(NA_real_, 8) else c(f$th, delta = f$delta, conv = f$conv) }, mc.cores = NC)
  r <- r[vapply(r, is.numeric, TRUE)]; B <- rbind(B, do.call(rbind, r)); saveRDS(B, "out/boot_B2_38.rds"); cat(format(Sys.time(), "%H:%M:%S"), "resamples done:", nrow(B), "\n") }
ok <- complete.cases(B) & B[, "conv"] == 0; cat("\ncompleted", nrow(B), "; converged", sum(ok), "\n"); Bk <- B[ok, 1:6]
tab <- data.table(par = names(th0), est = th0, se = apply(Bk, 2, sd), lo = apply(Bk, 2, quantile, 0.025), hi = apply(Bk, 2, quantile, 0.975)); print(tab[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 4) else v)])
asy <- function(b, byi) exp(b[1] + b[2] * log(byi)); bq <- quantile(prs[!duplicated(pid), BYI], c(0.1, 0.5, 0.9)); cat("BYI at the 10th, 50th, 90th percentile of the plots in the frame:", round(bq, 1), "\n")
for (q in bq) cat("asymptote (m) at BYI", round(q, 1), ":", round(asy(th0, q), 1), " 95% interval", round(quantile(apply(Bk, 1, asy, byi = q), c(0.025, 0.975)), 1), "\n")
cat("rate multiplier for planted stands exp(k_pl):", round(exp(th0[6]), 2), " 95% interval", round(quantile(exp(Bk[, 6]), c(0.025, 0.975)), 2), "\n"); fwrite(tab, "out/boot_B2_38_table.csv"); cat("done\n")
