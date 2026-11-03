## 02_fit.R <cand>: full-data fit (both responses), starts (a)/(b), signs, AIC, strata, LOSO with re-solved constants.
source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R"))
cand <- commandArgs(trailingOnly = TRUE)[1]; RES <- list()
for (resp in c("dDBH", "dHT")) { GUARD <- if (resp == "dDBH") 45 else 20
  d <- frameK(resp, cand); logm(cand, resp, "rows", nrow(d), "trees", length(unique(d$TreeID)), "installations", length(unique(paste(d$Data, d$Install))))
  t0 <- Sys.time()
  if (cand == "K0") { m <- fitS(resp, d, START[[resp]]); SL <- data.frame(start = "START", ok = !is.null(m), logLik = if (is.null(m)) NA else as.numeric(logLik(m))) } else {
    K0 <- readRDS(file.path(OB, "fit_K0.rds"))[[resp]]; d0 <- frameK(resp, "K0")
    sa <- rescale_start(resp, K0$b, d0, d); ma <- fitS(resp, d, sa); mb <- fitS(resp, d, K0$b)
    la <- if (is.null(ma)) NA else as.numeric(logLik(ma)); lb <- if (is.null(mb)) NA else as.numeric(logLik(mb))
    SL <- data.frame(start = c("a_rescaled", "b_K0vector"), ok = c(!is.null(ma), !is.null(mb)), logLik = c(la, lb))
    logm("  start a logLik", round(la, 3), "| start b logLik", round(lb, 3))
    m <- if (is.na(la) && is.na(lb)) NULL else if (is.na(lb) || (!is.na(la) && la >= lb)) ma else mb }
  if (is.null(m)) { logm("  MAIN FIT FAILED"); RES[[resp]] <- list(ok = FALSE, starts = SL); next }
  b <- fixef(m); s <- summary(m)$tTable; cc <- solve_cK(resp, d, b); sg <- SIGN[[resp]](b)
  logm("  done", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min; logLik", round(as.numeric(logLik(m)), 3), "AIC", round(AIC(m), 2),
       "; fixef", paste(sprintf("%s %.6f", names(b), b), collapse = " "), "; c", paste(round(cc, 4), collapse = " "), "; signs", paste(names(sg), sg, collapse = " "))
  ST <- strata(resp, d, b, cc, cand)
  LO <- list()
  for (ho in c("DOFAW", "FIA", "KMR PSP", "PSP")) { tr <- d[d$Data != ho, ]; te <- d[d$Data == ho, ]; t1 <- Sys.time(); mm <- fitS(resp, tr, b)
    row <- data.frame(cand = cand, resp = resp, heldout = ho, n_test = nrow(te), n_train = nrow(tr), ok = FALSE, rmse_log = NA, bias_log = NA, ratio = NA)
    if (!is.null(mm)) { b2 <- fixef(mm); c2 <- tryCatch(solve_cK(resp, tr, b2), error = function(e) NULL)
      if (!is.null(c2) && all(is.finite(c2))) { pr <- pa_pred(resp, te, b2) * c2[ifelse(te$Planted == 1, "planted", "natural")]
        if (all(is.finite(pr))) { lo <- log(te[[resp]] / te$YIP); lp <- log(pmax(pr, 1e-6) / te$YIP)
          row$ok <- TRUE; row$rmse_log <- rmse(lo, lp); row$bias_log <- mean(lp - lo); row$ratio <- sum(te[[resp]] / te$YIP) / sum(pr / te$YIP) } } }
    logm("  LOSO", ho, "ok", row$ok, "rmse_log", round(row$rmse_log, 4), "(", round(as.numeric(difftime(Sys.time(), t1, units = "mins")), 1), "min)"); LO[[ho]] <- row }
  RES[[resp]] <- list(ok = TRUE, b = b, tTable = s, tau = taus(m), cc = cc, logLik = as.numeric(logLik(m)), aic = AIC(m), n = nrow(d), sign = sg, loso = do.call(rbind, LO),
                      strata = ST, starts = SL, rows = d$rowid)
  saveRDS(RES, file.path(OB, sprintf("fit_%s.rds", cand))) }
saveRDS(RES, file.path(OB, sprintf("fit_%s.rds", cand))); logm("02 DONE", cand)
