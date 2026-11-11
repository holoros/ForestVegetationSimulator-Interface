# 20_sdimax_byi.R  SDImax as a function of BYI. Rules: reviews/2026-11-11_koa-sdimax-byi_PREREG.md. No plot or installation identifier is printed.
suppressMessages({library(data.table); library(lqmm)}); setwd("~/jobs/koa_final_eq_20261110"); source("scripts/utils.R"); source("release/koa_step.R"); options(width = 230)
NC <- 6; NBQ <- as.integer(Sys.getenv("KOA_NBQ", "300")); POP <- 742; L25 <- log(25.4); RNGkind("L'Ecuyer-CMRG"); set.seed(20261115)
f <- readRDS("frames/frames.rds"); tr <- f$tr; cf <- koa_read_coef("release/koa_final_equations.csv"); FT <- readRDS("out/rd_final_fits.rds"); bg0 <- FT$G$b; bm0 <- FT$bm
J <- "~/jobs/koa_brms_sdimax_20261102/out/"; sx <- fread(paste0(J, "plot_sdimax_rilong.csv")); sx[, ID := as.character(ID)]; FF <- fread(paste0(J, "fit_frame.csv")); FF[, ID := as.character(ID)]
P <- unique(tr[, .(pid, Data, Install, Plot = as.character(Plot), planted, BYI)]); stopifnot(!anyDuplicated(P$pid)); P[, key := ifelse(Data == "FIA", as.character(Install), pid)]
P <- merge(P, sx[, .(key = ID, ID1 = ID)], by = "key", all.x = TRUE); k2 <- sx[, .(Data, Plot = as.character(Plot), ID2 = ID)][, if (.N == 1) .SD, by = .(Data, Plot)]; P <- merge(P, k2, by = c("Data", "Plot"), all.x = TRUE); P[, ID := ifelse(!is.na(ID1), ID1, ID2)]
P <- merge(P, sx[, .(ID, smax = SDImax_mean, lo = `SDImax_q2.5`, hi = `SDImax_q97.5`, n_visits)], by = "ID", all.x = TRUE); P[, `:=`(inst = paste(Data, Install), lbyi = log(BYI), ls = log(smax), w = 1 / pmax((log(hi) - log(lo)) / 3.92, 0.05)^2)]
P <- merge(P, make_folds(P), by = "inst"); M <- P[!is.na(smax)]; SMown <- setNames(ifelse(is.na(P$smax), POP, P$smax), P$pid)
cat("plots:", nrow(P), " matched to a brms SDImax:", nrow(M), " planted", sum(M$planted == 1), " natural", sum(M$planted == 0), "\nBYI quantiles (0, 10, 50, 90, 100%) natural:", round(quantile(M[planted == 0, BYI], c(0, .1, .5, .9, 1))), " planted:", round(quantile(M[planted == 1, BYI], c(0, .1, .5, .9, 1))),
    "\nplot SDImax quantiles (10, 50, 90%) natural:", round(quantile(M[planted == 0, smax], c(.1, .5, .9))), " planted:", round(quantile(M[planted == 1, smax], c(.1, .5, .9))), "\nplots with one visit in the brms frame:", sum(M$n_visits == 1), "of", nrow(M), "\n")
# ---- (d) ceiling ----
mx <- tr[Status == "live", .(sdi_max = max(SDI_koa, na.rm = TRUE)), by = pid]; M <- merge(M, mx, by = "pid", all.x = TRUE)
cat("\n(d) correlation of ln(plot SDImax) with ln(the plot's largest observed koa SDI): all", round(M[is.finite(log(sdi_max)), cor(ls, log(sdi_max))], 3), "; one visit", round(M[n_visits == 1 & is.finite(log(sdi_max)), cor(ls, log(sdi_max))], 3), "; more than one visit", round(M[n_visits > 1 & is.finite(log(sdi_max)), cor(ls, log(sdi_max))], 3),
    "\nsd of ln(plot SDImax):", round(sd(M$ls), 3), "; correlation of ln(SDImax) with ln(BYI): all", round(cor(M$ls, M$lbyi), 3), " natural", round(M[planted == 0, cor(ls, lbyi)], 3), " planted", round(M[planted == 1, cor(ls, lbyi)], 3), "\n")
