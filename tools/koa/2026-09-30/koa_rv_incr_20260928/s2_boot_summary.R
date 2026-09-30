## s2_boot_summary.R <Bmax>. Summarise the installation-cluster bootstrap of Eq. 4 (first Bmax draws by draw index, successful fits
## only) and of Eq. 2: bootstrap SE, 95% percentile interval, ratio of bootstrap SE to Wald SE, and a bootstrap two-sided
## sign proportion p_boot = 2 min(P(b <= 0), P(b >= 0)).
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
Bmax <- as.integer(commandArgs(trailingOnly = TRUE)[1]); REF <- load_ref(); res <- list(); meta <- list()
for (resp in c("dDBH", "dHT")) {
  b <- read.csv(file.path(OUT, sprintf("boot_%s.csv", resp))); b <- b[!duplicated(b$draw), ]; b <- b[b$draw <= Bmax, ]
  ok <- b[b$ok == 1, ]; tt <- summary(REF[[resp]])$tTable
  meta[[resp]] <- data.frame(resp = resp, draws = nrow(b), ok = nrow(ok), tau_source_collapsed = sum(ok$tau_source < 0.01), median_secs = median(b$secs))
  for (t in TERMS) { x <- ok[[t]]; se <- sd(x); q <- quantile(x, c(0.025, 0.975))
    res[[paste(resp, t)]] <- data.frame(resp = resp, term = t, estimate = tt[t, 1], wald_se = tt[t, 2], wald_p = tt[t, ncol(tt)], boot_mean = mean(x), boot_se = se,
      lo95 = q[[1]], hi95 = q[[2]], ratio = se / tt[t, 2], p_boot = 2 * min(mean(x <= 0), mean(x >= 0)), p_wald_bootse = 2 * pnorm(-abs(tt[t, 1] / se)), n_ok = length(x),
      boot_se_excl_collapsed = sd(x[ok$tau_source >= 0.01])) }
}
hb <- file.path(OUT, "boot_height.csv")
if (file.exists(hb)) { h <- read.csv(hb); h <- h[h$ok == 1, ]; hr <- read.csv(file.path(OUT, "height_ref_and_treeRE.csv"))
  for (i in seq_len(nrow(hr))) { t <- hr$term[i]; x <- h[[t]]; q <- quantile(x, c(0.025, 0.975))
    res[[paste("HT", t)]] <- data.frame(resp = "HT (Eq. 2)", term = t, estimate = hr$est[i], wald_se = hr$wald_se[i], wald_p = NA, boot_mean = mean(x), boot_se = sd(x),
      lo95 = q[[1]], hi95 = q[[2]], ratio = sd(x) / hr$wald_se[i], p_boot = 2 * min(mean(x <= 0), mean(x >= 0)), p_wald_bootse = 2 * pnorm(-abs(hr$est[i] / sd(x))), n_ok = length(x), boot_se_excl_collapsed = NA) }
  meta$HT <- data.frame(resp = "HT (Eq. 2)", draws = nrow(read.csv(hb)), ok = nrow(h), tau_source_collapsed = NA, median_secs = NA) }
R <- do.call(rbind, res); M <- do.call(rbind, meta)
write.csv(R, file.path(OUT, "boot_summary.csv"), row.names = FALSE); write.csv(M, file.path(OUT, "boot_meta.csv"), row.names = FALSE)
options(width = 200); print(M); print(R[, c("resp", "term", "estimate", "wald_se", "boot_se", "lo95", "hi95", "ratio", "p_boot", "p_wald_bootse", "boot_se_excl_collapsed")], digits = 3)
