## a5/rerun/qr/02_fit_v104.R: copy of koa_selfthin_qr_20260927/02_fit_contain.R up to the line fits and bands (containment section
## not copied: it reads v102 trajectories). Changes: frame = analysis_frame_v104_DATA.csv (483 final live plot-measures), allometry K_HD/A of v104
## (engine lines only), deployed beta 0.14803, NC 1, n check 483. Seed 20260927, B 2000, taus 0.95/0.99 unchanged.
## 02_fit_contain.R  koa self-thinning QR test, step 2: quantile regression limiting lines with
## installation-cluster bootstrap, then containment of deployed (beta 0.16019) and variant B (beta 0.117)
## trajectories. Rules fixed in PREREG_boundary_rule.md before this script was written.
suppressPackageStartupMessages({ library(data.table); library(quantreg); library(parallel) })
J <- path.expand("~/jobs"); O <- file.path(J, "koa_v104_20261030/a5/rerun/qr")
SEED <- 20260927L; B <- 2000L; NC <- 1L; TAUS <- c(0.95, 0.99)
A_ALLOM <- 0.167997928455782; K_HD <- 1.04106514616602
BETA_DEP <- 0.14803309491927027; BETA_FIT <- 0.117; REINEKE <- -1.605
eng_line <- function(beta) c(b0 = log(1e4) - 2 * log(beta) + 2 * A_ALLOM / K_HD, b1 = -2 / K_HD)
ENG <- rbind(deployed_0.14803 = eng_line(BETA_DEP), fitted_0.117 = eng_line(BETA_FIT))
cat("engine-implied limiting lines (ln N = b0 + b1 ln QMD):\n"); print(ENG, digits = 8)

d <- fread(file.path(O, "analysis_frame_v104_DATA.csv"))
stopifnot(nrow(d) == 483L, !any(grepl("^(lat|lon|latitude|longitude|x|y)$", tolower(names(d)))))
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
fwrite(rule_B1(d)[, .(Data, Install, Plot, Measure, Origin, N, QMD, SDI_eng)], file.path(O, "boundary_B1_DATA_v104.csv"))
fwrite(rule_B2(d)[, .(Data, Install, Plot, Measure, Origin, N, QMD, SDI_eng)], file.path(O, "boundary_B2_DATA_v104.csv"))

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
fwrite(BT, file.path(O, "bootstrap_coefs_v104.csv"))

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
fwrite(OR, file.path(O, "origin_model_v104.csv"))

BS <- BT[set != "ORIGIN_pooled" & !is.na(b1), .(n_ok = .N,
  b0_lo = quantile(b0, .025), b0_hi = quantile(b0, .975), b1_lo = quantile(b1, .025), b1_hi = quantile(b1, .975),
  b1_sd = sd(b1), p_b1_gt_reineke = mean(b1 > REINEKE), p_b1_gt_engine = mean(b1 > -2 / K_HD)), by = .(set, tau)]
TAB <- merge(PT, BS, by = c("set", "tau"))
TAB[, `:=`(reineke = REINEKE, engine_slope = -2 / K_HD,
           reineke_in_boot = REINEKE >= b1_lo & REINEKE <= b1_hi,
           engine_in_boot = -2 / K_HD >= b1_lo & -2 / K_HD <= b1_hi)]
cat("\nfitted lines:\n"); print(TAB, digits = 5)
fwrite(TAB, file.path(O, "qr_lines_v104.csv"))

## ---- pointwise bootstrap bands on ln N over a QMD grid ---------------------------------------------
qgrid <- exp(seq(log(min(d$QMD)), log(max(d$QMD)), length.out = 200))
band <- function(s, ta, xq) { bt <- BT[set == s & tau == ta & !is.na(b1)]
  P <- outer(bt$b0, rep(1, length(xq))) + outer(bt$b1, log(xq))
  list(lo = apply(P, 2, quantile, .025), hi = apply(P, 2, quantile, .975)) }
BANDS <- rbindlist(lapply(c("ALL", "B1", "B2"), function(s) rbindlist(lapply(TAUS, function(ta) {
  bb <- band(s, ta, qgrid); p <- TAB[set == s & tau == ta]
  data.table(set = s, tau = ta, QMD = qgrid, lnN = p$b0 + p$b1 * log(qgrid), lnN_lo = bb$lo, lnN_hi = bb$hi) }))))
fwrite(BANDS, file.path(O, "qr_bands_v104.csv"))


saveRDS(list(TAB = TAB, OR = OR, BANDS = BANDS, ENG = ENG), file.path(O, "qr_results_v104.rds"))
cat("done\n")
