# 52_j1_eval_items.R  Evaluation numbers for manuscript v136 after Aaron's decisions of November 15, 2026 (J1 as the height increment equation; the joint
# curve of J1 as the height curve): (a) the height curve held out in the ten folds of record of the height frame; (b) the fallback rule recomputed with the
# joint curve, held out in the folds of the increment frame, with J1 beside it; (c) benchmark tree height for the rule with the joint curve; (d) intervals of
# derived quantities from the 500 resamples of script 45. No fitting choice is made here. No plot or installation identifier is printed.
L <- readLines("~/jobs/koa_final_eq_20261110/scripts/42_height_increment_round3.R"); k <- grep("^fith <- ", L); eval(parse(text = L[5:(k + 3)]))
L4 <- readLines("~/jobs/koa_final_eq_20261110/scripts/44_height_increment_round4.R"); eval(parse(text = L4[(grep("definitions start", L4) + 1):(grep("definitions end", L4) - 1)])); NC <- as.integer(Sys.getenv("KOA_CORES", "2"))
R44 <- readRDS("out/height_increment_44.rds"); thJ <- unlist(R44$FF$J1$th); kh <- function(th, d, byi) 1.37 + (exp(th[[1]] + th[[2]] * log(byi)) - 1.37) * (1 - exp(-exp(th[[7]]) * d))^exp(th[[8]])
cols <- c("bias_rel", "slope", "b1_lo", "b1_hi", "pass_int", "pass_slope", "min_region_int", "min_region_slope")
cat("\nJ1 estimates:", round(thJ, 5), "; curve b", round(exp(thJ[[7]]), 5), " c", round(exp(thJ[[8]]), 4), "\n")
cat("joint curve on the full height frame: n", nrow(hd), " plots", uniqueN(hd$pid), " RMSE", round(sqrt(mean((hd$HT - hJ(thJ, hd))^2)), 3), " bias", round(mean(hd$HT - hJ(thJ, hd)), 3), "; E2 of record RMSE", round(sqrt(mean((hd$HT - koa_height(hd$DBH, cf))^2)), 3), "\n")
# (a) height curve held out, folds of record of the height frame
hd <- merge(hd, make_folds(hd), by = "inst"); FK <- sort(unique(hd$fold))
ca <- rbindlist(parallel::mclapply(FK, function(kf) { hte <- which(hd$fold == kf); tin <- unique(hd$inst[hte]); hx <- which(hd$fold != kf); ix <- which(!prs$inst %in% tin); ft <- fitJ(unname(thJ), ix, hx)
  e <- tryCatch(coef(nls(HT ~ 1.37 + a0 * (1 - exp(-b * DBH))^c, data = hd[hx], start = as.list(cf$e2), control = nls.control(maxiter = 500))), error = function(e) NULL)
  data.table(fold = kf, conv = ft$conv, pid = hd$pid[hte], planted = hd$planted[hte], obs = hd$HT[hte], pJ = hJ(ft$th, hd[hte]), pE = if (is.null(e)) NA_real_ else 1.37 + e[["a0"]] * (1 - exp(-e[["b"]] * hd$DBH[hte]))^e[["c"]], A_nat = exp(ft$th[1] + ft$th[2] * log(BYIM[[1]]))) }, mc.cores = NC))
cat("\n(a) height curve held out by installation, ten folds of the height frame; fold convergence:", unique(ca[, .(fold, conv)])$conv, "\n")
print(rbind(cbind(curve = "joint (J1), BYI on the asymptote", ca[, c(metrics(obs, pJ), equiv_boot(obs, pJ, pid, nboot = 2000)[, ..cols])]), cbind(curve = "three-parameter, refitted (Eq. 3 of v135)", ca[, c(metrics(obs, pE), equiv_boot(obs, pE, pid, nboot = 2000)[, ..cols])])))
cat("by origin:\n"); print(ca[, .(n = .N, plots = uniqueN(pid), bias_J = round(mean(obs - pJ), 3), rmse_J = round(sqrt(mean((obs - pJ)^2)), 3), bias_E = round(mean(obs - pE), 3), rmse_E = round(sqrt(mean((obs - pE)^2)), 3)), by = planted])
cat("asymptote at natural median BYI across the ten fold fits:", round(range(ca$A_nat), 2), "\n")
# (b) fallback rule with the joint curve, folds of the increment frame
gR <- function(th, H, D, D1, x, lb, pl) kh(th, D1, exp(lb)) - kh(th, D, exp(lb))
cb <- rbindlist(parallel::mclapply(sort(unique(prs$fold)), function(kf) { trn <- which(prs$fold != kf); te <- which(prs$fold == kf); tin <- unique(prs$inst[te]); hx <- which(!hd$inst %in% tin); ft <- fitJ(unname(thJ), trn, hx)
  data.table(fold = kf, pid = prs$pid[te], planted = prs$planted[te], ylen = prs$ylen[te], w0 = prs$w0[te], obs = prs$adh[te], pJ = (proj(ft$th, gJ, te)$end - prs$H0[te]) / prs$yip[te], pR = (proj(ft$th, gR, te)$end - prs$H0[te]) / prs$yip[te]) }, mc.cores = NC))
