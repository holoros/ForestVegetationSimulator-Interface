# 35_stand_mortality.R  Stand-level mortality forms against the tree-level E6r of record, on the frame with PSP thinning removals censored, by the
# rules of 2026-11-14_koa-height-crown-standmort_PREREG.md (sections 3 and 5).
#   T0   E6r of record (tree level)
#   S1m  stand hazard exp(g0 + g1 ln RD + g2 ln QMD + g3 ln BYI + g4 planted), deaths allocated to trees by a refitted size and BAL risk
#   S2m  occurrence of any death in a plot-interval times the hazard among plot-intervals with deaths, same allocation
#   S4m  whole-stand model of Garcia (2009), S^a - (b QMD)^a = constant with S = 100 / sqrt(N); a common, b by origin, all fitted; same allocation
#   S3m  E6r with relative density held at or below 1 by a stand step (excess removed in proportion to the E6r hazard); no constant of its own
# Tests: installations held out (plot-interval survival, tree-level log score); 53-plot benchmark; six 200-year gates. No identifier is printed.
suppressMessages(library(data.table)); source("~/jobs/koa_final_eq_20261110/scripts/32_common.R"); NC <- as.integer(Sys.getenv("KOA_CORES", "6"))
mf <- as.data.table(readRDS("frames/mf_confirmed.rds")); mf <- flagrem(mf, FALSE); mf <- mf[rem__ == FALSE]; mf[, `:=`(sm = SM[pid], lbyi = log(BYI))]; stopifnot(nrow(mf) == 6722, sum(mf$died) == 845, !anyNA(mf$sm))
mf[, piv := paste(pid, Measure, e_Measure)]; mf[, `:=`(q0 = sqrt(mean(dbh_m^2)), nex = sum(EXPF_c)), by = piv]; cat("plot-interval stand values rebuilt from the tree rows where the stand table had none: tree-intervals with QMD missing", mf[, sum(is.na(QMD_koa))], "; with SDI of zero", mf[, sum(SDI_koa <= 0)], "\n")
mf[, `:=`(qx = pmax(ifelse(is.na(QMD_koa) | QMD_koa <= 0, q0, QMD_koa), 0.1), tx = ifelse(!is.na(TPH_koa) & TPH_koa > 0, TPH_koa, nex))]; mf[, sx := ifelse(!is.na(SDI_koa) & SDI_koa > 0, SDI_koa, tx * (qx / 25.4)^1.605)]; mf[, q1 := pmax(ifelse(is.na(e_QMD_koa) | e_QMD_koa <= 0, qx, e_QMD_koa), 0.1)]; stopifnot(all(mf$tx > 0), !anyNA(mf$sx))   # 267 tree-intervals start below breast height (DBH 0) on young PSP plots; QMD is floored at 0.1 cm and relative density at 0.001 there, as in E6r
mf[, `:=`(rd = pmax(SDI_koa / sm, 0.001), rds = pmax(sx / sm, 0.001), lq = log(qx), ltph = log(tx))]; mf <- merge(mf, P[, .(pid, fold)], by = "pid")
pv <- mf[, .(n = .N, d = sum(died), yip = yip[1], lrd = log(rds[1]), lq = lq[1], tx = tx[1], qx = qx[1], q1 = q1[1], lbyi = lbyi[1], pl = planted[1], ltph = ltph[1], fold = fold[1], pid = pid[1]), by = piv]
cat("censored frame: tree-intervals", nrow(mf), "deaths", sum(mf$died), "; plot-intervals", nrow(pv), "; with at least one death", sum(pv$d > 0), "; plots", uniqueN(pv$pid), "\n")
ml <- function(nll, p0) { o <- nlminb(p0, nll, control = list(iter.max = 2000, eval.max = 4000, rel.tol = 1e-12)); o }
Zs <- function(d) cbind(1, d$lrd, d$lq, d$lbyi, d$pl); Zo <- function(d) cbind(1, d$lrd, d$lq, d$lbyi, d$pl, d$ltph)
fit_s1 <- function(d) { Z <- Zs(d); ml(function(g) { p <- pmin(pmax(-expm1(-d$yip * exp(pmin(as.numeric(Z %*% g), 20))), 1e-12), 1 - 1e-12); -sum(d$d * log(p) + (d$n - d$d) * log1p(-p)) }, c(-4, 0.5, 0, 0, 0))$par }
fit_occ <- function(d) { Z <- Zo(d); y <- d$d > 0; ml(function(a) { p <- pmin(pmax(-expm1(-d$yip * exp(pmin(as.numeric(Z %*% a), 20))), 1e-12), 1 - 1e-12); -sum(ifelse(y, log(p), log1p(-p))) }, c(-2, 0.3, 0, 0, 0, 0))$par }
# tree allocation: p_i = 1 - exp(-yip h_stand r_i / rbar), r_i = exp(c1 ln(DBH+1) + c2 DBH + c3 DBH^2 + c4 BAL), rbar the plot-interval mean of r
rfun <- function(cc, dbh, bal) exp(cc[1] * log(dbh + 1) + cc[2] * dbh / 10 + cc[3] * (dbh / 10)^2 + cc[4] * bal / 10)
fit_alloc <- function(d, hs) ml(function(cc) { r <- rfun(cc, d$dbh_m, d$BAL); rb <- ave(r, d$piv); p <- pmin(pmax(-expm1(-d$yip * hs * r / rb), 1e-12), 1 - 1e-12); -sum(ifelse(d$died == 1, log(p), log1p(-p))) }, c(-0.8, -0.2, 0.03, 0.3))$par
hs_s1 <- function(g, d) exp(as.numeric(cbind(1, log(d$rds), d$lq, d$lbyi, d$planted) %*% g))
gsurv <- function(th, N0, D0, D1, pl) { a <- exp(th[1]); b <- exp(th[2] + th[3] * pl); S0 <- 100 / sqrt(N0); (S0 / (S0^a + pmax((b * D1)^a - (b * D0)^a, 0))^(1 / a))^2 }
fit_gar <- function(d) ml(function(th) { p <- pmin(pmax(1 - gsurv(th, d$tx, d$qx, d$q1, d$pl), 1e-12), 1 - 1e-12); -sum(d$d * log(p) + (d$n - d$d) * log1p(-p)) }, c(log(3), log(0.1), 0))$par
hs_gar <- function(th, d) -log(pmax(gsurv(th, d$tx, d$qx, d$q1, d$planted), 1e-9)) / d$yip
hs_s2 <- function(a, g, d) { po <- -expm1(-exp(as.numeric(cbind(1, log(d$rds), d$lq, d$lbyi, d$planted, d$ltph) %*% a))); m <- po * (-expm1(-exp(as.numeric(cbind(1, log(d$rds), d$lq, d$lbyi, d$planted) %*% g)))); -log1p(-pmin(m, 0.999)) }
fitall <- function(ti, pi) { dT <- mf[ti]; dP <- pv[pi]; g1 <- fit_s1(dP); a2 <- fit_occ(dP); g2 <- fit_s1(dP[d > 0]); c1 <- fit_alloc(dT, hs_s1(g1, dT)); c2 <- fit_alloc(dT, hs_s2(a2, g2, dT)); g4 <- fit_gar(dP); c4 <- fit_alloc(dT, pmax(hs_gar(g4, dT), 1e-8))
  X <- cbind(1, log(dT$dbh_m + 1), dT$dbh_m, dT$dbh_m^2, dT$BAL, log(dT$rd), dT$lbyi, dT$planted); mu <- c(0, colMeans(X[, -1])); sdv <- c(1, apply(X[, -1], 2, sd)); Zm <- sweep(sweep(X, 2, mu), 2, sdv, "/"); Zm[, 1] <- 1
  z <- ml(function(z) { h <- exp(pmin(as.numeric(Zm %*% z) + log(dT$yip), 30)); -sum(ifelse(dT$died == 1, log(-expm1(-h)), -h)) }, { z0 <- bm * sdv; z0[1] <- bm[1] + sum(bm[-1] * mu[-1]); unname(z0) })$par; b <- z / sdv; b[1] <- z[1] - sum(b[-1] * mu[-1])
  list(g1 = g1, a2 = a2, g2 = g2, c1 = c1, c2 = c2, g4 = g4, c4 = c4, bm = b) }
