## hcb_fit.R: Eq. 3 HCB. Baseline B = v105d C2h refit (RD = SDI/741.7117); HC1 (RD, share RD linear), HC2 (exp-constrained ln RD, share RD), HC3 (HC1 + lc2 RD).
source(path.expand("~/jobs/koa_formscreen_20261103/lib_cs.R"))
rd_prep <- function(f) { d <- read.csv(f, stringsAsFactors = FALSE, colClasses = c(Install = "character", Plot = "character")); nocoord(d)
  d <- d[is.finite(d$HCB) & is.finite(d$HT) & d$HT > 0 & is.finite(d$BYI), ]; d$plot <- paste(d$Install, d$Plot)
  d$BAL <- d$BALl; d$BAPH <- d$BAPH_hi; d$QMD <- sqrt(d$BAPH_hi / d$TPH_hi / (pi / 40000)); d$SDI <- d$TPH_hi * (d$QMD / 25.4)^1.605; d$RD <- d$SDI / POP
  d$share <- ifelse(d$BAPH > 0, d$BAL / d$BAPH, 0); d$lc2 <- log(pmax(d$BYI, 1) / 100); d }
d <- rd_prep(file.path(W, "frames/final/AK_HCB_v103.csv")); stopifnot(all(is.finite(d$RD) & d$RD > 0))
logm("HCB rows", nrow(d), "plots", length(unique(d$plot)), "installations", length(unique(d$Install)), "RD range", paste(signif(range(d$RD), 4), collapse = " "))
E0 <- "b0 + b1 * sqrt(HT / 100) + b2 * log(pmax(HT / pmax(DBH, 0.1), 0.5)) + b5 * lc2"
FM <- list(B = paste(E0, "+ b3 * sqrt(pmax(share * RD + 1, 0)) + b4 * log(RD)"), HC1 = paste(E0, "+ b3 * RD + b4 * share * RD"),
           HC2 = paste(E0, "+ exp(g3) * log(RD) + exp(g4) * share * RD"), HC3 = paste(E0, "+ b3 * RD + b4 * share * RD + b6 * lc2 * RD"))
FM <- lapply(FM, function(e) as.formula(paste("HCB ~ HT / (1 + exp(-(", e, ")))")))
fitn <- function(f, dd, starts) { best <- NULL
  for (s in starts) { m <- tryCatch(nls(f, data = dd, start = as.list(s), control = nls.control(maxiter = 500)), error = function(e) NULL)
    if (!is.null(m) && (is.null(best) || deviance(m) < deviance(best))) best <- m }
  best }
C2H <- c(b0 = -0.991220467774087, b1 = 0.0762310421638571, b2 = -1.26146477701742, b3 = 0.148582846601204, b4 = -0.150429809477625, b5 = -0.631911071201079)
F <- list(); F$B <- fitn(FM$B, d, list(C2H, replace(C2H, "b0", C2H[["b0"]] + C2H[["b4"]] * log(923 / POP))))
cb <- coef(F$B); F$HC1 <- fitn(FM$HC1, d, list(replace(cb, c("b3", "b4"), 0), replace(cb, c("b3", "b4"), c(0.5, 0.5))))
c1 <- coef(F$HC1); F$HC2 <- fitn(FM$HC2, d, list(c(c1[c("b0", "b1", "b2", "b5")], g3 = log(0.1), g4 = log(0.5)), c(c1[c("b0", "b1", "b2", "b5")], g3 = log(0.01), g4 = log(0.05)),
                                                c(c1[c("b0", "b1", "b2", "b5")], g3 = log(0.5), g4 = log(2))))
F$HC3 <- fitn(FM$HC3, d, list(c(c1, b6 = 0), c(c1, b6 = 0.5)))
for (m in names(F)) logm(m, if (is.null(F[[m]])) "FAILED" else paste(sprintf("%s=%.5g", names(coef(F[[m]])), coef(F[[m]])), collapse = " "), if (!is.null(F[[m]])) paste("rss", round(deviance(F[[m]]), 3)) else "")
mods <- names(F)[!sapply(F, is.null)]
ll <- function(rss, n) n / 2 * (-log(2 * pi) - log(rss / n) - 1); n <- nrow(d)
ins <- unique(d$Install)
LO <- do.call(rbind, lapply(ins, function(k) { tr <- d[d$Install != k, ]; te <- d[d$Install == k, ]
  do.call(rbind, lapply(mods, function(m) { mm <- fitn(FM[[m]], tr, list(coef(F[[m]]))); data.frame(Install = k, model = m, y = te$HCB, p = if (is.null(mm)) NA else predict(mm, te)) })) }))
