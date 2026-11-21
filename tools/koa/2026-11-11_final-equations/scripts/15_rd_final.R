# 15_rd_final.R  Relative-density framework with the plot-level brms SDImax of record (RI_LONG, koa_brms_sdimax_20261102; out/plot_sdimax_joined.rds).
#   E4r  dDBH = exp(b0 + b1 ln(DBH + 1) + b2 DBH + b3 (BAL / BA) RD + b4 ln(BYI) + b5 planted)
#   E6r  annual P(death) = 1 - exp(-exp(c0 + c1 ln(DBH + 1) + c2 DBH + c3 DBH^2 + c4 BAL + c5 ln(RD) + c6 ln(BYI) + c7 planted))
#   RD = SDI of live koa / SDImax of the plot. Height and the height rule are unchanged.
# Parts: (1) fits; (2) 200-year Bakuzis runs with gates (level gate restated: SDI must not rise by more than 5% between years 150 and 200);
# (3) plot benchmark; (4) 2,000 plot-cluster bootstrap resamples of both equations. No frontier, cap, floor or multiplier.
suppressMessages({library(data.table)})
setwd("~/jobs/koa_1150_20261121"); source("scripts/utils.R"); source("release/koa_step.R"); POP <- 742; NB <- as.integer(Sys.getenv("KOA_NBOOT", "2000")); NC <- as.integer(Sys.getenv("KOA_CORES", "6"))
f <- readRDS("frames/frames.rds"); tr <- f$tr; cf <- koa_read_coef("release/koa_final_equations.csv"); sj <- readRDS("out/plot_sdimax_joined.rds"); SM <- setNames(sj$smax, sj$pid)
d <- copy(f$df[keep_fixed == TRUE]); d[, `:=`(S0 = DBH, S1 = e_DBH)]; for (v in c("BAL", "BA_koa", "SDI_koa")) { e <- paste0("e_", v); d[is.na(get(e)), (e) := get(v)] }; d[, sm := SM[pid]]
xm <- function(S, BAL, BA, SDI, sm, byi, pl) cbind(1, log(S + 1), S, BAL / pmax(BA, 1e-6) * SDI / sm, log(byi), pl)
proj <- function(b, dd) { S <- dd$S0; n <- dd$yip; acc <- numeric(nrow(dd))
  for (t in seq_len(max(n))) { a <- t <= n; if (!any(a)) break; w <- (t - 1) / n[a]; iw <- function(v0, v1) (1 - w) * v0[a] + w * v1[a]
    g <- exp(xm(S[a], iw(dd$BAL, dd$e_BAL), iw(dd$BA_koa, dd$e_BA_koa), iw(dd$SDI_koa, dd$e_SDI_koa), dd$sm[a], dd$BYI[a], dd$planted[a]) %*% b); S[a] <- S[a] + g; acc[a] <- acc[a] + g }
  list(end = S, gbar = acc / n) }
fitg <- function(dd, b_start = NULL, passes = 3) { b <- if (is.null(b_start)) { y <- pmax((dd$S1 - dd$S0) / dd$yip, 0.01); coef(lm.fit(xm(dd$S0, dd$BAL, dd$BA_koa, dd$SDI_koa, dd$sm, dd$BYI, dd$planted), log(y))) } else b_start; b[is.na(b)] <- 0; w <- 1 / dd$yip; dl <- 0; conv <- NA
  for (it in seq_len(passes)) { o <- optim(b, function(bb) sum(w * (dd$S1 - proj(bb, dd)$end)^2), method = "BFGS", control = list(maxit = 500, reltol = 1e-10)); b <- o$par; conv <- o$convergence   # weights fixed within the pass
    pr <- proj(b, dd); r <- dd$S1 - pr$end; dl <- max(0, min(1.5, coef(lm(log(pmax(r^2 / dd$yip, 1e-8)) ~ log(pmax(pr$gbar, 0.01))))[[2]] / 2)); w <- 1 / (dd$yip * pmax(pr$gbar, 0.01)^(2 * dl)) }
  names(b) <- c("b0", "ls", "s", "xrd", "lbyi", "pl"); list(b = b, delta = dl, conv = conv) }