# ---- model 2: second stage ----
F2 <- list(byi = ls ~ lbyi, byi_origin = ls ~ lbyi + planted, origin = ls ~ planted, byi_x_origin = ls ~ lbyi * planted)
s2 <- function(fm, d, wt = TRUE) if (wt) lm(fm, data = d, weights = w) else lm(fm, data = d)
cat("\n(a) model 2, second stage on ln(plot brms SDImax), weighted; coefficient (SE) [in-sample R2]\n"); for (n in names(F2)) { m <- s2(F2[[n]], M); cat(sprintf("  %-13s", n), paste(names(coef(m)), sprintf("%.3f (%.3f)", coef(m), sqrt(diag(vcov(m)))), collapse = "; "), sprintf(" [%.3f]\n", summary(m)$r.squared)) }
oof2 <- function(fm, wt = TRUE, dat = M, newd = P) { out <- rep(NA_real_, nrow(newd)); for (k in sort(unique(newd$fold))) out[newd$fold == k] <- predict(s2(fm, dat[fold != k], wt), newd[fold == k]); out }
for (n in names(F2)) P[[paste0("o2_", n)]] <- oof2(F2[[n]]); P[, o2_mean := { o <- numeric(.N); for (k in unique(fold)) o[fold == k] <- weighted.mean(M[fold != k, ls], M[fold != k, w]); o }]
r2 <- function(obs, pred, ref) 1 - sum((obs - pred)^2) / sum((obs - ref)^2); Pm <- P[!is.na(smax)]
cat("held out by installation: R2 of ln(SDImax) against the fold-training mean, RMSE (ln scale), slope of observed on predicted\n"); print(rbindlist(lapply(names(F2), function(n) { p <- Pm[[paste0("o2_", n)]]; data.table(model = n, R2 = round(r2(Pm$ls, p, Pm$o2_mean), 3), rmse = round(sqrt(mean((Pm$ls - p)^2)), 3), slope = round(coef(lm(Pm$ls ~ p))[[2]], 2),
  R2_nat = round(r2(Pm[planted == 0, ls], p[Pm$planted == 0], Pm[planted == 0, o2_mean]), 3), R2_plt = round(r2(Pm[planted == 1, ls], p[Pm$planted == 1], Pm[planted == 1, o2_mean]), 3)) })))
lo1 <- sapply(unique(M$inst), function(i) coef(s2(F2$byi_origin, M[inst != i]))[["lbyi"]]); cat("ln(BYI) coefficient (byi_origin) with each installation left out: min", round(min(lo1), 3), " max", round(max(lo1), 3), " (", length(lo1), "installations )\n")
cat("stress, ln(BYI) coefficient (SE) in byi_origin: unweighted", sprintf("%.3f (%.3f)", coef(s2(F2$byi_origin, M, FALSE))[["lbyi"]], sqrt(diag(vcov(s2(F2$byi_origin, M, FALSE))))[["lbyi"]]),
    "; without FIA", { m <- s2(F2$byi_origin, M[Data != "FIA"]); sprintf("%.3f (%.3f)", coef(m)[["lbyi"]], sqrt(diag(vcov(m)))[["lbyi"]]) }, "; more than one visit", { m <- s2(F2$byi_origin, M[n_visits > 1]); sprintf("%.3f (%.3f), n %d", coef(m)[["lbyi"]], sqrt(diag(vcov(m)))[["lbyi"]], nrow(M[n_visits > 1])) },
    "; natural only", { m <- s2(ls ~ lbyi, M[planted == 0]); sprintf("%.3f (%.3f)", coef(m)[["lbyi"]], sqrt(diag(vcov(m)))[["lbyi"]]) }, "; planted only", { m <- s2(ls ~ lbyi, M[planted == 1]); sprintf("%.3f (%.3f)", coef(m)[["lbyi"]], sqrt(diag(vcov(m)))[["lbyi"]]) }, "\n")
