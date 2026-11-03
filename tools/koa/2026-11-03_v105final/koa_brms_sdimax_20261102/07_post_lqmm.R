## 07_post_lqmm.R (AMENDMENT 2b): LQMM analogue of 03_post.R. Plot SDImax = exp(b0 + u_i + b1 log 25.4), tau 0.95 (candidate of record)
## with tau 0.99 alongside; RD per plot visit; growth-plot lookup; figure; comparison with pooled frontier and v104/v105 projected maxima.
suppressPackageStartupMessages({library(data.table); library(ggplot2); library(patchwork)})
J <- path.expand("~/jobs/koa_brms_sdimax_20261102"); setwd(J)
D <- fread("out/fit_frame.csv"); E <- fread("out/lqmm_estimates.csv"); PR <- fread("out/lqmm_plot_raw.csv")
P <- dcast(PR, ID ~ tau, value.var = c("u", "SDImax")); setnames(P, c("ID", "u_tau95", "u_tau99", "SDImax", "SDImax_tau99"))
P[, `:=`(b0_tau95 = E[tau == 0.95, b0], b1_tau95 = E[tau == 0.95, b1])]
A <- fread("out/plot_visit_sdi.csv")
att <- A[, .(n_visits = .N, Origin = Origin[1], island = island[1], pBA_AK_mean = mean(pBA_AK, na.rm = TRUE)), by = .(source, ID)]
att[, koa_dom := pBA_AK_mean >= 0.5]
P <- merge(P, D[, .(n_rows_fit = .N), by = ID], by = "ID"); P <- merge(P, att, by = "ID", all.x = TRUE)
P[source == "FIA", c("STATECD", "UNITCD", "COUNTYCD", "PLOT") := tstrsplit(ID, "-", fixed = TRUE)]
P[source == "Network", c("Data", "Install", "Plot") := tstrsplit(ID, "|", fixed = TRUE)]
P[, fit := "LQMM_tau0.95"]
setcolorder(P, c("ID", "source", "STATECD", "UNITCD", "COUNTYCD", "PLOT", "Data", "Install", "Plot"))
fwrite(P, "out/plot_sdimax_lqmm.csv")
sm <- function(d, by) d[, .(n_plots = .N, SDImax_mean = mean(SDImax), SDImax_median = median(SDImax), SDImax_p2.5 = quantile(SDImax, .025),
                           SDImax_p97.5 = quantile(SDImax, .975), SDImax_min = min(SDImax), SDImax_max = max(SDImax),
                           tau99_median = median(SDImax_tau99), tau99_p2.5 = quantile(SDImax_tau99, .025), tau99_p97.5 = quantile(SDImax_tau99, .975)), by = by]
S1 <- rbindlist(list(cbind(group = "all", sm(P, NULL)), cbind(group = "source", sm(P, "source")), cbind(group = "origin", sm(P, c("source", "Origin"))),
                     cbind(group = "island_COUNTYCD", sm(P[source == "FIA"], "COUNTYCD")), cbind(group = "koa_dom", sm(P, "koa_dom")),
                     cbind(group = "source_koa_dom", sm(P, c("source", "koa_dom")))), fill = TRUE)
fwrite(S1, "out/plot_sdimax_summary_lqmm.csv"); print(S1, digits = 4)
cat("cor(log SDImax tau .95, n_rows_fit):", round(cor(log(P$SDImax), P$n_rows_fit), 3), "| share of plots with 1 row:", round(mean(P$n_rows_fit == 1), 3), "\n")
## RD per plot visit (SDI metric, all species, as in 03_post.R)
R <- merge(A, P[, .(ID, SDImax, SDImax_tau99)], by = "ID", all.x = TRUE)
R[, `:=`(RD = SDI / SDImax, RD_tau99 = SDI / SDImax_tau99, RD_sum = SDI_sum / SDImax)]
R[, in_fit := flag_excl == ""]; R[source == "FIA", INVYR := Year]; setcolorder(R, c("ID", "source", "Year", "INVYR"))
fwrite(R, "out/plot_rd_lqmm.csv")
rs <- function(d) d[!is.na(RD), .(n = .N, RD_median = median(RD), RD_mean = mean(RD), RD_p05 = quantile(RD, .05), RD_p95 = quantile(RD, .95), RD_max = max(RD),
                                  share_gt1 = mean(RD > 1), RDtau99_median = median(RD_tau99), RDsum_median = median(RD_sum, na.rm = TRUE))]
RS <- rbindlist(list(cbind(group = "all_in_fit", rs(R[in_fit == TRUE])), cbind(group = "all_rows", rs(R)), cbind(group = "FIA", rs(R[source == "FIA" & in_fit == TRUE])),
                     cbind(group = "Network", rs(R[source == "Network" & in_fit == TRUE])), cbind(group = "Network_Planted", rs(R[source == "Network" & Origin == "Planted" & in_fit == TRUE])),
                     cbind(group = "koa_dom_visit", rs(R[pBA_AK >= .5 & in_fit == TRUE])), cbind(group = "excluded_post_thinning", rs(R[in_fit == FALSE]))))
