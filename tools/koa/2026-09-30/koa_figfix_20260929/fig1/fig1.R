## Figure 1, koa plot network over Hawaii land cover. Journal register, advanced-viz house rules.
## Land cover: NLCD Hawaii 2001 (hi_landcover_wimperv_9-30-08_se5.img), warped to EPSG:4326 by warp.sh.
## Plots: AK_GEO.shp, TRUE coordinates, FUZZED here before anything is drawn or written.
suppressMessages({library(data.table); library(ggplot2); library(sf); library(patchwork)})
SEED <- 20260926; FUZZM <- 500
set.seed(SEED)

## ---- land cover -------------------------------------------------------------------
LAB <- c("Open water","Developed","Barren","Forest","Shrub, grass and wetland")
PAL <- c("Open water"="#A6CEE3","Developed"="#6E6E6E","Barren"="#D6D0C4",
         "Forest"="#1B7837","Shrub, grass and wetland"="#E3C27E")
## Codes READ from gdalinfo -hist, not assumed: 11 water; 21-24 developed; 31 barren;
## 42 evergreen forest (41 and 43 absent); 52 shrub, 71 grassland, 81 pasture, 82 crops,
## 90 and 95 wetland. Agriculture (81, 82) is folded into the shrub, grass and wetland class,
## which is what the five class legend requires; it is 1.1 of 23.1 million mapped cells.
recode <- function(v) {
  out <- rep(NA_character_, length(v))
  out[v == 11L] <- LAB[1]
  out[v %in% 21:24] <- LAB[2]
  out[v == 31L] <- LAB[3]
  out[v %in% 41:43] <- LAB[4]
  out[v %in% c(52L,71L,81L,82L,90L,95L)] <- LAB[5]
  out
}
rd <- function(f) {
  d <- fread(f, col.names=c("x","y","v"), showProgress=FALSE)
  d <- d[v > 0L]
  d[, lc := factor(recode(v), levels=LAB)]
  d[!is.na(lc), .(x,y,lc)]
}
arch <- rd("lc_arch.xyz"); isl <- rd("lc_isl.xyz")
cat("arch cells", nrow(arch), " isl cells", nrow(isl), "\n")

## ---- plots, fuzzed ----------------------------------------------------------------
p <- st_read("AK_GEO.shp", quiet=TRUE)
p <- p[, c("Data","geometry")]                  # drop LAT, LON, ELEV and all joined attributes
xy <- st_coordinates(p)
th <- runif(nrow(xy), 0, 2*pi); rr <- FUZZM*sqrt(runif(nrow(xy)))
pts <- data.table(Data = as.character(p$Data),
                  lon = xy[,1] + (rr*cos(th))/(111320*cos(xy[,2]*pi/180)),
                  lat = xy[,2] + (rr*sin(th))/110540)
rm(xy, p); invisible(gc())
PROG <- c("DOFAW","FIA","Kahikinui","Kap","KMR CAR","KMR PSP","Mauka","PSP")
PROG_LAB <- c(DOFAW="DOFAW",FIA="FIA",Kahikinui="Kahikinui",Kap="Kap","KMR CAR"="KMR CAR","KMR PSP"="KMR PSP",Mauka="Mauka upland",PSP="PSP")
SHP  <- c("DOFAW"=21,"FIA"=22,"Kahikinui"=23,"Kap"=24,"KMR CAR"=25,"KMR PSP"=3,"Mauka"=4,"PSP"=8)
n_by <- pts[, .N, by=Data]
lab_n <- setNames(sprintf("%s (%d)", PROG_LAB[PROG], n_by$N[match(PROG, n_by$Data)]), PROG)
pts[, Program := factor(Data, levels=PROG)]
cat("plots", nrow(pts), "| n by program:", paste(lab_n, collapse=", "), "\n")

## ---- panels -----------------------------------------------------------------------
sbar <- function(x0, y0, km, lab, sz=3.1) list(
  annotate("segment", x=x0, xend=x0 + km/111.32, y=y0, yend=y0, linewidth=0.9),
  annotate("text", x=x0 + km/222.64, y=y0 + 0.075, label=lab, size=sz, fontface="bold"))
narr <- function(x0, y0, h=0.22, sz=3.1) list(
  annotate("segment", x=x0, xend=x0, y=y0, yend=y0+h,
           arrow=arrow(length=unit(1.9,"mm"), type="closed"), linewidth=0.6),
  annotate("text", x=x0, y=y0-0.075, label="N", size=sz, fontface="bold"))

panel <- function(d, pp, ttl, sb, na_, xl, yl) {
  ggplot() +
    geom_raster(data=d, aes(x, y, fill=lc)) +
    scale_fill_manual(values=PAL, name="Land cover", drop=FALSE,
                      guide=guide_legend(order=1, nrow=2, byrow=TRUE,
                                         override.aes=list(colour=NA))) +
    geom_point(data=pp, aes(lon, lat, shape=Program), colour="black", fill="white",
               size=1.7, stroke=0.5) +
    scale_shape_manual(values=SHP, name="Data source (plots)", labels=lab_n, drop=FALSE,
                       guide=guide_legend(order=2, nrow=2, byrow=TRUE)) +
    sb + na_ +
    coord_sf(xlim=xl, ylim=yl, expand=FALSE, crs=4326) +
    labs(tag=ttl) +
    theme_void(base_size=10) +
    theme(plot.tag = element_text(face="bold", size=12), plot.tag.position = c(0.03, 0.97),
          legend.title = element_text(face="bold", size=10),
          legend.text  = element_text(size=9),
          legend.key.height = unit(4.2,"mm"))
}

XA <- c(-160.30,-154.72); YA <- c(18.82, 22.33)
XI <- c(-156.12,-154.72); YI <- c(18.87, 20.33)
a <- panel(arch, pts,                                   "(a)",
           sbar(-159.95, 19.35, 100, "100 km"), narr(-155.25, 21.75), XA, YA)
b <- panel(isl,  pts[lon>XI[1] & lon<XI[2] & lat>YI[1] & lat<YI[2]], "(b)",
           sbar(-156.02, 19.02, 30, "30 km"),  narr(-154.92, 20.02), XI, YI) +
     guides(fill="none", shape="none")   # one legend only; panel (a) carries it

fig <- (a | b) + plot_layout(guides="collect") +
  plot_annotation() &
  theme(legend.position="bottom", legend.box="vertical", legend.box.just="left",
        legend.margin=margin(t=0,b=0), legend.spacing.y=unit(1,"mm"),
        plot.background=element_rect(fill="white", colour=NA))

ggsave("Fig1_koa_network.png", fig, width=17.4, height=12.4, units="cm", dpi=600, bg="white")
ggsave("Fig1_koa_network.pdf", fig, width=17.4, height=12.4, units="cm", bg="white")
ggsave("Fig1_network.tiff", fig, width=17.4, height=12.4, units="cm", dpi=600, compression="lzw", bg="white")
ggsave("Fig1_thumb.png",       fig, width=17.4, height=12.4, units="cm", dpi=72,  bg="white")
ggsave("Fig1_embed.png",       fig, width=17.4, height=12.4, units="cm", dpi=300, bg="white")
cat("wrote Fig1_koa_network.png/.pdf and Fig1_thumb.png\n")
