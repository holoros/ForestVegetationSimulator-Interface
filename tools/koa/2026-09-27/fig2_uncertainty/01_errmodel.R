## Out-of-bag error models for the two BYI spatial random forests (Kona and statewide).
## OOB predictions: Kona from the archived per-plot OOB file, checked against ranger's own
## prediction.error; statewide recovered by refitting with the stored ranger arguments and seed,
## accepted only if prediction.error reproduces the archived fit.
suppressMessages({library(ranger); library(data.table)})
set.seed(20260927)
out <- list()
ref <- function(f, lab) {
  m <- readRDS(f); a <- m$ranger.arguments
  y <- a$data[[m$dependent.variable.name]]
  cat(lab, ": archived OOB MSE", m$prediction.error, " seed", if (is.null(a$seed)) "NULL" else a$seed, "\n")
  args <- a[intersect(names(a), names(formals(ranger::ranger)))]
  args$importance <- "none"; args$local.importance <- FALSE; args$num.threads <- 6
  r <- do.call(ranger::ranger, args)
  cat(lab, ": refit OOB MSE", r$prediction.error, " diff", r$prediction.error - m$prediction.error, "\n")
  data.table(model = lab, obs = y, oob = r$predictions, refit_mse = r$prediction.error, arch_mse = m$prediction.error)
}
k <- ref("in/BYI_srf_fit.RDS", "Kona")
s <- ref("in/BYI_srf_fit_HI.RDS", "statewide")
o <- readRDS("in/BYI_OOB_per_plot.rds")
cat("archived Kona OOB file: RMSE", sqrt(mean((o$obs - o$oob_pred)^2)), " n", length(o$obs),
    " obs identical to fit y:", isTRUE(all.equal(o$obs, k$obs)), "\n")
cat("refit Kona OOB vs archived file: max |diff|", max(abs(k$oob - o$oob_pred)), "\n")
d <- rbind(k, s); d[, sq := (obs - oob)^2]
print(d[, .(n = .N, n_zero = sum(obs == 0), rmse_oob = sqrt(mean(sq)), min_oob = min(oob), max_oob = max(oob), max_obs = max(obs)), by = model])
fwrite(d[, .(model, obs, oob)], "out_oob_pairs_DATA.csv")