G <- fitg(d); bg <- G$b; cat("(1) E4r, conv", G$conv, "delta", round(G$delta, 4), "\n"); print(round(bg, 5))
mf <- as.data.table(readRDS("frames/mf_confirmed.rds")); mf[, `:=`(ld = log(dbh_m + 1), lbyi = log(BYI), lrd = log(pmax(SDI_koa / SM[pid], 0.001)))]
FM <- died ~ ld + dbh_m + I(dbh_m^2) + BAL + lrd + lbyi + planted + offset(log(yip)); M <- glm(FM, family = binomial("cloglog"), data = mf, control = glm.control(maxit = 100)); bm <- coef(M)
cat("E6r, AIC", round(AIC(M), 1), "\n"); print(round(summary(M)$coefficients[, 1:2], 5)); cat("diameter of minimum mortality (cm):", round(uniroot(function(x) bm[["ld"]] / (x + 1) + bm[["dbh_m"]] + 2 * bm[["I(dbh_m^2)"]] * x, c(5, 300))$root, 1), "\n")
sim <- function(dbh, ht, ex, byi, pl, years, sm, bg. = bg, bm. = bm) { out <- vector("list", years + 1)
  for (y in 0:years) { s <- koa_stand(dbh, ht, ex); out[[y + 1]] <- data.table(year = y, BA = s$BA, TPH = s$TPH, QMD = s$QMD, SDI = s$SDI, RD = s$SDI / sm, HT = s$HT, DMAX = max(dbh)); if (y == years) break
    bal <- koa_bal(dbh, s$ba); rd <- s$SDI / sm; g <- as.numeric(exp(xm(dbh, bal, s$BA, s$SDI, sm, byi, pl) %*% bg.))
    pm <- 1 - exp(-exp(bm.[["(Intercept)"]] + bm.[["ld"]] * log(dbh + 1) + bm.[["dbh_m"]] * dbh + bm.[["I(dbh_m^2)"]] * dbh^2 + bm.[["BAL"]] * bal + bm.[["lrd"]] * log(max(rd, 0.001)) + bm.[["lbyi"]] * log(byi) + bm.[["planted"]] * pl))
    ht <- ht + koa_height(dbh + g, cf) - koa_height(dbh, cf); dbh <- dbh + g; ex <- ex * (1 - pm) }
  rbindlist(out) }
vis <- tr[Status == "live" & !is.na(DBH) & DBH > 0, .(n = .N, q = sqrt(sum(DBH^2 * EXPF_c) / sum(EXPF_c))), by = .(pid, Measure, planted)][n >= 10]
byiq <- unique(tr[, .(pid, planted, BYI)])[, .(lo = quantile(BYI, .1), md = quantile(BYI, .5), hi = quantile(BYI, .9)), by = planted]; pick <- rbind(vis[planted == 0][which.min(abs(q - quantile(q, 0.25)))], { vp <- tr[Status == "live" & !is.na(DBH) & DBH > 0 & planted == 1, .(n = .N, N = sum(EXPF_c), q = sqrt(sum(DBH^2 * EXPF_c) / sum(EXPF_c))), by = .(pid, Measure, planted)][n >= 30]; vp[, dd := abs((log(q) - median(log(q))) / sd(log(q))) + abs((log(N) - median(log(N))) / sd(log(N)))]; vp[which.min(dd), .(pid, Measure, planted, n, q)] })  # 1.15.0 Bakuzis follow-up: planted scenario list = visit with 30+ trees closest to the median QMD and stems of such visits
getL <- function(p) { pv <- pick[planted == p]; L <- tr[pid == pv$pid & Measure == pv$Measure & Status == "live" & !is.na(DBH) & DBH > 0]; L[is.na(HT) | HT < 1.37, HT := koa_height(DBH, cf)]; L }
smq <- merge(sj, unique(tr[, .(pid, planted)]), by = "pid")[, .(q10 = quantile(smax, .1), q50 = median(smax), q90 = quantile(smax, .9), plots = .N), by = planted]
cat("\n(2) plot SDImax of the two starting plots:", paste(pick$pid, round(SM[pick$pid]), collapse = "; "), "\nplot SDImax by origin (10th, 50th, 90th percentile):\n"); print(smq)
LIM <- c(`0` = 1.2 * 1410.063, `1` = 1.2 * 1135.136); options(width = 220)
runset <- function(tag, smf) { S <- rbindlist(lapply(c(0, 1), function(p) { L <- getL(p); rbindlist(lapply(c("lo", "md", "hi"), function(lv) cbind(planted = p, level = lv, sim(L$DBH, L$HT, L$EXPF_c, byiq[planted == p][[lv]], p, 200, smf(p))))) }))
  L1 <- getL(1); DS <- rbindlist(lapply(c(300, 600, 1200, 2400), function(n0) cbind(n0 = n0, sim(L1$DBH, L1$HT, L1$EXPF_c * n0 / sum(L1$EXPF_c), byiq[planted == 1, md], 1, 100, smf(1)))))
  w <- dcast(S, planted + year ~ level, value.var = c("BA", "QMD", "TPH"))
  gates <- data.table(set = tag, site = w[year >= 1 & year <= 100, all(BA_lo <= BA_md + 1e-9 & BA_md <= BA_hi + 1e-9 & QMD_lo <= QMD_md + 1e-9 & QMD_md <= QMD_hi + 1e-9)], sdi_lim = S[, max(SDI) <= LIM[as.character(planted[1])], by = planted][, all(V1)],
    ba200 = S[year == 200, all(BA <= 89.6)], no_rise = S[, SDI[year == 200] / SDI[year == 150] <= 1.05, by = .(planted, level)][, all(V1)], sukachev = w[year %in% c(40, 100), all(TPH_md <= TPH_lo * 1.02 & TPH_hi <= TPH_md * 1.02)],
    yield_dens = DS[year %in% c(20, 40, 100), all(diff(BA[order(n0)]) >= -1e-9), by = year][, all(V1)])
  cat("\n== SDImax:", tag, "==\n"); print(S[year %in% c(0, 20, 40, 60, 100, 150, 200), lapply(.SD, round, 1), by = .(planted, level, year), .SDcols = c("BA", "TPH", "QMD", "SDI", "RD", "HT", "DMAX")][, RD := round(RD, 2)][])
  sl <- S[year >= 100, .(late_slope = round(coef(lm(log(TPH) ~ log(QMD)))[[2]], 2), sdi_max = round(max(SDI)), rd_max = round(max(RD), 2), ba_max = round(max(BA), 1), ba_peak_year = year[which.max(BA)]), by = .(planted, level)]; smx <- S[, .(sdi_max_all = round(max(SDI)), rd_max_all = round(max(RD), 2), ba_max_all = round(max(BA), 1), ba_peak = year[which.max(BA)]), by = .(planted, level)]
  print(merge(sl[, .(planted, level, late_slope)], smx, by = c("planted", "level"))); cat("density series, planted, median BYI: BA at 20, 40, 100 yr and stems at 100 yr\n"); print(dcast(DS[year %in% c(20, 40, 100)], n0 ~ year, value.var = "BA")[, lapply(.SD, round, 1)]); print(DS[year == 100, .(n0, TPH = round(TPH), QMD = round(QMD, 1))])
  print(gates); list(S = S, DS = DS, gates = gates) }
