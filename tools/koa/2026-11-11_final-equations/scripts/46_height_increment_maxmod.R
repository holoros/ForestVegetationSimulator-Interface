# 46_height_increment_maxmod.R  Maximum times modifier forms M1 and M2 (section 9 of 2026-11-14_koa-height-crown-standmort_PREREG.md), suggested by Aaron on
# November 15, 2026: the maximum height increment is set by height and BYI (upper-quantile fit of a bounded form), then a modifier of competition and origin is
# fitted with the maximum fixed. Same frame, folds, tests and conditions as script 44, whose definitions and test code are reused. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_1150_20261121/scripts/42_height_increment_round3.R"); k <- grep("^fith <- ", L); eval(parse(text = L[5:(k + 3)]))
# ---- definitions start ----
suppressMessages(library(quantreg)); NC <- as.integer(Sys.getenv("KOA_CORES", "4"))
hd <- copy(f$hd); hd[, `:=`(pid = as.character(pid), lbyi = log(BYI), inst = paste(Data, Install))]
e2b <- cf$e2[["b"]]; e2c <- cf$e2[["c"]]; D80 <- -log(1 - 0.8^(1 / e2c)) / e2b; hd[, Aimp := 1.37 + (HT - 1.37) / (1 - exp(-e2b * DBH))^e2c]
anchor <- function(hx, tau) { d <- hd[hx][DBH >= D80]; unname(suppressWarnings(coef(rq(log(Aimp) ~ lbyi, tau = tau, data = d)))) }
b2 <- unname(readRDS("out/height_increment_42.rds")$FH$B2$th)                                   # a0, a_lbyi, lk, lc, x, k_pl
gA <- function(q) function(th, H, D, D1, x, lb, pl) bnd(exp(q[1] + q[2] * lb), exp(th[1] + th[4] * pl), exp(th[2]), H) * exp(th[3] * x)   # th = lk, lc, x, k_pl
gJ <- function(th, H, D, D1, x, lb, pl) G$B2(th[1:6], H, D, D1, x, lb, pl)
hJ <- function(th, d) 1.37 + (exp(th[1] + th[2] * d$lbyi) - 1.37) * (1 - exp(-exp(th[7]) * d$DBH))^exp(th[8])
LBR <- range(prs$lbyi); AMAX <- log(1.2 * 34.1); pen1 <- function(b, sw) 1e4 * sw * sum(pmax(0, b[1] + b[2] * LBR - AMAX)^2)
vpow <- function(th, g, ix) { pr <- proj(th, g, ix); r <- prs$H1[ix] - pr$end; dl <- max(0, min(1.5, coef(lm(log(pmax(r^2 / prs$yip[ix], 1e-8)) ~ log(pmax(pr$gbar, 0.01))))[[2]] / 2)); list(dl = dl, w = prs$w0[ix] / (prs$yip[ix] * pmax(pr$gbar, 0.01)^(2 * dl))) }
fitg <- function(g, th, ix = seq_len(n), pen = NULL, passes = 3) { w <- prs$w0[ix] / prs$yip[ix]; dl <- 0; conv <- NA
  for (it in seq_len(passes)) { o <- optim(th, function(b) { v <- sum(w * (prs$H1[ix] - proj(b, g, ix)$end)^2) + (if (is.null(pen)) 0 else pen(b, sum(w))); if (is.finite(v)) v else 1e12 }, method = "BFGS", control = list(maxit = 800, reltol = 1e-10)); th <- o$par; conv <- o$convergence
    v <- vpow(th, g, ix); dl <- v$dl; w <- v$w }
  list(th = th, delta = dl, conv = conv) }
fitJ <- function(th, ix = seq_len(n), hx = seq_len(nrow(hd)), passes = 3) { w <- prs$w0[ix] / prs$yip[ix]; dl <- 0; conv <- NA; dh <- hd[hx]; sw0 <- sum(prs$w0[ix]); s2h <- mean((dh$HT - koa_height(dh$DBH, cf))^2)
  for (it in seq_len(passes)) { s2i <- sum(w * (prs$H1[ix] - proj(th, gJ, ix)$end)^2) / sw0
    o <- optim(th, function(b) { v <- sum(w * (prs$H1[ix] - proj(b, gJ, ix)$end)^2) / s2i + sum((dh$HT - hJ(b, dh))^2) / s2h; if (is.finite(v)) v else 1e12 }, method = "BFGS", control = list(maxit = 800, reltol = 1e-10)); th <- o$par; conv <- o$convergence
    v <- vpow(th, gJ, ix); dl <- v$dl; w <- v$w }
  list(th = th, delta = dl, conv = conv) }
