## s32_sens_v104.R (A4): S3.2 sensitivities on the deployed L_NO fits. (a) restoring non-positive increments: constants re-solved and refit;
## (b) data source as a fixed intercept; (d) KMR PSP protocol switch residual; (e) is read from the joint draws by the report.
suppressPackageStartupMessages(library(nlme)); set.seed(20261030)
src <- readLines(path.expand("~/jobs/koa_v104_20261030/track2/inc/inc_v103.R")); commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112])); load(file.path(OUT, "fits_v103.rda")); OUTX <- file.path(W, "a4/inc/out"); R <- list()
## (a) frames with non-positive increments restored: rebuild NO0 (inc_v103 lines 148 to 179) and relax the sign screen
eval(parse(text = src[148:179]))
selA <- with(NO0, DBH.0 > 0 & DBH.1 > 0 & YIP > 0 & dDBH.ann < 10)
NOA <- list(dDBH = NO0[which(selA), ]); NOA$dHT <- NOA$dDBH[which(with(NOA$dDBH, HT.0 > 0 & dHT.ann < 10)), ]
for (resp in c("dDBH", "dHT")) { GUARD <- if (resp == "dDBH") 45 else 20; ref <- paste0(resp, "_L_NO"); m0 <- FITS[[ref]]; b <- fixef(m0); cf <- CAL[[ref]]$cf
  d <- NOA[[resp]]; d$frame <- "NO"; d$icls <- cut(d$YIP, c(0, 2, 5, 10, 20, 100), labels = c("1-2", "3-5", "6-10", "11-20", "21+"))
  e <- add_cr(d, d$BALl.0, d$BALl.1); d$CRl.0 <- e$CR.0; d$CRl.1 <- e$CR.1; d <- model_cols(d, "l")
  cc <- solve_c(resp, d, b); logm(resp, "restored frame rows", nrow(d), "(screened", nrow(model_cols(read.csv(file.path(FRD, sprintf("%s_NO_v103_model.csv", resp))), "l")), ") constants", round(cc, 4), "multipliers", round(cc / cf, 3))
  R[[paste(resp, "restored")]] <- data.frame(resp = resp, item = "restored_nonpositive", n = nrow(d), c_nat = cc[["natural"]], c_pl = cc[["planted"]], cal_nat = cc[["natural"]] / cf, cal_pl = cc[["planted"]] / cf, b9 = NA, b9_se = NA, aic = NA, aic_ref = AIC(m0))
  t0 <- Sys.time(); m1 <- tryCatch(fit_one(resp, d, "NO", start = b), error = function(e) { logm("  refit FAILED", conditionMessage(e)); NULL })
  if (!is.null(m1)) { R[[paste(resp, "restored_refit")]] <- data.frame(resp = resp, item = "restored_refit", n = nrow(d), c_nat = NA, c_pl = NA, cal_nat = NA, cal_pl = NA, b9 = fixef(m1)[["b9"]], b9_se = sqrt(vcov(m1)["b9", "b9"]), aic = AIC(m1), aic_ref = NA)
    logm(resp, "restored refit b9", round(fixef(m1)[["b9"]], 3), "SE", round(sqrt(vcov(m1)["b9", "b9"]), 3), round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min") }
  write.csv(do.call(rbind, R), file.path(OUTX, "s32_sens_v104.csv"), row.names = FALSE) }
## (b) data source as a fixed intercept (random intercepts on installation within source and tree)
for (resp in c("dDBH", "dHT")) { GUARD <- if (resp == "dDBH") 45 else 20; ref <- paste0(resp, "_L_NO"); m0 <- FITS[[ref]]; b <- fixef(m0)
  d <- model_cols(read.csv(file.path(FRD, sprintf("%s_NO_v103_model.csv", resp)), stringsAsFactors = FALSE), "l"); d$Data <- factor(d$Data); size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size))
  st <- c(b[["b0"]], rep(0, nlevels(d$Data) - 1), b[-1])
  t0 <- Sys.time(); m2 <- tryCatch(nlme(f3, data = d, fixed = list(b0 ~ Data, b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1), random = b0 ~ 1 | Install/TreeID, groups = ~ Install/TreeID, start = st, weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) { logm("  fixed source FAILED", conditionMessage(e)); NULL })
  if (!is.null(m2)) { fe <- fixef(m2); logm(resp, "fixed source intercept AIC", round(AIC(m2), 1), "vs", round(AIC(m0), 1), "diff", round(AIC(m2) - AIC(m0), 1), "b9", round(fe[["b9"]], 3), "SE", round(sqrt(vcov(m2)["b9", "b9"]), 3), "P", signif(2 * pnorm(-abs(fe[["b9"]] / sqrt(vcov(m2)["b9", "b9"]))), 3), round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min")
    R[[paste(resp, "fixed_source")]] <- data.frame(resp = resp, item = "fixed_source_intercept", n = nrow(d), c_nat = NA, c_pl = NA, cal_nat = NA, cal_pl = NA, b9 = fe[["b9"]], b9_se = sqrt(vcov(m2)["b9", "b9"]), aic = AIC(m2), aic_ref = AIC(m0)) }
  write.csv(do.call(rbind, R), file.path(OUTX, "s32_sens_v104.csv"), row.names = FALSE) }
## (d) KMR PSP protocol switch: mean log residual ln(obs / calibrated prediction) of KMR PSP diameter intervals ending by 2022 against those ending in 2023 or later; network offset = difference of mean log residual between PSP and DOFAW planted records
GUARD <- 45; ref <- "dDBH_L_NO"; b <- fixef(FITS[[ref]]); cc <- CAL[[ref]]$cc
d <- model_cols(read.csv(file.path(FRD, "dDBH_NO_v103_model.csv"), stringsAsFactors = FALSE), "l")
pr <- pa_pred("dDBH", d, b) * cc[ifelse(d$Planted == 1, "planted", "natural")]; d$lres <- log(d$dDBH / pmax(pr, 1e-6))
k <- d[d$Data == "KMR PSP", ]; a1 <- mean(k$lres[k$t.1 <= 2022]); a2 <- mean(k$lres[k$t.1 >= 2023])
off <- mean(d$lres[d$Data == "PSP" & d$Planted == 1]) - mean(d$lres[d$Data == "DOFAW" & d$Planted == 1])
logm("protocol switch: KMR PSP mean log residual to 2022", round(a1, 3), "n", sum(k$t.1 <= 2022), "from 2023", round(a2, 3), "n", sum(k$t.1 >= 2023), "shift", round(a2 - a1, 3), "| PSP minus DOFAW planted offset", round(off, 3))
R[["protocol"]] <- data.frame(resp = "dDBH", item = "protocol_switch", n = nrow(k), c_nat = a1, c_pl = a2, cal_nat = a2 - a1, cal_pl = off, b9 = NA, b9_se = NA, aic = NA, aic_ref = NA)
write.csv(do.call(rbind, R), file.path(OUTX, "s32_sens_v104.csv"), row.names = FALSE); logm("S32 SENS DONE")
