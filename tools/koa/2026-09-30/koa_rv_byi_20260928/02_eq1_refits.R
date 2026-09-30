## Eq. 1 refits by profile likelihood (R1 c8b). nlme 3.1-170 on this host stops with "Singularity in backsolve
## at level 0" for the archived nlme call (and for every variant tried in 02a/02b/02c), so Eq. 1 is fitted in its
## exactly equivalent conditionally linear form: given (k, p), AGB = (A + b_county + b_plot) * f(H40; k, p) + e,
## Var(e) = s^2 * H40^(2 delta), which is an lme with the regressor f and random slopes on f. (k, p) are chosen
## by maximizing the ML log-likelihood (nlme's default method) within the archived bounds k in [0.01, 0.20],
## p in [0.5, 5]. Unbounded, the likelihood runs to k -> 0 and A -> infinity (02_eq1_refits_UNBOUNDED.log). Plot BYI is the conditional asymptote.
suppressMessages({library(data.table); library(nlme)})
set.seed(20260928)
a0 <- as.data.frame(fread("in/AGB.FIA.csv", integer64 = "character"))
a0$CTY <- factor(a0$COUNTYCD); a0$PID <- factor(paste(a0$COUNTYCD, a0$PLOT, sep = "/"))
fitEq1 <- function(d, lab) {
  t0 <- Sys.time(); d$PID <- droplevels(d$PID); d$CTY <- droplevels(d$CTY)
  one <- function(k, p, ret = FALSE) { d$f <- (1 - exp(-k * d$H40.m))^p
    m <- try(lme(AGB ~ 0 + f, random = list(CTY = ~ 0 + f, PID = ~ 0 + f), weights = varPower(0.2, form = ~H40.m), data = d, method = "ML",
                 control = lmeControl(maxIter = 200, msMaxIter = 200, opt = "optim", returnObject = TRUE)), silent = TRUE)
    if (ret) return(m); if (inherits(m, "try-error")) return(1e10); -as.numeric(logLik(m)) }
  o <- optim(c(0.0377, 2.78), function(th) one(th[1], th[2]), method = "L-BFGS-B", lower = c(0.01, 0.5), upper = c(0.20, 5), control = list(maxit = 100, factr = 1e9, parscale = c(0.01, 1)))
  k <- o$par[1]; p <- o$par[2]; m <- one(k, p, TRUE)
  cf <- coef(m, level = 2); out <- data.table(PID = sub("^[^/]*/", "", rownames(cf)), A = cf$f)
  out[, c("COUNTYCD", "PLOT") := tstrsplit(PID, "/", type.convert = TRUE)]
  cat(sprintf("%s: rows %d plots %d | A %.1f k %.4f p %.3f | sd county %.1f sd plot %.1f | power %.3f | logLik %.2f | conv %d | %.0f s\n",
              lab, nrow(d), nrow(out), fixef(m)[1], k, p, as.numeric(VarCorr(m)[2, 2]), as.numeric(VarCorr(m)[4, 2]),
              coef(m$modelStruct$varStruct, unconstrained = FALSE), as.numeric(logLik(m)), o$convergence, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  cat(sprintf("   plot A: min %.1f median %.1f max %.1f\n", min(out$A), median(out$A), max(out$A)))
  out[, .(COUNTYCD, PLOT, A)]
}
arch <- fread("in/Schmoldt_Index_by_plot.csv")
F0 <- fitEq1(a0, "full frame as archived")
z <- merge(F0, arch, by = c("COUNTYCD", "PLOT"))
cat(sprintf("   reproduction vs archived Schmoldt_Index_by_plot.csv: n %d, r %.5f, median ratio %.4f, max |diff| %.2f\n", nrow(z), cor(z$A, z$Schmoldt_Index), median(z$A / z$Schmoldt_Index), max(abs(z$A - z$Schmoldt_Index))))
ad <- a0[!duplicated(paste(a0$PLT_CN, a0$SUBP)), ]
Fd <- fitEq1(ad, "condition-deduplicated frame")
z <- merge(Fd, F0, by = c("COUNTYCD", "PLOT")); cat(sprintf("   dedup vs full: r %.4f, median ratio %.3f\n", cor(z$A.x, z$A.y), median(z$A.x / z$A.y)))
a0$key <- paste(a0$COUNTYCD, a0$PLOT)
fv <- tapply(a0$INVYR, a0$key, min); lv <- tapply(a0$INVYR, a0$key, max); nv <- tapply(a0$INVYR, a0$key, function(x) length(unique(x)))
two <- names(nv)[nv >= 2]; cat("plots with >= 2 measurements:", length(two), " with 1:", sum(nv == 1), "\n")
cat("measurement years:"); print(table(a0$INVYR[!duplicated(paste(a0$key, a0$INVYR))]))
first_all <- a0[a0$INVYR == fv[a0$key], ]
F1 <- fitEq1(first_all[first_all$key %in% two, ], "first measurement, two-visit plots")
F2 <- fitEq1(a0[a0$key %in% two & a0$INVYR == lv[a0$key], ], "second measurement, two-visit plots")
F1a <- fitEq1(first_all, "first measurement, all plots")
F0two <- fitEq1(a0[a0$key %in% two, ], "both measurements, two-visit plots")
saveRDS(list(F0 = F0, Fd = Fd, F1 = F1, F2 = F2, F1a = F1a, F0two = F0two), "eq1_refits.rds")
cat("done\n")
