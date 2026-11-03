## 03_post.R: diagnostics, plot SDImax (per draw exp(b0_j + b1_j log 25.4)), RD, growth-plot lookup, figure.
## AMENDMENT 1 adaptation: reads the fit of record from out/fits_used.csv (role == "of_record"; written by 03a_eval.R); for the
## random-intercept fit RI_UNCENTERED there is no r_ID[,lqmd], so b1_j = common slope b_lqmd for every plot.
suppressPackageStartupMessages({library(data.table); library(brms); library(posterior); library(ggplot2); library(patchwork)})
options(cmdstanr_no_ver_check = TRUE)
J <- path.expand("~/jobs/koa_brms_sdimax_20261102"); setwd(J)
key <- fread("out/id_key.csv"); D <- fread("out/fit_frame.csv")
## AMENDMENT 2: optional args <fits_used csv> <output suffix>; e.g. out/fits_used_rilong.csv _rilong (the fit to post carries role of_record in that file;
## its record/provisional status is in out/record_amend2.csv). Defaults reproduce the AMENDMENT 1 behaviour.
aa <- commandArgs(TRUE); FU <- if (length(aa) >= 1) aa[1] else "out/fits_used.csv"; SUF <- if (length(aa) >= 2) aa[2] else ""
use <- fread(FU)   # fit, file, role (of_record / sensitivity / not_of_record), pass
rec <- use[role == "of_record", fit]; if (length(rec) != 1) stop("no fit of record in out/fits_used.csv")
use <- use[order(role != "of_record")]
L25 <- log(25.4)
FS <- list(); PS <- list()
for (k in seq_len(nrow(use))) {
  fn <- use$fit[k]; fit <- readRDS(use$file[k])
  dr <- as_draws_df(fit)
  hyp <- grep("^(b_|sd_|cor_|sigma$)", names(dr), value = TRUE)
  s <- summarise_draws(subset_draws(dr, variable = hyp), mean, sd, ~quantile(.x, c(.025, .975)), rhat, ess_bulk, ess_tail)
  setDT(s); setnames(s, c("2.5%", "97.5%"), c("q2.5", "q97.5"))
  pop <- exp(dr$b_Intercept + dr$b_lqmd * L25)
  dpop <- as_draws_df(data.frame(SDImax_pop = pop, .chain = dr$.chain, .iteration = dr$.iteration, .draw = dr$.draw))
  sp <- summarise_draws(dpop, mean, sd, ~quantile(.x, c(.025, .975)), rhat, ess_bulk, ess_tail); setDT(sp); setnames(sp, c("2.5%", "97.5%"), c("q2.5", "q97.5"))
  np <- nuts_params(fit); ndiv <- sum(np$Value[np$Parameter == "divergent__"]); ntd <- sum(np$Value[np$Parameter == "treedepth__"] >= max(np$Value[np$Parameter == "treedepth__"]))   # hits of the max treedepth reached
  ## plot-level draws
  g <- key$gid
  b0 <- sapply(g, function(x) dr[[sprintf("r_ID[%s,Intercept]", x)]]) + dr$b_Intercept
  has_rs <- sprintf("r_ID[%s,lqmd]", g[1]) %in% names(dr)
  b1 <- if (has_rs) sapply(g, function(x) dr[[sprintf("r_ID[%s,lqmd]", x)]]) + dr$b_lqmd else matrix(dr$b_lqmd, nrow(dr), length(g), dimnames = list(NULL, g))
  S <- exp(b0 + b1 * L25)
  ch <- matrix(dr$.chain); it <- dr$.iteration
  diag1 <- t(apply(S, 2, function(v) { a <- matrix(v, ncol = length(unique(dr$.chain))); c(rhat = rhat(a), ess_bulk = ess_bulk(a), ess_tail = ess_tail(a)) }))
  cf <- coef(fit, robust = TRUE)$ID
  b1med <- if ("lqmd" %in% dimnames(cf)[[3]]) cf[g, "Estimate", "lqmd"] else rep(median(dr$b_lqmd), length(g))
  P <- data.table(gid = g, SDImax_mean = colMeans(S), SDImax_median = apply(S, 2, median),
                  SDImax_q2.5 = apply(S, 2, quantile, .025), SDImax_q97.5 = apply(S, 2, quantile, .975),
                  SDImax_coefmed = exp(cf[g, "Estimate", "Intercept"] + b1med * L25),
                  b0_med = cf[g, "Estimate", "Intercept"], b1_med = b1med,
                  rhat = diag1[, "rhat"], ess_bulk = diag1[, "ess_bulk"], ess_tail = diag1[, "ess_tail"])
  P[, fit := fn]; PS[[fn]] <- P
  hyp_ok <- all(s$rhat < 1.01 & s$ess_bulk > 400 & s$ess_tail > 400) && ndiv == 0
  s[, fit := fn]; sp[, fit := fn]
  meta <- data.table(fit = fn, variable = c("divergent_after_warmup", "treedepth_hits", "hyper_criteria_pass", "plot_SDImax_share_rhat_lt_1.01", "plot_SDImax_share_essbulk_gt_400", "plot_SDImax_share_esstail_gt_400", "n_rows", "n_IDs", "file"),
                     value = c(ndiv, ntd, hyp_ok, round(mean(P$rhat < 1.01), 4), round(mean(P$ess_bulk > 400), 4), round(mean(P$ess_tail > 400), 4), nrow(D), nrow(key), basename(use$file[k])))
  FS[[fn]] <- list(s = rbind(s, sp), meta = meta)
  cat(fn, ": div", ndiv, "| hyper pass", hyp_ok, "| pop SDImax", round(sp$mean), "(", round(sp$q2.5), "to", round(sp$q97.5), ")\n")
  print(s[, .(variable, mean = round(mean, 4), q2.5 = round(q2.5, 4), q97.5 = round(q97.5, 4), rhat = round(rhat, 4), ess_bulk = round(ess_bulk), ess_tail = round(ess_tail))])
  if (fn == rec) { drp <- dr }
}
fsum <- rbindlist(lapply(FS, `[[`, "s"), fill = TRUE)
fsum <- fsum[, .(fit, variable, mean, sd, q2.5, q97.5, rhat, ess_bulk, ess_tail)]
meta <- rbindlist(lapply(FS, `[[`, "meta"))
fsum <- rbind(fsum[, lapply(.SD, as.character)], meta[, .(fit, variable, mean = value)], fill = TRUE)
fwrite(fsum, paste0("out/fit_summary", SUF, ".csv"))
## plot attributes
A <- fread("out/plot_visit_sdi.csv")
att <- A[, .(n_visits = .N, Origin = Origin[1], island = island[1], pBA_AK_mean = mean(pBA_AK, na.rm = TRUE)), by = .(source, ID)]
att[, koa_dom := pBA_AK_mean >= 0.5]
nr <- D[, .(n_rows_fit = .N), by = ID]
P <- PS[[rec]]; P[, fit_of_record := rec]; P <- merge(key, P, by = "gid"); P <- merge(P, nr, by = "ID"); P <- merge(P, att, by = "ID", all.x = TRUE)
for (fn in setdiff(names(PS), rec)) { q <- PS[[fn]][, .(gid, m = SDImax_mean, lo = SDImax_q2.5, hi = SDImax_q97.5)]; setnames(q, c("m", "lo", "hi"), paste0(c("SDImax_mean_", "SDImax_q2.5_", "SDImax_q97.5_"), fn)); P <- merge(P, q, by = "gid") }
P[, gid := NULL]
P[source == "FIA", c("STATECD", "UNITCD", "COUNTYCD", "PLOT") := tstrsplit(ID, "-", fixed = TRUE)]
P[source == "Network", c("Data", "Install", "Plot") := tstrsplit(ID, "|", fixed = TRUE)]
setcolorder(P, c("ID", "source", "STATECD", "UNITCD", "COUNTYCD", "PLOT", "Data", "Install", "Plot"))
fwrite(P, paste0("out/plot_sdimax", SUF, ".csv"))
sm <- function(d, by) d[, .(n_plots = .N, SDImax_mean_mean = mean(SDImax_mean), SDImax_mean_median = median(SDImax_mean),
                           SDImax_mean_p2.5 = quantile(SDImax_mean, .025), SDImax_mean_p97.5 = quantile(SDImax_mean, .975),
                           median_plot_q2.5 = median(SDImax_q2.5), median_plot_q97.5 = median(SDImax_q97.5),
                           median_CI_width = median(SDImax_q97.5 - SDImax_q2.5)), by = by]
