# 33_height_increment.R  Height increment forms against the E5 rule of record, by the rules of 2026-11-14_koa-height-crown-standmort_PREREG.md (section 1).
# Frame: all pairs of visits of a tree with a measured height (alive at both); covariates interpolated yearly along the tree's own visit record.
# Forms R0 (E5 rule), R1 (calibrated rule), L1 (peaking size form), L2 (L1 tied to diameter growth), B1 (bounded differential Chapman-Richards).
# Tests: installations held out; 53-plot benchmark of tree height; 200-year scenario heights. No plot or installation identifier is printed.
suppressMessages(library(data.table)); source("~/jobs/koa_1150_20261121/scripts/32_common.R"); NC <- as.integer(Sys.getenv("KOA_CORES", "6")); NB <- as.integer(Sys.getenv("KOA_NBOOT", "2000"))
A <- tr[Status == "live" & !is.na(DBH) & DBH > 0 & !is.na(BAL) & !is.na(BA_koa) & !is.na(SDI_koa)][order(uid, Measure)]; A <- A[!duplicated(A[, .(uid, Measure)])]
HV <- A[!is.na(HT) & HT >= 1.37]; nv <- HV[, .N, by = uid]; HV <- HV[uid %in% nv[N >= 2, uid]]
prs <- HV[, { k <- t(combn(.N, 2)); .(m0 = Measure[k[, 1]], m1 = Measure[k[, 2]], H0 = HT[k[, 1]], H1 = HT[k[, 2]], nvis = .N) }, by = .(uid, pid, Data, Install, planted, BYI)]
prs[, yip := m1 - m0]; prs <- prs[yip >= 1]; prs[, adh := (H1 - H0) / yip]; n_all <- nrow(prs); prs <- prs[adh >= -2 & adh <= 4]; prs[, `:=`(sm = SM[pid], lbyi = log(BYI), inst = paste(Data, Install), w0 = 2 / nvis)]; stopifnot(!anyNA(prs$sm))
prs <- merge(prs, make_folds(prs), by = "inst"); prs[, ylen := cut(yip, c(0, 1, 3, 9, 99), labels = c("1", "2-3", "4-9", ">9"))]; setorder(prs, uid, m0, m1); n <- nrow(prs); TM <- max(prs$yip)
cat("height pairs: all", n_all, "; kept (annualized change -2 to 4 m)", n, "; trees", uniqueN(prs$uid), "; plots", uniqueN(prs$pid), "; installations", uniqueN(prs$inst), "\n")
print(prs[, .(pairs = .N, trees = uniqueN(uid), plots = uniqueN(pid), mean_adh = round(mean(adh), 3), wsum = round(sum(w0), 0)), by = .(planted, ylen)][order(planted, ylen)])
# yearly paths
Dm <- D1m <- Xm <- matrix(NA_real_, n, TM); sp <- split(A[, .(Measure, DBH, BAL, BA_koa, SDI_koa)], A$uid)
for (i in seq_len(n)) { a <- sp[[prs$uid[i]]]; yy <- prs$m0[i]:(prs$m1[i]); ap <- function(v) approx(a$Measure, v, yy, rule = 2)$y; d <- ap(a$DBH); k <- length(yy) - 1
  Dm[i, 1:k] <- d[1:k]; D1m[i, 1:k] <- d[2:(k + 1)]; Xm[i, 1:k] <- (ap(a$BAL) / pmax(ap(a$BA_koa), 1e-6) * ap(a$SDI_koa) / prs$sm[i])[1:k] }
