# patch_51.py  Builds scripts/51_j1_items.R from scripts/39_b2_items.R by exact, counted replacements (run on firebreather in the job folder).
s = open('scripts/39_b2_items.R').read()
def rep(a, b, n=1):
    global s
    assert s.count(a) == n, (a[:60], s.count(a)); s = s.replace(a, b)
head = ("# 51_j1_items.R  Script 39_b2_items.R with three changes decided by Aaron on November 15, 2026: (i) the height increment equation is J1 of script 44\n"
        "# (PREREG section 8: joint fit with the height curve, adopted by rule); (ii) the height curve is the joint curve of J1, with BYI on the asymptote, wherever a\n"
        "# height is filled in; (iii) the natural scenarios carry two-stage ingrowth with QMD (PREREG section 13, script 50), with its bootstrap in the bands.\n"
        "# Planted scenarios, the benchmark, coverage and gates for basal area, stems, QMD and RD must reproduce script 39. The figure block of script 39 is not run here.\n"
        "# Outputs go to ms_v136 and to out/*_j1.csv.\n")
s = head + s
rep('ms_v134b', 'ms_v136', s.count('ms_v134b')); rep('_b2.csv', '_j1.csv', s.count('_b2.csv'))
rep('thB <- readRDS("out/height_increment_33b.rds")$FH$B2$th;', 'thB <- readRDS("out/height_increment_44.rds")$FF$J1$th; kh3 <- function(d, byi) 1.37 + (exp(thB[[1]] + thB[[2]] * log(byi)) - 1.37) * (1 - exp(-exp(thB[[7]]) * d))^exp(thB[[8]])\n'
    'IB <- readRDS("out/ingrowth_50.rds"); IBT <- IB$BT[IB$BT[, 4] == 1 & complete.cases(IB$BT), 1:3, drop = FALSE]; irate <- function(b, mu2, q) (1 - exp(-9 * exp(b[[1]] + b[[2]] * q))) * mu2 * 59.5 / 9\n'
    'IG <- function(pl) if (pl == 0) function(q) irate(IB$b, IB$mu2, q) else NULL; IGd <- function() { k <- IBT[sample(nrow(IBT), 1), ]; function(q) irate(k[1:2], k[[3]], q) }; cat("ingrowth bootstrap rows:", nrow(IBT), "\\n")\n')
rep('cat("B2:", round(thB, 5), "\\n")', 'cat("J1:", round(thB, 5), "\\n")')
rep('sig = 0, dl = 0, ph = 1) { out <- matrix', 'sig = 0, dl = 0, ph = 1, ing = NULL) { out <- matrix')
rep('dbh <- dbh + g; ex <- ex * (1 - pm) }', 'dbh <- dbh + g; ex <- ex * (1 - pm); if (!is.null(ing)) { ni <- ing(s$QMD); if (is.finite(ni) && ni > 0) { dbh <- c(dbh, 12.7); ht <- c(ht, kh3(12.7, byi)); ex <- c(ex, ni) } } }')
rep('simx(dbh, ht, ex, byi, pl, years, q$sm, q$bg, q$bm, q$R, FT$sigma, FT$delta, q$ph) }', 'simx(dbh, ht, ex, byi, pl, years, q$sm, q$bg, q$bm, q$R, FT$sigma, FT$delta, q$ph, ing = if (pl == 0) IGd() else NULL) }')
rep('HT := koa_height(DBH, cf)]', 'HT := kh3(DBH, BYI)]', 2)
rep('simx(L$DBH, L$HT, L$EXPF_c, SC$byi[i], SC$planted[i], 200, SC$sdimax[i])', 'simx(L$DBH, L$HT, L$EXPF_c, SC$byi[i], SC$planted[i], 200, SC$sdimax[i], ing = IG(SC$planted[i]))')
rep('simx(L$DBH, L$HT, L$EXPF_c, SC$byi[i], SC$planted[i], 100, SC$sdimax[i])', 'simx(L$DBH, L$HT, L$EXPF_c, SC$byi[i], SC$planted[i], 100, SC$sdimax[i], ing = IG(SC$planted[i]))')
a = s.index('# ---- (5) figures ----'); b = s.index('# ---- (6) workbook grid ----')
extra = ('# ---- bracket on ingrowth for the supplement: natural scenarios without ingrowth and with the constant rate ----\n'
         'N1c <- 10 / (432 / 59.5); BR <- rbindlist(lapply(list(none = NULL, constant = function(q) N1c, QMD = IG(0)), function(ig) rbindlist(lapply(which(SC$planted == 0), function(i) { L <- getL(0); cbind(level = SC$level[i], byi = SC$byi[i], year = 0:200, as.data.table(simx(L$DBH, L$HT, L$EXPF_c, SC$byi[i], 0, 200, SC$sdimax[i], ing = ig))) }))), idcol = "ingrowth")\n'
         'cat("\\ningrowth bracket, natural scenarios (deterministic):\\n"); print(BR[year %in% c(20, 40, 100, 200), .(ingrowth, level, byi = round(byi), year, BA = round(BA, 1), TPH = round(TPH), QMD = round(QMD, 1), RD = round(RD, 2), HT = round(HT, 1), VOL = round(VOL))][order(match(level, c("lo", "md", "hi")), year, ingrowth)], nrows = 100); fwrite(BR, "out/ingrowth_bracket_j1.csv")\n'
         'cat("\\n200-year basal-area-weighted height by scenario (J1, joint curve):\\n"); print(S[year %in% c(100, 200), .(planted, level, year, HT = round(HT, 1), VOL = round(VOL))])\n')
s = s[:a] + extra + s[b:]
rep('h0 <- koa_height(d0, cf);', 'h0 <- kh3(d0, 340);'); rep('simx(d0, h0, L$EXPF_c', 'simx(d0, kh3(d0, SITES[[s]]), L$EXPF_c')
rep('cat("\\n23t done\\n")', 'cat("\\n51 done\\n")')
assert 'koa_height(' not in s.split('# 23t_rdbyi_items.R')[1].replace('koa_height(D', 'X'), [l[:80] for l in s.split('\n') if 'koa_height(' in l]
open('scripts/51_j1_items.R', 'w').write(s); print('written', len(s.split('\n')), 'lines')