# ---- model 1: direct quantile mixed model ----
D <- merge(FF[, .(ID, ltph, lqmd)], M[, .(ID, pid, lbyi, planted, fold)], by = "ID"); D <- as.data.frame(D[order(ID)]); cat("\n(a) model 1, direct lqmm on", nrow(D), "rows of", length(unique(D$ID)), "plots\n")
F1 <- list(none = ltph ~ lqmd, byi = ltph ~ lqmd + lbyi, byi_origin = ltph ~ lqmd + lbyi + planted, origin = ltph ~ lqmd + planted); ctrl <- lqmmControl(LP_max_iter = 100000)
q1 <- function(fm, d, tau = 0.95) tryCatch(suppressWarnings(lqmm(fixed = fm, random = ~1, group = ID, tau = tau, data = d, control = ctrl)), error = function(e) NULL)
chk <- function(r, tau = 0.95) mean(r * (tau - (r < 0)))
for (n in names(F1)) { m <- q1(F1[[n]], D); if (is.null(m)) { cat("  ", n, "failed\n"); next }; b <- coef(m); cat(sprintf("  %-11s", n), paste(names(b), round(b, 4), collapse = "; "), " | population SDImax at median BYI of each origin (natural, planted):",
  paste(round(exp(sapply(c(0, 1), function(p) sum(b * c(1, L25, if ("lbyi" %in% names(b)) median(M[planted == p, lbyi]), if ("planted" %in% names(b)) p))))), collapse = ", "), "\n") }
cl <- rbindlist(parallel::mclapply(sort(unique(D$fold)), function(k) { trn <- D[D$fold != k, ]; te <- D[D$fold == k, ]; rbindlist(lapply(names(F1), function(n) { m <- q1(F1[[n]], trn); if (is.null(m)) return(NULL); X <- model.matrix(F1[[n]][-2], te); data.table(model = n, fold = k, n = nrow(te), loss = chk(te$ltph - as.numeric(X %*% coef(m)))) })) }, mc.cores = NC))
cat("held-out mean check loss at tau 0.95 (random effect zero), lower is better:\n"); print(cl[, .(loss = round(weighted.mean(loss, n), 4), folds = .N), by = model])
ids <- split(seq_len(nrow(D)), D$ID); bq <- do.call(rbind, parallel::mclapply(seq_len(NBQ), function(i) { s <- sample(names(ids), length(ids), TRUE); d <- do.call(rbind, lapply(seq_along(s), function(j) { x <- D[ids[[s[j]]], ]; x$ID <- j; x })); m <- q1(F1$byi_origin, d); if (is.null(m)) rep(NA_real_, 4) else coef(m) }, mc.cores = NC))
cat("byi_origin, plot-cluster bootstrap,", sum(complete.cases(bq)), "of", NBQ, "resamples: ln(BYI) coefficient 2.5, 50, 97.5%:", round(quantile(bq[, 3], c(.025, .5, .975), na.rm = TRUE), 3), "; planted:", round(quantile(bq[, 4], c(.025, .5, .975), na.rm = TRUE), 3), "; share with positive ln(BYI):", round(mean(bq[, 3] > 0, na.rm = TRUE), 3), "\n")
m99 <- q1(F1$byi_origin, D, 0.99); if (!is.null(m99)) cat("stress, tau 0.99:", paste(names(coef(m99)), round(coef(m99), 4), collapse = "; "), "\n")
for (pp in c(0, 1)) { m <- q1(F1$byi, D[D$planted == pp, ]); if (!is.null(m)) cat("stress, origin", pp, "alone:", paste(names(coef(m)), round(coef(m), 4), collapse = "; "), "\n") }
o1 <- rep(NA_real_, nrow(P)); for (k in sort(unique(P$fold))) { m <- q1(F1$byi_origin, D[D$fold != k, ]); if (!is.null(m)) { b <- coef(m); o1[P$fold == k] <- b[[1]] + b[[2]] * L25 + b[[3]] * P$lbyi[P$fold == k] + b[[4]] * P$planted[P$fold == k] } }; P[, o1_byi_origin := o1]
# ---- simulator and benchmark ----
xm <- function(S, BAL, BA, SDI, sm, byi, pl) cbind(1, log(S + 1), S, BAL / pmax(BA, 1e-6) * SDI / sm, log(byi), pl)
sim <- function(dbh, ht, ex, byi, pl, years, sm, bg, bm) { out <- vector("list", years + 1)
  for (y in 0:years) { s <- koa_stand(dbh, ht, ex); out[[y + 1]] <- data.table(year = y, BA = s$BA, TPH = s$TPH, QMD = s$QMD, SDI = s$SDI, RD = s$SDI / sm, HT = s$HT); if (y == years) break
    bal <- koa_bal(dbh, s$ba); rd <- s$SDI / sm; g <- as.numeric(exp(xm(dbh, bal, s$BA, s$SDI, sm, byi, pl) %*% bg))
    pm <- 1 - exp(-exp(bm[["(Intercept)"]] + bm[["ld"]] * log(dbh + 1) + bm[["dbh_m"]] * dbh + bm[["I(dbh_m^2)"]] * dbh^2 + bm[["BAL"]] * bal + bm[["lrd"]] * log(max(rd, 0.001)) + bm[["lbyi"]] * log(byi) + bm[["planted"]] * pl))
    ht <- ht + koa_height(dbh + g, cf) - koa_height(dbh, cf); dbh <- dbh + g; ex <- ex * (1 - pm) }
  rbindlist(out) }
