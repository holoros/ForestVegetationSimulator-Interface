#!/usr/bin/env Rscript
## inc_byi_x_v104.R (koa v104 A4-D4, 30 Oct 2026). Recursion fit of the ln(BYI) x ln(BAL+1) interaction candidate for Eq. 4,
## with the inc_v103.R machinery (engine form recursion, HCB_P crown ratio under live-list BAL, planted guards, NO frame,
## solve_c, installation cluster equivalence bootstrap). Candidate tag <resp>_LX_NO: live-list BAL, NO frame, one extra term
##   b10 * ln(BYI) * ln(BAL_t + 1) inside the recursion (BAL_t the within-period interpolated BAL).
## PREREGISTERED before running (RUN.md A4-D4): the candidate is deployed over the v104 vector (<resp>_L_NO) only if
##   (i) it passes the v103 sign checks (dDBH: b1>0, b4<0, b5>0, b6<0; dHT: b1>0, b4<0),
##   (ii) the BYI elasticity b8 + b10*ln(BAL+1) is >= 0 at the 5th and 95th percentiles of frame BAL (a richer site never lowers growth),
##   (iii) it is eligible under the v103 rule (equivalence pass on both frames at 25 percent and size class max deviation <= 0.25),
##        or, if no candidate is eligible, its maximum equivalence region is smaller than that of <resp>_L_NO (the fallback rule of record),
##   (iv) its leave one source out RMSE (log annual increment, recursion refit on three sources, scored on the fourth) is not worse than
##        that of <resp>_L_NO on more than one of the four sources.
## Everything else is reported as a sensitivity (Section S3.2). No coordinate column is read or written.
suppressPackageStartupMessages(library(nlme))
set.seed(20261030)
src <- readLines(path.expand("~/jobs/koa_v104_20261030/track2/inc/inc_v103.R"))
commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112]))   # paths, helpers, gr.hat2g/gr.hat3, START, model_cols, pa_pred, solve_c, fit_one, eq_boot, score, taus
OUTX <- file.path(W, "a4/inc/out"); dir.create(OUTX, showWarnings = FALSE, recursive = TRUE)
load(file.path(OUT, "fits_v103.rda"))   # FITS, CAL, DEC (v103 candidates)
## recursion with the interaction term
gr.hat2x <- function(d1, bal1, bal2, cr1, cr2, bapa1, bapa2, Planted, rain, n, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10) {
  max.n <- max(n); pd.c <- d1; bal.c <- bal1; bapa.c <- bapa1; cr.c <- cr1
  bal.gr <- (bal2 - bal1) / n; bapa.gr <- (bapa2 - bapa1) / n; cr.gr <- (cr2 - cr1) / n
  for (i in 1:max.n) {
    gr <- exp(b0 + b9 * Planted + b1 * log(pd.c + 1) + b2 * pd.c + b3 * (bal.c^2 / log(pd.c + 5)) + b4 * log(bal.c + 1) + b5 * log(cr.c) +
                b6 * sqrt(bapa.c * pd.c) + b7 * Planted * pmin(pd.c, GUARD) + b8 * log(rain) + b10 * log(rain) * log(bal.c + 1))
    pd.c <- pd.c + ifelse(i <= n, gr, 0.0); bal.c <- bal.c + bal.gr; cr.c <- cr.c + cr.gr; bapa.c <- bapa.c + bapa.gr
  }
  pd.c - d1
}
pa_pred <- function(resp, d, b) {
  size <- if (resp == "dDBH") d$DBH.0 else d$HT.0
  if ("b10" %in% names(b)) gr.hat2x(size, d$BALx.0, d$BALx.1, d$CRx.0, d$CRx.1, d$BAPH.0, d$BAPH.1, d$Planted, d$BYI, d$YIP, b["b0"], b["b1"], b["b2"], b["b3"], b["b4"], b["b5"], b["b6"], b["b7"], b["b8"], b["b9"], b["b10"])
  else gr.hat3(size, d$BALx.0, d$BALx.1, d$CRx.0, d$CRx.1, d$BAPH.0, d$BAPH.1, d$Planted, d$BYI, d$YIP, b["b0"], b["b1"], b["b2"], b["b3"], b["b4"], b["b5"], b["b6"], b["b7"], b["b8"], b["b9"]) }
