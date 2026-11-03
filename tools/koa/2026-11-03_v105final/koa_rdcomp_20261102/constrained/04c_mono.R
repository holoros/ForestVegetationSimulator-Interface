## 04c_mono.R: monotonicity check (PREREG_K3c): d ln g / d x <= 0, x = share x RD in [0, 2], DBH 2.5/10/25/40/60, other covariates at p5/p50/p95, Planted 0/1.
source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/lib_c.R"))
dK <- frameK("dDBH", "K3p"); d0 <- frameK("dDBH", "K0"); X <- seq(0, 2, by = 0.01); h <- 1e-6; out <- list()
for (cand in c("K0c", "K3pc", "K3c1", "K3c2")) { f <- file.path(OC, sprintf("fit_%s.rds", cand)); if (!file.exists(f)) next; R <- readRDS(f); if (!isTRUE(R$ok)) next
  M3 <<- MODE[[cand]]; b <- R$b; dd <- if (cand == "K0c") d0 else dK; b3 <- if ("b3" %in% names(b)) b[["b3"]] else 0
  for (pl in 0:1) for (pq in c(0.05, 0.5, 0.95)) { RD <- quantile(dd$BAPH.0, pq, names = FALSE); CR <- quantile(dd$CRx.0, pq, names = FALSE); BY <- quantile(dd$BYI, pq, names = FALSE)
    for (S in c(2.5, 10, 25, 40, 60)) {
      lng <- function(x) log(gr.hat3c(rep(S, length(x)), x, x, CR, CR, RD, RD, pl, BY, rep(1, length(x)), b[["b0"]], b[["b1"]], b[["b2"]], b[["b4"]], b[["b5"]], b[["b6"]], b[["b7"]], b[["b8"]], b[["b9"]], b3 = b3))
      fd <- (lng(X + h) - lng(X - h)) / (2 * h)
      an <- b[["b4"]] / (X + 1) + (if (M3 == "sq") 2 * b3 * X / log(S + 5) else if (M3 == "lin") b3 / log(S + 5) else 0)
      out[[length(out) + 1]] <- data.frame(cand = cand, Planted = pl, cov_pct = pq * 100, RD = RD, CR = CR, BYI = BY, DBH = S, x = X, deriv_fd = fd, deriv_an = an) } } }
G <- do.call(rbind, out); write.csv(G, file.path(OC, "monotonicity_grid.csv"), row.names = FALSE)
S <- do.call(rbind, lapply(split(G, G$cand), function(g) data.frame(cand = g$cand[1], n_grid = nrow(g), max_deriv_fd = max(g$deriv_fd), max_deriv_an = max(g$deriv_an),
  max_abs_fd_minus_an = max(abs(g$deriv_fd - g$deriv_an)), n_pos = sum(g$deriv_fd > 1e-10 | g$deriv_an > 0), pass = all(g$deriv_fd <= 1e-10 & g$deriv_an <= 0),
  min_x_pos = if (any(g$deriv_an > 0)) min(g$x[g$deriv_an > 0]) else NA)))
## compact table: max derivative by DBH (over x, percentiles and origin)
T <- aggregate(deriv_an ~ cand + DBH, G, max); names(T)[3] <- "max_deriv"
print(S, digits = 5); print(T, digits = 4); write.csv(S, file.path(OC, "monotonicity_summary.csv"), row.names = FALSE); write.csv(T, file.path(OC, "monotonicity_by_dbh.csv"), row.names = FALSE)
