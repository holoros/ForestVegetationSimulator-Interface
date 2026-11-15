# 42_height_increment_round3.R  Third round of height increment forms (section 7 of 2026-11-14_koa-height-crown-standmort_PREREG.md), asked for by Aaron
# on November 14, 2026 after the bootstrap of B2 showed an asymptote weakly constrained from above: keep an asymptotic (bounded) form and test how BYI
# enters it (on the rate, with origin, with competition, or not on the asymptote at all). Same frame, folds, tests and rule as scripts 33 and 33b; R0 and B2 are rerun for reference.
# No plot or installation identifier is printed.
suppressMessages(library(data.table)); source("~/jobs/koa_final_eq_20261110/scripts/32_common.R"); NC <- as.integer(Sys.getenv("KOA_CORES", "6")); NB <- as.integer(Sys.getenv("KOA_NBOOT", "2000"))
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
bnd <- function(A., k, m, H) pmax(m * k * H * ((A. / H)^(1 / m) - 1), 0); LB0 <- 5   # ln(BYI) is centred at 5 (BYI 148) where it enters an interaction or the rate
G <- list(R0 = function(th, H, D, D1, x, lb, pl) e2(D1) - e2(D),
          B2 = function(th, H, D, D1, x, lb, pl) bnd(exp(th[1] + th[2] * lb), exp(th[3] + th[6] * pl), exp(th[4]), H) * exp(th[5] * x),
          B4 = function(th, H, D, D1, x, lb, pl) bnd(exp(th[1] + th[2] * lb), exp(th[3] + th[6] * pl + th[7] * (lb - LB0)), exp(th[4]), H) * exp(th[5] * x),
          B5 = function(th, H, D, D1, x, lb, pl) bnd(exp(th[1] + th[2] * lb + th[7] * pl * (lb - LB0)), exp(th[3] + th[6] * pl), exp(th[4]), H) * exp(th[5] * x),
          B6 = function(th, H, D, D1, x, lb, pl) bnd(exp(th[1] + th[2] * lb), exp(th[3] + th[6] * pl), exp(th[4]), H) * exp((th[5] + th[7] * (lb - LB0)) * x),
          B7 = function(th, H, D, D1, x, lb, pl) bnd(exp(th[1]), exp(th[3] + th[6] * pl + th[2] * (lb - LB0)), exp(th[4]), H) * exp(th[5] * x),
          B8 = function(th, H, D, D1, x, lb, pl) bnd(exp(th[1]), exp(th[3] + th[6] * pl + th[2] * (lb - LB0) + th[7] * pl * (lb - LB0)), exp(th[4]), H) * exp(th[5] * x))
PN <- list(R0 = character(0), B2 = c("a0", "a_lbyi", "lk", "lc", "x", "k_pl"), B4 = c("a0", "a_lbyi", "lk", "lc", "x", "k_pl", "k_lbyi"), B5 = c("a0", "a_lbyi", "lk", "lc", "x", "k_pl", "a_pl_lbyi"),
           B6 = c("a0", "a_lbyi", "lk", "lc", "x", "k_pl", "x_lbyi"), B7 = c("a0", "k_lbyi", "lk", "lc", "x", "k_pl"), B8 = c("a0", "k_lbyi", "lk", "lc", "x", "k_pl", "k_pl_lbyi"))
# starting values: the B2 estimates of script 33b; new terms start at zero; B7 and B8 start with the B2 asymptote at BYI 148
b2 <- unname(readRDS("out/height_increment_33b.rds")$FH$B2$th); b7 <- c(b2[1] + b2[2] * LB0, 0, b2[3:6])
ST <- list(R0 = numeric(0), B2 = b2, B4 = c(b2, 0), B5 = c(b2, 0), B6 = c(b2, 0), B7 = b7, B8 = c(b7, 0))
proj <- function(th, g, ix = seq_len(n)) { H <- prs$H0[ix]; yp <- prs$yip[ix]; lb <- prs$lbyi[ix]; pl <- prs$planted[ix]; acc <- numeric(length(ix))
  for (t in seq_len(max(yp))) { a <- t <= yp; if (!any(a)) break; r <- ix[a]; inc <- g(th, pmax(H[a], 0.5), Dm[r, t], D1m[r, t], Xm[r, t], lb[a], pl[a]); inc[!is.finite(inc)] <- 50; inc <- pmin(pmax(inc, -5), 50); H[a] <- H[a] + inc; acc[a] <- acc[a] + abs(inc) }
  list(end = H, gbar = acc / yp) }
fith <- function(nm, ix = seq_len(n), th = ST[[nm]], passes = 3) { g <- G[[nm]]; if (!length(th)) return(list(th = th, delta = NA, conv = 0)); w <- prs$w0[ix] / prs$yip[ix]; dl <- 0; conv <- NA
  for (it in seq_len(passes)) { o <- optim(th, function(b) { v <- sum(w * (prs$H1[ix] - proj(b, g, ix)$end)^2); if (is.finite(v)) v else 1e12 }, method = "BFGS", control = list(maxit = 800, reltol = 1e-10)); th <- o$par; conv <- o$convergence
    pr <- proj(th, g, ix); r <- prs$H1[ix] - pr$end; dl <- max(0, min(1.5, coef(lm(log(pmax(r^2 / prs$yip[ix], 1e-8)) ~ log(pmax(pr$gbar, 0.01))))[[2]] / 2)); w <- prs$w0[ix] / (prs$yip[ix] * pmax(pr$gbar, 0.01)^(2 * dl)) }
  list(th = setNames(th, PN[[nm]]), delta = dl, conv = conv) }
FH <- parallel::mclapply(names(G), fith, mc.cores = 4); names(FH) <- names(G)
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
saveRDS(list(FH = FH, tab = tab, cv = cv, BH = BH, SH = SH, rule = rule, pick = pickh, best = best, PN = PN, n = n), "out/height_increment_42.rds"); cat("done\n")
