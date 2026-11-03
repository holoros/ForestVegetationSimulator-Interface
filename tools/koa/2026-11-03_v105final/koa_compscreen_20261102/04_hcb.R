## 04_hcb.R: Eq. 3 HCB. Deployed HCB_P (fixed) on C2 vs C1 (HCB_P form refitted with ln(C2/100)) vs C2h (RD terms). Covariates as hcb_v103.R,
## BAL definition l (engine), BAPH_hi, TPH_hi; RD = TPH (QMD/25.4)^1.605 / 923.
source(path.expand("~/jobs/koa_compscreen_20261102/lib.R"))
HCB_P <- c(b0 = 0.1684, b1 = 1.0146, b2 = -0.376, b3 = -0.0078, b4 = -0.3734, b5 = -0.221)
rd_prep <- function(f) { d <- read.csv(f, stringsAsFactors = FALSE, colClasses = c(Install = "character", Plot = "character")); nocoord(d)
  d <- d[is.finite(d$HCB) & is.finite(d$HT) & d$HT > 0 & is.finite(d$BYI), ]; d$plot <- paste(d$Install, d$Plot)
  d$BAL <- d$BALl; d$BAPH <- d$BAPH_hi; d$QMD <- sqrt(d$BAPH_hi / d$TPH_hi / (pi / 40000)); d$SDI <- d$TPH_hi * (d$QMD / 25.4)^1.605; d$RD <- d$SDI / POP
  d$share <- ifelse(d$BAPH > 0, d$BAL / d$BAPH, 0); d }
eta_D <- function(p, d) p[1] + p[2] * sqrt(d$HT / 100) + p[3] * log(pmax(d$HT / pmax(d$DBH, 0.1), 0.5)) + p[4] * sqrt(pmax(d$BAL * d$BAPH + 1, 0)) + p[5] * log(d$BAPH + 1) + p[6] * log(pmax(d$BYI, 1) / 100)
eta_R <- function(p, d) p[1] + p[2] * sqrt(d$HT / 100) + p[3] * log(pmax(d$HT / pmax(d$DBH, 0.1), 0.5)) + p[4] * sqrt(pmax(d$share * d$RD + 1, 0)) + p[5] * log(d$RD) + p[6] * log(pmax(d$BYI, 1) / 100)
pr <- function(eta, d) d$HT / (1 + exp(-eta))
## gate: deployed on the pre-substitution frame reproduces hcb_fit_stats_v103 dep_l RMSE
d0 <- rd_prep(file.path(W, "frames/final/AK_HCB_v103_PREV_20261102.csv")); g <- abs(rmse(d0$HCB, pr(eta_D(HCB_P, d0), d0)) - 2.3818958774374)
logm("GATE HCB_P deployed RMSE on the old index frame vs hcb_fit_stats_v103 (l):", signif(g, 3), if (g < 1e-9) "PASS" else "FAIL")
d <- rd_prep(file.path(W, "frames/final/AK_HCB_v103.csv")); stopifnot(all(is.finite(d$RD) & d$RD > 0)); logm("HCB rows", nrow(d), "plots", length(unique(d$plot)), "installations", length(unique(d$Install)))
FM <- list(C1 = HCB ~ HT / (1 + exp(-(b0 + b1 * sqrt(HT / 100) + b2 * log(pmax(HT / pmax(DBH, 0.1), 0.5)) + b3 * sqrt(pmax(BAL * BAPH + 1, 0)) + b4 * log(BAPH + 1) + b5 * log(pmax(BYI, 1) / 100)))),
           C2h = HCB ~ HT / (1 + exp(-(b0 + b1 * sqrt(HT / 100) + b2 * log(pmax(HT / pmax(DBH, 0.1), 0.5)) + b3 * sqrt(pmax(share * RD + 1, 0)) + b4 * log(RD) + b5 * log(pmax(BYI, 1) / 100)))))
fitn <- function(f, dd, starts) { best <- NULL
  for (s in starts) { m <- tryCatch(nls(f, data = dd, start = as.list(s), control = nls.control(maxiter = 500)), error = function(e) NULL)
    if (!is.null(m) && (is.null(best) || deviance(m) < deviance(best))) best <- m }
  best }