PN4 <- list(R0 = character(0), B2 = PN$B2, P1 = PN$B2, A1 = c("lk", "lc", "x", "k_pl"), A2 = c("lk", "lc", "x", "k_pl"), J1 = c(PN$B2, "ln_b", "ln_c"))
fit_form <- function(nm, ix = seq_len(n), hx = seq_len(nrow(hd)), start = NULL) { ft <- switch(nm,
    R0 = list(th = numeric(0), delta = NA, conv = 0, g = G$R0),
    B2 = { z <- fitg(G$B2, if (is.null(start)) b2 else start, ix); z$g <- G$B2; z },
    P1 = { z <- fitg(G$B2, if (is.null(start)) b2 else start, ix, pen1); z$g <- G$B2; z },
    A1 = , A2 = { q <- anchor(hx, if (nm == "A1") 0.95 else 0.50); g <- gA(q); z <- fitg(g, if (is.null(start)) b2[3:6] else start, ix); z$g <- g; z$q <- q; z },
    J1 = { z <- fitJ(if (is.null(start)) c(b2, log(e2b), log(e2c)) else start, ix, hx); z$g <- gJ; z })
  names(ft$th) <- PN4[[nm]]; ft }
A_of <- function(nm, ft, byi) if (nm %in% c("A1", "A2")) exp(ft$q[1] + ft$q[2] * log(byi)) else if (nm == "R0") NA_real_ else exp(ft$th[[1]] + ft$th[[2]] * log(byi))
BYIM <- c(natural = byiq[planted == 0, md], planted = byiq[planted == 1, md]); FORMS <- c("R0", "B2", "A1", "A2", "P1", "J1")
# ---- definitions end ----
# ---- maximum times modifier ----
gP <- function(th, H, D, D1, x, lb, pl) bnd(exp(th[1] + th[2] * lb), exp(th[3]), exp(th[4]), H)                                   # potential: a0, a_lbyi, lk, lc
gM <- function(q) function(th, H, D, D1, x, lb, pl) bnd(exp(q[1] + q[2] * lb), exp(q[3]), exp(q[4]), H) * exp(th[1] + th[2] * x + th[3] * pl)   # th = g0, g_x, g_pl
potq <- function(ix, tau, st = c(b2[1], b2[2], b2[3] + b2[6], b2[4])) { ob <- function(b) { r <- (prs$H1[ix] - proj(b, gP, ix)$end) / prs$yip[ix]; v <- sum(prs$w0[ix] * r * (tau - (r < 0))); if (is.finite(v)) v else 1e12 }
  o <- list(par = st); for (i in 1:2) o <- optim(o$par, ob, method = "Nelder-Mead", control = list(maxit = 1500, reltol = 1e-8)); list(q = o$par, conv = o$convergence) }
fit_form0 <- fit_form
fit_form <- function(nm, ix = seq_len(n), hx = seq_len(nrow(hd)), start = NULL) { if (!nm %in% c("M1", "M2")) return(fit_form0(nm, ix, hx, start))
  p <- potq(ix, if (nm == "M1") 0.95 else 0.90, if (is.null(start)) c(b2[1], b2[2], b2[3] + b2[6], b2[4]) else start[4:7]); g <- gM(p$q); z <- fitg(g, if (is.null(start)) c(-1, b2[5], 1) else start[1:3], ix)
  z$g <- g; z$q <- p$q; z$qconv <- p$conv; z$th <- c(g0 = z$th[1], g_x = z$th[2], g_pl = z$th[3]); names(z$th) <- c("g0", "g_x", "g_pl"); z }