ptree <- function(F, d, which) { if (which == "T0") return(-expm1(-d$yip * exp(as.numeric(cbind(1, log(d$dbh_m + 1), d$dbh_m, d$dbh_m^2, d$BAL, log(d$rd), d$lbyi, d$planted) %*% F$bm))))
  hs <- switch(which, S1m = hs_s1(F$g1, d), S2m = hs_s2(F$a2, F$g2, d), S4m = pmax(hs_gar(F$g4, d), 1e-8)); cc <- switch(which, S1m = F$c1, S2m = F$c2, S4m = F$c4); r <- rfun(cc, d$dbh_m, d$BAL); -expm1(-d$yip * hs * r / ave(r, d$piv)) }
FA <- fitall(seq_len(nrow(mf)), seq_len(nrow(pv))); cat("\n(1) full fits\nE6r refit here against the coefficients of record: largest difference", signif(max(abs(FA$bm - bm)), 3), "\n")
cat("S1m stand hazard (intercept, ln RD, ln QMD, ln BYI, planted):", round(FA$g1, 4), "\nS2m occurrence (intercept, ln RD, ln QMD, ln BYI, planted, ln stems per ha):", round(FA$a2, 4), "\nS2m hazard among plot-intervals with deaths:", round(FA$g2, 4), "\nallocation risk, S1m (ln(DBH+1), DBH/10, (DBH/10)^2, BAL/10):", round(FA$c1, 4), "; S2m:", round(FA$c2, 4), "; S4m:", round(FA$c4, 4), "\nS4m Garcia: exponent a", round(exp(FA$g4[1]), 4), "; b natural", round(exp(FA$g4[2]), 5), "; b planted", round(exp(FA$g4[2] + FA$g4[3]), 5), "\n")
cv <- rbindlist(parallel::mclapply(sort(unique(mf$fold)), function(k) { F <- fitall(which(mf$fold != k), which(pv$fold != k)); te <- mf[fold == k]; rbindlist(lapply(c("T0", "S1m", "S2m", "S4m"), function(w) data.table(form = w, piv = te$piv, pid = te$pid, planted = te$planted, yip = te$yip, died = te$died, p = pmin(pmax(ptree(F, te, w), 1e-9), 1 - 1e-9)))) }, mc.cores = NC))
cat("\n(2) held-out installations\n"); print(cv[, .(tree_logscore = round(-mean(ifelse(died == 1, log(p), log1p(-p))), 4), deaths = sum(died), predicted_deaths = round(sum(p), 1)), by = form])
pvc <- cv[, .(n = .N, obs = 1 - mean(died), pred = 1 - mean(p), planted = planted[1], pid = pid[1]), by = .(form, piv)]
print(pvc[, .(plot_intervals = .N, surv_bias = round(mean(obs - pred), 4), surv_rmse = round(sqrt(mean((obs - pred)^2)), 4), surv_rmse_w = round(sqrt(sum(n * (obs - pred)^2) / sum(n)), 4)), by = form]); print(dcast(pvc[, .(rmse = round(sqrt(mean((obs - pred)^2)), 4), bias = round(mean(obs - pred), 4)), by = .(form, planted)], planted ~ form, value.var = c("bias", "rmse")))
# system functions
al <- function(cc, hh, dbh, ex, bal) { r <- rfun(cc, dbh, bal); -expm1(-hh * r / (sum(ex * r) / sum(ex))) }
MF <- list(T0 = mort_tree,
  S1m = function(dbh, ex, bal, s, rd, byi, pl, ...) al(FA$c1, exp(sum(FA$g1 * c(1, log(max(rd, 0.001)), log(s$QMD), log(byi), pl))), dbh, ex, bal),
  S2m = function(dbh, ex, bal, s, rd, byi, pl, ...) { po <- -expm1(-exp(sum(FA$a2 * c(1, log(max(rd, 0.001)), log(s$QMD), log(byi), pl, log(s$TPH))))); m <- po * (-expm1(-exp(sum(FA$g2 * c(1, log(max(rd, 0.001)), log(s$QMD), log(byi), pl))))); al(FA$c2, -log1p(-min(m, 0.999)), dbh, ex, bal) },
  S4m = function(dbh, ex, bal, s, rd, byi, pl, d1) { q1 <- sqrt(sum(d1^2 * ex) / sum(ex)); al(FA$c4, max(-log(max(gsurv(FA$g4, s$TPH, s$QMD, q1, pl), 1e-9)), 1e-10), dbh, ex, bal) },
  S3m = function(dbh, ex, bal, s, rd, byi, pl, ...) { h <- exp(as.numeric(cbind(1, log(dbh + 1), dbh, dbh^2, bal, log(max(rd, 0.001)), log(byi), pl) %*% bm)); p <- -expm1(-h); if (rd <= 1) return(p)
    f <- function(k) { e2 <- ex * exp(-k * h); sum(e2) * (sqrt(sum(0.00007854 * dbh^2 * e2) / sum(e2) / 0.00007854) / 25.4)^1.605 / (s$SDI / rd) - 1 }; if (f(1) <= 0) return(p); up <- 2; while (is.finite(f(up)) && f(up) > 0 && up < 1e5) up <- up * 2; if (!is.finite(f(up)) || f(up) > 0) return(pmin(-expm1(-up / 2 * h), 0.999)); k <- uniroot(f, c(up / 2, up))$root; -expm1(-k * h) })
