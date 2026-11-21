# 68_bakuzis_full_1150.R  Full modified Bakuzis assessment (Leary 1997) of the koa 1.15.0 system as released (release_v1150): 2 origins x 5 BYI levels
# (5th, 10th, 50th, 90th, 95th percentile of each origin's plots) x 4 starting densities, 200 annual steps from the two measured starting lists,
# natural runs with QMD ingrowth as published and without as a check. Writes long trajectories for bakuzis_check.R and bakuzis_matrix.R, and the
# site and competition sensitivity tests, tree-level response grid and magnitude checks against the observed plot distribution. No identifier printed.
suppressMessages(library(data.table)); setwd("~/jobs/koa_1150_20261121"); dir.create("bakuzis_1150", showWarnings = FALSE)
L51 <- readLines("scripts/51_j1_items.R"); eval(parse(text = L51[1:grep("^SC <- CJ", L51)]))
e <- new.env(); sys.source("release_v1150/koa_step_rdbyi.R", e); cf <- e$koa_read_coef("release_v1150/koa_rdbyi_equations.csv")
bq <- unique(tr[, .(pid, planted, BYI)])[, .(p05 = quantile(BYI, .05), p10 = quantile(BYI, .10), p50 = quantile(BYI, .5), p90 = quantile(BYI, .9), p95 = quantile(BYI, .95)), by = planted]
cat("BYI levels by origin (5th, 10th, 50th, 90th, 95th percentile of plots):\n"); print(bq)
DEN <- list(`0` = c(500, 1000, 2000, 4000), `1` = c(300, 600, 1200, 2400))
run1 <- function(L, byi, pl, n0, ing, years = 200) {
  dbh <- L$DBH; ht <- L$HT; expf <- L$EXPF_c * n0 / sum(L$EXPF_c); sdm <- e$koa_sdimax(byi, pl, cf); out <- vector("list", years + 1); dead <- 0
  for (y in 0:years) { s <- e$koa_stand(dbh, ht, expf); bal <- e$koa_bal(dbh, s$ba); hcb <- e$koa_hcb(dbh, ht, bal, s$BA, cf); w <- s$ba / s$BA
    out[[y + 1]] <- data.table(age = y, BAPH = s$BA, TPH = s$TPH, QMD = s$QMD, SDI = s$SDI, RD = s$SDI / sdm, HT = s$HT, CR = sum(w * (1 - hcb / ht)), HD = sum(w * ht / (dbh / 100)), MORT = dead)
    if (y < years) { z <- e$koa_step(dbh, ht, expf, byi, pl, cf, sdm, "E5"); dead <- sum(expf - z$expf) / sum(expf); dbh <- z$dbh; ht <- z$ht; expf <- z$expf
      if (ing) { ni <- e$koa_ingrowth(z$qmd, cf); if (is.finite(ni) && ni > 0) { dbh <- c(dbh, 12.7); ht <- c(ht, e$koa_height(12.7, byi, cf)); expf <- c(expf, ni) } } } }
  rbindlist(out)[, VOL := 0.40 * BAPH * HT][] }