e2 <- function(d) koa_height(d, cf)
G <- list(R0 = function(th, H, D, D1, x, lb, pl) e2(D1) - e2(D),
          R1 = function(th, H, D, D1, x, lb, pl) (e2(D1) - e2(D)) * exp(th[1] + th[2] * lb + th[3] * pl + th[4] * x),
          L1 = function(th, H, D, D1, x, lb, pl) exp(th[1] + th[2] * log(H) + th[3] * H + th[4] * x + th[5] * lb + th[6] * pl),
          L2 = function(th, H, D, D1, x, lb, pl) exp(th[1] + th[2] * log(H) + th[3] * H + th[4] * x + th[5] * lb + th[6] * pl + th[7] * log(pmax(D1 - D, 0) + 0.05)),
          B1 = function(th, H, D, D1, x, lb, pl) { A. <- exp(th[1] + th[2] * lb + th[3] * pl); cc <- exp(th[5]); pmax(cc * exp(th[4]) * H * ((A. / H)^(1 / cc) - 1), 0) * exp(th[6] * x) })
PN <- list(R0 = character(0), R1 = c("c0", "lbyi", "pl", "x"), L1 = c("h0", "lH", "H", "x", "lbyi", "pl"), L2 = c("h0", "lH", "H", "x", "lbyi", "pl", "ldD"), B1 = c("a0", "a_lbyi", "a_pl", "lk", "lc", "x"))
# starting values: log-linear regression of the annualized increment on start-of-interval values (L1, L2); B1 from the E2 asymptote
s0 <- data.table(y = log(pmax(prs$adh, 0.02)), lH = log(prs$H0), H = prs$H0, x = Xm[, 1], lb = prs$lbyi, pl = prs$planted, ldD = log(pmax(D1m[, 1] - Dm[, 1], 0) + 0.05), w = prs$w0)
ST <- list(R0 = numeric(0), R1 = c(0, 0, 0, 0), L1 = unname(coef(lm(y ~ lH + H + x + lb + pl, s0, weights = w))), L2 = unname(coef(lm(y ~ lH + H + x + lb + pl + ldD, s0, weights = w))), B1 = c(log(25), 0.05, 0, log(0.05), log(1.2), -0.5))
proj <- function(th, g, ix = seq_len(n)) { H <- prs$H0[ix]; yp <- prs$yip[ix]; lb <- prs$lbyi[ix]; pl <- prs$planted[ix]; acc <- numeric(length(ix))
  for (t in seq_len(max(yp))) { a <- t <= yp; if (!any(a)) break; r <- ix[a]; inc <- g(th, pmax(H[a], 0.5), Dm[r, t], D1m[r, t], Xm[r, t], lb[a], pl[a]); inc[!is.finite(inc)] <- 50; inc <- pmin(pmax(inc, -5), 50); H[a] <- H[a] + inc; acc[a] <- acc[a] + abs(inc) }
  list(end = H, gbar = acc / yp) }
fith <- function(nm, ix = seq_len(n), th = ST[[nm]], passes = 3) { g <- G[[nm]]; if (!length(th)) return(list(th = th, delta = NA, conv = 0)); w <- prs$w0[ix] / prs$yip[ix]; dl <- 0; conv <- NA
  for (it in seq_len(passes)) { o <- optim(th, function(b) sum(w * (prs$H1[ix] - proj(b, g, ix)$end)^2), method = "BFGS", control = list(maxit = 800, reltol = 1e-10)); th <- o$par; conv <- o$convergence
    pr <- proj(th, g, ix); r <- prs$H1[ix] - pr$end; dl <- max(0, min(1.5, coef(lm(log(pmax(r^2 / prs$yip[ix], 1e-8)) ~ log(pmax(pr$gbar, 0.01))))[[2]] / 2)); w <- prs$w0[ix] / (prs$yip[ix] * pmax(pr$gbar, 0.01)^(2 * dl)) }
  list(th = setNames(th, PN[[nm]]), delta = dl, conv = conv) }