S1 <- rbindlist(list(cbind(group = "all", sm(P, NULL)), cbind(group = "source", sm(P, "source")), cbind(group = "origin", sm(P, c("source", "Origin"))),
                     cbind(group = "island_COUNTYCD", sm(P[source == "FIA"], "COUNTYCD")), cbind(group = "koa_dom", sm(P, "koa_dom")), cbind(group = "source_koa_dom", sm(P, c("source", "koa_dom")))), fill = TRUE)
fwrite(S1, paste0("out/plot_sdimax_summary", SUF, ".csv")); print(S1)
## RD per plot visit
R <- merge(A, P[, .(ID, SDImax_mean, SDImax_median, SDImax_q2.5, SDImax_q97.5)], by = "ID", all.x = TRUE)
R[, `:=`(RD = SDI / SDImax_mean, RD_lo = SDI / SDImax_q97.5, RD_hi = SDI / SDImax_q2.5, RD_sum = SDI_sum / SDImax_mean)]
R[, in_fit := flag_excl == ""]
R[source == "FIA", INVYR := Year]
setcolorder(R, c("ID", "source", "Year", "INVYR"))
fwrite(R, paste0("out/plot_rd_brms", SUF, ".csv"))
rs <- function(d) d[!is.na(RD), .(n = .N, RD_median = median(RD), RD_mean = mean(RD), RD_p05 = quantile(RD, .05), RD_p95 = quantile(RD, .95), RD_max = max(RD), share_gt1 = mean(RD > 1),
                                  RDsum_median = median(RD_sum, na.rm = TRUE))]
