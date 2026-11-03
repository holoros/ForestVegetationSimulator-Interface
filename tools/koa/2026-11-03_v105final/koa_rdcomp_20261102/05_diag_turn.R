## 05_diag_turn.R (diagnostic, not part of the rule): for candidates with b3 > 0 (BAL^2 term positive), the BAL-type competition effect
## f(x) = b3 x^2/ln(S+5) + b4 ln(x+1) stops decreasing at d f/dx = 0. Share of rows (t.0) beyond the turning point, and the range of x.
source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R"))
out <- list()
for (resp in c("dDBH", "dHT")) for (k in CANDS) { R <- readRDS(file.path(OB, sprintf("fit_%s.rds", k)))[[resp]]; d <- frameK(resp, k)
  S <- if (resp == "dDBH") d$DBH.0 else d$HT.0; x <- d$BALx.0; b3 <- R$b[["b3"]]; b4 <- R$b[["b4"]]
  slope <- 2 * b3 * x / log(S + 5) + b4 / (x + 1)
  f <- b3 * x^2 / log(S + 5) + b4 * log(x + 1)
  out[[paste(resp, k)]] <- data.frame(resp = resp, cand = k, b3 = b3, b4 = b4, x_p50 = median(x), x_p95 = quantile(x, .95), x_max = max(x),
    share_rows_slope_pos = mean(slope > 0), share_rows_f_pos = mean(f > 0)) }
o <- do.call(rbind, out); rownames(o) <- NULL; print(o, digits = 4); write.csv(o, file.path(OB, "diag_bal_turning.csv"), row.names = FALSE)
