# 43_boot_round3.R  Plot-cluster bootstrap of the form selected by script 42 (round 3; B2 if no round-3 form displaces it): whole plots resampled with
# replacement, the same estimator as the full fit (three passes of the variance power), warm start at the full-frame estimates.
# Results are saved after every chunk so the number of completed resamples is always known. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_final_eq_20261110/scripts/42_height_increment_round3.R"); k <- grep("^fith <- ", L); eval(parse(text = L[5:(k + 3)]))
NB <- as.integer(Sys.getenv("KOA_NBOOT", "500")); NC <- as.integer(Sys.getenv("KOA_CORES", "4")); RNGkind("L'Ecuyer-CMRG"); set.seed(20261143)
R <- readRDS("out/height_increment_42.rds"); FM <- if (is.na(R$pick)) "B2" else R$pick; cat("form bootstrapped:", FM, "\n"); th0 <- R$FH[[FM]]$th; print(round(th0, 5))
t0 <- Sys.time(); chk <- fith(FM, seq_len(n), th0); cat("refit from the estimates: max abs change", signif(max(abs(chk$th - th0)), 3), "; seconds", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "\n")
pl <- split(seq_len(n), prs$pid); np <- length(pl); cat("plots resampled:", np, "\n")
idx <- lapply(seq_len(NB), function(b) sample.int(np, np, replace = TRUE)); B <- NULL; CH <- split(seq_len(NB), ceiling(seq_len(NB) / (NC * 5)))
for (ch in CH) { r <- parallel::mclapply(ch, function(b) { ix <- unlist(pl[idx[[b]]], use.names = FALSE); f <- tryCatch(fith(FM, ix, th0), error = function(e) NULL); if (is.null(f)) rep(NA_real_, length(th0) + 2) else c(f$th, delta = f$delta, conv = f$conv) }, mc.cores = NC)
  r <- r[vapply(r, is.numeric, TRUE)]; B <- rbind(B, do.call(rbind, r)); saveRDS(B, "out/boot_round3_43.rds"); cat(format(Sys.time(), "%H:%M:%S"), "resamples done:", nrow(B), "\n") }
ok <- complete.cases(B) & B[, "conv"] == 0; cat("\ncompleted", nrow(B), "; converged", sum(ok), "\n"); Bk <- B[ok, seq_along(th0), drop = FALSE]
tab <- data.table(par = names(th0), est = th0, se = apply(Bk, 2, sd), lo = apply(Bk, 2, quantile, 0.025), hi = apply(Bk, 2, quantile, 0.975)); print(tab[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 4) else v)])
fwrite(tab, "out/boot_round3_43_table.csv"); cat("done\n")
