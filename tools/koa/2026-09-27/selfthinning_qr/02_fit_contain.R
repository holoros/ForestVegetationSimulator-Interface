## 02_fit_contain.R  koa self-thinning QR test, step 2: quantile regression limiting lines with
## installation-cluster bootstrap, then containment of deployed (beta 0.16019) and variant B (beta 0.117)
## trajectories. Rules fixed in PREREG_boundary_rule.md before this script was written.
suppressPackageStartupMessages({ library(data.table); library(quantreg); library(parallel) })
J <- path.expand("~/jobs"); W <- file.path(J, "koa_selfthin_qr_20260927"); O <- file.path(W, "out")
SEED <- 20260927L; B <- 2000L; NC <- 6L; TAUS <- c(0.95, 0.99)
A_ALLOM <- -0.16863070512157105; K_HD <- 1.1719473700506686
BETA_DEP <- 0.16019053617304435; BETA_FIT <- 0.117; REINEKE <- -1.605
eng_line <- function(beta) c(b0 = log(1e4) - 2 * log(beta) + 2 * A_ALLOM / K_HD, b1 = -2 / K_HD)
ENG <- rbind(deployed_0.16019 = eng_line(BETA_DEP), fitted_0.117 = eng_line(BETA_FIT))
cat("engine-implied limiting lines (ln N = b0 + b1 ln QMD):\n"); print(ENG, digits = 8)

d <- fread(file.path(O, "analysis_frame_DATA.csv"))
stopifnot(nrow(d) == 471L, !any(grepl("^(lat|lon|latitude|longitude|x|y)$", tolower(names(d)))))
d[, `:=`(x = log(QMD), y = log(N), x_live = log(QMD_live), planted = as.integer(Origin == "Planted"))]

## ---- boundary rules -------------------------------------------------------------------------------
rule_B1 <- function(dd) {
  br <- unique(quantile(dd$x, seq(0, 1, 0.1), type = 7))
  bin <- cut(dd$x, br, include.lowest = TRUE, labels = FALSE)
  keep <- ave(dd$SDI_eng, bin, FUN = function(s) s >= quantile(s, 0.9, type = 7))
  dd[as.logical(keep)]
}
rule_B2 <- function(dd) dd[dd[, .I[which.max(SDI_eng)], by = inst]$V1]
SETS <- list(
  ALL      = function(dd) dd[, .(x, y, inst)],
  B1       = function(dd) rule_B1(dd)[, .(x, y, inst)],
  B2       = function(dd) rule_B2(dd)[, .(x, y, inst)],
  ALL_live = function(dd) dd[, .(x = x_live, y, inst)],
  Natural  = function(dd) dd[Origin == "Natural", .(x, y, inst)],
  Planted  = function(dd) dd[Origin == "Planted", .(x, y, inst)])
for (s in names(SETS)) { z <- SETS[[s]](d)
  cat(sprintf("set %-8s n = %3d plot-measures, %3d installations\n", s, nrow(z), uniqueN(z$inst))) }
fwrite(rule_B1(d)[, .(Data, Install, Plot, Measure, Origin, N, QMD, SDI_eng)], file.path(O, "boundary_B1_DATA.csv"))
fwrite(rule_B2(d)[, .(Data, Install, Plot, Measure, Origin, N, QMD, SDI_eng)], file.path(O, "boundary_B2_DATA.csv"))

