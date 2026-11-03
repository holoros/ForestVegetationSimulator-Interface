## hcb_hc2_port.R (deviation): HC2 did not converge with exp(g3), exp(g4) under nls Gauss-Newton (3 starts). Same model refitted with the linear
## coefficients b3 (ln RD) and b4 (share RD) bounded at >= 0 by nls algorithm "port" (the exp parametrization's closure, boundary allowed).
source(path.expand("~/jobs/koa_formscreen_20261103/lib_cs.R"))
rd_prep <- function(f) { d <- read.csv(f, stringsAsFactors = FALSE, colClasses = c(Install = "character", Plot = "character")); nocoord(d)
  d <- d[is.finite(d$HCB) & is.finite(d$HT) & d$HT > 0 & is.finite(d$BYI), ]; d$plot <- paste(d$Install, d$Plot)
  d$BAL <- d$BALl; d$BAPH <- d$BAPH_hi; d$QMD <- sqrt(d$BAPH_hi / d$TPH_hi / (pi / 40000)); d$SDI <- d$TPH_hi * (d$QMD / 25.4)^1.605; d$RD <- d$SDI / POP
  d$share <- ifelse(d$BAPH > 0, d$BAL / d$BAPH, 0); d$lc2 <- log(pmax(d$BYI, 1) / 100); d }
d <- rd_prep(file.path(W, "frames/final/AK_HCB_v103.csv")); n <- nrow(d)
f <- HCB ~ HT / (1 + exp(-(b0 + b1 * sqrt(HT / 100) + b2 * log(pmax(HT / pmax(DBH, 0.1), 0.5)) + b5 * lc2 + b3 * log(RD) + b4 * share * RD)))
lw <- c(b0 = -Inf, b1 = -Inf, b2 = -Inf, b5 = -Inf, b3 = 0, b4 = 0)
fitp <- function(dd, starts) { best <- NULL; for (s in starts) { m <- tryCatch(nls(f, data = dd, start = as.list(s[names(lw)]), algorithm = "port", lower = lw, control = nls.control(maxiter = 500)), error = function(e) NULL)
  if (!is.null(m) && (is.null(best) || deviance(m) < deviance(best))) best <- m }; best }
H1 <- readRDS(file.path(OUT, "hcb_fits.rds"))$HC1$coef
m <- fitp(d, list(c(H1[c("b0", "b1", "b2", "b5")], b3 = 0.1, b4 = 0.5), c(H1[c("b0", "b1", "b2", "b5")], b3 = 0.01, b4 = 0.01), c(H1[c("b0", "b1", "b2", "b5")], b3 = 0, b4 = 0)))
cf <- coef(m); logm("HC2 (port, b3, b4 >= 0):", paste(sprintf("%s=%.5g", names(cf), cf), collapse = " "), "rss", round(deviance(m), 3), "| at bound:", paste(names(cf)[c(cf[["b3"]], cf[["b4"]]) <= 1e-8 & names(cf) %in% c("b3", "b4")], collapse = ","))
LO <- do.call(rbind, lapply(unique(d$Install), function(k) { tr <- d[d$Install != k, ]; te <- d[d$Install == k, ]; mm <- fitp(tr, list(coef(m), c(coef(m)[c("b0", "b1", "b2", "b5")], b3 = 0.01, b4 = 0.01)))
  data.frame(y = te$HCB, p = if (is.null(mm)) NA else predict(mm, te)) }))
ll <- function(rss, n) n / 2 * (-log(2 * pi) - log(rss / n) - 1)
B <- read.csv(file.path(OUT, "hcb_results.csv")); bB <- B[B$cand == "B", ]
## monotone by construction when b3, b4 >= 0 (eta non-decreasing in RD and share); grid check as hcb_fit.R
mx <- 0; for (h in qs(d$HT)) for (hd in qs(d$HT / d$DBH)) for (l in qs(d$lc2)) { for (sh in qs(d$share)) { nd <- data.frame(HT = h, DBH = h / hd, lc2 = l, share = sh, RD = grid50(d$RD)); mx <- max(mx, -min(diff(predict(m, nd)))) }
  for (r in qs(d$RD)) { nd <- data.frame(HT = h, DBH = h / hd, lc2 = l, share = seq(0, 1, length.out = 50), RD = r); mx <- max(mx, -min(diff(predict(m, nd)))) } }
k <- 7; out <- data.frame(component = "HCB", cand = "HC2", n = n, rss = deviance(m), k = k, coefs = paste(sprintf("%s=%.5g", names(cf), cf), collapse = "; "),
  loio_rmse = rmse(LO$y[is.finite(LO$p)], LO$p[is.finite(LO$p)]), loio_rows = sum(is.finite(LO$p)), signs = cf[["b1"]] > 0 & cf[["b2"]] < 0 & cf[["b5"]] < 0, mono = mx <= 1e-10, mono_max_decrease = mx,
  b5_boot_lo = NA, b5_boot_hi = NA, byi_new_term = "", byi_boot_lo = NA, byi_boot_hi = NA, byi_boot_ok = NA, logLik = ll(deviance(m), n))
out$AIC <- -2 * out$logLik + 2 * k; out$dAIC <- out$AIC - bB$AIC
B <- rbind(B[B$cand != "HC2", ], out[, names(B)]); write.csv(B, file.path(OUT, "hcb_results.csv"), row.names = FALSE); print(out); logm("HC2 PORT DONE")
