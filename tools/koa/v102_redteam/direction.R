suppressMessages({library(data.table); library(sf)})
S <- st_read("AK_GEO.shp", quiet=TRUE); sc <- st_coordinates(S)
S <- as.data.table(st_drop_geometry(S)); S[, `:=`(lon=sc[,1], lat=sc[,2])]
C <- fread("AK_PLT_GEO.csv")
kf <- function(d) paste(d$Data, d$Install, d$Plot, sep="|")
S[, k:=kf(S)]; C[, k:=kf(C)]
M <- merge(S[,.(k,Data,slon=lon,slat=lat)], C[,.(k,clon=LON,clat=LAT)], by="k")
grp <- function(v) fifelse(v==11,"water", fifelse(v %in% 21:24,"developed",
        fifelse(v==31,"barren", fifelse(v %in% 41:43,"FOREST",
        fifelse(v %in% c(52,71,81,82,90,95),"shrub/grass/wet","nodata")))))
ex <- function(lon,lat,tag){
  f <- tempfile(); write.table(data.frame(lon,lat), f, row.names=FALSE, col.names=FALSE)
  v <- as.integer(system(paste("gdallocationinfo -valonly -wgs84 lc_isl.tif <", f), intern=TRUE))
  a <- as.integer(system(paste("gdallocationinfo -valonly -wgs84 lc_arch.tif <", f), intern=TRUE))
  v[is.na(v) | v==0] <- a[is.na(v) | v==0]; unlink(f); v
}
M[, shp_lc := grp(ex(slon, slat))]
M[, csv_lc := grp(ex(clon, clat))]
cat("=== land cover at AK_GEO.shp positions ===\n"); print(M[, .N, by=shp_lc][order(-N)])
cat("\n=== land cover at figshare AK_PLT_GEO.csv positions ===\n"); print(M[, .N, by=csv_lc][order(-N)])
cat("\n=== forest hit rate, the discriminator ===\n")
cat("shp on FOREST:", M[shp_lc=="FOREST", .N], "of", nrow(M),
    sprintf("(%.1f%%)\n", 100*M[shp_lc=="FOREST",.N]/nrow(M)))
cat("csv on FOREST:", M[csv_lc=="FOREST", .N], "of", nrow(M),
    sprintf("(%.1f%%)\n", 100*M[csv_lc=="FOREST",.N]/nrow(M)))
cat("\n=== McNemar, paired on the same plots ===\n")
b <- M[shp_lc=="FOREST" & csv_lc!="FOREST", .N]; c2 <- M[shp_lc!="FOREST" & csv_lc=="FOREST", .N]
cat("shp forest / csv not:", b, "  csv forest / shp not:", c2, "\n")
cat("McNemar p =", signif(binom.test(c(b,c2))$p.value,3), "\n")
cat("\n=== forest hit rate by program ===\n")
print(M[, .(n=.N, shp=round(100*mean(shp_lc=="FOREST")), csv=round(100*mean(csv_lc=="FOREST"))), by=Data][order(-n)])
