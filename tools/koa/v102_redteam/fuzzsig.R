suppressMessages({library(data.table); library(sf)})
S <- st_read("AK_GEO.shp", quiet=TRUE)
sc <- st_coordinates(S); S <- as.data.table(st_drop_geometry(S))
S[, `:=`(slon=sc[,1], slat=sc[,2])]
C <- fread("AK_PLT_GEO.csv")
key_of <- function(d,a,b,c) paste(d[[a]], d[[b]], d[[c]], sep="|")
S[, k := key_of(S,"Data","Install","Plot")]; C[, k := key_of(C,"Data","Install","Plot")]
M <- merge(S[,.(k,Data,slon,slat)], C[,.(k,clon=LON,clat=LAT)], by="k")
# local metre scale
mlat <- mean(M$clat); kx <- 111320*cos(mlat*pi/180); ky <- 110540
M[, `:=`(dx=(slon-clon)*kx, dy=(slat-clat)*ky)]
M[, r := sqrt(dx^2+dy^2)]
M[, brg := atan2(dy,dx)]
cat("=== displacement radius by program, metres ===\n")
print(M[, .(n=.N, min=round(min(r),1), med=round(median(r),1),
            mean=round(mean(r),1), max=round(max(r),1)), by=Data][order(-n)])
cat("\n=== uniform-disc test, all plots ===\n")
R <- max(M$r)
cat("implied radius R =", round(R,1), "m\n")
cat("uniform disc would give median =", round(R/sqrt(2),1), "m; observed =", round(median(M$r),1), "m\n")
cat("KS of r^2 vs uniform(0,R^2): p =", signif(ks.test(M$r^2, "punif", 0, R^2)$p.value, 3), "\n")
cat("\n=== bearing uniformity (Rayleigh) ===\n")
Rb <- sqrt(sum(cos(M$brg))^2 + sum(sin(M$brg))^2)/nrow(M)
cat("mean resultant length =", round(Rb,4), " (0 = uniform)\n")
cat("Rayleigh p =", signif(exp(sqrt(1+4*nrow(M)+4*(nrow(M)^2-(nrow(M)*Rb)^2))-(1+2*nrow(M))), 3), "\n")
cat("\n=== per-program uniform-disc fit ===\n")
print(M[, {RR <- max(r); .(n=.N, R=round(RR,1), med_obs=round(median(r),1),
        med_exp=round(RR/sqrt(2),1), ks_p=signif(ks.test(r^2,"punif",0,RR^2)$p.value,3))}, by=Data][order(-n)])
