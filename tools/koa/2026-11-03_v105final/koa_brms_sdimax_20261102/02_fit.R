## 02_fit.R <fit> <adapt_delta> <iter>: brms SDImax fit (CONUS spec). 4 chains x 4 cores.
args <- commandArgs(TRUE); fitname <- args[1]; ad <- as.numeric(args[2]); it <- as.integer(args[3])
suppressPackageStartupMessages({library(data.table); library(brms)})
options(cmdstanr_no_ver_check = TRUE)
J <- path.expand("~/jobs/koa_brms_sdimax_20261102")
D <- fread(file.path(J, "out/fit_frame.csv"))
key <- data.table(ID = sort(unique(D$ID))); key[, gid := sprintf("g%04d", .I)]
fwrite(key, file.path(J, "out/id_key.csv"))
D <- merge(D, key, by = "ID"); D[, ID_orig := ID]; D[, ID := gid]
prior_conus <- c(prior(normal(12.634, 0.119), class = Intercept),
                 prior(normal(-1.797, 0.106), class = b, coef = lqmd),
                 prior(normal(0, 0.81), class = sd, group = ID, coef = Intercept),
                 prior(normal(0, 0.25), class = sd, group = ID, coef = lqmd))
prior_weak <- c(prior(normal(12, 2), class = Intercept),
                prior(normal(-1.6, 0.5), class = b, coef = lqmd),
                prior(normal(0, 1), class = sd, group = ID, coef = Intercept),
                prior(normal(0, 1), class = sd, group = ID, coef = lqmd))
if (fitname == "PRIMARY") { f <- bf(ltph ~ lqmd + (1 + lqmd | ID), quantile = 0.95); pr <- prior_conus }
if (fitname == "SENS_WEAK") { f <- bf(ltph ~ lqmd + (1 + lqmd | ID), quantile = 0.95); pr <- prior_weak }
if (fitname == "SENS_UNCENTERED") { f <- bf(ltph ~ lqmd + (1 + lqmd | ID), quantile = 0.95, center = FALSE); pr <- prior_conus }
cat(fitname, "adapt_delta", ad, "iter", it, "start", format(Sys.time()), "\n")
t0 <- Sys.time()
fit <- brm(f, data = as.data.frame(D), family = asym_laplace(), prior = pr,
           chains = 4, cores = 4, iter = it, warmup = it / 2, seed = 54321, backend = "cmdstanr",
           control = list(adapt_delta = ad), silent = 0, refresh = 500)
cat(fitname, "elapsed min", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 2), "\n")
saveRDS(fit, file.path(J, "fits", sprintf("%s_ad%s_it%d.rds", fitname, ad, it)))
print(prior_summary(fit))
print(summary(fit))
np <- nuts_params(fit); cat("divergent after warmup:", sum(np$Value[np$Parameter == "divergent__"]), "\n")
cat("max treedepth hits:", sum(np$Value[np$Parameter == "treedepth__"] >= 10), "\n")