## ---- point fits and rank-inversion intervals -------------------------------------------------------
fit1 <- function(z, tau) { f <- suppressWarnings(rq(y ~ x, tau = tau, data = z, method = "br")); coef(f) }
pt <- list(); rk <- list()
for (s in names(SETS)) for (tau in TAUS) {
  z <- SETS[[s]](d); f <- suppressWarnings(rq(y ~ x, tau = tau, data = z, method = "br"))
  sm <- tryCatch(suppressWarnings(summary(f, se = "rank", alpha = 0.05)$coefficients), error = function(e) NULL)
  pt[[paste(s, tau)]] <- data.table(set = s, tau = tau, n = nrow(z), n_inst = uniqueN(z$inst),
    b0 = coef(f)[1], b1 = coef(f)[2], n_above = sum(z$y > fitted(f) + 1e-9), n_on = sum(abs(resid(f)) < 1e-9))
  rk[[paste(s, tau)]] <- data.table(set = s, tau = tau,
    b0_rank_lo = if (is.null(sm)) NA_real_ else sm[1, 2], b0_rank_hi = if (is.null(sm)) NA_real_ else sm[1, 3],
    b1_rank_lo = if (is.null(sm)) NA_real_ else sm[2, 2], b1_rank_hi = if (is.null(sm)) NA_real_ else sm[2, 3])
}
PT <- merge(rbindlist(pt), rbindlist(rk), by = c("set", "tau"))

