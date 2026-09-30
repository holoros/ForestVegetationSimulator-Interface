## Surface value at the 38 FIA growth-model installations against the BYI they carry in AK_PLT_GEO.
suppressMessages(library(data.table))
g <- fread("../koa_zenodo_180/stage_v190/AK_PLT_GEO.csv")[Data == "FIA"]
g[, c("s", "u", "COUNTYCD", "PLOT") := tstrsplit(Install, "-", type.convert = TRUE)]; gp <- unique(g[, .(COUNTYCD, PLOT, BYI)])
pl <- fread("in/HI_PLOT.csv", integer64 = "character", select = c("INVYR", "COUNTYCD", "PLOT", "LAT", "LON"))
last <- pl[order(-INVYR)][!duplicated(paste(COUNTYCD, PLOT))]; x <- merge(gp, last, by = c("COUNTYCD", "PLOT"))
tf <- tempfile(); fwrite(x[, .(LON, LAT)], tf, sep = " ", col.names = FALSE)
x$surf <- suppressWarnings(as.numeric(system(sprintf("gdallocationinfo -valonly -wgs84 ../koa_zenodo_180/stage_v190/BYI_all.tif < %s", tf), intern = TRUE))); unlink(tf)
cat(sprintf("n %d; median AK_PLT_GEO %.1f; median surface %.1f; Spearman %.3f; |diff|<5 for %d\n", nrow(x), median(x$BYI), median(x$surf, na.rm = TRUE),
            cor(x$BYI, x$surf, method = "spearman", use = "complete.obs"), sum(abs(x$BYI - x$surf) < 5, na.rm = TRUE)))
cat("counties:"); print(table(x$COUNTYCD))
