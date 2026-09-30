## BYI temporal stability (R1 c8b). Two estimation routes:
##  Route 1 (primary): shape (k, p) recovered from the archived fit by least squares with the archived plot
##  asymptotes held fixed, then held at those values while A (fixed + county + plot random) is re-estimated by
##  lme (varPower on H40) separately on first-measurement and on second-measurement subplot rows of the
##  plots measured twice. This keeps plot BYI on the scale of the archived index.
##  Route 2 (sensitivity): the bounded profile-likelihood refits of 02_eq1_refits.R (k on its 0.01 bound).
## Agreement: Pearson and Spearman r, mean difference (second - first), Lin's CCC, OLS slope of second on first,
## TOST at +/-25% of the mean BYI, all with 2,000 plot-cluster bootstrap resamples (percentile intervals).
suppressMessages({library(data.table); library(nlme)})
set.seed(20260928); B <- 2000
a <- as.data.frame(fread("in/AGB.FIA.csv", integer64 = "character")); a$key <- paste(a$COUNTYCD, a$PLOT, sep = "/")
arch <- fread("in/Schmoldt_Index_by_plot.csv"); arch[, pid := paste(COUNTYCD, PLOT, sep = "/")]
a$Aarch <- arch$Schmoldt_Index[match(a$key, arch$pid)]
w <- 1 / a$H40.m^(2 * 1.1)
sh <- nls(AGB ~ Aarch * (1 - exp(-k * H40.m))^p, data = a, start = list(k = 0.05, p = 2.5), weights = w, control = nls.control(maxiter = 500))
k0 <- coef(sh)[["k"]]; p0 <- coef(sh)[["p"]]
cat(sprintf("recovered archived shape: k %.4f p %.3f; f(H40) at the median H40 (%.1f m) = %.3f, at 30 m = %.3f\n", k0, p0, median(a$H40.m),
            (1 - exp(-k0 * median(a$H40.m)))^p0, (1 - exp(-k0 * 30))^p0))
cat(sprintf("share of subplot rows with f(H40) < 0.5: %.3f\n", mean((1 - exp(-k0 * a$H40.m))^p0 < 0.5)))
fitA <- function(d, lab) { d$f <- (1 - exp(-k0 * d$H40.m))^p0; d$CTY <- factor(d$COUNTYCD); d$PID <- factor(d$key)
  m <- lme(AGB ~ 0 + f, random = list(CTY = ~ 0 + f, PID = ~ 0 + f), weights = varPower(0.2, form = ~H40.m), data = d, method = "ML",
           control = lmeControl(maxIter = 200, msMaxIter = 200, opt = "optim"))
  cf <- coef(m, level = 2); out <- data.table(pid = sub("^[^/]*/", "", rownames(cf)), A = cf$f)
  cat(sprintf("%s: rows %d plots %d fixed A %.1f\n", lab, nrow(d), nrow(out), fixef(m)[1])); out }