G <- CJ(planted = c(0, 1), lev = c("p05", "p10", "p50", "p90", "p95"), di = 1:4, ing = c(TRUE, FALSE))[!(planted == 1 & ing == TRUE)]
G[, byi := mapply(function(p, l) bq[planted == p][[l]], planted, lev)]; G[, n0 := mapply(function(p, i) DEN[[as.character(p)]][i], planted, di)]
TR <- rbindlist(parallel::mclapply(seq_len(nrow(G)), function(i) { g <- G[i]; L <- getL(g$planted); cbind(g, run1(L, g$byi, g$planted, g$n0, g$ing)) }, mc.cores = as.integer(Sys.getenv("KOA_CORES", "4"))))
TR[, origin := fifelse(planted == 1, "planted", "natural")]; TR[, site := match(lev, c("p05", "p10", "p50", "p90", "p95"))]
pub <- TR[ing == (planted == 0)]
fwrite(TR, "bakuzis_1150/trajectories_all.csv")
for (o in c("natural", "planted")) for (d in 1:4) fwrite(pub[origin == o & di == d, .(site, origin, age, HT, TPH, BAPH, QMD, VOL)], sprintf("bakuzis_1150/traj_%s_d%d.csv", o, d))
fwrite(pub[di == 2, .(site, origin, age, HT, TPH, BAPH, QMD, VOL)], "bakuzis_1150/traj_ref_density.csv")
# ---- observed distribution ----
obs <- tr[Status == "live" & !is.na(DBH) & DBH > 0, .(BA = sum(0.00007854 * DBH^2 * EXPF_c), N = sum(EXPF_c)), by = .(pid, Measure, planted)][, QMD := sqrt(BA / N / 0.00007854)][, SDI := N * (QMD / 25.4)^1.605]
OQ <- obs[, .(n = .N, BA99 = quantile(BA, .99), BA999 = quantile(BA, .999), BAobs_max = max(BA), SDI99 = quantile(SDI, .99), SDI999 = quantile(SDI, .999), SDImax_obs = max(SDI)), by = planted]
cat("\nobserved plot visits (live koa): 99th and 99.9th percentiles of basal area and SDI\n"); print(OQ, digits = 4)
MX <- pub[, .(BAmax = max(BAPH), SDImax = max(SDI), RDmax = max(RD), HTmax = max(HT), QMD200 = QMD[age == 200]), by = .(origin, planted, lev, n0)]
MX <- merge(MX, OQ, by = "planted"); MX[, `:=`(ba_above_999 = BAmax > BA999, sdi_above_999 = SDImax > SDI999)]
cat("\nprojected maxima against the observed tail (published configuration):\n"); print(MX[, .(origin, lev, n0, BAmax = round(BAmax, 1), BA999 = round(BA999, 1), SDImax = round(SDImax), SDI999 = round(SDI999), RDmax = round(RDmax, 2), ba_above_999, sdi_above_999)])
# ---- site sensitivity: ordering by BYI at each age, each origin x density ----
ordv <- function(x) all(diff(x) >= -1e-6)
SO <- pub[age %in% c(5, 10, 20, 40, 60, 100, 150, 200)][order(site), .(HT = ordv(HT), QMD = ordv(QMD), BA = ordv(BAPH), VOL = ordv(VOL)), by = .(origin, n0, age)]
cat("\nsite ordering (better BYI not below poorer BYI) by age; share of origin x density x age cells that hold:\n"); print(SO[, lapply(.SD, mean), by = origin, .SDcols = c("HT", "QMD", "BA", "VOL")])
cat("first age at which each variable leaves site order (published, reference density):\n")
fo <- function(v) pub[di == 2][order(site), .(ok = ordv(get(v))), by = .(origin, age)][ok == FALSE, .(first = min(age)), by = origin]
for (v in c("HT", "QMD", "BAPH", "VOL", "TPH")) { f <- fo(v); cat(" ", v, ":", if (nrow(f)) paste(f$origin, f$first, collapse = "; ") else "none", "\n") }
MAI <- pub[age >= 5, .(mai_peak = age[which.max(VOL / age)], mai_max = max(VOL / age), ba_peak = age[which.max(BAPH)]), by = .(origin, lev, site, n0)]
cat("\nculmination of mean annual volume increment (assumed volume) and age of peak basal area:\n"); print(dcast(MAI, origin + n0 ~ site, value.var = "mai_peak")); print(dcast(MAI, origin + n0 ~ site, value.var = "ba_peak"))
cat("better sites culminate no later (share of origin x density rows): ", MAI[order(site), .(ok = all(diff(mai_peak) <= 0)), by = .(origin, n0)][, mean(ok)], "\n")
# ---- competition sensitivity: density series at each origin x site ----
CS <- pub[age %in% c(10, 20, 40, 100, 200)][order(n0), .(qmd_falls_with_density = all(diff(QMD) <= 1e-6), ba_rises_with_density = all(diff(BAPH) >= -1e-6), tph_rises = all(diff(TPH) >= -1e-6)), by = .(origin, site, age)]
cat("\ncompetition: share of origin x site cells where QMD falls, BA rises and stems rise with starting density, by age\n"); print(CS[, lapply(.SD, mean), by = .(origin, age), .SDcols = 4:6])
CV <- pub[age %in% c(10, 20, 40, 100, 200), .(cv_BA = sd(BAPH) / mean(BAPH), cv_TPH = sd(TPH) / mean(TPH), cv_VOL = sd(VOL) / mean(VOL)), by = .(origin, site, age)]
cat("convergence across starting densities (coefficient of variation; constant final yield expects BA and VOL CV to shrink with age):\n"); print(dcast(CV, origin + site ~ age, value.var = "cv_BA"), digits = 3); print(dcast(CV, origin + site ~ age, value.var = "cv_TPH"), digits = 3)
MR <- pub[age %in% 1:10, .(mort = mean(MORT)), by = .(origin, site, n0)]
cat("mean annual mortality rate, years 1 to 10, by starting density (should rise with density):\n"); print(dcast(MR, origin + site ~ n0, value.var = "mort"), digits = 3)
cat("share of origin x site rows where early mortality rises with density: ", MR[order(n0), .(ok = all(diff(mort) >= -1e-9)), by = .(origin, site)][, mean(ok)], "\n")
# ---- Sukachev, Reineke, Eichhorn summaries ----
SK <- pub[age %in% c(40, 100, 200)][order(site), .(ratio_max = max(TPH[-1] / TPH[-.N])), by = .(origin, n0, age)]
cat("\nSukachev: largest ratio of stems at a higher BYI level to the next lower level (gate 1.02):\n"); print(dcast(SK, origin + n0 ~ age, value.var = "ratio_max"), digits = 3)
RE <- pub[, { k <- which(TPH < max(TPH) * 0.95 & age >= 1 & c(0, diff(QMD)) >= 0.10); if (length(k) >= 10) { f <- lm(log(TPH[k]) ~ log(QMD[k])); .(slope = coef(f)[2], n = length(k)) } else .(slope = NA_real_, n = length(k)) }, by = .(origin, site, n0)]
cat("Reineke slope of ln(stems) on ln(QMD) over the self-thinning years (QMD growth at least 0.10 cm per year, stems below 95% of start); evaluated", RE[!is.na(slope), .N], "of", nrow(RE), "\n"); print(RE[, .(min = min(slope, na.rm = TRUE), median = median(slope, na.rm = TRUE), max = max(slope, na.rm = TRUE), not_eval = sum(is.na(slope))), by = .(origin, n0)], digits = 3)
EI <- pub[, .(HTb = round(HT)), by = .(origin, site, n0, VOL, age)][, .(VOL = mean(VOL)), by = .(origin, n0, site, HTb)][, .(cv = sd(VOL) / mean(VOL), nsite = .N), by = .(origin, n0, HTb)][nsite >= 3]
cat("Eichhorn: coefficient of variation of volume across BYI levels at matched mean height (1 m bins, bins with 3 or more sites): median by origin x density\n"); print(EI[, .(median_cv = median(cv), max_cv = max(cv), bins = .N), by = .(origin, n0)], digits = 3)
# ---- long-term bounds ----
cat("\nlong-term bounds (published configuration, all 40 runs): crown ratio range", round(range(pub$CR), 2), "; height to diameter ratio range", round(range(pub$HD)), "; final stems range", round(range(pub[age == 200]$TPH)), "; BA at 200 as share of peak", round(range(pub[, .(r = BAPH[age == 200] / max(BAPH)), by = .(origin, lev, n0)]$r), 2), "\n")
# ---- tree-level response grid (one tree, the other inputs at their medians) ----
grid <- CJ(planted = c(0, 1), byi = c(100, 200, 300, 400, 500), x = c(0, 0.1, 0.3, 0.6), dbh = c(10, 30), rd = c(0.3, 0.6, 1.0), bal = c(0, 15))
grid[, dD := exp(cf$e4[["b0"]] + cf$e4[["ls"]] * log(dbh + 1) + cf$e4[["s"]] * dbh + cf$e4[["xrd"]] * x + cf$e4[["lbyi"]] * log(byi) + cf$e4[["pl"]] * planted)]
grid[, pm := 1 - exp(-exp(cf$e6[["(Intercept)"]] + cf$e6[["ld"]] * log(dbh + 1) + cf$e6[["dbh_m"]] * dbh + cf$e6[["dbh_m2"]] * dbh^2 + cf$e6[["BAL"]] * bal + cf$e6[["lrd"]] * log(rd) + cf$e6[["lbyi"]] * log(byi) + cf$e6[["planted"]] * planted))]
cat("\ntree-level responses: diameter increment (cm/yr) of a 30 cm tree by BYI and competition x = (BAL/BA) x RD; annual mortality probability by RD at BYI 300\n")
print(dcast(unique(grid[dbh == 30, .(planted, byi, x, dD)]), planted + byi ~ x, value.var = "dD"), digits = 3)
print(dcast(unique(grid[dbh == 30 & byi == 300, .(planted, bal, rd, pm)]), planted + bal ~ rd, value.var = "pm"), digits = 3)
print(dcast(unique(grid[dbh == 30 & rd == 0.6 & bal == 0, .(planted, byi, pm)]), planted ~ byi, value.var = "pm"), digits = 3)
saveRDS(list(G = G, OQ = OQ, MX = MX, SO = SO, MAI = MAI, CS = CS, CV = CV, MR = MR, SK = SK, RE = RE, EI = EI, grid = grid), "bakuzis_1150/bakuzis_68.rds"); cat("68 done\n")