R1 <- runset("each starting plot's own value", function(p) SM[[pick[planted == p, pid]]]); R2 <- runset("population value 742", function(p) POP)
R3 <- runset("10th percentile of the origin's plots", function(p) smq[planted == p, q10]); R4 <- runset("90th percentile of the origin's plots", function(p) smq[planted == p, q90])
# ---------------- (3) benchmark ----------------
startv <- tr[Status == "live" & !is.na(DBH) & DBH > 0, .(n = .N), by = .(pid, Measure)][n >= 5][, .SD[which.min(Measure)], by = pid]
bench <- rbindlist(lapply(seq_len(nrow(startv)), function(i) { p <- startv$pid[i]; m0 <- startv$Measure[i]; L <- tr[pid == p & Measure == m0 & Status == "live" & !is.na(DBH) & DBH > 0]; pl <- L$planted[1]; byi <- L$BYI[1]
  L[is.na(HT) | HT < 1.37, HT := koa_height(DBH, cf)]; later <- sort(unique(tr[pid == p & Measure > m0, Measure])); if (nrow(f$srep[pid == p & Measure >= m0])) later <- later[later <= min(f$srep[pid == p & Measure >= m0, Measure])]
  if (!length(later)) return(NULL); z <- sim(L$DBH, L$HT, L$EXPF_c, byi, pl, max(later) - m0, SM[[p]])
  rbindlist(lapply(later, function(m1) { ob <- merge(tr[pid == p & Measure == m1 & uid %in% L$uid & Status == "live", .(uid, DBH_c)], L[, .(uid, EXPF_c)], by = "uid"); if (!nrow(ob)) return(NULL); zz <- z[year == m1 - m0]
    data.table(pid = p, planted = pl, h = m1 - m0, o_surv = sum(ob$EXPF_c) / sum(L$EXPF_c), p_surv = zz$TPH / sum(L$EXPF_c), o_qmd = sqrt(sum(ob$DBH_c^2 * ob$EXPF_c) / sum(ob$EXPF_c)), p_qmd = zz$QMD, o_ba = sum(0.00007854 * ob$DBH_c^2 * ob$EXPF_c), p_ba = zz$BA) })) }))
