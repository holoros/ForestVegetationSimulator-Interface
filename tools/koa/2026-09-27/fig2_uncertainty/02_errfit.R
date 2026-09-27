## Local OOB RMSE as a function of predicted BYI, one loess per model, same response and span as the
## April 2026 confidence script (loess of squared residual on prediction, span 0.6) but local
## linear (degree 1; degree 2 bent upward past 600 Mg ha-1 on 41 points, 561 against a binned 326), on
## OUT-OF-BAG pairs and all plots, not in-sample forested plots. Predictions beyond the
## observed OOB prediction range are held at the edge value (no extrapolation of the curve).
suppressMessages(library(data.table))
d <- fread("out_oob_pairs_DATA.csv"); d[, sq := (obs - oob)^2]
fits <- list(); tab <- list()
G <- c(0, 25, 50, 100, 150, 200, 264, 300, 400, 450, 600, 800, 1000, 1256)
for (m in c("Kona", "statewide")) {
  x <- d[model == m]
  lo <- loess(sq ~ oob, data = x, span = 0.6, degree = 1, control = loess.control(surface = "direct"))
  rng <- range(x$oob)
  f <- function(v) { v2 <- pmin(pmax(v, rng[1]), rng[2]); p <- predict(lo, newdata = data.frame(oob = v2)); sqrt(pmax(p, 0)) }
  fits[[m]] <- list(lo = lo, rng = rng)
  tab[[m]] <- data.table(model = m, BYI = G, local_rmse = round(f(G), 1))
  ## check: mean of predicted local MSE over the training OOB preds recovers the global OOB MSE
  cat(m, ": global OOB RMSE", round(sqrt(mean(x$sq)), 1), " sqrt(mean fitted MSE)", round(sqrt(mean(f(x$oob)^2)), 1),
      " oob range", round(rng, 1), " any negative fitted MSE:", any(predict(lo) < 0), "\n")
  ## binned empirical check
  x[, bin := cut(oob, c(-1, 25, 100, 200, 300, 450, 2000))]
  print(x[, .(n = .N, emp_rmse = round(sqrt(mean(sq)), 1), loess_rmse = round(sqrt(mean(f(oob)^2)), 1)), by = bin][order(bin)])
}
print(dcast(rbindlist(tab), BYI ~ model, value.var = "local_rmse"))
saveRDS(fits, "out/errmodels.rds"); fwrite(rbindlist(tab), "out/local_rmse_table.csv")
