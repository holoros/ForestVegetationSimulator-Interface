## Figure 2 with an uncertainty layer. Panels (a) and (b) are the 26 September Figure 2
## unchanged in data, extent and scale (fig2_ORIGINAL_COPY.R). Panels (c) and (d) map the local
## out-of-bag RMSE implied by each cell's BYI under the error model of the random forest that
## produced it: the Kona model on Hawaii Island (lon > -156.10 and lat < 20.35), the statewide
## model elsewhere (02_errfit.R, out/errmodels.rds).
suppressMessages({library(data.table); library(ggplot2); library(patchwork); library(scales)})
rd <- function(f) { d <- fread(f, col.names = c("x","y","v"), showProgress = FALSE); d[v > -9998] }
arch <- rd("byi_arch.xyz"); isl <- rd("byi_isl.xyz")
E <- readRDS("out/errmodels.rds")
lr <- function(v, m) { r <- E[[m]]$rng; v2 <- pmin(pmax(v, r[1]), r[2])
  sqrt(pmax(predict(E[[m]]$lo, newdata = data.frame(oob = v2)), 0)) }
addu <- function(d) { d[, model := fifelse(x > -156.10 & y < 20.35, "Kona", "statewide")]
  d[, u := NA_real_]; for (m in c("Kona","statewide")) d[model == m, u := lr(v, m)]; d }
arch <- addu(arch); isl <- addu(isl)
cat("cells arch", nrow(arch), " isl", nrow(isl), "\n")
for (nm in c("arch","isl")) { d <- get(nm)
  cat(nm, ": u range", round(range(d$u), 1), " median", round(median(d$u), 1),
      " share of cells with BYI above model OOB range:",
      round(d[, mean(v > fifelse(model == "Kona", E$Kona$rng[2], E$statewide$rng[2]))], 4), "\n") }
print(arch[, .(cells = .N, med_BYI = median(v), med_u = median(u)), by = model])
fwrite(rbind(arch[, .(panel = "arch", q = c(.05,.5,.95), u = quantile(u, c(.05,.5,.95)))],
             isl[,  .(panel = "isl",  q = c(.05,.5,.95), u = quantile(u, c(.05,.5,.95)))]), "out/u_quantiles.csv")

LIM <- range(c(arch$v, isl$v)); BRK <- seq(0, 1250, by = 250)
ULIM <- c(0, 450); UBRK <- seq(0, 450, by = 150)
sbar <- function(x0, y0, km, lab, sz = 3.1, dy = 0.075) list(
  annotate("segment", x = x0, xend = x0 + km/111.32, y = y0, yend = y0, linewidth = 0.9),
  annotate("text", x = x0 + km/222.64, y = y0 + dy, label = lab, size = sz, fontface = "bold"))
narr <- function(x0, y0, h = 0.22, sz = 3.1) list(
  annotate("segment", x = x0, xend = x0, y = y0, yend = y0 + h,
           arrow = arrow(length = unit(1.9, "mm"), type = "closed"), linewidth = 0.6),
  annotate("text", x = x0, y = y0 - 0.075, label = "N", size = sz, fontface = "bold"))
cb <- function() guide_colourbar(title.position = "left", barwidth = unit(58, "mm"),
                                 barheight = unit(3.4, "mm"), ticks.colour = "white")
base <- function(p, ttl, sb, na_, xl, yl) p + sb + na_ +
  coord_sf(xlim = xl, ylim = yl, expand = FALSE, crs = 4326) + labs(title = ttl) +
  theme_void(base_size = 10) +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.04, margin = margin(b = 3)),
        legend.title = element_text(face = "bold", size = 10, vjust = 0.9),
        legend.text = element_text(size = 9))
fb <- scale_fill_viridis_c(name = expression(bold("BYI (Mg ha"^-1*")")), limits = LIM, breaks = BRK,
                           oob = squish, guide = cb())
fu <- scale_fill_viridis_c(option = "magma", direction = -1, begin = 0.05, end = 0.95,
                           name = expression(bold("Local OOB RMSE (Mg ha"^-1*")")),
                           limits = ULIM, breaks = UBRK, oob = squish, guide = cb())
XA <- c(-160.30, -154.72); YA <- c(18.82, 22.33); XI <- c(-156.12, -154.72); YI <- c(18.87, 20.33)
a <- base(ggplot() + geom_raster(data = arch, aes(x, y, fill = v)) + fb, "(a) Hawaiian archipelago",
          sbar(-159.95, 19.35, 100, "100 km", dy = 0.13), narr(-155.25, 21.75), XA, YA)
b <- base(ggplot() + geom_raster(data = isl, aes(x, y, fill = v)) + fb, "(b) Hawaii Island detail",
          sbar(-156.10, 18.93, 30, "30 km"), narr(-154.92, 20.02), XI, YI)
c <- base(ggplot() + geom_raster(data = arch, aes(x, y, fill = u)) + fu, "(c) Archipelago error",
          sbar(-159.95, 19.35, 100, "100 km", dy = 0.13), narr(-155.25, 21.75), XA, YA)
d <- base(ggplot() + geom_raster(data = isl, aes(x, y, fill = u)) + fu, "(d) Hawaii Island error",
          sbar(-156.10, 18.93, 30, "30 km"), narr(-154.92, 20.02), XI, YI)
row1 <- (a | b) + plot_layout(guides = "collect") & theme(legend.position = "bottom", legend.margin = margin(0,0,0,0))
row2 <- (c | d) + plot_layout(guides = "collect") & theme(legend.position = "bottom", legend.margin = margin(0,0,0,0))
fig <- wrap_elements(row1) / wrap_elements(row2) +
  plot_annotation(caption = expression(
    "Sequential ramps. Site classes used in Figs. 3 to 6 and S6 to S8: Low 100, Medium 264, High 450 Mg ha"^-1*".")) &
  theme(plot.caption = element_text(hjust = 0, size = 9, colour = "grey25", lineheight = 1.15, margin = margin(t = 4)),
        plot.caption.position = "plot", plot.background = element_rect(fill = "white", colour = NA))
W <- 17.4; H <- 18.6
ggsave("Fig2_byi_surface_v102.tiff", fig, width = W, height = H, units = "cm", dpi = 600, bg = "white",
       device = "tiff", compression = "lzw")
ggsave("Fig2_byi_surface_v102.pdf", fig, width = W, height = H, units = "cm", bg = "white")
ggsave("Fig2_check_150dpi.png", fig, width = W, height = H, units = "cm", dpi = 150, bg = "white")
cat("DONE\n")