cat("\n(b) annual height increment held out by installation (m/yr): J1 and the fallback rule with the joint curve\n")
print(rbind(cbind(form = "J1", cb[, c(metrics(obs, pJ), equiv_boot(obs, pJ, pid, nboot = 2000)[, ..cols])]), cbind(form = "rule, joint curve", cb[, c(metrics(obs, pR), equiv_boot(obs, pR, pid, nboot = 2000)[, ..cols])])))
cat("by origin:\n"); print(cb[, .(pairs = .N, bias_J = round(mean(obs - pJ), 3), rmse_J = round(sqrt(mean((obs - pJ)^2)), 3), bias_R = round(mean(obs - pR), 3), rmse_R = round(sqrt(mean((obs - pR)^2)), 3)), by = planted])
cat("by origin and interval length:\n"); print(cb[, .(pairs = .N, bias_J = round(mean(obs - pJ), 3), rmse_J = round(sqrt(mean((obs - pJ)^2)), 3), bias_R = round(mean(obs - pR), 3), rmse_R = round(sqrt(mean((obs - pR)^2)), 3)), by = .(planted, ylen)][order(planted, ylen)])
cat("each tree weighted as its consecutive intervals: J1 RMSE", round(cb[, sqrt(sum(w0 * (obs - pJ)^2) / sum(w0))], 4), " bias", round(cb[, sum(w0 * (obs - pJ)) / sum(w0)], 4), "; rule RMSE", round(cb[, sqrt(sum(w0 * (obs - pR)^2) / sum(w0))], 4), " bias", round(cb[, sum(w0 * (obs - pR)) / sum(w0)], 4), "\n")
cat("underprediction of the rule as a share of mean observed increment:", round(100 * cb[, mean(obs - pR) / mean(obs)], 1), "%\n")
# (c) benchmark tree height
hfs <- list(J1 = function(H, D, D1, x, lbyi, pl) { inc <- gJ(thJ, pmax(H, 0.5), D, D1, x, lbyi, pl); inc[!is.finite(inc)] <- 0; inc }, rule_joint = function(H, D, D1, x, lbyi, pl) gR(thJ, H, D, D1, x, lbyi, pl), rule_v135 = ht_rule)
bh <- function(nm) rbindlist(lapply(PI, function(x) { hmax <- max(x$obs$h); m0 <- tr[pid == x$p & uid %in% x$L$uid, min(Measure)]; L. <- x$L; meas0 <- tr[pid == x$p & Measure == m0 & uid %in% L.$uid & !is.na(HT) & HT >= 1.37, uid]
  ob <- tr[pid == x$p & Measure == m0 + hmax & uid %in% meas0 & Status == "live" & !is.na(HT) & HT >= 1.37, .(uid, oH = HT)]; if (!nrow(ob)) return(NULL)
  z <- sim2(L.$DBH, L.$HT, L.$EXPF_c, x$byi, x$pl, hmax, SMO[[x$p]], hfs[[nm]], mort_tree, keep = hmax)$th[[1]]; data.table(form = nm, pid = x$p, planted = x$pl, obs = ob$oH, pred = z[match(ob$uid, L.$uid)]) }))
BH <- rbindlist(lapply(names(hfs), bh)); cat("\n(c) benchmark: tree height at each plot's longest horizon (trees with measured height at both ends)\n"); print(BH[, .(trees = .N, plots = uniqueN(pid), bias = round(mean(obs - pred), 2), rmse = round(sqrt(mean((obs - pred)^2)), 3)), by = form]); print(BH[, .(trees = .N, bias = round(mean(obs - pred), 2), rmse = round(sqrt(mean((obs - pred)^2)), 2)), by = .(form, planted)])
# (d) derived intervals from the 500 resamples of script 45
B <- readRDS("out/boot_round4_45.rds")$J1; ok <- B[, "conv"] == 0; B <- B[ok, ]; q <- function(v) c(se = sd(v), quantile(v, c(0.025, 0.975)))
cat("\n(d) J1, 500 plot-cluster resamples of both frames; converged", sum(ok), "\n"); D <- rbind(b = q(exp(B[, "ln_b"])), c = q(exp(B[, "ln_c"])), m_shape = q(exp(B[, "lc"])), exp_k_pl = q(exp(B[, "k_pl"])), A_nat = q(B[, "A_nat"]), A_pl = q(B[, "A_pl"]),
  A_byi_lo_nat = q(exp(B[, "a0"] + B[, "a_lbyi"] * log(byiq[planted == 0, lo]))), A_byi_hi_nat = q(exp(B[, "a0"] + B[, "a_lbyi"] * log(byiq[planted == 0, hi]))))
est <- c(exp(thJ[[7]]), exp(thJ[[8]]), exp(thJ[[4]]), exp(thJ[[6]]), exp(thJ[[1]] + thJ[[2]] * log(BYIM[[1]])), exp(thJ[[1]] + thJ[[2]] * log(BYIM[[2]])), exp(thJ[[1]] + thJ[[2]] * log(byiq[planted == 0, lo])), exp(thJ[[1]] + thJ[[2]] * log(byiq[planted == 0, hi]))); print(round(cbind(est = est, D), 4))
cat("share of resamples with a positive BYI coefficient:", round(mean(B[, "a_lbyi"] > 0), 3), "; BYI range of the height frame:", round(range(hd$BYI), 1), "; of the increment frame:", round(range(prs$BYI), 1), "\n")
cat("asymptote of the joint curve over the BYI range of the height frame (m):", round(exp(thJ[[1]] + thJ[[2]] * log(range(hd$BYI))), 1), "; tallest measured tree by origin: natural", round(hd[planted == 0, max(HT)], 1), " planted", round(hd[planted == 1, max(HT)], 1), "\n")
saveRDS(list(ca = ca, cb = cb, BH = BH, D = D), "out/j1_eval_52.rds"); cat("done\n")