PN4$M1 <- PN4$M2 <- c("g0", "g_x", "g_pl"); FORMS <- c("R0", "M1", "M2")
A_of <- function(nm, ft, byi) if (nm == "R0") NA_real_ else exp(ft$q[1] + ft$q[2] * log(byi))
start_of <- function(ft) c(unname(ft$th), ft$q)
cat("\nstage 1 frame: trees with DBH >=", round(D80, 1), "cm:", hd[DBH >= D80, .N], "on", hd[DBH >= D80, uniqueN(pid)], "plots; median BYI natural", round(BYIM[[1]], 1), "planted", round(BYIM[[2]], 1), "\n")
FF <- parallel::mclapply(FORMS, fit_form, mc.cores = NC); names(FF) <- FORMS; stopifnot(!any(sapply(FF, inherits, "try-error")))
cat("\n(1) full-frame fits\n"); for (nm in FORMS) { ft <- FF[[nm]]; pr <- proj(ft$th, ft$g); cat("\n", nm, " convergence", ft$conv, " delta", round(ft$delta, 3), " mean observed - predicted (m/yr)", round(mean((prs$H1 - pr$end) / prs$yip), 4), "\n"); if (length(ft$th)) print(round(ft$th, 5))
  if (!is.null(ft$q)) { cat("  stage 1 (maximum): a0", round(ft$q[1], 4), " a_lbyi", round(ft$q[2], 4), " lk", round(ft$q[3], 4), " lc", round(ft$q[4], 4), " convergence", ft$qconv, "\n"); md <- exp(ft$th[[1]] + ft$th[[2]] * Xm + ft$th[[3]] * prs$planted); cat("  modifier in the fitting frame: median", round(median(md, na.rm = TRUE), 3), " 95th percentile", round(quantile(md, 0.95, na.rm = TRUE), 3), " max", round(max(md, na.rm = TRUE), 3), "\n") }; if (nm != "R0") cat("  asymptote (m) at median BYI: natural", round(A_of(nm, ft, BYIM[[1]]), 2), " planted", round(A_of(nm, ft, BYIM[[2]]), 2), "\n") }
# (2) installations held out
jobs <- CJ(form = FORMS, fold = sort(unique(prs$fold)), sorted = FALSE)
cvl <- parallel::mclapply(seq_len(nrow(jobs)), function(j) { nm <- jobs$form[j]; k <- jobs$fold[j]; trn <- which(prs$fold != k); te <- which(prs$fold == k); tin <- unique(prs$inst[te]); hx <- which(!hd$inst %in% tin); hte <- which(hd$inst %in% tin)
  ft <- fit_form(nm, trn, hx, if (length(FF[[nm]]$th)) start_of(FF[[nm]]) else NULL); pr <- proj(ft$th, ft$g, te)
  hc <- if (nm == "J1" && length(hte)) { e <- tryCatch(coef(nls(HT ~ 1.37 + a0 * (1 - exp(-b * DBH))^c, data = hd[hx], start = as.list(cf$e2), control = nls.control(maxiter = 500))), error = function(e) NULL)
    data.table(fold = k, pid = hd$pid[hte], obs = hd$HT[hte], pJ = hJ(ft$th, hd[hte]), pE = if (is.null(e)) NA_real_ else 1.37 + e[["a0"]] * (1 - exp(-e[["b"]] * hd$DBH[hte]))^e[["c"]]) } else NULL
  list(cv = data.table(form = nm, fold = k, conv = ft$conv, pid = prs$pid[te], planted = prs$planted[te], ylen = prs$ylen[te], w0 = prs$w0[te], obs = prs$adh[te], pred = (pr$end - prs$H0[te]) / prs$yip[te]),
       hc = hc, a = data.table(form = nm, fold = k, A_nat = A_of(nm, ft, BYIM[[1]]), A_pl = A_of(nm, ft, BYIM[[2]]))) }, mc.cores = NC)