startv <- tr[Status == "live" & !is.na(DBH) & DBH > 0, .(n = .N), by = .(pid, Measure)][n >= 5][, .SD[which.min(Measure)], by = pid]
benchf <- function(SMv, bg, bm) rbindlist(lapply(seq_len(nrow(startv)), function(i) { p <- startv$pid[i]; m0 <- startv$Measure[i]; L <- tr[pid == p & Measure == m0 & Status == "live" & !is.na(DBH) & DBH > 0]; pl <- L$planted[1]; byi <- L$BYI[1]
  L[is.na(HT) | HT < 1.37, HT := koa_height(DBH, cf)]; later <- sort(unique(tr[pid == p & Measure > m0, Measure])); if (nrow(f$srep[pid == p & Measure >= m0])) later <- later[later <= min(f$srep[pid == p & Measure >= m0, Measure])]
  if (!length(later)) return(NULL); z <- sim(L$DBH, L$HT, L$EXPF_c, byi, pl, max(later) - m0, SMv[[p]], bg, bm)
  rbindlist(lapply(later, function(m1) { ob <- merge(tr[pid == p & Measure == m1 & uid %in% L$uid & Status == "live", .(uid, DBH_c)], L[, .(uid, EXPF_c)], by = "uid"); if (!nrow(ob)) return(NULL); zz <- z[year == m1 - m0]
    data.table(pid = p, planted = pl, h = m1 - m0, o_surv = sum(ob$EXPF_c) / sum(L$EXPF_c), p_surv = zz$TPH / sum(L$EXPF_c), o_qmd = sqrt(sum(ob$DBH_c^2 * ob$EXPF_c) / sum(ob$EXPF_c)), p_qmd = zz$QMD, o_ba = sum(0.00007854 * ob$DBH_c^2 * ob$EXPF_c), p_ba = zz$BA) })) }))