sm1 <- function(b) b[, .(n = .N, plots = uniqueN(pid), surv_bias = round(mean(o_surv - p_surv), 3), surv_rmse = round(sqrt(mean((o_surv - p_surv)^2)), 3), qmd_bias = round(mean(o_qmd - p_qmd), 2), qmd_rmse = round(sqrt(mean((o_qmd - p_qmd)^2)), 2), ba_bias = round(mean(o_ba - p_ba), 2), ba_rmse = round(sqrt(mean((o_ba - p_ba)^2)), 2))]
cat("\n(3) benchmark, plot SDImax (current refit for comparison: survival RMSE 0.214, QMD 4.21, BA 10.97; D1 with M1 at one constant: 0.214, 4.01, 10.54)\n"); print(cbind(set = "all", sm1(bench))); bench[, hcl := cut(h, c(0, 3, 9, 20, 100), labels = c("1-3", "4-9", "10-20", ">20"))]; print(bench[, sm1(.SD), by = .(planted, hcl)][order(planted, hcl)])
last <- bench[, .SD[which.max(h)], by = pid]; cols <- c("bias_rel", "slope", "b1_lo", "b1_hi", "pass_int", "pass_slope")
cat("equivalence at each plot's longest horizon (25% region, convention)\n"); print(rbindlist(lapply(list(all = last, planted = last[planted == 1], natural = last[planted == 0]), function(x) rbind(cbind(var = "survival", equiv_boot(x$o_surv, x$p_surv, x$pid)[, ..cols]), cbind(var = "QMD", equiv_boot(x$o_qmd, x$p_qmd, x$pid)[, ..cols]), cbind(var = "BA", equiv_boot(x$o_ba, x$p_ba, x$pid)[, ..cols]))), idcol = "set"))
saveRDS(list(G = G, bm = bm, m_se = summary(M)$coefficients[, 2], R = list(own = R1, pop = R2, q10 = R3, q90 = R4), bench = bench, smq = smq), "out/rd_final_fits.rds"); fwrite(bench, "out/benchmark_rd_final.csv")
cat("\nparts 1 to 3 written; starting", NB, "bootstrap resamples\n")
# ---------------- (4) bootstraps ----------------
idx <- split(seq_len(nrow(d)), d$pid); pn <- names(idx); RNGkind("L'Ecuyer-CMRG"); set.seed(20261110)
bt <- do.call(rbind, parallel::mclapply(seq_len(NB), function(i) { dd <- d[unlist(idx[sample(pn, length(pn), TRUE)], use.names = FALSE)]; tryCatch(fitg(dd, b_start = bg)$b, error = function(e) rep(NA_real_, length(bg))) }, mc.cores = NC)); colnames(bt) <- names(bg)
cat("E4r plot-cluster bootstrap, completed:", sum(complete.cases(bt)), "of", NB, "\n"); print(round(rbind(est = bg, se = apply(bt, 2, sd, na.rm = TRUE), lo = apply(bt, 2, quantile, .025, na.rm = TRUE), hi = apply(bt, 2, quantile, .975, na.rm = TRUE)), 5))
ix <- split(seq_len(nrow(mf)), mf$pid); pm <- names(ix)
bmm <- do.call(rbind, parallel::mclapply(seq_len(NB), function(i) { dd <- mf[unlist(ix[sample(pm, length(pm), TRUE)], use.names = FALSE)]; tryCatch(coef(glm(FM, family = binomial("cloglog"), data = dd, control = glm.control(maxit = 100))), error = function(e) rep(NA_real_, length(bm))) }, mc.cores = NC))
cat("E6r plot-cluster bootstrap, completed:", sum(complete.cases(bmm)), "of", NB, "\n"); print(round(rbind(est = bm, se_model = summary(M)$coefficients[, 2], se = apply(bmm, 2, sd, na.rm = TRUE), lo = apply(bmm, 2, quantile, .025, na.rm = TRUE), hi = apply(bmm, 2, quantile, .975, na.rm = TRUE)), 5))
cat("share of resamples with a positive DBH-squared coefficient:", round(mean(bmm[, "I(dbh_m^2)"] > 0, na.rm = TRUE), 4), "\n")
pr <- proj(bg, d); d[, `:=`(og = S1 - S0, pg = pr$end - S0, v = yip * pmax(pr$gbar, 0.01)^(2 * G$delta))]; pp <- d[, .(n = .N, R = sum(og) / sum(pg), sv = sum(v), sp = sum(pg)), by = pid][n >= 5]; d2 <- merge(d, pp[, .(pid, R)], by = "pid")
sigma2 <- sum((d2$og - d2$R * d2$pg)^2 / d2$v) / (nrow(d2) - nrow(pp)); tau2 <- max(0, var(pp$R) - mean(sigma2 * pp$sv / pp$sp^2)); mf[, p := fitted(M)]; pmx <- mf[, .(D = sum(died), E = sum(p), V = sum(p * (1 - p))), by = pid]; phi <- max(0, sum((pmx$D - pmx$E)^2 - pmx$V) / sum(pmx$E^2))
cat("interval components: sigma", round(sqrt(sigma2), 4), " tau", round(sqrt(tau2), 4), " delta", round(G$delta, 4), " phi", round(phi, 4), "\n")
saveRDS(list(bg = bg, delta = G$delta, bt = bt, bm = bm, m_se = summary(M)$coefficients[, 2], bmm = bmm, sigma = sqrt(sigma2), tau = sqrt(tau2), phi = phi), "out/rd_final_boot.rds")