stopifnot(!any(sapply(cvl, inherits, "try-error"))); cv <- rbindlist(lapply(cvl, `[[`, "cv")); HC <- rbindlist(lapply(cvl, `[[`, "hc")); AF <- rbindlist(lapply(cvl, `[[`, "a"))
cat("\n(2) held-out installations, annual height increment (m/yr), observed diameter and competition paths\nfold convergence codes:\n"); print(unique(cv[, .(form, fold, conv)])[, .N, by = .(form, conv)])
np <- c(R0 = 0, M1 = 7, M2 = 7); tab <- cv[, c(metrics(obs, pred), equiv_boot(obs, pred, pid, nboot = 2000)[, .(bias_rel, slope, b1_lo, b1_hi, pass_int, pass_slope, min_region_int, min_region_slope)]), by = form]; tab[, k := np[form]]; print(tab)
cat("\nheld-out bias and RMSE by origin and interval length:\n"); print(dcast(cv[, .(n = .N, bias = round(mean(obs - pred), 3), rmse = round(sqrt(mean((obs - pred)^2)), 3)), by = .(form, planted, ylen)], planted + ylen + n ~ form, value.var = c("bias", "rmse")))
cat("\nheld-out, each tree weighted as its consecutive intervals: RMSE\n"); print(cv[, .(wrmse = round(sqrt(sum(w0 * (obs - pred)^2) / sum(w0)), 4), wbias = round(sum(w0 * (obs - pred)) / sum(w0), 4)), by = form])
cat("\nasymptote (m) at the median BYI across the ten fold fits: range\n"); print(AF[form != "R0", .(A_nat_min = round(min(A_nat), 1), A_nat_max = round(max(A_nat), 1), A_pl_min = round(min(A_pl), 1), A_pl_max = round(max(A_pl), 1)), by = form])
# (3) system tests: benchmark tree height and 200-year scenario heights (E2 of record fills missing heights in every form)
hf_of <- function(nm) { ft <- FF[[nm]]; function(H, D, D1, x, lbyi, pl) { inc <- ft$g(ft$th, pmax(H, 0.5), D, D1, x, lbyi, pl); inc[!is.finite(inc)] <- 0; pmin(pmax(inc, -5), 50) } }
bh <- function(nm) rbindlist(lapply(PI, function(x) { hmax <- max(x$obs$h); m0 <- tr[pid == x$p & uid %in% x$L$uid, min(Measure)]; L <- x$L; meas0 <- tr[pid == x$p & Measure == m0 & uid %in% L$uid & !is.na(HT) & HT >= 1.37, uid]
  ob <- tr[pid == x$p & Measure == m0 + hmax & uid %in% meas0 & Status == "live" & !is.na(HT) & HT >= 1.37, .(uid, oH = HT)]; if (!nrow(ob)) return(NULL)
  z <- sim2(L$DBH, L$HT, L$EXPF_c, x$byi, x$pl, hmax, SMO[[x$p]], hf_of(nm), mort_tree, keep = hmax)$th[[1]]; data.table(form = nm, pid = x$p, planted = x$pl, h = hmax, obs = ob$oH, pred = z[match(ob$uid, L$uid)], H0 = L$HT[match(ob$uid, L$uid)]) }))
