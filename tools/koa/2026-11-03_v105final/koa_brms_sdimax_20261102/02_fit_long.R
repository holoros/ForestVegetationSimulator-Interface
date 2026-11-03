## 02_fit_long.R (AMENDMENT 2a): RI_LONG = RI_UNCENTERED rerun, 4 chains (reduced from 6, see AMENDMENT 2) x 6,000 iter (3,000 warmup),
## adapt_delta 0.99, max_treedepth 12, same priors and seed 54321, 4 cores.
suppressPackageStartupMessages({library(data.table); library(brms)})
options(cmdstanr_no_ver_check = TRUE)
J <- path.expand("~/jobs/koa_brms_sdimax_20261102")
D <- fread(file.path(J, "out/fit_frame.csv"))
key <- fread(file.path(J, "out/id_key.csv"))   # same gid key as the earlier fits
D <- merge(D, key, by = "ID"); D[, ID_orig := ID]; D[, ID := gid]
f <- bf(ltph ~ 0 + Intercept + lqmd + (1 | ID), quantile = 0.95)
pr <- c(prior(normal(12.634, 0.119), class = b, coef = Intercept), prior(normal(-1.797, 0.106), class = b, coef = lqmd),
        prior(normal(0, 0.81), class = sd, group = ID, coef = Intercept))
cat("RI_LONG start", format(Sys.time()), "\n"); t0 <- Sys.time()
fit <- brm(f, data = as.data.frame(D), family = asym_laplace(), prior = pr, chains = 4, cores = 4, iter = 6000, warmup = 3000,
           seed = 54321, backend = "cmdstanr", control = list(adapt_delta = 0.99, max_treedepth = 12), silent = 0, refresh = 250)
cat("RI_LONG elapsed min", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2), "\n")
saveRDS(fit, file.path(J, "fits", "RI_LONG_ad0.99_it6000_td12.rds"))
print(prior_summary(fit)); print(summary(fit))
np <- nuts_params(fit); cat("divergent after warmup:", sum(np$Value[np$Parameter == "divergent__"]), "\n")
cat("treedepth >= 12 hits:", sum(np$Value[np$Parameter == "treedepth__"] >= 12), "\n")
print(table(np$Value[np$Parameter == "treedepth__"]))
