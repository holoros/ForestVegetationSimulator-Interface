## Land cover class at each plot, TRUE position and FUZZED position, tabulated by program.
## Coordinates are read, used, and discarded. Only counts are written or printed.
suppressMessages({library(sf); library(data.table)})
SEED <- 20260926; FUZZM <- 500
set.seed(SEED)
p  <- st_read("AK_GEO.shp", quiet=TRUE)
xy <- st_coordinates(p); prog <- as.character(p$Data)
th <- runif(nrow(xy),0,2*pi); rr <- FUZZM*sqrt(runif(nrow(xy)))
fx <- xy[,1] + (rr*cos(th))/(111320*cos(xy[,2]*pi/180))
fy <- xy[,2] + (rr*sin(th))/110540

val <- function(lon, lat) {
  o <- suppressWarnings(system2("gdallocationinfo",
        c("-valonly","-wgs84","hi_landcover_wimperv_9-30-08_se5.img",
          format(lon, digits=12), format(lat, digits=12)), stdout=TRUE, stderr=FALSE))
  if (length(o)==0 || is.na(suppressWarnings(as.integer(o[1])))) NA_integer_ else as.integer(o[1])
}
v_true <- mapply(val, xy[,1], xy[,2])
v_fuzz <- mapply(val, fx,      fy)
rm(xy, fx, fy); invisible(gc())

LAB <- c("11"="Open water","21"="Developed","22"="Developed","23"="Developed","24"="Developed",
         "31"="Barren","41"="Forest","42"="Forest","43"="Forest",
         "52"="Shrub/grass/wet","71"="Shrub/grass/wet","81"="Shrub/grass/wet",
         "82"="Shrub/grass/wet","90"="Shrub/grass/wet","95"="Shrub/grass/wet","0"="OUTSIDE/nodata")
cls <- function(v) ifelse(is.na(v), "OUTSIDE/nodata", ifelse(as.character(v) %in% names(LAB), LAB[as.character(v)], paste0("code ", v)))
d <- data.table(prog=prog, raw_true=v_true, true=cls(v_true), fuzz=cls(v_fuzz))
cat("== class at TRUE position, by program\n"); print(dcast(d[, .N, by=.(prog, true)], prog ~ true, value.var="N", fill=0))
cat("\n== DOFAW detail, raw codes at TRUE position\n"); print(d[prog=="DOFAW", .N, by=.(raw_true, true)])
cat("\n== plots whose class CHANGES under the fuzz\n"); print(d[true != fuzz, .N, by=.(prog, true, fuzz)][order(-N)])
cat("\n== totals\n"); cat("n", nrow(d), "| changed by fuzz", d[true!=fuzz, .N], "\n")
