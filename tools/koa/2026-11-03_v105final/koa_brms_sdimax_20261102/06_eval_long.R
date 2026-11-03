## 06_eval_long.R (AMENDMENT 2): evaluate RI_LONG (original + relaxed tiers), LQMM convergence, apply the AMENDMENT 2 rule of record.
suppressPackageStartupMessages({library(data.table); library(brms); library(posterior)})
options(cmdstanr_no_ver_check = TRUE)
J <- path.expand("~/jobs/koa_brms_sdimax_20261102"); setwd(J)
LQ <- fread("out/lqmm_estimates.csv"); lq_ok <- isTRUE(LQ[tau == 0.95, converged])
f <- "fits/RI_LONG_ad0.99_it6000_td12.rds"; ri_orig <- FALSE; ri_rel <- FALSE; EV <- NULL
if (file.exists(f)) {
  fit <- readRDS(f); dr <- as_draws_df(fit)
  hyp <- grep("^(b_|sd_|cor_|sigma$)", names(dr), value = TRUE)
  dr$SDImax_pop <- exp(dr$b_Intercept + dr$b_lqmd * log(25.4))
  s <- setDT(summarise_draws(subset_draws(dr, variable = c(hyp, "SDImax_pop")), mean, ~quantile(.x, c(.025, .975)), rhat, ess_bulk, ess_tail))
  print(s); sh <- s[variable != "SDImax_pop"]
  np <- nuts_params(fit); ndiv <- sum(np$Value[np$Parameter == "divergent__"]); ntd <- sum(np$Value[np$Parameter == "treedepth__"] >= 12)
  ri_orig <- all(sh$rhat < 1.01) && all(sh$ess_bulk > 400) && all(sh$ess_tail > 400) && ndiv == 0
  ri_rel <- all(sh$rhat < 1.05) && all(sh$ess_bulk > 100) && ndiv == 0
  EV <- data.table(fit = "RI_LONG", file = normalizePath(f), n_hyper = nrow(sh), max_rhat = max(sh$rhat), min_ess_bulk = min(sh$ess_bulk), min_ess_tail = min(sh$ess_tail),
                   divergent = ndiv, treedepth12_hits = ntd, n_draws = nrow(dr), pass_original = ri_orig, pass_relaxed = ri_rel)
  fwrite(cbind(fit = "RI_LONG", s), "out/fit_summary_rilong.csv")
}
tier <- if (is.null(EV)) "not_run" else if (ri_orig) "original" else if (ri_rel) "relaxed_only_PROVISIONAL" else "fail"
rec <- if (ri_orig) "RI_LONG" else if (lq_ok) "LQMM_tau0.95" else NA_character_
out <- data.table(fit = c("RI_LONG", "LQMM_tau0.95", "LQMM_tau0.99"),
                  converged_or_tier = c(tier, as.character(lq_ok), as.character(isTRUE(LQ[tau == 0.99, converged]))),
                  role = c(fifelse(!is.na(rec) & rec == "RI_LONG", "of_record", fifelse(tier == "relaxed_only_PROVISIONAL", "provisional", "not_of_record")),
                           fifelse(!is.na(rec) & rec == "LQMM_tau0.95", "of_record", fifelse(rec %in% "RI_LONG" & lq_ok, "comparison", "not_of_record")),
                           "sensitivity"))
if (!is.null(EV)) fwrite(EV, "out/fit_eval_rilong.csv")
fwrite(out, "out/record_amend2.csv"); print(EV); print(out)
cat(if (is.na(rec)) "NO FIT OF RECORD (pooled frontier stands)" else paste("FIT OF RECORD:", rec), "| RI_LONG tier:", tier, "\n")
## fits_used file for 03_post.R (RI_LONG as of_record or provisional)
if (tier %in% c("original", "relaxed_only_PROVISIONAL"))
  fwrite(data.table(fit = "RI_LONG", file = normalizePath(f), role = "of_record", pass = ri_orig), "out/fits_used_rilong.csv")