FH <- parallel::mclapply(names(G), fith, mc.cores = 5); names(FH) <- names(G)
cat("\n(1) full-frame fits\n"); for (nm in names(G)) { pr <- proj(FH[[nm]]$th, G[[nm]]); cat(nm, " convergence", FH[[nm]]$conv, " delta", round(FH[[nm]]$delta, 3), " mean observed - predicted (m/yr)", round(mean((prs$H1 - pr$end) / prs$yip), 4), "\n"); if (length(FH[[nm]]$th)) print(round(FH[[nm]]$th, 5)) }
# (2) installations held out
jobs <- CJ(form = names(G), fold = sort(unique(prs$fold)), sorted = FALSE)
cv <- rbindlist(parallel::mclapply(seq_len(nrow(jobs)), function(j) { nm <- jobs$form[j]; k <- jobs$fold[j]; trn <- which(prs$fold != k); te <- which(prs$fold == k); ft <- fith(nm, trn, FH[[nm]]$th); pr <- proj(ft$th, G[[nm]], te)
  data.table(form = nm, fold = k, conv = ft$conv, pid = prs$pid[te], planted = prs$planted[te], ylen = prs$ylen[te], w0 = prs$w0[te], obs = prs$adh[te], pred = (pr$end - prs$H0[te]) / prs$yip[te]) }, mc.cores = NC))
cat("\n(2) held-out installations, annual height increment (m/yr), observed diameter and competition paths\nfold convergence codes:\n"); print(unique(cv[, .(form, fold, conv)])[, .N, by = .(form, conv)])
np <- sapply(PN, length); tab <- cv[, c(metrics(obs, pred), equiv_boot(obs, pred, pid, nboot = 2000)[, .(bias_rel, slope, b1_lo, b1_hi, pass_int, pass_slope, min_region_int, min_region_slope)]), by = form]; tab[, k := np[form]]; print(tab)
cat("\nheld-out bias and RMSE by origin and interval length:\n"); print(dcast(cv[, .(n = .N, bias = round(mean(obs - pred), 3), rmse = round(sqrt(mean((obs - pred)^2)), 3)), by = .(form, planted, ylen)], planted + ylen + n ~ form, value.var = c("bias", "rmse")))
cat("\nheld-out, each tree weighted as its consecutive intervals (weight 2 / height visits): RMSE\n"); print(cv[, .(wrmse = round(sqrt(sum(w0 * (obs - pred)^2) / sum(w0)), 4), wbias = round(sum(w0 * (obs - pred)) / sum(w0), 4)), by = form])
# (3) system tests: benchmark tree height and 200-year scenario heights
hf_of <- function(nm, th = FH[[nm]]$th) function(H, D, D1, x, lbyi, pl) { inc <- G[[nm]](th, pmax(H, 0.5), D, D1, x, lbyi, pl); inc[!is.finite(inc)] <- 0; pmin(pmax(inc, -5), 50) }
bh <- function(nm) rbindlist(lapply(PI, function(x) { hmax <- max(x$obs$h); m0 <- tr[pid == x$p & uid %in% x$L$uid, min(Measure)]; L <- x$L; meas0 <- tr[pid == x$p & Measure == m0 & uid %in% L$uid & !is.na(HT) & HT >= 1.37, uid]
  ob <- tr[pid == x$p & Measure == m0 + hmax & uid %in% meas0 & Status == "live" & !is.na(HT) & HT >= 1.37, .(uid, oH = HT)]; if (!nrow(ob)) return(NULL)
  z <- sim2(L$DBH, L$HT, L$EXPF_c, x$byi, x$pl, hmax, SMO[[x$p]], hf_of(nm), mort_tree, keep = hmax)$th[[1]]; data.table(form = nm, pid = x$p, planted = x$pl, h = hmax, obs = ob$oH, pred = z[match(ob$uid, L$uid)], H0 = L$HT[match(ob$uid, L$uid)]) }))