## installation-cluster bootstrap of the new BYI term (HC3 b6) and of b5 (reported)
set.seed(SEED); sp <- split(seq_len(n), d$Install)
BS <- t(sapply(seq_len(NB), function(b) { dd <- d[unlist(sp[sample(ins, replace = TRUE)], use.names = FALSE), ]
  c(sapply(mods, function(m) { mm <- fitn(FM[[m]], dd, list(coef(F[[m]]))); if (is.null(mm)) NA else coef(mm)[["b5"]] }),
    HC3_b6 = { mm <- fitn(FM$HC3, dd, list(coef(F$HC3))); if (is.null(mm)) NA else coef(mm)[["b6"]] }) }))
colnames(BS)[seq_along(mods)] <- paste0(mods, "_b5")
## monotonicity: HCB non-decreasing in RD at fixed share, and in share at fixed RD
pr <- function(m, nd) predict(F[[m]], nd)
mono <- function(m) { ok <- TRUE; mx <- 0
  for (h in qs(d$HT)) for (hd in qs(d$HT / d$DBH)) for (l in qs(d$lc2)) {
    for (sh in qs(d$share)) { nd <- data.frame(HT = h, DBH = h / hd, lc2 = l, share = sh, RD = grid50(d$RD)); dy <- diff(pr(m, nd)); mx <- max(mx, -min(dy)); ok <- ok && all(dy >= -1e-10) }
    for (r in qs(d$RD)) { nd <- data.frame(HT = h, DBH = h / hd, lc2 = l, share = seq(0, 1, length.out = 50), RD = r); dy <- diff(pr(m, nd)); mx <- max(mx, -min(dy)); ok <- ok && all(dy >= -1e-10) } }
  c(ok = ok, max_decrease = mx) }
res <- do.call(rbind, lapply(mods, function(m) { cf <- coef(F[[m]]); se <- summary(F[[m]])$coefficients[, 2]; lo <- LO[LO$model == m & is.finite(LO$p), ]; mo <- mono(m)
  data.frame(component = "HCB", cand = m, n = n, rss = deviance(F[[m]]), k = length(cf) + 1, coefs = paste(sprintf("%s=%.5g (SE %.3g)", names(cf), cf, se), collapse = "; "),
             loio_rmse = rmse(lo$y, lo$p), loio_rows = nrow(lo), signs = cf[["b1"]] > 0 & cf[["b2"]] < 0 & cf[["b5"]] < 0, mono = as.logical(mo[["ok"]]), mono_max_decrease = mo[["max_decrease"]],
             b5_boot_lo = qboot(BS[, paste0(m, "_b5")])[["lo"]], b5_boot_hi = qboot(BS[, paste0(m, "_b5")])[["hi"]],
             byi_new_term = if (m == "HC3") "b6 (lc2 x RD)" else "", byi_boot_lo = if (m == "HC3") qboot(BS[, "HC3_b6"])[["lo"]] else NA,
             byi_boot_hi = if (m == "HC3") qboot(BS[, "HC3_b6"])[["hi"]] else NA, byi_boot_ok = if (m == "HC3") qboot(BS[, "HC3_b6"])[["n_ok"]] else NA) }))
res$logLik <- ll(res$rss, n); res$AIC <- -2 * res$logLik + 2 * res$k; res$dAIC <- res$AIC - res$AIC[res$cand == "B"]
write.csv(res, file.path(OUT, "hcb_results.csv"), row.names = FALSE); write.csv(BS, file.path(OUT, "hcb_boot.csv"), row.names = FALSE)
saveRDS(lapply(F, function(m) if (!is.null(m)) list(coef = coef(m), se = summary(m)$coefficients[, 2])), file.path(OUT, "hcb_fits.rds"))
print(res, digits = 4); logm("HCB DONE")