nv <- tapply(a$INVYR, a$key, function(x) length(unique(x))); two <- names(nv)[nv >= 2]
fv <- tapply(a$INVYR, a$key, min); lv <- tapply(a$INVYR, a$key, max)
R0 <- fitA(a, "route 1, all rows (reproduction check)")
z <- merge(R0, arch, by = "pid"); cat(sprintf("   route 1 all rows vs archived: r %.4f, median ratio %.3f\n", cor(z$A, z$Schmoldt_Index), median(z$A / z$Schmoldt_Index)))
R1 <- fitA(a[a$key %in% two & a$INVYR == fv[a$key], ], "route 1, first measurement")
R2 <- fitA(a[a$key %in% two & a$INVYR == lv[a$key], ], "route 1, second measurement")
agree <- function(x, y, lab) {
  n <- length(x); mb <- mean(c(x, y)); delta <- 0.25 * mb
  st <- function(i) { xi <- x[i]; yi <- y[i]
    c(pear = cor(xi, yi), spear = cor(xi, yi, method = "spearman"), md = mean(yi - xi), mdp = mean(yi - xi) / mean(c(xi, yi)),
      ccc = 2 * cov(xi, yi) / (var(xi) + var(yi) + (mean(xi) - mean(yi))^2), slope = unname(coef(lm(yi ~ xi))[2]),
      within25 = mean(abs(yi - xi) <= 0.25 * (xi + yi) / 2)) }
  e <- st(seq_len(n)); bt <- t(replicate(B, st(sample.int(n, n, TRUE))))
  q <- function(v, pr) unname(quantile(v, pr))
  out <- data.table(comparison = lab, n = n, mean_BYI = mb, stat = names(e), est = e,
                    lo95 = apply(bt, 2, q, .025), hi95 = apply(bt, 2, q, .975), lo90 = apply(bt, 2, q, .05), hi90 = apply(bt, 2, q, .95))
  tost_md <- (out[stat == "md"]$lo90 > -delta) & (out[stat == "md"]$hi90 < delta)
  tost_sl <- (out[stat == "slope"]$lo90 > 0.75) & (out[stat == "slope"]$hi90 < 1.25)
  cat(sprintf("%s: n %d, mean BYI %.1f, region +/- %.1f; mean diff %.1f (90%% %.1f to %.1f) -> %s; slope %.3f (90%% %.3f to %.3f) -> %s\n", lab, n, mb, delta,
              e["md"], out[stat == "md"]$lo90, out[stat == "md"]$hi90, ifelse(tost_md, "EQUIVALENT", "not shown equivalent"),
              e["slope"], out[stat == "slope"]$lo90, out[stat == "slope"]$hi90, ifelse(tost_sl, "EQUIVALENT", "not shown equivalent")))
  out[, `:=`(region = delta, tost_mean = tost_md, tost_slope = tost_sl)]; out }
m12 <- merge(R1, R2, by = "pid"); T <- agree(m12$A.x, m12$A.y, "Route 1: first vs second measurement (shape fixed at archived)")
za <- merge(m12, arch, by = "pid")
T <- rbind(T, agree(za$Schmoldt_Index, za$A.x, "Route 1: archived (both measurements) vs first only"))
T <- rbind(T, agree(za$Schmoldt_Index, za$A.y, "Route 1: archived (both measurements) vs second only"))
E <- readRDS("eq1_refits.rds"); e12 <- merge(E$F1, E$F2, by = c("COUNTYCD", "PLOT"))
T <- rbind(T, agree(e12$A.x, e12$A.y, "Route 2: first vs second measurement (bounded profile refits)"))
num <- c("mean_BYI", "est", "lo95", "hi95", "lo90", "hi90", "region"); T[, (num) := lapply(.SD, round, 3), .SDcols = num]
options(width = 220); print(T); fwrite(T, "out_T2_byi_temporal_agreement.csv")
## how the plot moved between measurements
d <- as.data.table(a)[key %in% two, .(H40 = mean(H40.m), AGB = mean(AGB)), by = .(pid = key, INVYR)]
dd <- dcast(d, pid ~ INVYR, value.var = c("H40", "AGB"))
cat(sprintf("two-visit plots: median H40 change %.2f m, median AGB change %.1f (frame units), share with AGB decline %.3f\n",
            median(dd$H40_2019 - dd$H40_2010, na.rm = TRUE), median(dd$AGB_2019 - dd$AGB_2010, na.rm = TRUE), mean(dd$AGB_2019 < dd$AGB_2010, na.rm = TRUE)))
dz <- merge(dd, m12, by = "pid"); cat(sprintf("Spearman of BYI change (second - first) with AGB change: %.3f; with H40 change: %.3f\n",
  cor(dz$A.y - dz$A.x, dz$AGB_2019 - dz$AGB_2010, method = "spearman", use = "complete.obs"), cor(dz$A.y - dz$A.x, dz$H40_2019 - dz$H40_2010, method = "spearman", use = "complete.obs")))
cat("done\n")
