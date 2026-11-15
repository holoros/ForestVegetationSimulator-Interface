# 45_boot_round4.R  Plot-cluster bootstrap of the round-4 forms (section 8 of the PREREG note): the eligible candidates of script 44 other than B2 (whose
# 500 resamples are those of script 43) and the bounded form P1. For A1, A2 and J1 the plots of the height frame and of the increment frame are resampled
# together and stage 1 is repeated in every resample. Results are saved after every chunk. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_final_eq_20261110/scripts/42_height_increment_round3.R"); k <- grep("^fith <- ", L); eval(parse(text = L[5:(k + 3)]))
L4 <- readLines("~/jobs/koa_final_eq_20261110/scripts/44_height_increment_round4.R"); eval(parse(text = L4[(grep("definitions start", L4) + 1):(grep("definitions end", L4) - 1)]))
NB <- as.integer(Sys.getenv("KOA_NBOOT", "500")); RNGkind("L'Ecuyer-CMRG"); set.seed(20261145)
R <- readRDS("out/height_increment_44.rds"); FB <- union(setdiff(R$cand, "B2"), "P1"); cat("forms bootstrapped:", FB, "; resamples", NB, "; cores", NC, "\n")
plI <- split(seq_len(n), prs$pid); plH <- split(seq_len(nrow(hd)), hd$pid); U <- union(names(plI), names(plH)); nu <- length(U); cat("plots resampled (both frames):", nu, "; increment frame only:", length(plI), "\n")
idx <- lapply(seq_len(NB), function(b) sample.int(nu, nu, replace = TRUE)); OUT <- list()
for (FM in FB) { th0 <- unlist(R$FF[[FM]]$th); B <- NULL; CH <- split(seq_len(NB), ceiling(seq_len(NB) / (NC * 5))); cat("\n", FM, "\n")
  for (ch in CH) { r <- parallel::mclapply(ch, function(b) { u <- U[idx[[b]]]; ix <- unlist(plI[u], use.names = FALSE); hx <- unlist(plH[u], use.names = FALSE)
      ft <- tryCatch(fit_form(FM, ix, hx, unname(th0)), error = function(e) NULL); if (is.null(ft)) return(rep(NA_real_, length(th0) + 6))
      c(ft$th, q0 = if (is.null(ft$q)) NA else ft$q[1], q1 = if (is.null(ft$q)) NA else ft$q[2], A_nat = A_of(FM, ft, BYIM[[1]]), A_pl = A_of(FM, ft, BYIM[[2]]), delta = ft$delta, conv = ft$conv) }, mc.cores = NC)
    r <- r[vapply(r, is.numeric, TRUE)]; B <- rbind(B, do.call(rbind, r)); OUT[[FM]] <- B; saveRDS(OUT, "out/boot_round4_45.rds"); cat(format(Sys.time(), "%H:%M:%S"), "resamples done:", nrow(B), "\n") }
  ok <- !is.na(B[, "conv"]) & B[, "conv"] == 0; cat("completed", nrow(B), "; converged", sum(ok), "\n"); Bk <- B[ok, setdiff(colnames(B), c("delta", "conv")), drop = FALSE]; Bk <- Bk[, colSums(!is.na(Bk)) > 0, drop = FALSE]
  ft0 <- R$FF[[FM]]; est <- c(th0, if (!is.null(ft0$q)) c(q0 = ft0$q[1], q1 = ft0$q[2]), A_nat = A_of(FM, ft0, BYIM[[1]]), A_pl = A_of(FM, ft0, BYIM[[2]]))
  tb <- data.table(form = FM, par = colnames(Bk), est = est[colnames(Bk)], se = apply(Bk, 2, sd), lo = apply(Bk, 2, quantile, 0.025), hi = apply(Bk, 2, quantile, 0.975), share_pos = colMeans(Bk > 0)); print(tb[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 4) else v)]); OUT[[paste0(FM, "_table")]] <- tb }
saveRDS(OUT, "out/boot_round4_45.rds")
# choice: narrowest asymptote interval (upper over lower) at the median BYI of natural stands among the candidates; B2 from script 43
B43 <- readRDS("out/boot_round3_43.rds"); ok <- complete.cases(B43) & B43[, "conv"] == 0; a2 <- exp(B43[ok, 1] + B43[ok, 2] * log(BYIM[[1]]))
W <- rbind(data.table(form = "B2", lo = quantile(a2, 0.025), hi = quantile(a2, 0.975)), rbindlist(lapply(FB, function(FM) OUT[[paste0(FM, "_table")]][par == "A_nat", .(form, lo, hi)])))[, ratio := hi / lo]
W[, candidate := form %in% R$cand]; cat("\nasymptote at the median BYI of natural stands, 95% interval and upper over lower:\n"); print(W[, .(form, lo = round(lo, 2), hi = round(hi, 2), ratio = round(ratio, 3), candidate)])
pick <- if (any(W$candidate)) W[candidate == TRUE][order(ratio)]$form[1] else NA; cat("adopted:", if (is.na(pick)) "none (B2 stays only if it passed; see script 44)" else pick, "\n"); fwrite(W, "out/boot_round4_45_choice.csv"); cat("done\n")