## ---- installation-cluster bootstrap ----------------------------------------------------------------
inst_all <- sort(unique(d$inst)); rows_by_inst <- split(seq_len(nrow(d)), d$inst)
set.seed(SEED, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
IDX <- lapply(seq_len(B), function(b) sample(inst_all, length(inst_all), replace = TRUE))
boot_one <- function(b) {
  ii <- IDX[[b]]; db <- d[unlist(rows_by_inst[ii], use.names = FALSE)]
  db[, inst := rep(paste0(ii, "#", seq_along(ii)), lengths(rows_by_inst[ii]))]  # duplicated clusters distinct
  out <- list()
  for (s in names(SETS)) for (tau in TAUS) {
    z <- SETS[[s]](db)
    cf <- if (nrow(z) >= 5 && uniqueN(z$x) >= 3) tryCatch(fit1(z, tau), error = function(e) c(NA, NA)) else c(NA, NA)
    out[[length(out) + 1]] <- list(b = b, set = s, tau = tau, b0 = cf[1], b1 = cf[2])
  }
  ## pooled origin model at each tau: y ~ x * planted
  for (tau in TAUS) {
    cf <- tryCatch(coef(suppressWarnings(rq(y ~ x * planted, tau = tau, data = db, method = "br"))),
                   error = function(e) rep(NA, 4))
    out[[length(out) + 1]] <- list(b = b, set = "ORIGIN_pooled", tau = tau, b0 = cf[3], b1 = cf[4])  # planted shift, slope diff
  }
  rbindlist(out)
}
t0 <- Sys.time()
BT <- rbindlist(mclapply(seq_len(B), boot_one, mc.cores = NC, mc.preschedule = TRUE))
cat(sprintf("bootstrap: %d reps in %.1f s; failed fits by set:\n", B, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
print(BT[, .(failed = sum(is.na(b1))), by = .(set, tau)])
fwrite(BT, file.path(O, "bootstrap_coefs.csv"))

## origin model point fit
OR <- rbindlist(lapply(TAUS, function(ta) { f <- suppressWarnings(rq(y ~ x * planted, tau = ta, data = d, method = "br"))
  cf <- coef(f); bt <- BT[set == "ORIGIN_pooled" & tau == ta & !is.na(b1)]
  data.table(tau = ta, planted_shift = cf[3], shift_lo = quantile(bt$b0, .025), shift_hi = quantile(bt$b0, .975),
             slope_diff = cf[4], sdiff_lo = quantile(bt$b1, .025), sdiff_hi = quantile(bt$b1, .975),
             ## planted minus natural ln N at the median ln QMD of the data
             diff_at_medQ = cf[3] + cf[4] * median(d$x),
             diff_lo = quantile(bt$b0 + bt$b1 * median(d$x), .025), diff_hi = quantile(bt$b0 + bt$b1 * median(d$x), .975),
             p_boot_diff_le0 = mean(bt$b0 + bt$b1 * median(d$x) <= 0)) }))
cat("\npooled origin model (planted minus natural):\n"); print(OR, digits = 4)
fwrite(OR, file.path(O, "origin_model.csv"))

BS <- BT[set != "ORIGIN_pooled" & !is.na(b1), .(n_ok = .N,
  b0_lo = quantile(b0, .025), b0_hi = quantile(b0, .975), b1_lo = quantile(b1, .025), b1_hi = quantile(b1, .975),
  b1_sd = sd(b1), p_b1_gt_reineke = mean(b1 > REINEKE), p_b1_gt_engine = mean(b1 > -2 / K_HD)), by = .(set, tau)]
TAB <- merge(PT, BS, by = c("set", "tau"))
TAB[, `:=`(reineke = REINEKE, engine_slope = -2 / K_HD,
           reineke_in_boot = REINEKE >= b1_lo & REINEKE <= b1_hi,
           engine_in_boot = -2 / K_HD >= b1_lo & -2 / K_HD <= b1_hi)]
cat("\nfitted lines:\n"); print(TAB, digits = 5)
fwrite(TAB, file.path(O, "qr_lines.csv"))

## ---- pointwise bootstrap bands on ln N over a QMD grid ---------------------------------------------
qgrid <- exp(seq(log(min(d$QMD)), log(max(d$QMD)), length.out = 200))
band <- function(s, ta, xq) { bt <- BT[set == s & tau == ta & !is.na(b1)]
  P <- outer(bt$b0, rep(1, length(xq))) + outer(bt$b1, log(xq))
  list(lo = apply(P, 2, quantile, .025), hi = apply(P, 2, quantile, .975)) }
BANDS <- rbindlist(lapply(c("ALL", "B1", "B2"), function(s) rbindlist(lapply(TAUS, function(ta) {
  bb <- band(s, ta, qgrid); p <- TAB[set == s & tau == ta]
  data.table(set = s, tau = ta, QMD = qgrid, lnN = p$b0 + p$b1 * log(qgrid), lnN_lo = bb$lo, lnN_hi = bb$hi) }))))
fwrite(BANDS, file.path(O, "qr_bands.csv"))

## ---- trajectories ----------------------------------------------------------------------------------
TR <- fread(file.path(J, "koa_v102_20260918/track3/derived/engine_v102_out_m1/trajectories.csv"))
TR <- TR[, .(source = "deployed_v102_m1", scenario, site, age, rep, QMD, TPH, SDI)]
G <- fread(file.path(J, "koa_prereg_B_beta_20260926/out/GRID_trajectories.csv"))
G[, scenario := fifelse(origin == "nat", "Even-aged natural", "Even-aged planted")]
G <- G[, .(source = paste0("variantB_", arm), scenario, site, age = year, rep = 0L, QMD, TPH, SDI)]
## parity: variant B C5 arm against deployed rep 0, ages 1 to 100
pc <- merge(G[source == "variantB_C5_anchored" & age <= 100], TR[rep == 0], by = c("scenario", "site", "age"))
cat(sprintf("\nparity C5 grid vs deployed trajectories rep 0: rows %d, max|dTPH| %.3e, max|dQMD| %.3e\n",
            nrow(pc), max(abs(pc$TPH.x - pc$TPH.y)), max(abs(pc$QMD.x - pc$QMD.y))))
## check engine SDI formula against the SDI column
cat(sprintf("max|SDI - TPH (QMD/25)^1.605| deployed: %.3e\n", TR[, max(abs(SDI - TPH * (QMD / 25)^1.605))]))
ALLT <- rbind(TR, G)
QMIN <- min(d$QMD); QMAX <- max(d$QMD)

XG <- seq(log(1), log(200), length.out = 4000)   # ln QMD grid for pointwise bands, interpolated
contain <- function(tt, s, ta) {
  p <- TAB[set == s & tau == ta]; bb <- band(s, ta, exp(XG))
  x <- log(tt$QMD)
  lim <- exp(p$b0 + p$b1 * x)
  hi <- exp(approx(XG, bb$hi, xout = x)$y); lo <- exp(approx(XG, bb$lo, xout = x)$y)
  tt[, `:=`(set = s, tau = ta, Nlim = lim, Nlim_lo = lo, Nlim_hi = hi,
            exN = TPH - lim, exSDI = (TPH - lim) * (QMD / 25)^1.605,
            above = TPH > lim, above_hi = TPH > hi, above_lo = TPH > lo,
            extrap = QMD > QMAX | QMD < QMIN)]
  tt
}
summ <- function(x) x[, {
  k <- which.max(exN)
  .(n = .N, n_extrap = sum(extrap), frac_above = mean(above), frac_above_upper = mean(above_hi),
    frac_above_lower = mean(above_lo),
    max_exN = exN[k], max_exSDI = exSDI[k], rel_ex_pct = 100 * exN[k] / Nlim[k],
    age_at_max = age[k], QMD_at_max = QMD[k], TPH_at_max = TPH[k], Nlim_at_max = Nlim[k], Nlim_hi_at_max = Nlim_hi[k],
    max_exN_to_upper = max(TPH - Nlim_hi), extrap_at_max = extrap[k]) }, by = .(source, scenario, site, set, tau)]

res <- list(); mcs <- list()
for (s in c("ALL", "B1", "B2")) for (ta in TAUS) {
  ## point projections: deployed rep 0 ages 1 to 100, variant B arms years 1 to 100 and 1 to 200
  a <- contain(copy(ALLT[rep == 0 & age <= 100]), s, ta); a[, horizon := "1-100"]
  b <- contain(copy(ALLT[source != "deployed_v102_m1" & rep == 0]), s, ta); b[, horizon := "1-200"]
  res[[paste(s, ta)]] <- rbind(summ(a)[, horizon := "1-100"], summ(b)[, horizon := "1-200"])
  if (s == "ALL") {
    m <- contain(copy(TR[rep > 0]), s, ta)
    mcs[[paste(s, ta)]] <- m[, .(any_above = any(above), any_above_upper = any(above_hi), max_exN = max(exN)),
                              by = .(scenario, site, rep, set, tau)][,
      .(n_reps = .N, frac_reps_any_above = mean(any_above), frac_reps_any_above_upper = mean(any_above_upper),
        max_exN_over_reps = max(max_exN), q975_max_exN = quantile(max_exN, .975)), by = .(scenario, site, set, tau)]
  }
}
RES <- rbindlist(res); MCS <- rbindlist(mcs)
fwrite(RES, file.path(O, "containment_summary.csv")); fwrite(MCS, file.path(O, "containment_montecarlo.csv"))
options(width = 250)
cat("\ncontainment, ALL lines, ages/years 1 to 100:\n")
print(RES[set == "ALL" & horizon == "1-100", .(source, scenario, site, tau, frac_above = round(frac_above, 3),
  frac_above_upper = round(frac_above_upper, 3), max_exN = round(max_exN, 1), max_exSDI = round(max_exSDI, 1),
  rel = round(rel_ex_pct, 1), age_at_max, QMD_at_max = round(QMD_at_max, 1), TPH_at_max = round(TPH_at_max, 1),
  Nlim = round(Nlim_at_max, 1), Nlim_hi = round(Nlim_hi_at_max, 1), to_upper = round(max_exN_to_upper, 1), n_extrap)])
cat("\nMonte Carlo reps, ALL lines:\n"); print(MCS, digits = 4)

## verdict per pre-stated rule
dep <- RES[source == "deployed_v102_m1" & set == "ALL" & tau == 0.99 & horizon == "1-100"]
vb  <- RES[source == "variantB_C3_fitted" & set == "ALL" & tau == 0.99 & horizon == "1-100"]
verdict <- function(r) if (!any(r$frac_above > 0)) "PASS" else if (any(r$frac_above_upper > 0)) "FAIL" else "INDETERMINATE"
cat(sprintf("\nVERDICT (pre-stated rule, ALL tau 0.99, rep 0, 1-100): deployed %s; variant B beta 0.117 %s\n",
            verdict(dep), verdict(vb)))
saveRDS(list(TAB = TAB, OR = OR, BANDS = BANDS, RES = RES, MCS = MCS, ENG = ENG, qgrid = qgrid,
             QMIN = QMIN, QMAX = QMAX), file.path(O, "qr_results.rds"))
cat("done\n")
