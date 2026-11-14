# 28_common.R  Shared setup for the November 13, 2026 checks (28a, 28b). Builds its preamble from the scripts of record (22t, 23t) so that
# frames, S1, the increment fitter and the simulator are byte-for-byte those behind manuscript v133. No plot or installation identifier is printed.
suppressMessages({library(data.table)}); setwd("~/jobs/koa_final_eq_20261110"); options(width = 230)
# Fold partition: make_folds() calls set.seed() and sample(), so the partition depends on the RNG kind in force. Script 23t (Table 3) set L'Ecuyer-CMRG before building folds;
# scripts 22t and 25 built them under the default Mersenne-Twister. KOA_FOLDS=lecuyer (default) reproduces the Table 3 partition, KOA_FOLDS=mersenne the other.
if (Sys.getenv("KOA_FOLDS", "lecuyer") == "lecuyer") RNGkind("L'Ecuyer-CMRG"); cat("fold RNG kind:", RNGkind()[1], "\n")
L22 <- readLines("scripts/22t_rdbyi_final.R"); a <- grep("^suppressMessages", L22)[1]; b <- grep("^G <- fitg\\(d, bgs\\)", L22)[1]; stopifnot(length(a) == 1, length(b) == 1, b > a)
eval(parse(text = L22[a:(b - 1)]))                                   # f, tr, REM, flagrem, cf0, P (with fold), M, s1fit, s1p, bs, SM, d (with fold_s), xm, proj, fitg
L23 <- readLines("scripts/23t_rdbyi_items.R"); cf <- cf0
g1 <- grep("^simx <- function", L23); g2 <- grep("^draw <- function", L23); eval(parse(text = L23[g1:(g2 - 1)]))
g3 <- grep("^o <- rep\\(NA_real_, nrow\\(P\\)\\)", L23); g4 <- grep("^PI <- Filter", L23); eval(parse(text = L23[g3:g4]))            # SMO, startv, plotinfo, PI
g5 <- grep("^vis <- tr\\[", L23); g6 <- grep("^getL <- function", L23); eval(parse(text = L23[c(g5, g6)]))                         # vis, byiq, pick, getL
FT <- readRDS("out/rdbyi2_fits.rds"); bg <- FT$bg; bm <- FT$bm; stopifnot(max(abs(bs - FT$bs)) < 1e-8)
prepmf <- function(x) { x <- as.data.table(x); x[, `:=`(ld = log(dbh_m + 1), lbyi = log(BYI))]; x <- flagrem(x, FALSE); x <- x[rem__ == FALSE]; x[, sm := SM[pid]]; nna <- sum(is.na(x$sm)); if (nna) cat("rows without SDImax dropped:", nna, "\n"); x <- x[!is.na(sm)]
  merge(x, P[, .(pid, fold, inst)], by = "pid") }
Xmat <- function(m, sm = m$sm) cbind(1, m$ld, m$dbh_m, m$dbh_m^2, m$BAL, log(pmax(m$SDI_koa / sm, 0.001)), m$lbyi, m$planted)
mlfitG <- function(X, yy, oo, b0 = unname(bm)) { mu <- c(0, colMeans(X[, -1])); sdv <- c(1, apply(X[, -1], 2, sd)); Zm <- sweep(sweep(X, 2, mu), 2, sdv, "/"); Zm[, 1] <- 1
  z0 <- b0 * sdv; z0[1] <- b0[1] + sum(b0[-1] * mu[-1])
  nll <- function(z) { h <- exp(pmin(as.numeric(Zm %*% z) + oo, 30)); -sum(ifelse(yy == 1, log(-expm1(-h)), -h)) }; gr <- function(z) { h <- exp(pmin(as.numeric(Zm %*% z) + oo, 30)); -as.numeric(crossprod(Zm, ifelse(yy == 1, h * exp(-h) / (-expm1(-h)), -h))) }
  o <- nlminb(z0, nll, gr, control = list(iter.max = 1000, eval.max = 2000, rel.tol = 1e-12)); bb <- o$par / sdv; bb[1] <- o$par[1] - sum(bb[-1] * mu[-1]); list(b = setNames(bb, names(bm)), gmax = max(abs(gr(o$par)))) }
mfc <- prepmf(readRDS("frames/mf_confirmed.rds")); chk <- mlfitG(Xmat(mfc), mfc$died, log(mfc$yip)); cat("common: mortality frame rows", nrow(mfc), "deaths", sum(mfc$died), "; refit against the fit of record, largest difference", signif(max(abs(chk$b - bm)), 3), "\n"); stopifnot(nrow(mfc) == 6722, sum(mfc$died) == 845, max(abs(chk$b - bm)) < 1e-3)
benchrun <- function(coefs) rbindlist(lapply(PI, function(x) { q <- coefs(x); z <- simx(x$L$DBH, x$L$HT, x$L$EXPF_c, x$byi, x$pl, max(x$obs$h), q$sm, q$bg, q$bm); cbind(pid = x$p, planted = x$pl, x$obs, p_surv = z[x$obs$h + 1, "TPH"] / x$N0, p_qmd = z[x$obs$h + 1, "QMD"], p_ba = z[x$obs$h + 1, "BA"]) }))
sm1 <- function(b) b[, .(n = .N, plots = uniqueN(pid), surv_bias = round(mean(o_surv - p_surv), 3), surv_rmse = round(sqrt(mean((o_surv - p_surv)^2)), 3), qmd_bias = round(mean(o_qmd - p_qmd), 2), qmd_rmse = round(sqrt(mean((o_qmd - p_qmd)^2)), 2), ba_bias = round(mean(o_ba - p_ba), 2), ba_rmse = round(sqrt(mean((o_ba - p_ba)^2)), 2))]
benchsum <- function(b, tag) { cat("\n", tag, "\n"); print(rbind(cbind(set = "all", sm1(b)), cbind(set = "planted", sm1(b[planted == 1])), cbind(set = "natural", sm1(b[planted == 0])), cbind(set = "horizon 10 yr or more", sm1(b[h >= 10]))))
  last <- b[, .SD[which.max(h)], by = pid]; cols <- c("bias_rel", "slope", "b1_lo", "b1_hi", "pass_int", "pass_slope")
  print(rbindlist(lapply(list(all = last, planted = last[planted == 1], natural = last[planted == 0]), function(x) rbind(cbind(var = "survival", equiv_boot(x$o_surv, x$p_surv, x$pid)[, ..cols]), cbind(var = "QMD", equiv_boot(x$o_qmd, x$p_qmd, x$pid)[, ..cols]), cbind(var = "BA", equiv_boot(x$o_ba, x$p_ba, x$pid)[, ..cols]))), idcol = "set")) }
