## Compare the figshare AK_PLT_GEO.csv coordinates against AK_GEO.shp geometry.
## Coordinates are read and discarded. Only distances and counts are printed.
suppressMessages({library(sf); library(data.table)})
g <- st_read("AK_GEO.shp", quiet=TRUE)
gx <- st_coordinates(g)
G <- data.table(pid = paste(g$Data, g$Install, g$Plot, sep="/"),
                glon = as.numeric(gx[,1]), glat = as.numeric(gx[,2]),
                gELEV = suppressWarnings(as.numeric(as.character(g$ELEV))))
C <- fread("AK_PLT_GEO.csv")
C[, pid := paste(Data, Install, Plot, sep="/")]
C <- C[, .(pid = pid, clon = as.numeric(LON), clat = as.numeric(LAT), cELEV = as.numeric(ELEV))]
cat("shp rows", nrow(G), "| csv rows", nrow(C), "| keys in common", length(intersect(G$pid, C$pid)), "\n")
cat("keys only in shp:", length(setdiff(G$pid,C$pid)), "| only in csv:", length(setdiff(C$pid,G$pid)), "\n\n")
M <- merge(G, C, by="pid")
M[, d_m := sqrt(((clon-glon)*111320*cos(glat*pi/180))^2 + ((clat-glat)*110540)^2)]
cat("== separation between the two sources, metres\n")
print(summary(M$d_m))
cat("\nexact matches (< 0.1 m):", M[d_m < 0.1, .N], "of", nrow(M), "\n")
cat("differing by more than 10 m:", M[d_m > 10, .N], "\n")
if (M[d_m > 10, .N] > 0) print(M[d_m > 10, .(pid, d_m = round(d_m))][order(-d_m)][1:min(10,.N)])
cat("\n== elevation agreement\n"); print(summary(M$cELEV - M$gELEV))
rm(gx, G, C, M); invisible(gc())