solve_c <- function(resp, d, b) {   # as inc_v103.R, with a non-finite guard: a diverged prediction sum counts as +Inf so the bracket stays valid
  sapply(c(natural = 0, planted = 1), function(pl) { dd <- d[d$Planted == pl, ]; if (nrow(dd) == 0) return(NA_real_)
    f <- function(lc) { bb <- b; bb["b0"] <- b["b0"] + lc; v <- sum(pa_pred(resp, dd, bb)) - sum(dd[[resp]]); if (!is.finite(v)) 1e12 else v }
    exp(uniroot(f, c(-4, 4), tol = 1e-8)$root) }) }
fit_x <- function(resp, d, start) {
  size <- if (resp == "dDBH") "DBH.0" else "HT.0"
  f <- as.formula(sprintf("%s ~ gr.hat2x(d1 = %s, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10)", resp, size))
  nlme(f, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 + b10 ~ 1, random = b0 ~ 1 | Data/Install/TreeID, start = start, weights = varPower(0.2, form = ~DBH.0), control = ctl) }
SIGN <- list(dDBH = function(b) c(b1_pos = b[["b1"]] > 0, b4_neg = b[["b4"]] < 0, b5_pos = b[["b5"]] > 0, b6_neg = b[["b6"]] < 0), dHT = function(b) c(b1_pos = b[["b1"]] > 0, b4_neg = b[["b4"]] < 0))
FR <- list(); for (resp in c("dDBH", "dHT")) for (fr in c("CS", "NO")) { d <- read.csv(file.path(FRD, sprintf("%s_%s_v103_model.csv", resp, fr)), stringsAsFactors = FALSE); nocoord(d)
  d$icls <- factor(d$icls, levels = c("1-2", "3-5", "6-10", "11-20", "21+")); FR[[paste(resp, fr)]] <- d }