F <- list(); F$C1 <- fitn(FM$C1, d, list(HCB_P)); F$C2h <- fitn(FM$C2h, d, list(HCB_P, coef(F$C1), replace(coef(F$C1), c("b3", "b4"), 0)))
stopifnot(!is.null(F$C1), !is.null(F$C2h))
ll <- function(rss, n) n / 2 * (-log(2 * pi) - log(rss / n) - 1)
pD <- pr(eta_D(HCB_P, d), d); n <- nrow(d)
## LOIO
ins <- unique(d$Install)
LO <- do.call(rbind, lapply(ins, function(k) { tr <- d[d$Install != k, ]; te <- d[d$Install == k, ]
  out <- data.frame(Install = k, y = te$HCB, D = pr(eta_D(HCB_P, te), te), C1 = NA, C2h = NA)
  m1 <- fitn(FM$C1, tr, list(coef(F$C1), HCB_P)); if (!is.null(m1)) out$C1 <- predict(m1, te)
  m2 <- fitn(FM$C2h, tr, list(coef(F$C2h), coef(F$C1))); if (!is.null(m2)) out$C2h <- predict(m2, te); out }))
## plot-cluster bootstrap of b5 (BYI)
set.seed(SEED); ids <- unique(d$plot); sp <- split(seq_len(n), d$plot)
BS <- t(sapply(seq_len(NB), function(b) { dd <- d[unlist(sp[sample(ids, replace = TRUE)], use.names = FALSE), ]
  sapply(c("C1", "C2h"), function(m) { mm <- fitn(FM[[m]], dd, list(coef(F[[m]]))); if (is.null(mm)) NA else coef(mm)[["b5"]] }) }))
## monotonicity: HCB non-decreasing in stand density at fixed share, HT, HT/DBH, BYI
qs <- function(v) quantile(v, c(.1, .5, .9)); grid <- function(v) seq(quantile(v, .01), quantile(v, .99), length.out = 50)
mono <- function(p, rdform) { ok <- TRUE; res <- c()
  for (h in qs(d$HT)) for (hd in qs(d$HT / d$DBH)) for (by in qs(d$BYI)) for (sh in qs(d$share)) {
    if (rdform) { nd <- data.frame(HT = h, DBH = h / hd, BYI = by, share = sh, RD = grid(d$RD)); y <- pr(eta_R(p, nd), nd) }
    else { b <- grid(d$BAPH); nd <- data.frame(HT = h, DBH = h / hd, BYI = by, BAPH = b, BAL = sh * b); y <- pr(eta_D(p, nd), nd) }
    ok <- ok && all(diff(y) >= -1e-10) }
  ok }
cfs <- rbind(D = HCB_P, C1 = coef(F$C1), C2h = coef(F$C2h))
res <- data.frame(component = "HCB", cand = c("D", "C1", "C2h"), n = n, rss = c(sum((d$HCB - pD)^2), deviance(F$C1), deviance(F$C2h)), k = c(1, 7, 7))
res$logLik <- ll(res$rss, n); res$AIC <- -2 * res$logLik + 2 * res$k; res$dAIC <- res$AIC - res$AIC[1]
res$rmse <- sqrt(res$rss / n); res$loio_rmse <- c(rmse(LO$y, LO$D), with(LO[is.finite(LO$C1), ], rmse(y, C1)), with(LO[is.finite(LO$C2h), ], rmse(y, C2h)))
res$loio_rows <- c(nrow(LO), sum(is.finite(LO$C1)), sum(is.finite(LO$C2h)))
res <- cbind(res, cfs); res$b5_boot_lo <- c(NA, qboot(BS[, "C1"])["lo"], qboot(BS[, "C2h"])["lo"]); res$b5_boot_hi <- c(NA, qboot(BS[, "C1"])["hi"], qboot(BS[, "C2h"])["hi"])
res$b5_boot_ok <- c(NA, qboot(BS[, "C1"])["n_ok"], qboot(BS[, "C2h"])["n_ok"])
res$signs <- res$b1 > 0 & res$b2 < 0 & res$b5 < 0; res$signs_strict_HCB_P <- apply(sign(cfs) == matrix(sign(HCB_P), 3, 6, byrow = TRUE), 1, all)
res$mono <- c(mono(HCB_P, FALSE), mono(coef(F$C1), FALSE), mono(coef(F$C2h), TRUE)); res$gate_old_index_rmse_diff <- c(g, NA, NA)
write.csv(res, file.path(OUT, "hcb_results.csv"), row.names = FALSE); write.csv(BS, file.path(OUT, "hcb_boot.csv"), row.names = FALSE)
print(res, digits = 4); logm("cor ln(BAPH+1) vs ln(RD)", round(cor(log(d$BAPH + 1), log(d$RD)), 4)); logm("HCB DONE")