BH <- rbindlist(lapply(names(G), bh)); cat("\n(3a) benchmark: tree height at each plot's longest horizon, trees with measured height at both ends (whole system, S1 out of fold)\n")
print(BH[, .(trees = .N, plots = uniqueN(pid), bias = round(mean(obs - pred), 2), rmse = round(sqrt(mean((obs - pred)^2)), 3), rmse_growth = round(sqrt(mean(((obs - H0) - (pred - H0))^2 / pmax(h, 1)^2)), 3)), by = form]); print(dcast(BH[, .(n = .N, bias = round(mean(obs - pred), 2), rmse = round(sqrt(mean((obs - pred)^2)), 2)), by = .(form, planted)], planted + n ~ form, value.var = c("bias", "rmse")))
SH <- rbindlist(lapply(names(G), function(nm) cbind(form = nm, runsc(hf_of(nm))))); TALL <- c(`0` = 34.1, `1` = 28.4)
cat("\n(3b) basal-area-weighted height (m) of the six scenarios\n"); print(dcast(SH[year %in% c(20, 40, 100, 200)], form + planted + level ~ year, value.var = "HT", fun.aggregate = function(v) round(v[1], 1))[order(form, planted, match(level, c("lo", "md", "hi")))])
lr <- SH[, { w <- dcast(.SD[year == 100], planted ~ level, value.var = "HT"); .(bound200 = all(.SD[year == 200, HT <= 1.2 * TALL[as.character(planted)]]), site100 = w[, all(lo <= md + 1e-9 & md <= hi + 1e-9)], max_tree_200 = round(max(.SD[year == 200, HMAX]), 1)) }, by = form]; print(lr)
# rule
r0 <- tab[form == "R0"]; b0 <- BH[form == "R0", sqrt(mean((obs - pred)^2))]
rule <- merge(merge(tab[, .(form, k, rmse, pass_int, min_region_slope)], lr, by = "form"), BH[, .(bench_rmse = sqrt(mean((obs - pred)^2))), by = form], by = "form")
rule[, `:=`(a = rmse <= 0.95 * r0$rmse, b = pass_int & min_region_slope < r0$min_region_slope, c = bound200 & site100, d = bench_rmse <= b0 + 1e-9)]; rule[, pass := a & b & c & d & form != "R0"]
cat("\n(4) rule of the PREREG note: (a) held-out RMSE at least 5% below R0; (b) intercept passes and slope region smaller than R0; (c) 200-year bound and site order at 100 years; (d) benchmark RMSE not above R0\n"); print(rule[, .(form, k, rmse = round(rmse, 4), ratio = round(rmse / r0$rmse, 3), min_region_slope = round(min_region_slope, 3), bench_rmse = round(bench_rmse, 3), a, b, c, d, pass)])
ps <- rule[pass == TRUE]; pickh <- if (nrow(ps)) ps[rmse <= min(rmse) * 1.02][order(k, rmse)]$form[1] else NA; best <- rule[form != "R0"][order(rmse)]$form[1]
cat("adopted:", if (is.na(pickh)) "none (E5 stays)" else pickh, "; best tested by held-out RMSE:", best, "\n")
# bootstrap of the adopted or best form, plots resampled
bf <- if (is.na(pickh)) best else pickh; idx <- split(seq_len(n), prs$pid); pids <- names(idx); RNGkind("L'Ecuyer-CMRG"); set.seed(20261114)
BO <- do.call(rbind, parallel::mclapply(seq_len(NB), function(i) { ix <- unlist(idx[sample(pids, length(pids), TRUE)], use.names = FALSE); o <- tryCatch(fith(bf, ix, FH[[bf]]$th), error = function(e) NULL); if (is.null(o) || o$conv != 0) rep(NA_real_, length(FH[[bf]]$th)) else o$th }, mc.cores = NC, mc.set.seed = TRUE))
cat("\n(5) plot-cluster bootstrap of", bf, ":", sum(complete.cases(BO)), "of", NB, "resamples converged\n"); print(round(rbind(est = FH[[bf]]$th, se = apply(BO, 2, sd, na.rm = TRUE), lo = apply(BO, 2, quantile, .025, na.rm = TRUE), hi = apply(BO, 2, quantile, .975, na.rm = TRUE)), 5))
pr <- proj(FH[[bf]]$th, G[[bf]]); cat("residual of end height about", bf, ": sd per sqrt(year) at mean increment (m):", round(sqrt(mean((prs$H1 - pr$end)^2 / prs$yip)), 3), "\n")
saveRDS(list(FH = FH, tab = tab, cv = cv, BH = BH, SH = SH, rule = rule, pick = pickh, best = best, boot = BO, PN = PN, n = n), "out/height_increment_33.rds"); cat("done\n")