BH <- rbindlist(lapply(FORMS, bh)); cat("\n(3a) benchmark: tree height at each plot's longest horizon, trees with measured height at both ends (whole system, S1 out of fold)\n")
print(BH[, .(trees = .N, plots = uniqueN(pid), bias = round(mean(obs - pred), 2), rmse = round(sqrt(mean((obs - pred)^2)), 3)), by = form]); print(dcast(BH[, .(n = .N, bias = round(mean(obs - pred), 2), rmse = round(sqrt(mean((obs - pred)^2)), 2)), by = .(form, planted)], planted + n ~ form, value.var = c("bias", "rmse")))
SH <- rbindlist(lapply(FORMS, function(nm) cbind(form = nm, runsc(hf_of(nm))))); TALL <- c(`0` = 34.1, `1` = 28.4)
cat("\n(3b) basal-area-weighted height (m) of the six scenarios\n"); print(dcast(SH[year %in% c(20, 40, 100, 200)], form + planted + level ~ year, value.var = "HT", fun.aggregate = function(v) round(v[1], 1))[order(form, planted, match(level, c("lo", "md", "hi")))])
lr <- SH[, { w <- dcast(.SD[year == 100], planted ~ level, value.var = "HT"); .(bound200 = all(.SD[year == 200, HT <= 1.2 * TALL[as.character(planted)]]), site100 = w[, all(lo <= md + 1e-9 & md <= hi + 1e-9)], max_tree_200 = round(max(.SD[year == 200, HMAX]), 1)) }, by = form]; print(lr)
# conditions (a) to (d)
r0 <- tab[form == "R0"]; b0 <- BH[form == "R0", sqrt(mean((obs - pred)^2))]
rule <- merge(merge(tab[, .(form, k, rmse, pass_int, min_region_slope)], lr, by = "form"), BH[, .(bench_rmse = sqrt(mean((obs - pred)^2))), by = form], by = "form")
rule[, `:=`(a = rmse <= 0.95 * r0$rmse, b = pass_int & min_region_slope < r0$min_region_slope, c = bound200 & site100, d = bench_rmse <= b0 + 1e-9)]; rule[, pass := a & b & c & d & form != "R0"]; rule[, eligible := pass & form != "P1"]
cat("\n(4) conditions of the PREREG note: (a) held-out RMSE at least 5% below R0; (b) intercept passes and slope region smaller than R0; (c) 200-year bound and site order at 100 years; (d) benchmark RMSE not above R0\n"); print(rule[, .(form, k, rmse = round(rmse, 4), ratio = round(rmse / r0$rmse, 3), min_region_slope = round(min_region_slope, 3), bench_rmse = round(bench_rmse, 3), a, b, c, d, pass, eligible)])
el <- rule[eligible == TRUE]; cand <- if (nrow(el)) el[rmse <= min(rmse) * 1.02, form] else character(0)
cat("eligible forms within 2% of the lowest held-out RMSE among them (the choice among these is by the asymptote interval, script 45):", if (length(cand)) cand else "none", "\n")
saveRDS(list(FF = lapply(FF, function(z) z[setdiff(names(z), "g")]), tab = tab, cv = cv, HC = HC, AF = AF, BH = BH, SH = SH, rule = rule, cand = cand, n = n, D80 = D80, BYIM = BYIM), "out/height_increment_46.rds"); cat("done\n")
# (5) plot-cluster bootstrap of each M form that passes, both stages repeated in every resample
NB <- as.integer(Sys.getenv("KOA_NBOOT", "500")); RNGkind("L'Ecuyer-CMRG"); set.seed(20261146); FB <- rule[pass == TRUE, form]; cat("\n(5) forms bootstrapped:", if (length(FB)) FB else "none", "\n")
plI <- split(seq_len(n), prs$pid); npl <- length(plI); idx <- lapply(seq_len(NB), function(b) sample.int(npl, npl, replace = TRUE)); OUT <- list()
for (FM in FB) { s0 <- start_of(FF[[FM]]); B <- NULL; CH <- split(seq_len(NB), ceiling(seq_len(NB) / (NC * 5))); cat("\n", FM, "\n")
  for (ch in CH) { r <- parallel::mclapply(ch, function(b) { ix <- unlist(plI[idx[[b]]], use.names = FALSE); ft <- tryCatch(fit_form(FM, ix, start = s0), error = function(e) NULL); if (is.null(ft)) return(rep(NA_real_, 11))
      c(ft$th, a0 = ft$q[1], a_lbyi = ft$q[2], lk = ft$q[3], lc = ft$q[4], A_nat = A_of(FM, ft, BYIM[[1]]), A_pl = A_of(FM, ft, BYIM[[2]]), delta = ft$delta, conv = ft$conv) }, mc.cores = NC)
    r <- r[vapply(r, is.numeric, TRUE)]; B <- rbind(B, do.call(rbind, r)); OUT[[FM]] <- B; saveRDS(OUT, "out/boot_maxmod_46.rds"); cat(format(Sys.time(), "%H:%M:%S"), "resamples done:", nrow(B), "\n") }
  ok <- !is.na(B[, "conv"]) & B[, "conv"] == 0; cat("completed", nrow(B), "; converged", sum(ok), "\n"); Bk <- B[ok, setdiff(colnames(B), c("delta", "conv")), drop = FALSE]; ft0 <- FF[[FM]]
  est <- c(ft0$th, a0 = ft0$q[1], a_lbyi = ft0$q[2], lk = ft0$q[3], lc = ft0$q[4], A_nat = A_of(FM, ft0, BYIM[[1]]), A_pl = A_of(FM, ft0, BYIM[[2]]))
  tb <- data.table(form = FM, par = colnames(Bk), est = unname(est), se = apply(Bk, 2, sd), lo = apply(Bk, 2, quantile, 0.025), hi = apply(Bk, 2, quantile, 0.975), share_pos = colMeans(Bk > 0)); print(tb[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 4) else v)]); fwrite(tb, paste0("out/boot_maxmod_46_", FM, ".csv")) }
cat("all done\n")
