suppressMessages({library(data.table); library(sf)})
S <- st_read("AK_GEO.shp", quiet=TRUE); sc <- st_coordinates(S)
S <- as.data.table(st_drop_geometry(S)); S[, `:=`(lon=sc[,1], lat=sc[,2])]
C <- fread("AK_PLT_GEO.csv")
kf <- function(d) paste(d$Data, d$Install, d$Plot, sep="|")
S[, k:=kf(S)]; C[, k:=kf(C)]
M <- merge(S[,.(k,Data,slon=lon,slat=lat)], C[,.(k,clon=LON,clat=LAT,rain,temp)], by="k")
ex <- function(lon,lat,ras){
  f <- tempfile(); write.table(data.frame(lon,lat), f, row.names=FALSE, col.names=FALSE)
  v <- suppressWarnings(as.numeric(system(paste("gdallocationinfo -valonly -wgs84", ras, "<", f), intern=TRUE)))
  unlink(f); v
}
M[, `:=`(rain_s = ex(slon,slat,"rain.tif"), rain_c = ex(clon,clat,"rain.tif"),
         temp_s = ex(slon,slat,"temp.tif"), temp_c = ex(clon,clat,"temp.tif"))]
rep_test <- function(stored, at_s, at_c, nm, tol){
  ok <- is.finite(stored) & is.finite(at_s) & is.finite(at_c)
  ds <- abs(stored[ok]-at_s[ok]); dc <- abs(stored[ok]-at_c[ok])
  cat("\n===", nm, "  n =", sum(ok), "===\n")
  cat(sprintf("  exact reproduction (|diff| < %g):   shp %3d   csv %3d\n", tol, sum(ds<tol), sum(dc<tol)))
  cat(sprintf("  median |stored - extracted|:        shp %8.3f   csv %8.3f\n", median(ds), median(dc)))
  cat(sprintf("  RMSE:                               shp %8.3f   csv %8.3f\n",
      sqrt(mean(ds^2)), sqrt(mean(dc^2))))
  cat(sprintf("  correlation with stored:            shp %8.4f   csv %8.4f\n",
      cor(stored[ok],at_s[ok]), cor(stored[ok],at_c[ok])))
}
rep_test(M$rain, M$rain_s, M$rain_c, "RAINFALL, mm", 1)
rep_test(M$temp, M$temp_s, M$temp_c, "TEMPERATURE, C", 0.01)