sm1 <- function(b) b[, .(n = .N, plots = uniqueN(pid), surv_bias = round(mean(o_surv - p_surv), 3), surv_rmse = round(sqrt(mean((o_surv - p_surv)^2)), 3), qmd_bias = round(mean(o_qmd - p_qmd), 2), qmd_rmse = round(sqrt(mean((o_qmd - p_qmd)^2)), 2), ba_bias = round(mean(o_ba - p_ba), 2), ba_rmse = round(sqrt(mean((o_ba - p_ba)^2)), 2))]
eq1 <- function(b) { l <- b[, .SD[which.max(h)], by = pid]; e <- equiv_boot(l$o_ba, l$p_ba, l$pid); data.table(ba_slope = round(e$slope, 2), ba_lo = round(e$b1_lo, 2), ba_hi = round(e$b1_hi, 2), ba_pass_int = e$pass_int, ba_pass_slope = e$pass_slope) }
SMS <- list(own = SMown, pop742 = setNames(rep(POP, nrow(P)), P$pid), s2_origin_oof = setNames(exp(P$o2_origin), P$pid), s2_byi_oof = setNames(exp(P$o2_byi), P$pid), s2_byi_origin_oof = setNames(exp(P$o2_byi_origin), P$pid), s2_byi_x_origin_oof = setNames(exp(P$o2_byi_x_origin), P$pid), s1_byi_origin_oof = setNames(exp(P$o1_byi_origin), P$pid))
cat("\nout-of-fold SDImax of the benchmark plots, by candidate (10, 50, 90%):\n"); bp <- unique(startv$pid); for (n in names(SMS)) cat(sprintf("  %-20s", n), round(quantile(SMS[[n]][bp], c(.1, .5, .9), na.rm = TRUE)), " missing:", sum(is.na(SMS[[n]][bp])), "\n")
B1 <- parallel::mclapply(SMS, function(s) benchf(s, bg0, bm0), mc.cores = NC)
cat("\n(b) benchmark with the current E4r and E6r (fitted with each plot's own SDImax)\n"); print(rbindlist(lapply(names(B1), function(n) cbind(SDImax = n, sm1(B1[[n]]), eq1(B1[[n]])))))
cat("by origin:\n"); print(rbindlist(lapply(names(B1), function(n) cbind(SDImax = n, B1[[n]][, sm1(.SD), by = planted])))[order(planted)])
cat("horizons of 10 years or more:\n"); print(rbindlist(lapply(names(B1), function(n) cbind(SDImax = n, sm1(B1[[n]][h >= 10])))))
# ---- refit of E4r and E6r with a candidate SDImax ----
d <- copy(f$df[keep_fixed == TRUE]); d[, `:=`(S0 = DBH, S1 = e_DBH)]; for (v in c("BAL", "BA_koa", "SDI_koa")) { e <- paste0("e_", v); d[is.na(get(e)), (e) := get(v)] }
proj <- function(b, dd) { S <- dd$S0; n <- dd$yip; for (t in seq_len(max(n))) { a <- t <= n; if (!any(a)) break; w <- (t - 1) / n[a]; iw <- function(v0, v1) (1 - w) * v0[a] + w * v1[a]
    g <- exp(xm(S[a], iw(dd$BAL, dd$e_BAL), iw(dd$BA_koa, dd$e_BA_koa), iw(dd$SDI_koa, dd$e_SDI_koa), dd$sm[a], dd$BYI[a], dd$planted[a]) %*% b); S[a] <- S[a] + g }; S }
gbar <- function(b, dd) (proj(b, dd) - dd$S0) / dd$yip
fitg <- function(dd, b, passes = 3) { w <- 1 / dd$yip; for (it in seq_len(passes)) { b <- optim(b, function(bb) sum(w * (dd$S1 - proj(bb, dd))^2), method = "BFGS", control = list(maxit = 500, reltol = 1e-10))$par
    g <- pmax(gbar(b, dd), 0.01); r <- dd$S1 - proj(b, dd); dl <- max(0, min(1.5, coef(lm(log(pmax(r^2 / dd$yip, 1e-8)) ~ log(g)))[[2]] / 2)); w <- 1 / (dd$yip * g^(2 * dl)) }; setNames(b, names(bg0)) }