COEF <- list(); STAT <- list(); STRATA <- list(); EQUIV <- list(); SG <- list(); FITX <- list(); CALX <- list(); LOSO <- list(); ELAS <- list()
for (resp in c("dDBH", "dHT")) {
  GUARD <- if (resp == "dDBH") 45 else 20; tag <- paste0(resp, "_LX_NO"); ref <- paste0(resp, "_L_NO")
  d <- model_cols(FR[[paste(resp, "NO")]], "l"); st <- c(fixef(FITS[[ref]]), b10 = 0)
  logm("FIT", tag, "rows", nrow(d), "trees", length(unique(d$TreeID)), "installations", length(unique(paste(d$Data, d$Install))))
  t0 <- Sys.time(); m <- tryCatch(fit_x(resp, d, st), error = function(e) { logm("  FAILED", conditionMessage(e)); NULL }); if (is.null(m)) next
  bb <- fixef(m); s <- summary(m)$tTable; tau <- taus(m); cf_si <- exp(0.5 * sum(tau[1:2]^2)); cc <- solve_c(resp, d, bb)
  logm("  done in", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min; logLik", round(as.numeric(logLik(m)), 2), "(L_NO", round(as.numeric(logLik(FITS[[ref]])), 2), "); fixef", paste(sprintf("%.6f", bb), collapse = " "),
       "; tau", paste(sprintf("%.4f", tau), collapse = " "), "; CF", round(cf_si, 4), "; c_nat", round(cc[["natural"]], 4), "c_pl", round(cc[["planted"]], 4))
  COEF[[tag]] <- data.frame(fit = tag, resp = resp, bal = "l", frame = "NO", term = rownames(s), estimate = s[, 1], se = s[, 2], t = s[, 3], p = s[, 4], row.names = NULL)
  STAT[[tag]] <- data.frame(fit = tag, resp = resp, n = nrow(d), logLik = as.numeric(logLik(m)), aic = AIC(m), logLik_L_NO = as.numeric(logLik(FITS[[ref]])), aic_L_NO = AIC(FITS[[ref]]),
    sigma = m$sigma, tau_source = tau[1], tau_inst = tau[2], tau_tree = tau[3], cf_source_inst = cf_si, c_natural = cc[["natural"]], c_planted = cc[["planted"]], cal_natural = cc[["natural"]] / cf_si, cal_planted = cc[["planted"]] / cf_si)
  FITX[[tag]] <- m; CALX[[tag]] <- list(b = bb, cc = cc, cf = cf_si, tau = tau)
  sg <- SIGN[[resp]](bb); q <- quantile(d$BALx.0, c(0.05, 0.5, 0.95)); el <- bb[["b8"]] + bb[["b10"]] * log(q + 1)
  ELAS[[tag]] <- data.frame(fit = tag, bal_q = names(q), bal = q, elasticity = el, pass = el >= 0, row.names = NULL)
  SG[[tag]] <- rbind(data.frame(fit = tag, check = names(sg), value = bb[sub("_.*", "", names(sg))], pass = as.logical(sg), row.names = NULL),
                     data.frame(fit = tag, check = c("elast_q05_nonneg", "elast_q95_nonneg"), value = el[c(1, 3)], pass = el[c(1, 3)] >= 0))
  logm("  sign checks", paste(SG[[tag]]$check, sprintf("%.4f", SG[[tag]]$value), ifelse(SG[[tag]]$pass, "PASS", "FAIL"), collapse = " "), "| elasticity at BAL q05/q50/q95", paste(sprintf("%.3f", el), collapse = " "))
  for (ef in c("CS", "NO")) { de <- model_cols(FR[[paste(resp, ef)]], "l"); sc <- score(resp, de, bb, cc, tag); STRATA[[paste(tag, ef)]] <- sc$strata; EQUIV[[paste(tag, ef)]] <- sc$equiv }
  ## leave one source out, recursion refit on three sources for both the interaction form and the L_NO form, scored on the held out source (log annual increment RMSE, PA prediction x pooled constants re-solved on the training frame)
  for (ho in unique(d$Data)) { tr <- d[d$Data != ho, ]; te <- d[d$Data == ho, ]; if (nrow(te) < 20) next
    for (form in c("L", "LX")) { t1 <- Sys.time()
      mm <- tryCatch(if (form == "LX") fit_x(resp, tr, st) else fit_one(resp, tr, "NO", start = fixef(FITS[[ref]])), error = function(e) NULL)
      if (is.null(mm)) { logm("  LOSO", ho, form, "FAILED"); next }
      b2 <- fixef(mm); c2 <- tryCatch(solve_c(resp, tr, b2), error = function(e) NULL); if (is.null(c2) || any(!is.finite(c2))) { logm("  LOSO", ho, form, "constants not solvable; fixef", paste(sprintf("%.3f", b2), collapse = " ")); next }
      pr <- pa_pred(resp, te, b2) * c2[ifelse(te$Planted == 1, "planted", "natural")]; if (any(!is.finite(pr))) { logm("  LOSO", ho, form, "non-finite predictions"); next }
      lo <- log(te[[resp]] / te$YIP); lp <- log(pmax(pr, 1e-6) / te$YIP)
      LOSO[[paste(tag, ho, form)]] <- data.frame(resp = resp, form = form, heldout = ho, n_test = nrow(te), n_train = nrow(tr), rmse_log = rmse(lo, lp), bias_log = mean(lp - lo), rmse_ann = rmse(te[[resp]] / te$YIP, pr / te$YIP),
        ratio = sum(te[[resp]] / te$YIP) / sum(pr / te$YIP), b8 = b2[["b8"]], b10 = if (form == "LX") b2[["b10"]] else NA, row.names = NULL)
      logm("  LOSO", ho, form, "n_test", nrow(te), "rmse_log", round(rmse(lo, lp), 4), "ratio", round(sum(te[[resp]] / te$YIP) / sum(pr / te$YIP), 3), "(", round(as.numeric(difftime(Sys.time(), t1, units = "mins")), 1), "min)") } }
  save(FITX, CALX, file = file.path(OUTX, "fits_byi_x_v104.rda"))
  write.csv(do.call(rbind, COEF), file.path(OUTX, "coefficients_byi_x_v104.csv"), row.names = FALSE); write.csv(do.call(rbind, STAT), file.path(OUTX, "fit_stats_byi_x_v104.csv"), row.names = FALSE)
  write.csv(do.call(rbind, SG), file.path(OUTX, "sign_checks_byi_x_v104.csv"), row.names = FALSE); write.csv(do.call(rbind, ELAS), file.path(OUTX, "elasticity_byi_x_v104.csv"), row.names = FALSE)
  write.csv(do.call(rbind, STRATA), file.path(OUTX, "evaluation_strata_byi_x_v104.csv"), row.names = FALSE); write.csv(do.call(rbind, EQUIV), file.path(OUTX, "equivalence_byi_x_v104.csv"), row.names = FALSE)
  write.csv(do.call(rbind, LOSO), file.path(OUTX, "loso_byi_x_v104.csv"), row.names = FALSE)
}
## selection against the v103 rule and the deployed L_NO row
EV <- do.call(rbind, STRATA); EQ <- do.call(rbind, EQUIV); SGd <- do.call(rbind, SG); SEL0 <- read.csv(file.path(OUT, "selection_v103.csv"), stringsAsFactors = FALSE); LO <- do.call(rbind, LOSO)
sel <- list()
for (tag in names(FITX)) { resp <- sub("_LX_NO", "", tag); ref <- paste0(resp, "_L_NO")
  e_cs <- EQ[EQ$fit == tag & EQ$eval_frame == "CS", ]; e_no <- EQ[EQ$fit == tag & EQ$eval_frame == "NO", ]; ev_no <- EV[EV$fit == tag & EV$eval_frame == "NO", ]; ev_cs <- EV[EV$fit == tag & EV$eval_frame == "CS", ]
  szlev <- if (resp == "dDBH") c("0-5", "5-10", "10-20", "20-30", "30-40", "40-60") else c("0-5", "5-10", "10-15", "15-20", "20-30"); szr <- ev_no[ev_no$strat == "size" & ev_no$level %in% szlev, ]
  r0 <- SEL0[SEL0$fit == ref, ]; lo <- LO[LO$resp == resp, ]; w <- merge(lo[lo$form == "LX", c("heldout", "rmse_log")], lo[lo$form == "L", c("heldout", "rmse_log")], by = "heldout", suffixes = c("_LX", "_L"))
  n_worse <- sum(w$rmse_log_LX > w$rmse_log_L)
  x <- data.frame(fit = tag, resp = resp, sign_pass = all(SGd$pass[SGd$fit == tag & !grepl("elast", SGd$check)]), elast_pass = all(SGd$pass[SGd$fit == tag & grepl("elast", SGd$check)]),
    eq_int_CS = e_cs$min_region_int, eq_slope_CS = e_cs$min_region_slope, eq_int_NO = e_no$min_region_int, eq_slope_NO = e_no$min_region_slope,
    equiv_pass_both = all(c(e_cs$pass_int_25, e_cs$pass_slope_25, e_no$pass_int_25, e_no$pass_slope_25) == 1), max_eq_region = max(e_cs$min_region_int, e_cs$min_region_slope, e_no$min_region_int, e_no$min_region_slope),
    size_max_dev_NO = max(abs(szr$ratio - 1)), size_ratios_NO = paste(sprintf("%s:%.2f", szr$level, szr$ratio), collapse = " "), rmse_CS = ev_cs$rmse_ann[ev_cs$strat == "all"], rmse_NO = ev_no$rmse_ann[ev_no$strat == "all"],
    slope_CS = e_cs$slope, slope_NO = e_no$slope, max_eq_region_L_NO = r0$max_eq_region, rmse_NO_L_NO = r0$rmse_NO, loso_sources = nrow(w), loso_worse_than_L = n_worse,
    loso_rmse_LX = paste(sprintf("%s:%.3f", w$heldout, w$rmse_log_LX), collapse = " "), loso_rmse_L = paste(sprintf("%s:%.3f", w$heldout, w$rmse_log_L), collapse = " "))
  x$eligible <- x$sign_pass & x$equiv_pass_both & x$size_max_dev_NO <= 0.25
  x$deploy <- x$sign_pass & x$elast_pass & (x$eligible | (!r0$eligible & x$max_eq_region < r0$max_eq_region)) & n_worse <= 1
  sel[[tag]] <- x; logm("SELECTION", tag, "eligible", x$eligible, "| max region", round(x$max_eq_region, 4), "vs L_NO", round(r0$max_eq_region, 4), "| LOSO worse on", n_worse, "of", nrow(w), "| sign", x$sign_pass, "elasticity", x$elast_pass, "| DEPLOY", x$deploy) }
sel <- do.call(rbind, sel); write.csv(sel, file.path(OUTX, "selection_byi_x_v104.csv"), row.names = FALSE); print(t(sel))
logm("ALL DONE")
