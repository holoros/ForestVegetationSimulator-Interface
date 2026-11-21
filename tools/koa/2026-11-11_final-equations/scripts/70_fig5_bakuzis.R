# 70_fig5_bakuzis.R  Fig. 5 of v141: projections as a modified Bakuzis matrix (Leary 1997) from the koa 1.15.0 release. Five BYI levels per origin
# (5th, 10th, 50th, 90th, 95th percentile) from the scenario starting lists at their own density, 200 annual steps, natural runs with QMD ingrowth;
# 90% Monte Carlo bands of script 51 for basal area at the median level; planted and natural density series at the median level for the
# competition panel. Headless, color, 180 x 125 mm, 600 dpi. No identifier printed.
suppressMessages({library(data.table); library(ggplot2); library(patchwork)}); setwd("~/jobs/koa_1150_20261121"); dir.create("ms_v141", showWarnings = FALSE)
L51 <- readLines("scripts/51_j1_items.R"); eval(parse(text = L51[1:grep("^SC <- CJ", L51)]))
e <- new.env(); sys.source("release_v1150/koa_step_rdbyi.R", e); cf <- e$koa_read_coef("release_v1150/koa_rdbyi_equations.csv")
bq <- unique(tr[, .(pid, planted, BYI)])[, .(p05 = quantile(BYI, .05), p10 = quantile(BYI, .1), p50 = quantile(BYI, .5), p90 = quantile(BYI, .9), p95 = quantile(BYI, .95)), by = planted]
run <- function(pl, byi, n0 = NULL, years = 200) { L <- getL(pl); ex <- if (is.null(n0)) L$EXPF_c else L$EXPF_c * n0 / sum(L$EXPF_c); as.data.table(e$koa_project(L$DBH, L$HT, ex, byi, pl, years, cf, ingrowth = pl == 0)) }
G <- CJ(planted = c(0, 1), lev = c("p05", "p10", "p50", "p90", "p95")); G[, byi := mapply(function(p, l) bq[planted == p][[l]], planted, lev)]
S <- rbindlist(lapply(seq_len(nrow(G)), function(i) cbind(G[i], run(G$planted[i], G$byi[i]))))
S[, `:=`(origin = factor(ifelse(planted == 1, "Planted", "Natural"), c("Natural", "Planted")), VOL = 0.40 * BA * HT)]
S[, level := factor(lev, c("p05", "p10", "p50", "p90", "p95"), c("5th", "10th", "50th", "90th", "95th"))]
D <- rbindlist(lapply(list(list(0, c(500, 1000, 2000, 4000)), list(1, c(300, 600, 1200, 2400))), function(z) rbindlist(lapply(z[[2]], function(n) cbind(planted = z[[1]], n0 = n, run(z[[1]], bq[planted == z[[1]]]$p50, n, 100))))))
D[, origin := factor(ifelse(planted == 1, "Planted", "Natural"), c("Natural", "Planted"))]; D[, dens := factor(match(n0, sort(unique(n0[planted == planted[1]]))), 1:4)]; D[, dens := factor(frank(n0, ties.method = "dense"), 1:4), by = planted]
B <- fread("ms_v136/scenarios_long_j1.csv")[site_dev == FALSE & var == "BA" & level == "md"][, origin := factor(ifelse(planted == 1, "Planted", "Natural"), c("Natural", "Planted"))]
pal <- c("5th" = "#B2182B", "10th" = "#EF8A62", "50th" = "#4D9221", "90th" = "#2166AC", "95th" = "#542788")
th <- theme_bw(base_size = 8) + theme(panel.grid.minor = element_blank(), legend.key.height = unit(3, "mm"), plot.tag = element_text(face = "bold"), strip.background = element_rect(fill = "#EEF3E8"))
lt <- scale_linetype_manual(values = c(Natural = "solid", Planted = "22"), name = "Origin")
cl <- scale_colour_manual(values = pal, name = "BYI percentile")
pa <- ggplot(S, aes(year, HT, colour = level, linetype = origin)) + geom_line(linewidth = 0.5) + cl + lt + labs(x = "Years from start", y = "Height (m)", tag = "(a)") + th
pb <- ggplot() + geom_ribbon(data = B, aes(year, ymin = p05, ymax = p95, fill = origin), alpha = 0.18) + scale_fill_manual(values = c(Natural = "#1B7837", Planted = "#A6DBA0"), guide = "none") +
  geom_line(data = S, aes(year, BA, colour = level, linetype = origin), linewidth = 0.5) + cl + lt + labs(x = "Years from start", y = expression(Basal~area~(m^2~ha^{-1})), tag = "(b)") + th
pc <- ggplot(S, aes(year, TPH, colour = level, linetype = origin)) + geom_line(linewidth = 0.5) + scale_y_log10() + cl + lt + labs(x = "Years from start", y = expression(Stems~(ha^{-1})), tag = "(c)") + th
ref <- data.table(x = c(10, 100)); ref[, y := 2000 * (x / 10)^-1.605]
pd <- ggplot(S, aes(QMD, TPH, colour = level, linetype = origin)) + geom_line(linewidth = 0.5) + geom_line(data = ref, aes(x, y), inherit.aes = FALSE, colour = "grey35", linewidth = 0.4, linetype = "dotted") +
  scale_x_log10() + scale_y_log10() + cl + lt + labs(x = "QMD (cm)", y = expression(Stems~(ha^{-1})), tag = "(d)") + th
pe <- ggplot(S, aes(HT, VOL, colour = level, linetype = origin)) + geom_line(linewidth = 0.5) + cl + lt + labs(x = "Height (m)", y = expression(Assumed~volume~(m^3~ha^{-1})), tag = "(e)") + th
pf <- ggplot(D, aes(year, QMD, colour = dens, linetype = origin)) + geom_line(linewidth = 0.5) + facet_wrap(~origin, nrow = 1) + lt + guides(linetype = "none") +
  scale_colour_manual(values = c("1" = "#FDB863", "2" = "#E08214", "3" = "#B35806", "4" = "#542788"), labels = c("300 / 500", "600 / 1,000", "1,200 / 2,000", "2,400 / 4,000"), name = expression(Start~planted~"/"~natural~(stems~ha^{-1}))) +
  labs(x = "Years from start", y = "QMD (cm)", tag = "(f)") + th
fig <- (pa | pb | pc) / (pd | pe | pf) + plot_layout(guides = "collect") & theme(legend.position = "bottom", legend.box = "vertical")
ggsave("ms_v141/Fig5_bakuzis.png", fig, width = 180, height = 135, units = "mm", dpi = 600); ggsave("ms_v141/Fig5_bakuzis.tif", fig, width = 180, height = 135, units = "mm", dpi = 600, compression = "lzw")
fwrite(S, "ms_v141/fig5_trajectories.csv"); fwrite(D, "ms_v141/fig5_density_series.csv")
cat("starting lists: natural trees", nrow(getL(0)), "stems", round(sum(getL(0)$EXPF_c)), "; planted trees", nrow(getL(1)), "stems", round(sum(getL(1)$EXPF_c)), "QMD", round(sqrt(sum(getL(1)$DBH^2 * getL(1)$EXPF_c) / sum(getL(1)$EXPF_c)), 2), "\n")
print(S[year %in% c(20, 40, 100, 200), .(origin, level, byi = round(byi), year, HT = round(HT, 1), BA = round(BA, 1), TPH = round(TPH), QMD = round(QMD, 1), VOL = round(VOL))])
print(dcast(D[year %in% c(20, 40, 100)], origin + year ~ n0, value.var = "QMD"), digits = 3); cat("70 done\n")
