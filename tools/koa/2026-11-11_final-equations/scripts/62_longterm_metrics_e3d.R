# 62_longterm_metrics_e3d.R  Script 53 with crown base E3d of koa 1.14.2 (HCB = min(exp(b0 + lH ln HT), 0.98 HT), koa_rdbyi_equations.csv) in place of C5.
# Everything else is unchanged. Writes out/longterm_metrics_62.csv for Table S36.
# 53_longterm_metrics_j1.R  Script 36 with the system of manuscript v136: height increment J1, the joint height curve wherever a height is filled in or the
# fallback rule is applied, and two-stage QMD ingrowth in the natural scenarios.
# 36_longterm_metrics.R  Crown ratio and height to diameter ratio as long-term assessment metrics (PREREG section 5), after the evaluation of
# individual-tree simulators by emergent properties (Vospernik 2017; Vospernik et al. 2010). 200-year runs of the six scenarios with the height step
# of record (E5 rule) and with the adopted or best tested fitted height increment form; crown base from the form chosen in script 34 (natural FIA trees).
# Reported: basal-area-weighted stand means and the means of the smallest and largest fifth of stems by diameter, beside the ranges in the data.
# Assessment metrics, not adoption gates. No plot or installation identifier is printed.
suppressMessages(library(data.table)); source("~/jobs/koa_final_eq_20261110/scripts/32_common.R")
CB <- readRDS("out/crown_base_34.rds"); thB <- readRDS("out/height_increment_44.rds")$FF$J1$th; kh3 <- function(d, byi) 1.37 + (exp(thB[[1]] + thB[[2]] * log(byi)) - 1.37) * (1 - exp(-exp(thB[[7]]) * d))^exp(thB[[8]])
getL <- function(p) { pv <- pick[planted == p]; L <- tr[pid == pv$pid & Measure == pv$Measure & Status == "live" & !is.na(DBH) & DBH > 0]; L[is.na(HT) | HT < 1.37, HT := kh3(DBH, BYI)]; L }
IB <- readRDS("out/ingrowth_50.rds"); irate <- function(q) (1 - exp(-9 * exp(IB$b[[1]] + IB$b[[2]] * q))) * IB$mu2 * 59.5 / 9
hfn <- function(nm) if (nm == "R0") function(Hh, D, D1, x, lbyi, pl) kh3(D1, exp(lbyi)) - kh3(D, exp(lbyi)) else function(Hh, D, D1, x, lbyi, pl) { Hh <- pmax(Hh, 0.5); A. <- exp(thB[[1]] + thB[[2]] * lbyi); cc <- exp(thB[[4]]); inc <- pmax(cc * exp(thB[[3]] + thB[[6]] * pl) * Hh * ((A. / Hh)^(1 / cc) - 1), 0) * exp(thB[[5]] * x); inc[!is.finite(inc)] <- 0; inc }
forms <- c("R0", "J1"); cat("height forms compared: R0 (fallback rule with the joint curve) and J1 (adopted); crown base form: E3d", "; natural scenarios with QMD ingrowth\n")
hcb <- function(ht, dbh, bal, BA, rd, byi) pmin(exp(-1.49852188060747 + 1.07812413578363 * log(ht)), 0.98 * ht)
YK <- c(0, 20, 40, 100, 200)
one <- function(i, nm) { L <- getL(SC$planted[i]); dbh <- L$DBH; ht <- L$HT; ex <- L$EXPF_c; byi <- SC$byi[i]; pl <- SC$planted[i]; sm <- SC$sdimax[i]; hf <- hfn(nm); out <- list()
  for (y in 0:200) { s <- koa_stand(dbh, ht, ex); bal <- koa_bal(dbh, s$ba); rd <- s$SDI / sm
    if (y %in% YK) { hd <- ht / (dbh / 100); cr <- 1 - hcb(ht, dbh, bal, s$BA, rd, byi) / ht; o <- order(dbh); cw <- cumsum(ex[o]) / sum(ex); sm5 <- o[cw <= 0.2 | seq_along(o) == 1]; lg5 <- o[cw > 0.8]; wm <- function(v, ix, w) sum(v[ix] * w[ix]) / sum(w[ix])
      out[[length(out) + 1]] <- data.table(form = nm, planted = pl, level = SC$level[i], year = y, HT = s$HT, QMD = s$QMD, hd = wm(hd, seq_along(hd), s$ba), hd_small = wm(hd, sm5, ex), hd_large = wm(hd, lg5, ex), cr = wm(cr, seq_along(cr), s$ba), cr_small = wm(cr, sm5, ex), cr_large = wm(cr, lg5, ex)) }
    if (y == 200) break; g <- as.numeric(exp(xm(dbh, bal, s$BA, s$SDI, sm, byi, pl) %*% bg)); pm <- mort_tree(dbh, ex, bal, s, rd, byi, pl); ht <- ht + hf(ht, dbh, dbh + g, bal / max(s$BA, 1e-6) * rd, log(byi), pl); dbh <- dbh + g; ex <- ex * (1 - pm); if (pl == 0) { ni <- irate(s$QMD); if (is.finite(ni) && ni > 0) { dbh <- c(dbh, 12.7); ht <- c(ht, kh3(12.7, byi)); ex <- c(ex, ni) } } }
  rbindlist(out) }