mf <- as.data.table(readRDS("frames/mf_confirmed.rds")); FM <- died ~ ld + dbh_m + I(dbh_m^2) + BAL + lrd + lbyi + planted + offset(log(yip))
refit <- function(SMv) { dd <- copy(d); dd[, sm := SMv[pid]]; b <- fitg(dd, bg0); m2 <- copy(mf); m2[, `:=`(ld = log(dbh_m + 1), lbyi = log(BYI), lrd = log(pmax(SDI_koa / SMv[pid], 0.001)))]; g <- glm(FM, family = binomial("cloglog"), data = m2, start = bm0, control = glm.control(maxit = 200)); list(bg = b, bm = coef(g), conv = g$converged, aic = AIC(g)) }
FULL <- list(pop742 = setNames(rep(POP, nrow(P)), P$pid), s2_origin = setNames(exp(predict(s2(F2$origin, M), P)), P$pid), s2_byi_origin = setNames(exp(predict(s2(F2$byi_origin, M), P)), P$pid), s2_byi_x_origin = setNames(exp(predict(s2(F2$byi_x_origin, M), P)), P$pid))
RF <- parallel::mclapply(FULL, refit, mc.cores = 4); cat("\n(b) E4r and E6r refitted with each candidate's SDImax (full-data SDImax model for fitting)\n")
for (n in names(RF)) cat(sprintf("  %-17s", n), "E4r:", paste(names(RF[[n]]$bg), round(RF[[n]]$bg, 4), collapse = " "), "\n", sprintf("  %-17s", ""), "E6r:", paste(round(RF[[n]]$bm, 4), collapse = " "), " converged", RF[[n]]$conv, " AIC", round(RF[[n]]$aic, 1), "(own SDImax: 4462.0)\n")
OOFN <- c(pop742 = "pop742", s2_origin = "s2_origin_oof", s2_byi_origin = "s2_byi_origin_oof", s2_byi_x_origin = "s2_byi_x_origin_oof")
B2 <- parallel::mclapply(names(RF), function(n) benchf(SMS[[OOFN[[n]]]], RF[[n]]$bg, RF[[n]]$bm), mc.cores = 4); names(B2) <- names(RF)
cat("benchmark with the refitted equations and out-of-fold SDImax (the SDImax model is out of fold; the growth and mortality refits use all plots)\n"); print(rbindlist(lapply(names(B2), function(n) cbind(SDImax = n, sm1(B2[[n]]), eq1(B2[[n]]))))); cat("by origin:\n"); print(rbindlist(lapply(names(B2), function(n) cbind(SDImax = n, B2[[n]][, sm1(.SD), by = planted])))[order(planted)])
# ---- (c) Bakuzis ----
vis <- tr[Status == "live" & !is.na(DBH) & DBH > 0, .(n = .N, q = sqrt(sum(DBH^2 * EXPF_c) / sum(EXPF_c))), by = .(pid, Measure, planted)][n >= 10]; byiq <- unique(tr[, .(pid, planted, BYI)])[, .(lo = quantile(BYI, .1), md = quantile(BYI, .5), hi = quantile(BYI, .9)), by = planted]; pick <- vis[, .SD[which.min(abs(q - quantile(q, 0.25)))], by = planted]
getL <- function(p) { pv <- pick[planted == p]; L <- tr[pid == pv$pid & Measure == pv$Measure & Status == "live" & !is.na(DBH) & DBH > 0]; L[is.na(HT) | HT < 1.37, HT := koa_height(DBH, cf)]; L }
LIM <- c(`0` = 1.2 * 1410.063, `1` = 1.2 * 1135.136)
runset <- function(tag, smf, bg, bm) { S <- rbindlist(lapply(c(0, 1), function(p) { L <- getL(p); rbindlist(lapply(c("lo", "md", "hi"), function(lv) { by <- byiq[planted == p][[lv]]; cbind(planted = p, level = lv, byi = by, sdimax = smf(p, by), sim(L$DBH, L$HT, L$EXPF_c, by, p, 200, smf(p, by), bg, bm)) })) }))
  L1 <- getL(1); bmd <- byiq[planted == 1, md]; DS <- rbindlist(lapply(c(300, 600, 1200, 2400), function(n0) cbind(n0 = n0, sim(L1$DBH, L1$HT, L1$EXPF_c * n0 / sum(L1$EXPF_c), bmd, 1, 100, smf(1, bmd), bg, bm)))); w <- dcast(S, planted + year ~ level, value.var = c("BA", "QMD", "TPH"))
  ordy <- w[year >= 1, .(first_ba_out_of_order = { o <- which(!(BA_lo <= BA_md + 1e-9 & BA_md <= BA_hi + 1e-9)); if (length(o)) year[o[1]] else NA_integer_ }), by = planted]
  gates <- data.table(set = tag, site = w[year >= 1 & year <= 100, all(BA_lo <= BA_md + 1e-9 & BA_md <= BA_hi + 1e-9 & QMD_lo <= QMD_md + 1e-9 & QMD_md <= QMD_hi + 1e-9)], sdi_lim = S[, max(SDI) <= LIM[as.character(planted[1])], by = planted][, all(V1)], ba200 = S[year == 200, all(BA <= 89.6)],
    no_rise = S[, SDI[year == 200] / SDI[year == 150] <= 1.05, by = .(planted, level)][, all(V1)], sukachev = w[year %in% c(40, 100), all(TPH_md <= TPH_lo * 1.02 & TPH_hi <= TPH_md * 1.02)], yield_dens = DS[year %in% c(20, 40, 100), all(diff(BA[order(n0)]) >= -1e-9), by = year][, all(V1)],
    ba_out_nat = ordy[planted == 0, first_ba_out_of_order], ba_out_plt = ordy[planted == 1, first_ba_out_of_order])
  cat("\n== ", tag, " ==\n"); print(S[year %in% c(20, 40, 100, 200), .(planted, level, byi = round(byi), sdimax = round(sdimax), year, BA = round(BA, 1), TPH = round(TPH), QMD = round(QMD, 1), SDI = round(SDI), RD = round(RD, 2))]); print(S[, .(ba_max = round(max(BA), 1), ba_peak = year[which.max(BA)], rd_max = round(max(RD), 2)), by = .(planted, level)]); print(gates); gates }
