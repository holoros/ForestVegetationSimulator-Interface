# 36_longterm_metrics.R  Crown ratio and height to diameter ratio as long-term assessment metrics (PREREG section 5), after the evaluation of
# individual-tree simulators by emergent properties (Vospernik 2017; Vospernik et al. 2010). 200-year runs of the six scenarios with the height step
# of record (E5 rule) and with the adopted or best tested fitted height increment form; crown base from the form chosen in script 34 (natural FIA trees).
# Reported: basal-area-weighted stand means and the means of the smallest and largest fifth of stems by diameter, beside the ranges in the data.
# Assessment metrics, not adoption gates. No plot or installation identifier is printed.
suppressMessages(library(data.table)); source("~/jobs/koa_final_eq_20261110/scripts/32_common.R")
H <- readRDS("out/height_increment_33b.rds"); CB <- readRDS("out/crown_base_34.rds"); L33 <- readLines("scripts/33b_height_increment_round2.R"); e2 <- function(d) koa_height(d, cf); eval(parse(text = L33[grep("^G <- list", L33):(grep("^PN <- list", L33) - 1)]))
hfn <- function(nm) if (nm == "R0") ht_rule else { th <- H$FH[[nm]]$th; function(Hh, D, D1, x, lbyi, pl) { inc <- G[[nm]](th, pmax(Hh, 0.5), D, D1, x, lbyi, pl); inc[!is.finite(inc)] <- 0; pmin(pmax(inc, -5), 50) } }
forms <- unique(c("R0", if (!is.na(H$pick)) H$pick else H$best)); cat("height forms compared: R0 (E5 rule) and", setdiff(forms, "R0"), if (is.na(H$pick)) "(best tested, not adopted)" else "(adopted)", "; crown base form:", CB$pick, "\n")
hcb <- function(ht, dbh, bal, BA, rd, byi) { z <- data.table(lH = log(ht), dh = dbh / ht, x = bal / max(BA, 1e-6) * rd, lb = log(byi), s1 = sqrt(ht / 100), lhd = log(ht / dbh), sb = sqrt(bal * BA + 1), lba = log(BA + 1), lb100 = log(byi / 100)); tm <- CB$TM[[CB$pick]]
  ht / (1 + exp(as.numeric(cbind(rep(1, length(ht)), if (length(tm)) as.matrix(z[, ..tm])) %*% CB$FC[[CB$pick]]))) }
YK <- c(0, 20, 40, 100, 200)
one <- function(i, nm) { L <- getL(SC$planted[i]); dbh <- L$DBH; ht <- L$HT; ex <- L$EXPF_c; byi <- SC$byi[i]; pl <- SC$planted[i]; sm <- SC$sdimax[i]; hf <- hfn(nm); out <- list()
  for (y in 0:200) { s <- koa_stand(dbh, ht, ex); bal <- koa_bal(dbh, s$ba); rd <- s$SDI / sm
    if (y %in% YK) { hd <- ht / (dbh / 100); cr <- 1 - hcb(ht, dbh, bal, s$BA, rd, byi) / ht; o <- order(dbh); cw <- cumsum(ex[o]) / sum(ex); sm5 <- o[cw <= 0.2 | seq_along(o) == 1]; lg5 <- o[cw > 0.8]; wm <- function(v, ix, w) sum(v[ix] * w[ix]) / sum(w[ix])
      out[[length(out) + 1]] <- data.table(form = nm, planted = pl, level = SC$level[i], year = y, HT = s$HT, QMD = s$QMD, hd = wm(hd, seq_along(hd), s$ba), hd_small = wm(hd, sm5, ex), hd_large = wm(hd, lg5, ex), cr = wm(cr, seq_along(cr), s$ba), cr_small = wm(cr, sm5, ex), cr_large = wm(cr, lg5, ex)) }
    if (y == 200) break; g <- as.numeric(exp(xm(dbh, bal, s$BA, s$SDI, sm, byi, pl) %*% bg)); pm <- mort_tree(dbh, ex, bal, s, rd, byi, pl); ht <- ht + hf(ht, dbh, dbh + g, bal / max(s$BA, 1e-6) * rd, log(byi), pl); dbh <- dbh + g; ex <- ex * (1 - pm) }
  rbindlist(out) }
M <- rbindlist(lapply(forms, function(nm) rbindlist(lapply(seq_len(nrow(SC)), one, nm = nm))))
ob <- tr[Status == "live" & !is.na(HT) & HT >= 1.37 & DBH >= 2.5]; cat("\nobserved height to diameter ratio (m per m), live trees with DBH of 2.5 cm or more: 5th, 50th, 95th percentile\n"); print(ob[, as.list(round(quantile(HT / (DBH / 100), c(.05, .5, .95)))), by = planted]); print(ob[, .(n = .N, hd = round(median(HT / (DBH / 100)))), by = .(planted, dclass = cut(DBH, c(0, 10, 20, 40, 200)))][order(planted, dclass)])
cat("observed crown ratio, 360 FIA trees in natural stands: 5th, 50th, 95th percentile", round(quantile(1 - CB$cv[form == CB$pick, obs / HT], c(.05, .5, .95)), 2), "\n")
cat("\nheight to diameter ratio and crown ratio in the 200-year runs (stand value is basal-area weighted; small and large are the smallest and largest fifth of stems by DBH)\n")
print(M[, .(form, planted, level, year, HT = round(HT, 1), QMD = round(QMD, 1), hd = round(hd), hd_small = round(hd_small), hd_large = round(hd_large), cr = round(cr, 2), cr_small = round(cr_small, 2), cr_large = round(cr_large, 2))][order(form, planted, match(level, c("lo", "md", "hi")), year)])
q <- ob[, .(lo = quantile(HT / (DBH / 100), .05), hi = quantile(HT / (DBH / 100), .95)), by = planted]; crq <- quantile(1 - CB$cv[form == CB$pick, obs / HT], c(.05, .95))
chk <- M[, .(hd_small_above_large = all(hd_small >= hd_large - 1e-9), hd_falls = hd[year == 200] < hd[year == 0], hd_in_range = all(hd >= q[planted == .BY$planted, lo] & hd <= q[planted == .BY$planted, hi]), cr_in_range = all(cr >= crq[1] & cr <= crq[2])), by = .(form, planted, level)]
cat("\nordering and range checks by scenario (data range is the 5th to 95th percentile; crown range is from natural stands only)\n"); print(chk[order(form, planted, match(level, c("lo", "md", "hi")))])
saveRDS(list(M = M, chk = chk), "out/longterm_metrics_36.rds"); fwrite(M, "out/longterm_metrics_36.csv"); cat("done\n")