M <- rbindlist(lapply(forms, function(nm) rbindlist(lapply(seq_len(nrow(SC)), one, nm = nm))))
ob <- tr[Status == "live" & !is.na(HT) & HT >= 1.37 & DBH >= 2.5]; cat("\nobserved height to diameter ratio (m per m), live trees with DBH of 2.5 cm or more: 5th, 50th, 95th percentile\n"); print(ob[, as.list(round(quantile(HT / (DBH / 100), c(.05, .5, .95)))), by = planted]); print(ob[, .(n = .N, hd = round(median(HT / (DBH / 100)))), by = .(planted, dclass = cut(DBH, c(0, 10, 20, 40, 200)))][order(planted, dclass)])
cat("observed crown ratio, 360 FIA trees in natural stands: 5th, 50th, 95th percentile", round(quantile(1 - CB$cv[form == CB$pick, obs / HT], c(.05, .5, .95)), 2), "\n")
cat("\nheight to diameter ratio and crown ratio in the 200-year runs (stand value is basal-area weighted; small and large are the smallest and largest fifth of stems by DBH)\n")
print(M[, .(form, planted, level, year, HT = round(HT, 1), QMD = round(QMD, 1), hd = round(hd), hd_small = round(hd_small), hd_large = round(hd_large), cr = round(cr, 2), cr_small = round(cr_small, 2), cr_large = round(cr_large, 2))][order(form, planted, match(level, c("lo", "md", "hi")), year)])
q <- ob[, .(lo = quantile(HT / (DBH / 100), .05), hi = quantile(HT / (DBH / 100), .95)), by = planted]; crq <- quantile(1 - CB$cv[form == CB$pick, obs / HT], c(.05, .95))
chk <- M[, .(hd_small_above_large = all(hd_small >= hd_large - 1e-9), hd_falls = hd[year == 200] < hd[year == 0], hd_in_range = all(hd >= q[planted == .BY$planted, lo] & hd <= q[planted == .BY$planted, hi]), cr_in_range = all(cr >= crq[1] & cr <= crq[2])), by = .(form, planted, level)]
cat("\nordering and range checks by scenario (data range is the 5th to 95th percentile; crown range is from natural stands only)\n"); print(chk[order(form, planted, match(level, c("lo", "md", "hi")))])
saveRDS(list(M = M, chk = chk), "out/longterm_metrics_62.rds"); fwrite(M, "out/longterm_metrics_62.csv"); cat("done\n")