pf <- function(m) function(p, by) exp(predict(m, data.table(lbyi = log(by), planted = p)))
cat("\n(c) 200-year runs. SDImax predicted for the scenario BYI values:\n"); G <- rbindlist(list(
  runset("742, current equations", function(p, by) POP, bg0, bm0), runset("742, refitted with 742", function(p, by) POP, RF$pop742$bg, RF$pop742$bm),
  runset("origin mean, refitted", pf(s2(F2$origin, M)), RF$s2_origin$bg, RF$s2_origin$bm), runset("f(BYI, origin), current equations", pf(s2(F2$byi_origin, M)), bg0, bm0),
  runset("f(BYI, origin), refitted", pf(s2(F2$byi_origin, M)), RF$s2_byi_origin$bg, RF$s2_byi_origin$bm), runset("f(BYI x origin), refitted", pf(s2(F2$byi_x_origin, M)), RF$s2_byi_x_origin$bg, RF$s2_byi_x_origin$bm)))
cat("\ngates, all sets\n"); print(G)
cat("\nSDImax at the workbook site classes (planted), f(BYI, origin):", paste(c(120, 230, 340, 450), round(pf(s2(F2$byi_origin, M))(1, c(120, 230, 340, 450))), sep = ": ", collapse = "; "), " f(BYI x origin):", paste(round(pf(s2(F2$byi_x_origin, M))(1, c(120, 230, 340, 450))), collapse = "; "), "\n")
saveRDS(list(P = P[, .(planted, BYI, smax, fold, o2_byi_origin, o2_origin, o1_byi_origin)], RF = RF, s2 = lapply(F2, function(fm) coef(s2(fm, M))), gates = G, bq = bq), "out/sdimax_byi.rds"); cat("\n20 done\n")
