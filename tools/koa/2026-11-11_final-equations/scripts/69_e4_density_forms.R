# 69_e4_density_forms.R  PREREG section 10: stand-density term in diameter increment after the Bakuzis assessment (script 68). Forms E4r, D1 (+ r RD),
# D2 (+ r ln RD), D3 (+ r BA), fitted by the estimator of record of script 22t with S1 of record; held out on the folds of record; equivalence;
# density series and six gates with E6r and E5 of record. No identifier printed.
suppressMessages(library(data.table)); setwd("~/jobs/koa_1150_20261121")
L22 <- readLines("scripts/22t_rdbyi_final.R"); eval(parse(text = L22[1:(grep("^G <- fitg", L22) - 1)]))
NC <- as.integer(Sys.getenv("KOA_CORES", "4"))
FORMS <- c("E4r", "D1", "D2", "D3"); base_names <- names(bgs)
mk_xm <- function(FORM) function(S, BAL, BA, SDI, sm, byi, pl) { B <- cbind(1, log(S + 1), S, BAL / pmax(BA, 1e-6) * SDI / sm, log(byi), pl)
  switch(FORM, E4r = B, D1 = cbind(B, SDI / sm), D2 = cbind(B, log(pmax(SDI / sm, 1e-3))), D3 = cbind(B, BA)) }
FIT <- list(); CV <- list()
for (FORM in FORMS) { xm <- mk_xm(FORM); bgs <- if (FORM == "E4r") setNames(bgs[base_names], base_names) else setNames(c(bgs[base_names], 0), c(base_names, "r"))
  G <- fitg(d, bgs); FIT[[FORM]] <- G; cat("\n", FORM, ": convergence", G$conv, " delta", round(G$delta, 4), "\n"); print(round(G$b, 5))
  cv <- rbindlist(parallel::mclapply(sort(unique(d$fold_s)), function(k) { xm <<- mk_xm(FORM); bk <- s1fit(M[fold != k]); trn <- d[fold_s != k]; te <- d[fold_s == k]; smt <- s1p(bk, trn$lbyi, trn$planted); sme <- s1p(bk, te$lbyi, te$planted); b <- fitg(trn, G$b, smt)$b
    te2 <- copy(te); te2[, `:=`(e_BAL = BAL, e_BA_koa = BA_koa, e_SDI_koa = SDI_koa)]; data.table(pid = te$pid, planted = te$planted, obs = (te$S1 - te$S0) / te$yip, pred = (proj(b, te2, sme)$end - te$S0) / te$yip) }, mc.cores = min(NC, 10)))
  eq <- equiv_boot(cv$obs, cv$pred, cv$pid); CV[[FORM]] <- data.table(form = FORM, k = length(G$b), bias = mean(cv$obs - cv$pred), rmse = sqrt(mean((cv$obs - cv$pred)^2)), eq[, .(slope, b1_lo, b1_hi, pass_int, pass_slope)]) }
CVT <- rbindlist(CV); CVT[, rmse_ratio := rmse / CVT[form == "E4r", rmse]]; cat("\nheld-out annual diameter increment (folds of record):\n"); print(CVT, digits = 4)
# ---- projections with E6r and E5 of record ----
L51 <- readLines("scripts/51_j1_items.R"); eval(parse(text = L51[1:grep("^SC <- CJ", L51)]))
e <- new.env(); sys.source("release_v1150/koa_step_rdbyi.R", e); cf <- e$koa_read_coef("release_v1150/koa_rdbyi_equations.csv")
bq <- unique(tr[, .(pid, planted, BYI)])[, .(lo = quantile(BYI, .1), md = quantile(BYI, .5), hi = quantile(BYI, .9)), by = planted]
stepF <- function(b, FORM, dbh, ht, expf, byi, pl, sdm) { s <- e$koa_stand(dbh, ht, expf); bal <- e$koa_bal(dbh, s$ba); rd <- s$SDI / sdm; X <- mk_xm(FORM)(dbh, bal, rep(s$BA, length(dbh)), rep(s$SDI, length(dbh)), sdm, byi, pl)
  dD <- as.vector(exp(X %*% b)); x <- (bal / max(s$BA, 1e-6)) * rd; dH <- e$koa_dht(ht, x, byi, pl, cf); m <- cf$e6
  eta <- m[["(Intercept)"]] + m[["ld"]] * log(dbh + 1) + m[["dbh_m"]] * dbh + m[["dbh_m2"]] * dbh^2 + m[["BAL"]] * bal + m[["lrd"]] * log(max(rd, 0.001)) + m[["lbyi"]] * log(byi) + m[["planted"]] * pl
  list(dbh = dbh + dD, ht = ht + dH, expf = expf * exp(-exp(eta)), qmd = s$QMD) }
projF <- function(b, FORM, L, byi, pl, n0 = NULL, years = 200) { dbh <- L$DBH; ht <- L$HT; expf <- if (is.null(n0)) L$EXPF_c else L$EXPF_c * n0 / sum(L$EXPF_c); sdm <- e$koa_sdimax(byi, pl, cf); out <- vector("list", years + 1)
  for (y in 0:years) { s <- e$koa_stand(dbh, ht, expf); out[[y + 1]] <- c(year = y, BA = s$BA, TPH = s$TPH, QMD = s$QMD, SDI = s$SDI)
    if (y < years) { z <- stepF(b, FORM, dbh, ht, expf, byi, pl, sdm); dbh <- z$dbh; ht <- z$ht; expf <- z$expf
      if (pl == 0) { ni <- e$koa_ingrowth(z$qmd, cf); if (is.finite(ni) && ni > 0) { dbh <- c(dbh, 12.7); ht <- c(ht, e$koa_height(12.7, byi, cf)); expf <- c(expf, ni) } } } }
  as.data.table(do.call(rbind, out)) }
