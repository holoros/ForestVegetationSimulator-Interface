# 83b_bakuzis_lists.R  koa v142, red team A3: is the planted Bakuzis outcome a property of the starting list? Reruns the planted part of the
# modified Bakuzis matrix of script 68 (5 BYI levels x 4 starting densities, 200 annual steps, released v142 equations) on every candidate planted
# list: the list of record (rule 1.1 of script 51), the earlier rule (visit nearest the 25th percentile of QMD among visits with 10 or more trees),
# and every other planted visit with 30 or more live trees. Reports, per list, the spacing response of QMD to starting density, the Sukachev ratio,
# the Reineke slope, site-order inversions, and height to diameter ratio at year 100. Writes only to bakuzis_142_lists/. No identifier printed.
suppressMessages(library(data.table)); setwd("~/jobs/koa_1150_20261121"); dir.create("bakuzis_142_lists", showWarnings = FALSE)
L68 <- readLines("scripts/68_bakuzis_full_1150.R"); eval(parse(text = L68[1:(grep("^G <- CJ", L68) - 1)]))
vp <- tr[Status == "live" & !is.na(DBH) & DBH > 0 & planted == 1, .(n = .N, N = sum(EXPF_c), q = sqrt(sum(DBH^2 * EXPF_c) / sum(EXPF_c))), by = .(pid, Measure, planted)][n >= 30]
old <- vis[planted == 1][which.min(abs(q - quantile(q, 0.25)))]
LS <- unique(rbind(cbind(list = "record", pick[planted == 1, .(pid, Measure)]), cbind(list = "earlier rule", old[, .(pid, Measure)]), cbind(list = "candidate", vp[, .(pid, Measure)])), by = c("pid", "Measure"))
LS[, id := sprintf("L%02d", .I)]; LS[, `:=`(n = mapply(function(p, m) tr[pid == p & Measure == m & Status == "live" & !is.na(DBH) & DBH > 0, .N], pid, Measure),
  qmd = mapply(function(p, m) tr[pid == p & Measure == m & Status == "live" & !is.na(DBH) & DBH > 0, sqrt(sum(DBH^2 * EXPF_c) / sum(EXPF_c))], pid, Measure),
  N = mapply(function(p, m) tr[pid == p & Measure == m & Status == "live" & !is.na(DBH) & DBH > 0, sum(EXPF_c)], pid, Measure))]
cat("planted lists:", nrow(LS), "\n"); print(LS[, .(id, list, trees = n, qmd = round(qmd, 1), stems_ha = round(N))])
getLv <- function(p, m) { L <- tr[pid == p & Measure == m & Status == "live" & !is.na(DBH) & DBH > 0]; L[is.na(HT) | HT < 1.37, HT := kh3(DBH, BYI)]; L }
G <- CJ(id = LS$id, lev = c("p05", "p10", "p50", "p90", "p95"), di = 1:4); G[, byi := sapply(lev, function(l) bq[planted == 1][[l]])]; G[, n0 := DEN[["1"]][di]]
TR <- rbindlist(parallel::mclapply(seq_len(nrow(G)), function(i) { g <- G[i]; ls <- LS[id == g$id]; cbind(g, run1(getLv(ls$pid, ls$Measure), g$byi, 1, g$n0, FALSE)) }, mc.cores = as.integer(Sys.getenv("KOA_CORES", "4"))))
TR[, site := match(lev, c("p05", "p10", "p50", "p90", "p95"))]; fwrite(TR, "bakuzis_142_lists/trajectories_planted_lists.csv")
yrs <- c(10, 20, 40, 100, 200); rn <- function(x, nm) { setnames(x, nm); x }
SP <- TR[lev == "p50" & age %in% yrs, .(rho_qmd_n0 = cor(QMD, n0, method = "spearman"), qmd_hi_over_lo = QMD[n0 == max(n0)] / QMD[n0 == min(n0)]), by = .(id, age)]
SK <- TR[age == 40, .(sukachev = TPH[lev == "p95"] / TPH[lev == "p05"]), by = .(id, di)]
RE <- TR[, { m <- c(NA, -diff(TPH)) > 0.001 * TPH; k <- which(m & age >= 1); if (length(k) >= 10) .(slope = coef(lm(log(TPH[k]) ~ log(QMD[k])))[[2]], years = length(k)) else .(slope = NA_real_, years = length(k)) }, by = .(id, lev, di)]
SO <- TR[age >= 1, { w <- dcast(.SD, age + di ~ site, value.var = c("BAPH", "VOL")); .(ba_inv = sum(w$BAPH_1 > w$BAPH_5 + 1e-9), vol_inv = sum(w$VOL_1 > w$VOL_5 + 1e-9)) }, by = id]
HD <- TR[age == 100, .(hd100_min = min(HD), hd100_max = max(HD), qmd100_max = max(QMD), ht100 = max(HT)), by = id]
OUT <- Reduce(function(a, b) merge(a, b, by = "id"), list(LS[, .(id, list, trees = n, qmd0 = round(qmd, 1), stems0 = round(N))],
  rn(dcast(SP, id ~ age, value.var = "rho_qmd_n0"), c("id", paste0("rho_y", yrs))), rn(dcast(SP, id ~ age, value.var = "qmd_hi_over_lo"), c("id", paste0("q2400_q300_y", yrs))),
  SK[, .(sukachev_max = max(sukachev), sukachev_min = min(sukachev)), by = id], RE[, .(reineke_min = min(slope, na.rm = TRUE), reineke_max = max(slope, na.rm = TRUE), reineke_na = sum(is.na(slope))), by = id], SO, HD))
fwrite(OUT, "bakuzis_142_lists/bakuzis_lists_summary.csv"); print(OUT, digits = 3)
cat("\nacross all lists: spacing rho at year 100 range", round(range(OUT$rho_y100), 2), "; year 200", round(range(OUT$rho_y200), 2), "; Sukachev max", round(max(OUT$sukachev_max), 3),
  "; Reineke", round(min(OUT$reineke_min, na.rm = TRUE), 2), "to", round(max(OUT$reineke_max, na.rm = TRUE), 2), "; lists with any BA site inversion", sum(OUT$ba_inv > 0), "of", nrow(OUT), "\n"); cat("83b done\n")
