## Pipeline counts for the BYI construction (R1 c7, R2 c14). Aggregates only; coordinates never printed.
suppressMessages(library(data.table))
a <- fread("in/AGB.FIA.csv")
cat("Eq1 frame rows", nrow(a), " plots", uniqueN(a[,.(COUNTYCD,PLOT)]), " plot-visits", uniqueN(a$PLT_CN),
    " subplot-visits", uniqueN(a[,.(PLT_CN,SUBP)]), "\n")
cat("rows by CONDID:"); print(table(a$CONDID)); cat("rows by COND_STATUS_CD:"); print(table(a$COND_STATUS_CD))
v <- a[, .(nv = uniqueN(INVYR)), by = .(COUNTYCD, PLOT)]; cat("visits per plot:"); print(table(v$nv))
cat("plots by county:"); print(a[, uniqueN(PLOT), by = COUNTYCD])
p <- fread("in/PLT.GEO_FIA.csv")
cat("PLT.GEO_FIA rows", nrow(p), "\n")
p[, ID := paste(STATECD, UNITCD, COUNTYCD, PLOT, sep = "-")]; p <- p[!duplicated(ID)]
cat("unique FIA plot locations", nrow(p), "\n")
print(p[, .(n = .N, kona = sum(!is.na(KonaTWI)), whc50 = sum(!is.na(WHC50)), ptype = sum(!is.na(PTYPE) & PTYPE != ""), geo = sum(!is.na(GEO_YR))), by = COUNTYCD])
s <- fread("in/Schmoldt_Index_by_plot.csv")
cat("Schmoldt_Index_by_plot rows", nrow(s), "\n"); print(s[, .N, by = COUNTYCD])
cat("archived plot BYI: "); print(summary(s$Schmoldt_Index)); cat("sd", sd(s$Schmoldt_Index), " n<=1", sum(s$Schmoldt_Index <= 1), "\n")
g <- fread("../koa_zenodo_180/stage_v190/AK_PLT_GEO.csv")
cat("AK_PLT_GEO rows", nrow(g), " nonNA BYI", sum(!is.na(g$BYI)), "\n"); print(summary(g$BYI)); cat("sd", sd(g$BYI, na.rm = TRUE), "\n")
print(g[, .(n = .N, med = median(BYI, na.rm = TRUE), min = min(BYI, na.rm = TRUE), max = max(BYI, na.rm = TRUE)), by = Data])
m <- merge(p, s, by = c("COUNTYCD", "PLOT"), all = TRUE)
cat("merged rows", nrow(m), " with index", sum(!is.na(m$Schmoldt_Index)), " index but no location", sum(is.na(m$ID)), "\n")
m[, SI := ifelse(is.na(Schmoldt_Index), 0, Schmoldt_Index)]
kona_vars <- c("PTYPE","rain","aws050wta","WHC50","temp","GEO_YR","Kona30mDEM","aws025wta","WHC25","KonaSKF")
k <- m[complete.cases(m[, c("SI", kona_vars, "LON", "LAT"), with = FALSE])]
cat("Kona frame n", nrow(k), " zeros", sum(k$SI == 0), " by county:"); print(k[, .(n = .N, zeros = sum(SI == 0)), by = COUNTYCD])
sw_vars <- c("rain","temp","aws025wta","aws050wta","aws0100wta","aws0150wta","WHC100","WHC150","WHC25","WHC50","AWS100")
w <- m[SI < 1500 & !is.na(WHC50)]; w <- w[complete.cases(w[, c("SI", sw_vars), with = FALSE])]
cat("statewide frame n", nrow(w), " zeros", sum(w$SI == 0), " by county:"); print(w[, .(n = .N, zeros = sum(SI == 0)), by = COUNTYCD])
cat("plots with index dropped from Kona frame", sum(m$SI > 0) - sum(k$SI > 0), "; from statewide", sum(m$SI > 0) - sum(w$SI > 0), "\n")
## compare to the stored fit data
for (f in c("in/BYI_srf_fit.RDS", "in/BYI_srf_fit_HI.RDS")) {
  d <- readRDS(f)$ranger.arguments$data; fr <- if (grepl("HI", f)) w else k
  vs <- setdiff(names(d), "Schmoldt_Index")
  cat(f, " stored n", nrow(d), " rebuilt n", nrow(fr), " y sorted identical:", isTRUE(all.equal(sort(d$Schmoldt_Index), sort(fr$SI))), "\n")
}
saveRDS(list(k = k, w = w, m = m), "work_frames_RESTRICTED.rds")
