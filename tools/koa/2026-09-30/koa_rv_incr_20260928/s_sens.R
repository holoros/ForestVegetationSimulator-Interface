## s_sens.R <spec>. One sensitivity refit of Eq. 4 for both responses. Specs:
##  fixsrc   (R1 c1a) data source as a FIXED effect on b0, installation as the only random intercept
##  dofaw    (R1 c1b) DOFAW Historical records only, random b0 ~ 1 | Install, all ten terms free
##  lt3      (R1 c4)  remeasurement intervals >= 3 years only
##  wlen     (R1 c4)  full frame, residual variance additionally proportional to 1 / interval length (weight ~ YIP)
##  nocr     (R1 c6)  ln(CR) removed (b5 = 0)
##  treere   (R1 c3)  tree-level random intercept nested in installation within source
##  balconv  (R1 c5)  BAL.0 and BAL.1 replaced by the conventional live-tree BAL of s4_bal_build.R
## Every spec is started from the reference (deployed-start) vector; for dDBH, which has two optima on the full frame, it is also
## started from the record-start vector (published fixef, b9 = 0) and the higher likelihood solution is kept (both logged).
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
spec <- commandArgs(trailingOnly = TRUE)[1]; if (spec == "nonpos") FRAME_TAG <- "nonpos"
REF <- load_ref()
CO <- list(); ST <- list(); FITS <- list(); PRED <- list()
for (resp in c("dDBH", "dHT")) {
  m0 <- REF[[resp]]; ref_tt <- summary(m0)$tTable
  d <- prep(resp)
  if (spec == "balconv") { b <- read.csv(file.path(OUT, sprintf("bal_%s.csv", resp)), stringsAsFactors = FALSE)
    stopifnot(nrow(b) == nrow(d), all(b$TreeID == d$TreeID), all(b$t.0 == d$t.0)); d$BAL.0 <- b$BALc.0; d$BAL.1 <- b$BALc.1 }
  if (spec == "dofaw") d <- d[d$Data == "DOFAW", ]
  if (spec == "lt3") d <- d[d$YIP >= 3, ]
  d$invYIP <- 1 / d$YIP; d$TreeN <- paste(d$Plot, d$Tree, sep = "/")
  d$Data <- droplevels(d$Data)
  starts <- list(ref = fixef(m0)); if (resp == "dDBH") starts$recstart <- rec_start(resp)
  fitone <- function(st) {
    if (spec == "fixsrc") {
      re <- ranef(m0)$Data; lv <- levels(d$Data); s0 <- re[match(lv, sub("^.*?/", "", rownames(re))), 1]; s0[is.na(s0)] <- 0
      stv <- c(st[["b0"]] + s0[1], s0[-1] - s0[1], st[TERMS[-1]])
      nlme(form3(resp), data = d, fixed = list(b0 ~ Data, b1 ~ 1, b2 ~ 1, b3 ~ 1, b4 ~ 1, b5 ~ 1, b6 ~ 1, b7 ~ 1, b8 ~ 1, b9 ~ 1),
           random = b0 ~ 1 | InstID, start = stv, weights = varPower(0.2, form = ~DBH.0), control = ctl)
    } else if (spec == "dofaw") {
      nlme(form3(resp), data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | InstID,
           start = st, weights = varPower(0.2, form = ~DBH.0), control = ctl)
    } else if (spec == "wlen") {
      nlme(form3(resp), data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install,
           start = st, weights = varComb(varPower(0.2, form = ~DBH.0), varFixed(~invYIP)), control = ctl)
    } else if (spec == "nocr") {
      nlme(form3(resp, nocr = TRUE), data = d, fixed = b0 + b1 + b2 + b3 + b4 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install,
           start = st[TERMS[-6]], weights = varPower(0.2, form = ~DBH.0), control = ctl)
    } else if (spec == "treere") {
      nlme(form3(resp), data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install/TreeN,
           start = st, weights = varPower(0.2, form = ~DBH.0), control = ctl)
    } else fit_ref(resp, d, st)
  }
  best <- NULL; ll <- c()
  for (sl in names(starts)) {
    t0 <- Sys.time(); m <- tryCatch(fitone(starts[[sl]]), error = function(e) { logm(resp, spec, sl, "ERROR", conditionMessage(e)); NULL })
    ll[sl] <- if (is.null(m)) NA else as.numeric(logLik(m))
    logm(resp, spec, sl, "n", nrow(d), "secs", round(as.numeric(difftime(Sys.time(), t0, units = "secs"))), "logLik", round(ll[sl], 3),
         if (!is.null(m)) paste("fixef", paste(sprintf("%.5f", fixef(m)), collapse = " ")) else "")
    if (!is.null(m) && (is.null(best) || ll[sl] > as.numeric(logLik(best)) + 1e-6)) { best <- m; bl <- sl }
  }
  if (is.null(best)) next
  m <- best; tt <- summary(m)$tTable; tn <- rownames(tt)
  tn2 <- sub("^b0\\.\\(Intercept\\)$", "b0", tn)
  cf <- data.frame(spec = spec, resp = resp, term = tn2, estimate = tt[, 1], se = tt[, 2], p = tt[, ncol(tt)], row.names = NULL)
  mm <- match(cf$term, rownames(ref_tt)); cf$ref_estimate <- ref_tt[mm, 1]; cf$ref_se <- ref_tt[mm, 2]
  cf$dz_refSE <- (cf$estimate - cf$ref_estimate) / cf$ref_se
  CO[[resp]] <- cf
  tau <- vc_taus(m); p0 <- fitted(m, level = 0); km <- kmult(d, p0, resp)
  ## multipliers of this refit evaluated on the full frame as well (lt3 and dofaw fit a subset)
  kf <- if (spec %in% c("lt3", "dofaw")) { dfull <- prep(resp); kmult(dfull, predict(m, newdata = dfull, level = 0), resp) } else km
  ST[[resp]] <- data.frame(spec = spec, resp = resp, start_kept = bl, logLik_ref_start = ll["ref"], logLik_rec_start = if ("recstart" %in% names(ll)) ll["recstart"] else NA,
    n = nrow(d), n_planted = sum(d$Planted == 1), n_inst = length(unique(d$InstID)), n_trees = length(unique(d$TreeID)),
    logLik = as.numeric(logLik(m)), AIC = AIC(m), ref_logLik = as.numeric(logLik(m0)), ref_AIC = AIC(m0),
    tau1 = tau[1], tau2 = if (length(tau) > 1) tau[2] else NA, tau3 = if (length(tau) > 2) tau[3] else NA, sigma = m$sigma,
    cf_fit = exp(0.5 * sum(tau[seq_len(min(2, length(tau)))]^2)),
    r2_cond_period = r2(d[[resp]], fitted(m)), r2_pa_period = r2(d[[resp]], p0), r2_pa_ann_cal = km$r2_cal, rmse_pa_ann_cal = km$rmse_cal,
    k_nat = km$k[["natural"]], k_nat_lo = km$lo[["natural"]], k_nat_hi = km$hi[["natural"]],
    k_pl = if ("planted" %in% names(km$k)) km$k[["planted"]] else NA, k_pl_lo = if ("planted" %in% names(km$k)) km$lo[["planted"]] else NA,
    k_pl_hi = if ("planted" %in% names(km$k)) km$hi[["planted"]] else NA,
    kfull_nat = kf$k[["natural"]], kfull_pl = kf$k[["planted"]], kfull_nat_lo = kf$lo[["natural"]], kfull_nat_hi = kf$hi[["natural"]],
    kfull_pl_lo = kf$lo[["planted"]], kfull_pl_hi = kf$hi[["planted"]], r2_full_pa_ann_cal = kf$r2_cal, row.names = NULL)
  FITS[[resp]] <- m
}
write.csv(do.call(rbind, CO), file.path(OUT, sprintf("sens_%s_coef.csv", spec)), row.names = FALSE)
write.csv(do.call(rbind, ST), file.path(OUT, sprintf("sens_%s_stats.csv", spec)), row.names = FALSE)
save(FITS, file = file.path(OUT, sprintf("sens_%s_fits.rda", spec)))
print(do.call(rbind, CO)); print(t(do.call(rbind, ST)))
logm("SENS DONE", spec)
