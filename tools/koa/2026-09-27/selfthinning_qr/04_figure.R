## 04_figure.R  Figure: observed koa plot-measures, ALL-data QR limiting lines (tau 0.95, 0.99) with
## installation-cluster bootstrap 95% bands, engine-implied limiting line, and even-aged trajectories
## (rep 0, ages 1 to 100) by site class; panel a deployed beta 0.16019, panel b variant B beta 0.117.
suppressPackageStartupMessages({ library(data.table); library(ggplot2) })
J <- path.expand("~/jobs"); O <- file.path(J, "koa_selfthin_qr_20260927/out")
R <- readRDS(file.path(O, "qr_results.rds")); ENG <- R$ENG
d <- fread(file.path(O, "analysis_frame_DATA.csv"))
stopifnot(!any(grepl("^(lat|lon|latitude|longitude|x|y)$", tolower(names(d)))))
PAN <- c(dep = "(a)~Deployed~engine*','~beta==\"0.160\"", fit = "(b)~Variant~B*','~beta==\"0.117\"")
BA <- R$BANDS[set == "ALL"]
BA <- rbindlist(lapply(names(PAN), function(k) copy(BA)[, panel := PAN[[k]]]))
BA[, line := factor(fifelse(tau == 0.95, "QR tau 0.95", "QR tau 0.99"))]
qg <- exp(seq(log(min(d$QMD)), log(max(d$QMD)), length.out = 200))
EL <- rbind(data.table(panel = PAN[["dep"]], QMD = qg, N = exp(ENG[1, 1] + ENG[1, 2] * log(qg))),
            data.table(panel = PAN[["fit"]], QMD = qg, N = exp(ENG[2, 1] + ENG[2, 2] * log(qg))))
EL[, line := "Engine limiting line"]
TR <- fread(file.path(J, "koa_v102_20260918/track3/derived/engine_v102_out_m1/trajectories.csv"))[rep == 0 & age <= 100 & grepl("^Even", scenario)]
TR <- TR[, .(panel = PAN[["dep"]], scenario, site, age, QMD, TPH)]
G <- fread(file.path(J, "koa_prereg_B_beta_20260926/out/GRID_trajectories.csv"))[arm == "C3_fitted" & year <= 100]
G <- G[, .(panel = PAN[["fit"]], scenario = fifelse(origin == "nat", "Even-aged natural", "Even-aged planted"), site, age = year, QMD, TPH)]
T2 <- rbind(TR, G)
T2[, origin := factor(fifelse(grepl("planted", scenario), "Planted", "Natural"), levels = c("Natural", "Planted"))]
T2[, site := factor(site, levels = c("Low", "Medium", "High"))]
OB <- rbindlist(lapply(names(PAN), function(k) d[, .(panel = PAN[[k]], QMD, N, Origin = factor(Origin, levels = c("Natural", "Planted")))]))
for (z in list(BA, EL, T2, OB)) z[, panel := factor(panel, levels = unname(PAN))]

site_col <- c(Low = "#009E73", Medium = "#0072B2", High = "#D55E00")   # Okabe-Ito
p <- ggplot() +
  geom_ribbon(data = BA, aes(QMD, ymin = exp(lnN_lo), ymax = exp(lnN_hi), group = line, fill = line), alpha = 0.45) +
  geom_point(data = OB, aes(QMD, N, shape = Origin), size = 0.9, stroke = 0.3, colour = "grey25") +
  geom_line(data = BA, aes(QMD, exp(lnN), linetype = line, group = line), linewidth = 0.5, colour = "black") +
  geom_line(data = EL, aes(QMD, N, linetype = line), linewidth = 0.5, colour = "black") +
  geom_path(data = T2, aes(QMD, TPH, colour = site, group = interaction(site, origin)), linewidth = 0.7,
            linetype = "solid") +
  geom_point(data = T2[age %in% c(20, 40, 60, 100)], aes(QMD, TPH, colour = site, shape = origin), size = 1.3,
             stroke = 0.5, show.legend = FALSE) +
  facet_wrap(~panel, nrow = 1, labeller = label_parsed) +
  scale_x_log10(breaks = c(1, 2, 5, 10, 20, 50, 100)) +
  scale_y_log10(breaks = c(20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000),
                labels = function(v) formatC(round(v), format = "d", big.mark = ",")) +
  coord_cartesian(xlim = c(0.6, 100), ylim = c(12, 30000), expand = FALSE) +
  annotation_logticks(sides = "bl", linewidth = 0.25, short = unit(0.05, "cm"), mid = unit(0.08, "cm"), long = unit(0.12, "cm")) +
  scale_shape_manual(values = c(Natural = 1, Planted = 2), name = "Observed") +
  scale_colour_manual(values = site_col, name = "Projected site class") +
  scale_fill_manual(values = c("QR tau 0.95" = "grey75", "QR tau 0.99" = "#E69F00"), name = NULL,
                    labels = c(expression(tau == 0.95 ~ "95% band"), expression(tau == 0.99 ~ "95% band"))) +
  scale_linetype_manual(values = c("QR tau 0.95" = "solid", "QR tau 0.99" = "longdash", "Engine limiting line" = "dotted"),
                        breaks = c("QR tau 0.95", "QR tau 0.99", "Engine limiting line"), name = NULL,
                        labels = c(expression("QR" ~ tau == 0.95), expression("QR" ~ tau == 0.99), "Engine limiting line")) +
  labs(x = "Quadratic mean diameter (cm)", y = expression("Stand density (stems ha"^{-1} * ")")) +
  theme_classic(base_size = 8.5) +
  theme(strip.background = element_blank(), strip.text = element_text(size = 9, hjust = 0),
        legend.position = "bottom", legend.box = "vertical", legend.spacing.y = unit(0, "pt"),
        legend.margin = margin(0, 0, 0, 0), legend.key.width = unit(0.9, "cm"), legend.text = element_text(size = 7.5),
        legend.title = element_text(size = 7.5), panel.spacing = unit(0.5, "cm"),
        plot.margin = margin(4, 8, 2, 4), panel.background = element_rect(fill = "white", colour = NA),
        plot.background = element_rect(fill = "white", colour = NA)) +
  guides(shape = guide_legend(order = 1, override.aes = list(size = 1.6)), colour = guide_legend(order = 2),
         linetype = guide_legend(order = 3), fill = guide_legend(order = 4))
W <- 174; H <- 118
ggsave(file.path(O, "Fig_selfthinning_QR.png"), p, width = W, height = H, units = "mm", dpi = 600, device = png, type = "cairo", bg = "white")
ggsave(file.path(O, "Fig_selfthinning_QR.pdf"), p, width = W, height = H, units = "mm", device = cairo_pdf, bg = "white")
cat("figure written\n")
