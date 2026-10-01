## stage12_summary_v103.R (a2/registry, 2026-09-30): B_stage12_summary and B_background_by_origin of origin_refit_span.R, recomputed on
## frames/final/plot_intervals_v103.csv. fitB and the removal / refit2 Thin_Yr screen are copied from track2/stage1/stage1_garcia_v103.R, so the
## recoded row reproduces stage1_fit_v103.json. published_table = the v103 plot_intervals with the deposit coding (no recode, no screen).
W <- file.path(Sys.getenv("HOME"), "jobs/koa_v103_20260930"); OUT <- file.path(W, "a2/registry/stage12")
fitB <- function(d) {
  s1 <- glm(any_mort ~ log(pmax(sdi, 1)) + planted, family = binomial(link = "cloglog"), offset = log(yip), data = d)
  dm <- d[d$any_mort & d$m_ann > 0, ]; s2 <- lm(log(m_ann) ~ log(pmax(sdi, 1)) + planted, data = dm)
  list(s1 = s1, s2 = s2, pbar = mean(1 - exp(-exp(predict(s1, newdata = transform(d, yip = 1), type = "link")))), duan = mean(exp(residuals(s2))), n = nrow(d),
       nplots = length(unique(paste(d$Data, d$Install, d$Plot))), nmort = nrow(dm), uncond_w = weighted.mean(d$m_ann, d$expf_alive)) }
ORT <- read.csv(file.path(W, "inputs/psp_origin_thinning_2026-09-16_DATA.csv"), stringsAsFactors = FALSE)
psp_planted <- as.character(ORT$Install[ORT$Origin_new == "Planted"])
remS <- setNames(strsplit(as.character(ORT$removal_t1_years), ";"), as.character(ORT$Install)); remS <- lapply(remS, function(x) as.integer(x[!is.na(x) & x != "NA" & x != ""]))
remy <- lapply(seq_len(nrow(ORT)), function(i) { y <- c(ORT$Thin_Yr[i], suppressWarnings(as.numeric(unlist(strsplit(as.character(ORT$removal_t1_years[i]), ";"))))); unique(y[is.finite(y)]) }); names(remy) <- as.character(ORT$Install)
pi0 <- read.csv(file.path(W, "frames/final/plot_intervals_v103.csv"), stringsAsFactors = FALSE)
stopifnot(!any(tolower(names(pi0)) %in% c("lat", "lon", "latitude", "longitude")))
pi0$any_mort <- as.logical(pi0$any_mort); pi1 <- pi0; isp <- pi1$Data == "PSP"
pi1$planted[isp] <- as.integer(as.character(pi1$Install[isp]) %in% psp_planted)
pi1$removal <- mapply(function(d, i, t0, t1) d == "PSP" && as.character(i) %in% names(remS) && (as.integer(t1) %in% remS[[as.character(i)]] || any(remS[[as.character(i)]] > t0 & remS[[as.character(i)]] < t1)), pi1$Data, pi1$Install, pi1$m_from, pi1$m_to)
pi1$spans_thin <- mapply(function(d, i, t0, t1) d == "PSP" && !is.null(remy[[as.character(i)]]) && any(remy[[as.character(i)]] > t0 & remy[[as.character(i)]] < t1), pi1$Data, pi1$Install, pi1$m_from, pi1$m_to)
pi2 <- pi1[!pi1$removal & !pi1$spans_thin, ]
b0 <- fitB(pi0); b2 <- fitB(pi2)
summ <- data.frame(fit = c("published_table", "origin_recoded_removals_excluded"), n_intervals = c(b0$n, b2$n), n_plots = c(b0$nplots, b2$nplots), n_with_mortality = c(b0$nmort, b2$nmort),
  pbar = c(b0$pbar, b2$pbar), duan = c(b0$duan, b2$duan), auc = NA, gate_reproduction = NA, share_with_mortality = c(mean(pi0$any_mort), mean(pi2$any_mort)),
  uncond_weighted = c(b0$uncond_w, b2$uncond_w), cond_weighted = c(weighted.mean(pi0$m_ann[pi0$any_mort], pi0$expf_alive[pi0$any_mort]), weighted.mean(pi2$m_ann[pi2$any_mort], pi2$expf_alive[pi2$any_mort])))
bg <- do.call(rbind, lapply(list(published = pi0, recoded = pi2), function(d) do.call(rbind, lapply(0:1, function(p) { s <- d[d$planted == p & d$sdi < 200, ]
  data.frame(origin = ifelse(p == 1, "planted", "natural"), n = nrow(s), w_ann_mort = if (nrow(s)) weighted.mean(s$m_ann, s$expf_alive) else NA, median_ann_mort = if (nrow(s)) median(s$m_ann) else NA) }))))
bg$table <- rep(c("published", "recoded"), each = 2)
write.csv(summ, file.path(OUT, "B_stage12_summary_v103.csv"), row.names = FALSE); write.csv(bg, file.path(OUT, "B_background_by_origin_v103.csv"), row.names = FALSE)
cat("recoded S1", coef(b2$s1), "S2", coef(b2$s2), "pbar", b2$pbar, "\n"); print(summ); print(bg)
