## 02c_fit.R <cand>: dDBH full-data fit through gr.hat3c, starts (a)/(b) per PREREG_K3c, signs, AIC, strata, LOSO with re-solved constants.
source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/lib_c.R"))
cand <- commandArgs(trailingOnly = TRUE)[1]; resp <- "dDBH"; M3 <- MODE[[cand]]
d <- frameK(resp, FRAMEOF[[cand]]); logm(cand, "mode", M3, "rows", nrow(d), "trees", length(unique(d$TreeID)), "installations", length(unique(paste(d$Data, d$Install))))
t0 <- Sys.time(); K0 <- readRDS(file.path(OB, "fit_K0.rds"))$dDBH; K3p <- readRDS(file.path(OB, "fit_K3p.rds"))$dDBH
if (cand %in% c("K0c", "K3pc")) { st <- if (cand == "K0c") START$dDBH else K3p$b; m <- fitS(resp, d, st); SL <- data.frame(start = cand, ok = !is.null(m), logLik = if (is.null(m)) NA else as.numeric(logLik(m))) } else {
  d0 <- frameK(resp, "K0"); sa <- K3p$b; sb <- rescale_start(resp, K0$b, d0, d)
  if (cand == "K3c2") { sa["b3"] <- 0; tl <- function(dd) sd(dd$BALx.0 / log(dd$DBH.0 + 5)); tq <- sd(d0$BALx.0^2 / log(d0$DBH.0 + 5)); sb["b3"] <- K0$b[["b3"]] * tq / tl(d) }
  ma <- fitS(resp, d, sa); mb <- fitS(resp, d, sb)
  la <- if (is.null(ma)) NA else as.numeric(logLik(ma)); lb <- if (is.null(mb)) NA else as.numeric(logLik(mb))
  SL <- data.frame(start = c("a_K3p", "b_K0rescaled"), ok = c(!is.null(ma), !is.null(mb)), logLik = c(la, lb))
  logm("  start a logLik", round(la, 4), "| start b logLik", round(lb, 4), "| start b vector", paste(sprintf("%s %.5g", names(sb), sb), collapse = " "))
  m <- if (is.na(la) && is.na(lb)) NULL else if (is.na(lb) || (!is.na(la) && la >= lb)) ma else mb }
if (is.null(m)) { logm("MAIN FIT FAILED"); saveRDS(list(ok = FALSE, starts = SL), file.path(OC, sprintf("fit_%s.rds", cand))); quit(save = "no") }
b <- fixef(m); s <- summary(m)$tTable; cc <- solve_cK(resp, d, b); sg <- SIGNc(b, cand)
logm("  done", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min; logLik", round(as.numeric(logLik(m)), 4), "AIC", round(AIC(m), 3), "df", attr(logLik(m), "df"),
     "; fixef", paste(sprintf("%s %.6f", names(b), b), collapse = " "), "; c", paste(round(cc, 4), collapse = " "), "; signs", paste(names(sg), sg, collapse = " "))
ST <- strata(resp, d, b, cc, cand); LO <- list()
for (ho in c("DOFAW", "FIA", "KMR PSP", "PSP")) { tr <- d[d$Data != ho, ]; te <- d[d$Data == ho, ]; t1 <- Sys.time(); mm <- fitS(resp, tr, b)
  row <- data.frame(cand = cand, resp = resp, heldout = ho, n_test = nrow(te), n_train = nrow(tr), ok = FALSE, rmse_log = NA, bias_log = NA, ratio = NA)
  if (!is.null(mm)) { b2 <- fixef(mm); c2 <- tryCatch(solve_cK(resp, tr, b2), error = function(e) NULL)
    if (!is.null(c2) && all(is.finite(c2))) { pr <- pa_pred(resp, te, b2) * c2[ifelse(te$Planted == 1, "planted", "natural")]
      if (all(is.finite(pr))) { lo <- log(te[[resp]] / te$YIP); lp <- log(pmax(pr, 1e-6) / te$YIP)
        row$ok <- TRUE; row$rmse_log <- rmse(lo, lp); row$bias_log <- mean(lp - lo); row$ratio <- sum(te[[resp]] / te$YIP) / sum(pr / te$YIP) } } }
  logm("  LOSO", ho, "ok", row$ok, "rmse_log", round(row$rmse_log, 6), "(", round(as.numeric(difftime(Sys.time(), t1, units = "mins")), 1), "min)"); LO[[ho]] <- row }
saveRDS(list(ok = TRUE, b = b, tTable = s, tau = taus(m), cc = cc, logLik = as.numeric(logLik(m)), aic = AIC(m), df = attr(logLik(m), "df"), n = nrow(d), sign = sg,
             loso = do.call(rbind, LO), strata = ST, starts = SL, mode = M3), file.path(OC, sprintf("fit_%s.rds", cand)))
logm("02c DONE", cand)
