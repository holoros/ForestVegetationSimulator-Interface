## respec_v104.R (A4): respecifications of the deployed L_NO increment fits for S3.2 "Respecifications" sentence:
## (i) without ln(CR) (b5 fixed at 0), (ii) without the tree random intercept, (iii) residual variance proportional to interval length (varFixed(~YIP)) in place of varPower on size.
suppressPackageStartupMessages(library(nlme)); set.seed(20261030)
src <- readLines(path.expand("~/jobs/koa_v104_20261030/track2/inc/inc_v103.R")); commandArgs <- function(trailingOnly = TRUE) "none"; eval(parse(text = src[1:112]))
load(file.path(OUT, "fits_v103.rda")); OUTX <- file.path(W, "a4/inc/out")
res <- list()
for (resp in c("dDBH", "dHT")) { GUARD <- if (resp == "dDBH") 45 else 20; ref <- paste0(resp, "_L_NO"); m0 <- FITS[[ref]]
  d <- model_cols(read.csv(file.path(FRD, sprintf("%s_NO_v103_model.csv", resp)), stringsAsFactors = FALSE), "l"); st <- fixef(m0); size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
  # (i) no ln(CR): b5 fixed at 0 via a wrapper
  gr.hat3n <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b6, b7, b8, b9) gr.hat3(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, 0, b6, b7, b8, b9)
  fn <- as.formula(sprintf("%s ~ gr.hat3n(d1 = %s, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b6, b7, b8, b9)", resp, size))
  t0 <- Sys.time(); m1 <- tryCatch(nlme(fn, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install/TreeID, start = st[c("b0","b1","b2","b3","b4","b6","b7","b8","b9")], weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) NULL)
  logm(resp, "no lnCR", if (is.null(m1)) "FAILED" else sprintf("AIC %.1f vs %.1f (diff %.1f); b9 %.3f SE %.3f; max |dcoef|/SE %.2f", AIC(m1), AIC(m0), AIC(m1) - AIC(m0), fixef(m1)[["b9"]], sqrt(vcov(m1)["b9","b9"]), max(abs(fixef(m1) - st[names(fixef(m1))]) / sqrt(diag(vcov(m0)))[names(fixef(m1))])), round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min")
  # (ii) no tree intercept
  t0 <- Sys.time(); m2 <- tryCatch(nlme(f3, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install, start = st, weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) NULL)
  logm(resp, "no tree intercept", if (is.null(m2)) "FAILED" else sprintf("AIC %.1f vs %.1f (diff %.1f); tau %s", AIC(m2), AIC(m0), AIC(m2) - AIC(m0), paste(sprintf("%.4f", taus(m2)), collapse = " ")), round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min")
  # (iii) residual variance proportional to YIP
  t0 <- Sys.time(); m3 <- tryCatch(nlme(f3, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install/TreeID, start = st, weights = varFixed(~YIP), control = ctl), error = function(e) NULL)
  logm(resp, "var prop YIP", if (is.null(m3)) "FAILED" else sprintf("AIC %.1f vs %.1f (diff %.1f)", AIC(m3), AIC(m0), AIC(m3) - AIC(m0)), round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min")
  res[[resp]] <- data.frame(resp = resp, aic_ref = AIC(m0), aic_no_lncr = if (is.null(m1)) NA else AIC(m1), b9_no_lncr = if (is.null(m1)) NA else fixef(m1)[["b9"]], b9_se_no_lncr = if (is.null(m1)) NA else sqrt(vcov(m1)["b9","b9"]),
    max_shift_se_no_lncr = if (is.null(m1)) NA else max(abs(fixef(m1) - st[names(fixef(m1))]) / sqrt(diag(vcov(m0)))[names(fixef(m1))]), aic_no_tree = if (is.null(m2)) NA else AIC(m2), tau_no_tree = if (is.null(m2)) NA else paste(sprintf("%.4f", taus(m2)), collapse = ";"), aic_var_yip = if (is.null(m3)) NA else AIC(m3))
  write.csv(do.call(rbind, res), file.path(OUTX, "respec_v104.csv"), row.names = FALSE) }
logm("RESPEC DONE")
