# 47_ingrowth.R  Ingrowth for the natural (uneven-aged) scenarios (section 10 of 2026-11-14_koa-height-crown-standmort_PREREG.md), asked for by Aaron on
# November 15, 2026: a density-dependent annual rate of koa passing 12.7 cm, fitted to the remeasured FIA subplots of natural stands, tested held out and
# through the 200-year gates. No plot or installation identifier is printed.
suppressMessages(library(data.table)); source("~/jobs/koa_final_eq_20261110/scripts/32_common.R"); set.seed(20261147); DIN <- 12.7
x <- tr[Data == "FIA" & planted == 0]; v <- x[, .(m0 = min(Measure), m1 = max(Measure)), by = .(pid, Data, Install, planted, BYI)][m1 > m0]
st <- x[Status == "live" & !is.na(DBH) & DBH > 0, .(sdi = SDI_koa[1], ba = BA_koa[1], ba_all = BAPH_all[1], n_live = .N), by = .(pid, Measure)]
d <- merge(v, st, by.x = c("pid", "m0"), by.y = c("pid", "Measure"), all.x = TRUE); d[is.na(sdi), `:=`(sdi = 0, ba = 0, n_live = 0L)]
rc <- f$recruits[Data == "FIA" & planted == 0 & DBH >= DIN, .(y = .N), by = .(pid, Measure)]; d <- merge(d, rc, by.x = c("pid", "m1"), by.y = c("pid", "Measure"), all.x = TRUE); d[is.na(y), y := 0L]
d[, `:=`(yrs = m1 - m0, area = 1 / 59.5, rd = sdi / SM[pid], inst = paste(Data, Install))]; d[, off := log(yrs * area)]; stopifnot(!anyNA(d$rd), nrow(d) == 48, sum(d$y) == 10)
cat("subplots", nrow(d), "; installations", uniqueN(d$inst), "; subplot-years", sum(d$yrs), "; recruits", sum(d$y), "on", sum(d$y > 0), "subplots; crude rate (trees/ha/yr)", round(sum(d$y) / sum(d$yrs * d$area), 3), "\n")
cat("RD at the first visit: "); print(round(quantile(d$rd, c(0, .1, .25, .5, .75, .9, 1)), 3)); cat("all-species basal area missing on", sum(is.na(d$ba_all)), "subplots\n")
cat("recruits by RD third:\n"); print(d[, .(subplots = .N, recruits = sum(y), rate = round(sum(y) / sum(yrs * area), 2)), by = .(rd_third = cut(rd, quantile(rd, c(0, 1/3, 2/3, 1)), include.lowest = TRUE))][order(rd_third)])
FM <- list(N1 = y ~ 1, N2 = y ~ rd, N3 = y ~ ba_all); fit <- function(nm, dd) glm(FM[[nm]], family = poisson, offset = off, data = dd)
F <- lapply(names(FM), fit, dd = d); names(F) <- names(FM)
cat("\n(1) full fits\n"); for (nm in names(F)) { m <- F[[nm]]; cat("\n", nm, ": deviance", round(deviance(m), 2), " AIC", round(AIC(m), 2), " Pearson dispersion", round(sum(residuals(m, "pearson")^2) / df.residual(m), 2), "\n"); print(round(coef(summary(m)), 4)) }
# installation bootstrap
ins <- unique(d$inst); sp <- split(seq_len(nrow(d)), d$inst); NBT <- 2000
BT <- do.call(rbind, lapply(seq_len(NBT), function(b) { dd <- d[unlist(sp[sample(ins, length(ins), replace = TRUE)])]; if (sum(dd$y) == 0) return(c(NA, NA, NA)); c(n1c = unname(coef(fit("N1", dd))), tryCatch(unname(coef(fit("N2", dd))), error = function(e) c(NA, NA))) }))
ok <- complete.cases(BT) & abs(BT[, 3]) < 50; cat("\n(2) installation bootstrap:", NBT, "resamples;", sum(ok), "usable\n")
q <- function(z) round(quantile(z, c(0.025, 0.975)), 4)
cat("N1 rate (trees/ha/yr):", round(exp(coef(F$N1)), 3), " 95%:", round(exp(q(BT[ok, 1])), 3), "\nN2 n0:", round(coef(F$N2)[1], 4), " 95%:", q(BT[ok, 2]), "\nN2 n1 (RD):", round(coef(F$N2)[2], 4), " 95%:", q(BT[ok, 3]), " share negative:", round(mean(BT[ok, 3] < 0), 3), "\n")
# held out by installation
d <- merge(d, make_folds(d), by = "inst"); pdv <- function(y, mu) 2 * sum(ifelse(y > 0, y * log(y / mu), 0) - (y - mu))
cv <- rbindlist(lapply(sort(unique(d$fold)), function(k) { trn <- d[fold != k]; te <- d[fold == k]; rbindlist(lapply(names(FM), function(nm) { m <- tryCatch(fit(nm, trn), error = function(e) NULL); data.table(form = nm, fold = k, y = te$y, mu = if (is.null(m)) NA_real_ else as.numeric(predict(m, te, type = "response"))) })) }))
cat("\n(3) held out by installation (ten folds of record): Poisson deviance, total predicted and observed recruits\n"); HO <- cv[, .(subplots = .N, deviance = round(pdv(y, mu), 3), predicted = round(sum(mu), 2), observed = sum(y)), by = form]; print(HO)
# simulator with ingrowth
th <- unname(readRDS("out/height_increment_42.rds")$FH$B2$th)
hB2 <- function(H, D, D1, x, lbyi, pl) { H <- pmax(H, 0.5); A <- exp(th[1] + th[2] * lbyi); k <- exp(th[3] + th[6] * pl); m <- exp(th[4]); inc <- pmax(m * k * H * ((A / H)^(1 / m) - 1), 0) * exp(th[5] * x); inc[!is.finite(inc)] <- 0; inc }
sim3 <- function(dbh, ht, ex, byi, pl, years, sm, hfun = hB2, mfun = mort_tree, ing = NULL) { out <- matrix(NA_real_, years + 1, 8, dimnames = list(NULL, c("BA", "TPH", "QMD", "HT", "VOL", "RD", "SDI", "HMAX")))
  for (y in 0:years) { s <- koa_stand(dbh, ht, ex); out[y + 1, ] <- c(s$BA, s$TPH, s$QMD, s$HT, 0.40 * s$BA * s$HT, s$SDI / sm, s$SDI, max(ht)); if (y == years) break
    bal <- koa_bal(dbh, s$ba); rd <- s$SDI / sm; g <- as.numeric(exp(xm(dbh, bal, s$BA, s$SDI, sm, byi, pl) %*% bg)); pm <- mfun(dbh, ex, bal, s, rd, byi, pl, dbh + g)
    ht <- ht + hfun(ht, dbh, dbh + g, bal / max(s$BA, 1e-6) * rd, log(byi), pl); dbh <- dbh + g; ex <- ex * (1 - pm)
    if (!is.null(ing)) { ni <- ing(rd); if (is.finite(ni) && ni > 0) { dbh <- c(dbh, DIN); ht <- c(ht, koa_height(DIN, cf)); ex <- c(ex, ni) } } }
  out }
