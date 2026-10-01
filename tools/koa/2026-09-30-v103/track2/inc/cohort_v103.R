## cohort_v103.R: cohort BAL fraction (koa_params.BAL_COHORT_LIN_B form, frac = a0 + a1 ln QMD over stems within 5 percent of QMD, plot-years with
## >= 5 positive-diameter stems), Part E of refit2.R, on the repaired v103 tree table (repaired BAPH, QMD) under d, l, c; plot-clustered SEs.
## Gate: the same code on refit2's bal_treevisit2.csv reproduces cohort_bal_fraction2.csv.
W <- path.expand("~/jobs/koa_v103_20260930"); R2D <- path.expand("~/jobs/koa_refit_20260929")
cof <- function(T) { T$key <- paste(T$Data, T$Install, T$Plot, T$Measure, sep = "|"); T$live <- T$Status == "live" & is.finite(T$DBH) & T$DBH > 0
  py <- split(seq_len(nrow(T)), T$key); CO <- list()
  for (b in c("d", "l", "c")) { v <- paste0("BAL", b)
    rr <- lapply(py, function(g) { x <- T[g, ]; L <- x$live & is.finite(x[[v]]); if (sum(x$DBH > 0, na.rm = TRUE) < 5 || sum(L) == 0) return(NULL)
      q <- x$QMD[1]; if (!is.finite(q) || q <= 0 || !is.finite(x$BAPH[1]) || x$BAPH[1] <= 0) return(NULL)
      near <- L & abs(x$DBH - q) <= 0.05 * q; if (!any(near)) return(NULL)
      data.frame(key = x$key[1], plot = paste(x$Data[1], x$Install[1], x$Plot[1]), QMD = q, frac = mean(x[[v]][near] / x$BAPH[near])) })
    cf <- do.call(rbind, rr); cf <- cf[is.finite(cf$frac), ]; m <- lm(frac ~ log(QMD), data = cf)
    X <- model.matrix(m); e <- resid(m); XtXi <- solve(crossprod(X)); meat <- Reduce(`+`, lapply(split(seq_len(nrow(X)), cf$plot), function(i) { u <- crossprod(X[i, , drop = FALSE], e[i]); u %*% t(u) })); V <- XtXi %*% meat %*% XtXi
    CO[[b]] <- data.frame(bal = b, n_plotyears = nrow(cf), n_plots = length(unique(cf$plot)), a0 = coef(m)[[1]], a1 = coef(m)[[2]], se_a0_cluster = sqrt(V[1, 1]), se_a1_cluster = sqrt(V[2, 2]), r2 = summary(m)$r.squared, mean_frac = mean(cf$frac), row.names = NULL) }
  do.call(rbind, CO) }
T2 <- read.csv(file.path(R2D, "out/bal_treevisit2.csv"), stringsAsFactors = FALSE); T2$BALd <- T2$BAL
g <- cof(T2); ref <- read.csv(file.path(R2D, "out/cohort_bal_fraction2.csv"))
dd <- max(abs(g$a0 - ref$a0), abs(g$a1 - ref$a1)); cat("COHORT REPRODUCTION on refit2 bal_treevisit2: max abs diff", dd, if (dd < 1e-9) "PASS" else "FAIL", "\n"); print(g); print(ref)
T3 <- read.csv(file.path(W, "inputs/AK_TREE_v103.csv"), stringsAsFactors = FALSE); c3 <- cof(T3); print(c3)
write.csv(rbind(cbind(version = "refit2_repro", g), cbind(version = "v103", c3)), file.path(W, "out/inc/cohort_bal_fraction_v103.csv"), row.names = FALSE)
cat("COHORT DONE\n")