cat("\n(3) benchmark, 53 plots, S1 out of fold, E4r of record\n"); BM <- rbindlist(lapply(names(MF), function(w) cbind(form = w, benchsys(ht_rule, MF[[w]])))); print(BM[, sm1(.SD), by = form]); print(BM[, sm1(.SD), by = .(form, planted)]); print(BM[h >= 10, sm1(.SD), by = form])
SS <- rbindlist(lapply(names(MF), function(w) cbind(form = w, runsc(ht_rule, MF[[w]])))); GT <- rbindlist(lapply(names(MF), function(w) cbind(form = w, gates6(SS[form == w], MF[[w]]))))
cat("\n(4) six gates, 200-year runs\n"); print(GT); cat("\nstems per ha at 40 and 100 years, and basal area at 100 and 200 years (low, median, high BYI)\n")
print(dcast(SS[year %in% c(40, 100)], form + planted + year ~ level, value.var = "TPH", fun.aggregate = function(v) round(v[1]))[, .(form, planted, year, lo, md, hi)]); print(dcast(SS[year %in% c(100, 200)], form + planted + year ~ level, value.var = "BA", fun.aggregate = function(v) round(v[1], 1))[, .(form, planted, year, lo, md, hi)])
print(SS[, .(max_RD = round(max(RD), 2), peak_BA = round(max(BA), 1), peak_year = year[which.max(BA)]), by = .(form, planted, level)][order(form, planted, match(level, c("lo", "md", "hi")))])
b0 <- BM[form == "T0", sm1(.SD)]; rule <- merge(BM[, sm1(.SD), by = form][, .(form, surv_rmse, ba_rmse)], GT, by = "form"); g0 <- GT[form == "T0"]
rule[, keeps := (site_to_100 | !g0$site_to_100) & (sdi_lim | !g0$sdi_lim) & (ba200 | !g0$ba200) & (no_rise | !g0$no_rise) & (yield_dens | !g0$yield_dens)]; rule[, preferred := form != "T0" & keeps & sukachev & ba_rmse <= 1.02 * 6.76 & surv_rmse <= 1.02 * 0.124]
cat("\n(5) rule: every gate E6r passes, the Sukachev gate as well, benchmark basal area RMSE within 2% of 6.76 and survival RMSE within 2% of 0.124\n"); print(rule[, .(form, surv_rmse, ba_rmse, keeps, sukachev, preferred)])
saveRDS(list(FA = FA, cv = cv, BM = BM, SS = SS, GT = GT, rule = rule), "out/stand_mortality_35.rds"); cat("done\n")