RS <- rbindlist(list(cbind(group = "all_in_fit", rs(R[in_fit == TRUE])), cbind(group = "all_rows", rs(R)), cbind(group = "FIA", rs(R[source == "FIA" & in_fit == TRUE])),
                     cbind(group = "Network", rs(R[source == "Network" & in_fit == TRUE])), cbind(group = "Network_Planted", rs(R[source == "Network" & Origin == "Planted" & in_fit == TRUE])),
                     cbind(group = "koa_dom_visit", rs(R[pBA_AK >= .5 & in_fit == TRUE])), cbind(group = "excluded_post_thinning", rs(R[in_fit == FALSE]))))
fwrite(RS, paste0("out/rd_summary", SUF, ".csv")); print(RS)
## growth-model plots
G <- unique(fread(path.expand("~/jobs/koa_v104_20261030/frames/final/dDBH_NO_v103_model.csv"), select = c("Data", "Install", "Plot"), colClasses = "character"))
G[, ID := fifelse(Data == "FIA", Install, paste(Data, Install, Plot, sep = "|"))]
G <- merge(G, P[, .(ID, SDImax_mean, SDImax_median, SDImax_q2.5, SDImax_q97.5, n_rows_fit)], by = "ID", all.x = TRUE)
G[, fitted := !is.na(SDImax_mean)]
G[, note := fifelse(Data == "FIA", "FIA growth plot = subplot of FIA plot; SDImax is the FIA plot's", "")]
fwrite(G, paste0("out/growth_plot_sdimax", SUF, ".csv")); print(G[, .(n = .N, fitted = sum(fitted)), by = Data])
## figure
pb0 <- mean(drp$b_Intercept); pb1 <- mean(drp$b_lqmd)
set.seed(54321); smp <- sample(P$ID, 40)
rng <- D[, .(lo = min(lqmd), hi = max(lqmd)), by = ID][ID %in% smp]
pl <- merge(rng, P[, .(ID, b0_med, b1_med)], by = "ID")
pl <- pl[, .(lqmd = seq(lo - 0.3, hi + 0.3, length.out = 20)), by = .(ID, b0_med, b1_med)][, ltph := b0_med + b1_med * lqmd]
p1 <- ggplot(D, aes(lqmd, ltph)) + geom_point(aes(colour = source), size = 0.7, alpha = 0.45) +
  geom_line(data = pl, aes(group = ID), colour = "grey35", linewidth = 0.3, alpha = 0.8) +
  geom_abline(intercept = pb0, slope = pb1, colour = "firebrick", linewidth = 1.1) +
  scale_colour_manual(values = c(FIA = "#1b7837", Network = "#2166ac")) +
  labs(x = "ln QMD (cm)", y = "ln TPH (trees/ha)", colour = NULL,
       title = sprintf("%s population tau 0.95 line (red): ln TPH = %.2f %+.3f ln QMD; 40 sampled plot lines (grey)", rec, pb0, pb1)) +
  theme_bw(base_size = 9) + theme(panel.background = element_rect(fill = "white"), panel.grid.minor = element_blank(), legend.position = c(.85, .85))
popm <- as.numeric(fsum[fit == rec & variable == "SDImax_pop", mean])
p2 <- ggplot(P, aes(SDImax_mean)) + geom_histogram(bins = 40, fill = "grey60", colour = "white") +
  geom_vline(xintercept = popm, colour = "firebrick", linewidth = 1) +
  geom_vline(xintercept = c(1983, 1147), linetype = c("dashed", "dotted")) +
  labs(x = "Plot SDImax (posterior mean, trees/ha at QMD 25.4 cm)", y = "Plots",
       title = sprintf("Red: population %.0f; dashed: pooled tau 0.99 fixed 1,983; dotted: koa-dominated 1,147", popm)) +
  theme_bw(base_size = 9) + theme(panel.background = element_rect(fill = "white"), panel.grid.minor = element_blank())
ggsave(paste0("fig_sdimax", SUF, ".png"), p1 + p2 + plot_layout(widths = c(1.2, 1)), width = 11, height = 4.6, dpi = 300)
cat("done\n")