fwrite(RS, "out/rd_summary_lqmm.csv"); print(RS, digits = 3)
## growth-model plots
G <- unique(fread(path.expand("~/jobs/koa_v104_20261030/frames/final/dDBH_NO_v103_model.csv"), select = c("Data", "Install", "Plot"), colClasses = "character"))
G[, ID := fifelse(Data == "FIA", Install, paste(Data, Install, Plot, sep = "|"))]
G <- merge(G, P[, .(ID, SDImax, SDImax_tau99, n_rows_fit)], by = "ID", all.x = TRUE)
G[, fitted := !is.na(SDImax)]; G[, note := fifelse(Data == "FIA", "FIA growth plot = subplot of FIA plot; SDImax is the FIA plot's", "")]
fwrite(G, "out/growth_plot_sdimax_lqmm.csv"); print(G[, .(n = .N, fitted = sum(fitted)), by = Data])
## comparison table
pop <- E[tau == 0.95]; pop99 <- E[tau == 0.99]
md <- function(x) median(x)
CMP <- data.table(quantity = c("LQMM tau .95 population SDImax (QMD 25.4)", "LQMM tau .95 plot median, all", "LQMM tau .95 plot median, koa-dominated",
                               "LQMM tau .95 plot p97.5, all", "LQMM tau .99 population SDImax", "LQMM tau .99 plot median, all",
                               "pooled fixed-slope tau .99, all (koa_maxsdi)", "pooled fixed-slope tau .99, koa-dominated (koa_maxsdi)",
                               "v104 max projected SDI natural even-aged", "v104 planted", "v104 uneven-aged", "v105 natural even-aged", "v105 planted", "v105 uneven-aged"),
                  value = c(pop$SDImax_pop, md(P$SDImax), md(P[koa_dom == TRUE, SDImax]), quantile(P$SDImax, .975), pop99$SDImax_pop, md(P$SDImax_tau99),
                            1983, 1147, 430, 881, 607, 430, 882, 611))
CMP[, ratio_to_lqmm95_pop := value / pop$SDImax_pop]
fwrite(CMP, "out/compare_lqmm.csv"); print(CMP, digits = 4)
## figure
set.seed(54321); smp <- sample(P$ID, 40)
rng <- D[, .(lo = min(lqmd), hi = max(lqmd)), by = ID][ID %in% smp]
pl <- merge(rng, P[, .(ID, u_tau95)], by = "ID")[, .(lqmd = seq(lo - 0.3, hi + 0.3, length.out = 20)), by = .(ID, u_tau95)]
pl[, ltph := pop$b0 + u_tau95 + pop$b1 * lqmd]
p1 <- ggplot(D, aes(lqmd, ltph)) + geom_point(aes(colour = source), size = 0.7, alpha = 0.45) +
  geom_line(data = pl, aes(group = ID), colour = "grey35", linewidth = 0.3, alpha = 0.8) +
  geom_abline(intercept = pop$b0, slope = pop$b1, colour = "firebrick", linewidth = 1.1) +
  scale_colour_manual(values = c(FIA = "#1b7837", Network = "#2166ac")) +
  labs(x = "ln QMD (cm)", y = "ln TPH (trees/ha)", colour = NULL,
       title = sprintf("LQMM tau 0.95 population line (red): ln TPH = %.2f %+.3f ln QMD; 40 sampled plot lines (grey)", pop$b0, pop$b1)) +
  theme_bw(base_size = 9) + theme(panel.background = element_rect(fill = "white"), panel.grid.minor = element_blank(), legend.position = c(.85, .85))
p2 <- ggplot(P, aes(SDImax)) + geom_histogram(bins = 40, fill = "grey60", colour = "white") +
  annotate("rect", xmin = pop$SDImax_pop_q2.5, xmax = pop$SDImax_pop_q97.5, ymin = -Inf, ymax = Inf, fill = "firebrick", alpha = 0.15) +
  geom_vline(xintercept = pop$SDImax_pop, colour = "firebrick", linewidth = 1) +
  geom_vline(xintercept = c(1983, 1147), linetype = c("dashed", "dotted")) +
  geom_vline(xintercept = c(430, 882, 611), colour = "#2166ac", linetype = "longdash", linewidth = 0.4) +
  labs(x = "Plot SDImax, LQMM tau 0.95 (trees/ha at QMD 25.4 cm)", y = "Plots",
       title = sprintf("Red: population %.0f (band: bootstrap 95%% %.0f to %.0f); black dashed 1,983 / dotted 1,147 pooled tau .99;\nblue: v105 projected max SDI 430, 611, 882",
                       pop$SDImax_pop, pop$SDImax_pop_q2.5, pop$SDImax_pop_q97.5)) +
  theme_bw(base_size = 9) + theme(panel.background = element_rect(fill = "white"), panel.grid.minor = element_blank())
ggsave("fig_sdimax_lqmm.png", p1 + p2 + plot_layout(widths = c(1.2, 1)), width = 11.5, height = 4.8, dpi = 300)
cat("done\n")
