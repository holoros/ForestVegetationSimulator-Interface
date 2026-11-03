## 03a_eval.R (AMENDMENT 1): evaluate every finished fit against the preregistered criteria and apply the selection rule.
## Criteria on all b_, sd_, cor_ and sigma: Rhat < 1.01, bulk ESS > 400, tail ESS > 400; zero divergent transitions after warmup.
suppressPackageStartupMessages({library(data.table); library(brms); library(posterior)})
options(cmdstanr_no_ver_check = TRUE)
J <- path.expand("~/jobs/koa_brms_sdimax_20261102"); setwd(J)
order_rec <- c("PRIMARY", "SENS_UNCENTERED", "RI_UNCENTERED"); all_fits <- c(order_rec, "SENS_WEAK")
files <- list.files("fits", pattern = "^(PRIMARY|SENS_UNCENTERED|RI_UNCENTERED|SENS_WEAK)_ad.*\\.rds$", full.names = TRUE)
EV <- list(); SS <- list()
for (f in files) {
  fn <- sub("_ad.*$", "", basename(f)); fit <- readRDS(f); dr <- as_draws_df(fit)
  hyp <- grep("^(b_|sd_|cor_|sigma$)", names(dr), value = TRUE)
  dr$SDImax_pop <- exp(dr$b_Intercept + dr$b_lqmd * log(25.4))   # population-level (typical plot) value, diagnostic only
  s <- setDT(summarise_draws(subset_draws(dr, variable = hyp), mean, ~quantile(.x, c(.025, .975)), rhat, ess_bulk, ess_tail))
  sp <- setDT(summarise_draws(subset_draws(dr, variable = "SDImax_pop"), mean, ~quantile(.x, c(.025, .975)), rhat, ess_bulk, ess_tail))
  SS[[fn]] <- cbind(fit = fn, rbind(s, sp))
  np <- nuts_params(fit); ndiv <- sum(np$Value[np$Parameter == "divergent__"]); ntd <- sum(np$Value[np$Parameter == "treedepth__"] >= 10)
  EV[[fn]] <- data.table(fit = fn, file = normalizePath(f), n_hyper = nrow(s), max_rhat = max(s$rhat), min_ess_bulk = min(s$ess_bulk), min_ess_tail = min(s$ess_tail),
                         divergent = ndiv, treedepth_hits = ntd, n_draws = nrow(dr),
                         pass = all(s$rhat < 1.01) && all(s$ess_bulk > 400) && all(s$ess_tail > 400) && ndiv == 0)
  cat(fn, "\n"); print(s[, .(variable, mean = round(mean, 4), rhat = round(rhat, 4), ess_bulk = round(ess_bulk), ess_tail = round(ess_tail))])
}
E <- rbindlist(EV); E <- E[order(match(fit, all_fits))]
cand <- E[fit %in% order_rec & pass == TRUE][order(match(fit, order_rec))]
rec <- if (nrow(cand)) cand$fit[1] else NA_character_
E[, role := fifelse(!is.na(rec) & fit == rec, "of_record", fifelse(fit == "SENS_WEAK", "sensitivity", "not_of_record"))]
E[, eligible_for_record := fit %in% order_rec]
fwrite(E, "out/fit_eval.csv"); fwrite(rbindlist(SS), "out/fit_summary.csv")   # SDImax_pop rows are not part of the criteria; print(E[, !"file"])
missing <- setdiff(order_rec, E$fit); if (length(missing)) cat("NOTE: fits not finished:", paste(missing, collapse = ","), "\n")
if (is.na(rec)) cat("NO FIT OF RECORD: none of", paste(order_rec, collapse = ", "), "met the criteria\n") else cat("FIT OF RECORD:", rec, "\n")
fwrite(E[, .(fit, file, role, pass)], "out/fits_used.csv")