run3 <- function(ing = NULL, years = 200) rbindlist(lapply(seq_len(nrow(SC)), function(i) { L <- getL(SC$planted[i]); cbind(planted = SC$planted[i], level = SC$level[i], byi = SC$byi[i], sdimax = SC$sdimax[i], year = 0:years, as.data.table(sim3(L$DBH, L$HT, L$EXPF_c, SC$byi[i], SC$planted[i], years, SC$sdimax[i], ing = if (SC$planted[i] == 0) ing else NULL))) }))
i1 <- function(b) function(rd) exp(b[1]); i2 <- function(b) function(rd) exp(b[1] + b[2] * rd)
S0 <- run3(); S1 <- run3(i1(coef(F$N1))); S2 <- run3(i2(coef(F$N2)))
cat("\n(4) natural scenarios, deterministic, height increment Eq. 6 of record (B2)\n"); YR <- c(20, 40, 100, 200)
T4 <- rbind(cbind(ingrowth = "none", S0), cbind(ingrowth = "N1 constant", S1), cbind(ingrowth = "N2 density", S2))[planted == 0 & year %in% YR, .(ingrowth, level, year, BA = round(BA, 1), TPH = round(TPH), QMD = round(QMD, 1), RD = round(RD, 2), HT = round(HT, 1))]
print(T4[order(match(level, c("lo", "md", "hi")), year, ingrowth)], nrows = 200)
cat("\nRD range in the natural scenarios with N2:", round(range(S2[planted == 0, RD]), 2), "; in the fitting frame:", round(range(d$rd), 2), "\n")
cat("\n(5) six 200-year gates of record: without ingrowth, with N1, with N2\n"); print(rbind(cbind(ingrowth = "none", gates6(S0)), cbind(ingrowth = "N1", gates6(S1)), cbind(ingrowth = "N2", gates6(S2))))
# bands from the ingrowth coefficients only
ND <- 300; kk <- which(ok)[seq_len(min(ND, sum(ok)))]; BD <- rbindlist(parallel::mclapply(kk, function(j) cbind(draw = j, run3(i2(BT[j, 2:3]))[planted == 0 & year %in% YR, .(level, year, BA, TPH, QMD, RD)]), mc.cores = 4))
cat("\n(6) N2: 95% range over", length(kk), "bootstrap draws of the ingrowth coefficients (every other equation at its estimates)\n")
print(BD[, .(BA_lo = round(quantile(BA, .025), 1), BA_hi = round(quantile(BA, .975), 1), TPH_lo = round(quantile(TPH, .025)), TPH_hi = round(quantile(TPH, .975)), RD_lo = round(quantile(RD, .025), 2), RD_hi = round(quantile(RD, .975), 2)), by = .(level, year)][order(match(level, c("lo", "md", "hi")), year)])
g2 <- gates6(S2); a <- HO[form == "N2", deviance] < HO[form == "N1", deviance]; b <- coef(F$N2)[[2]] < 0 && quantile(BT[ok, 3], 0.975) < 0; cc <- all(unlist(g2))
cat("\n(7) rule: (a) held-out deviance below N1:", a, "; (b) n1 negative with the upper limit below zero:", b, "; (c) gates pass with N2:", cc, "\nN2 enters the natural scenarios:", a && b && cc, "\n")
saveRDS(list(d = d[, .(rd, ba, ba_all, y, yrs, fold)], F = lapply(F, coef), BT = BT, HO = HO, T4 = T4, BD = BD, S0 = S0, S1 = S1, S2 = S2, adopt = a && b && cc), "out/ingrowth_47.rds"); cat("done\n")
