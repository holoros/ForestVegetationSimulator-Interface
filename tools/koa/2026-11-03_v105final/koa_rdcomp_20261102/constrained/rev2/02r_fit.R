## 02r_fit.R <cand>: K3c3 (full: starts a/b, signs, AIC, strata, LOSO) or P05/P5 (K3c2 boundary profile, main fit only).
source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/rev2/lib_r2.R"))
cand <- commandArgs(trailingOnly = TRUE)[1]; resp <- "dDBH"; SET(cand)
d <- frameK(resp, "K3p"); logm(cand, "M3", M3, "M6", M6, "B3FIX", B3FIX, "rows", nrow(d)); t0 <- Sys.time()
K3c1 <- readRDS(file.path(OC, "fit_K3c1.rds")); sa <- K3c1$b
if (cand == "K3c3") { sf <- sd(sqrt(d$BAPH.0 * d$DBH.0)) / sd(log(d$BAPH.0)); sa["b6"] <- K3c1$b[["b6"]] * sf; sb <- sa; sb["b6"] <- 0 } else sb <- NULL
ma <- fitS(resp, d, sa); mb <- if (is.null(sb)) NULL else fitS(resp, d, sb)
la <- if (is.null(ma)) NA else as.numeric(logLik(ma)); lb <- if (is.null(mb)) NA else as.numeric(logLik(mb))
logm("  start a logLik", round(la, 4), "| start b logLik", round(lb, 4))
m <- if (is.na(la) && is.na(lb)) NULL else if (is.na(lb) || (!is.na(la) && la >= lb)) ma else mb
if (is.null(m)) { logm("MAIN FIT FAILED"); saveRDS(list(ok = FALSE), file.path(OR, sprintf("fit_%s.rds", cand))); quit(save = "no") }
b <- fixef(m); cc <- solve_cK(resp, d, b); sg <- SIGN$dDBH(b)
logm("  done", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min; logLik", round(as.numeric(logLik(m)), 4), "AIC", round(AIC(m), 3), "df", attr(logLik(m), "df"),
     "; fixef", paste(sprintf("%s %.6f", names(b), b), collapse = " "), "; c", paste(round(cc, 4), collapse = " "), "; signs", paste(names(sg), sg, collapse = " "))
out <- list(ok = TRUE, b = b, tTable = summary(m)$tTable, cc = cc, logLik = as.numeric(logLik(m)), aic = AIC(m), df = attr(logLik(m), "df"), n = nrow(d), sign = sg,
            starts = data.frame(start = c("a", "b"), logLik = c(la, lb)), M3 = M3, M6 = M6, B3FIX = B3FIX)
if (cand == "K3c3") { out$strata <- strata(resp, d, b, cc, cand); LO <- list()
  for (ho in c("DOFAW", "FIA", "KMR PSP", "PSP")) { tr <- d[d$Data != ho, ]; te <- d[d$Data == ho, ]; mm <- fitS(resp, tr, b)
    row <- data.frame(cand = cand, resp = resp, heldout = ho, n_test = nrow(te), n_train = nrow(tr), ok = FALSE, rmse_log = NA, bias_log = NA, ratio = NA)
    if (!is.null(mm)) { b2 <- fixef(mm); c2 <- tryCatch(solve_cK(resp, tr, b2), error = function(e) NULL)
      if (!is.null(c2) && all(is.finite(c2))) { pr <- pa_pred(resp, te, b2) * c2[ifelse(te$Planted == 1, "planted", "natural")]
        if (all(is.finite(pr))) { lo <- log(te[[resp]] / te$YIP); lp <- log(pmax(pr, 1e-6) / te$YIP)
          row$ok <- TRUE; row$rmse_log <- rmse(lo, lp); row$bias_log <- mean(lp - lo); row$ratio <- sum(te[[resp]] / te$YIP) / sum(pr / te$YIP) } } }
    logm("  LOSO", ho, "ok", row$ok, "rmse_log", round(row$rmse_log, 6)); LO[[ho]] <- row }
  out$loso <- do.call(rbind, LO) }
saveRDS(out, file.path(OR, sprintf("fit_%s.rds", cand))); logm("02r DONE", cand)