obs <- tr[Status == "live" & !is.na(DBH) & DBH > 0, .(BA = sum(0.00007854 * DBH^2 * EXPF_c), N = sum(EXPF_c)), by = .(pid, Measure, planted)][, QMD := sqrt(BA / N / 0.00007854)][, SDI := N * (QMD / 25.4)^1.605]
OQ <- obs[, .(BA999 = quantile(BA, .999), BAmax = max(BA), SDI99 = quantile(SDI, .99)), by = planted]; BAMAX <- max(obs$BA)
DEN <- list(`0` = c(500, 1000, 2000, 4000), `1` = c(300, 600, 1200, 2400)); INR <- list(`0` = c(500, 1000, 2000), `1` = c(300, 600, 1200))
RES <- list(); TRJ <- list()
for (FORM in FORMS) { b <- FIT[[FORM]]$b
  runs <- CJ(planted = c(0, 1), lev = c("lo", "md", "hi"), n0 = c(NA, 300, 500, 600, 1000, 1200, 2000, 2400, 4000))[is.na(n0) | n0 %in% DEN[[1]] & planted == 0 | n0 %in% DEN[[2]] & planted == 1]
  T <- rbindlist(parallel::mclapply(seq_len(nrow(runs)), function(i) { r <- runs[i]; cbind(r, projF(b, FORM, getL(r$planted), bq[planted == r$planted][[r$lev]], r$planted, if (is.na(r$n0)) NULL else r$n0)) }, mc.cores = NC))
  T[, form := FORM]; TRJ[[FORM]] <- T
  ds <- T[!is.na(n0) & year %in% c(20, 40, 100)][, inr := mapply(function(p, n) n %in% INR[[as.character(p)]], planted, n0)][inr == TRUE][order(n0), .(rise = max(QMD[-1] / QMD[-.N]) - 1), by = .(planted, lev, year)]
  bamax_in <- T[!is.na(n0)][, inr := mapply(function(p, n) n %in% INR[[as.character(p)]], planted, n0)][inr == TRUE, .(ba = max(BA)), by = planted][OQ, on = "planted"]
  R0 <- T[is.na(n0)]; ord <- function(v) all(diff(v) >= -1e-9)
  g1 <- R0[year %in% 1:100, .(ok = ord(BA[match(c("lo", "md", "hi"), lev)]) & ord(QMD[match(c("lo", "md", "hi"), lev)])), by = .(planted, year)][, all(ok)]
  g2 <- all(R0[, .(m = max(SDI)), by = planted][OQ, on = "planted"][, m <= 1.2 * SDI99]); g3 <- R0[year == 200, max(BA)] <= 1.2 * BAMAX
  g4 <- R0[, .(r = SDI[year == 200] / SDI[year == 150]), by = .(planted, lev)][, all(r <= 1.05)]
  g5 <- R0[year %in% c(40, 100)][, .(r = max(TPH[match(c("md", "hi"), lev)] / TPH[match(c("lo", "md"), lev)])), by = .(planted, year)][, all(r <= 1.02)]
  g6 <- T[!is.na(n0) & planted == 1 & lev == "md" & year %in% c(20, 40, 100)][order(n0), .(ok = all(diff(BA) >= -1e-9)), by = year][, all(ok)]
  RES[[FORM]] <- data.table(form = FORM, qmd_rise_max = max(ds$rise), ds_pass = max(ds$rise) <= 0.02, ba_in_range = all(bamax_in$ba <= bamax_in$BA999), site_order = g1, sdi_lim = g2, ba200 = g3, no_rise = g4, sukachev = g5, yield_dens = g6)
  cat("\n", FORM, ": QMD by starting density (lev md) at 20, 40, 100 years\n"); print(dcast(T[!is.na(n0) & lev == "md" & year %in% c(20, 40, 100)], planted + year ~ n0, value.var = "QMD"), digits = 3)
  print(dcast(T[!is.na(n0) & lev == "md" & year %in% c(20, 40, 100)], planted + year ~ n0, value.var = "BA"), digits = 3) }
RT <- merge(CVT, rbindlist(RES), by = "form"); RT[, r_negative := sapply(form, function(f) if (f == "E4r") NA else FIT[[f]]$b[["r"]] < 0)]
RT[, eligible := rmse_ratio <= 1.02 & pass_int & pass_slope & (is.na(r_negative) | r_negative) & ds_pass & ba_in_range & site_order & sdi_lim & ba200 & no_rise & sukachev & yield_dens]
cat("\nrule of PREREG section 10:\n"); print(RT[, .(form, k, rmse = round(rmse, 4), rmse_ratio = round(rmse_ratio, 4), slope = round(slope, 3), pass_int, pass_slope, r_negative, qmd_rise_max = round(qmd_rise_max, 3), ds_pass, ba_in_range, site_order, sdi_lim, ba200, no_rise, sukachev, yield_dens, eligible)])
el <- RT[eligible == TRUE][order(k, rmse)]; cat("adopted:", if (nrow(el)) el$form[1] else "none (E4r stays)", "(rule text of PREREG section 10 addendum: among eligible forms, fewest coefficients first; E4r is one of the listed forms)\n")
saveRDS(list(FIT = FIT, CVT = CVT, RT = RT, TRJ = rbindlist(TRJ)), "out/e4_density_69.rds"); cat("69 done\n")
