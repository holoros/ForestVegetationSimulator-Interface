## a5/rerun/qr/01_frame_v104.R: final live plot-measure frame for the independent limiting line. Preliminary
## (koa_selfthin_qr_20260927/01_data_envelope.R) used the anchor frame of the v102 record (AK_TREE v102, n 471, N = sum EXPF of live stems,
## QMD = plot-year column, >= 5 records of any status). Final: the anchor frame of the deployed beta 0.14803 (track2/stage1/beta_anchor_v103.py,
## "v103_koa_live": live koa stems with DBH > 0 and EXPF > 0, plot-measures with >= 5 such stems, N = sum EXPF, QMD from the same stems,
## inputs/AK_TREE_v103.csv), gated on its z99 and n. Origin from engine_v103/AK_PLT.csv as in the preliminary. No coordinates read.
suppressPackageStartupMessages(library(data.table))
W <- path.expand("~/jobs/koa_v104_20261030"); O <- file.path(W, "a5/rerun/qr")
coord_pat <- "^(lat|lon|long|latitude|longitude|x|y|utm.*|easting|northing|coord.*|geom.*|lat_.*|lon_.*)$"
hdr <- names(fread(file.path(W, "inputs/AK_TREE_v103.csv"), nrows = 0)); stopifnot(!any(grepl(coord_pat, tolower(hdr))))
t <- fread(file.path(W, "inputs/AK_TREE_v103.csv"), select = c("Data", "Install", "Plot", "Measure", "Tree", "Status", "DBH", "EXPF", "Age"))
ph <- names(fread(file.path(W, "engine_v103/AK_PLT.csv"), nrows = 0)); stopifnot(!any(grepl(coord_pat, tolower(ph))))
p <- fread(file.path(W, "engine_v103/AK_PLT.csv"), select = c("Data", "Install", "Plot", "Origin"))
for (d in list(t, p)) d[, `:=`(Data = as.character(Data), Install = as.character(Install), Plot = as.character(Plot))]
A3 <- 0.167997928455782; K3 <- 1.04106514616602
lk <- t[Status == "live" & DBH > 0 & EXPF > 0]
g <- lk[, .(n = .N, N = sum(EXPF), QMD = sqrt(sum(EXPF * DBH^2) / sum(EXPF)), Age = median(Age, na.rm = TRUE)), by = .(Data, Install, Plot, Measure)][n >= 5]
z <- g$N * exp((log(g$QMD) - A3) / K3)^2; z99 <- unname(quantile(z, 0.99, type = 7))
cat(sprintf("GATE anchor frame: n %d (v103_koa_live 483), z99 %.6f (456333.510467), beta %.12f (0.148033094919)\n", nrow(g), z99, 100 / sqrt(z99)))
stopifnot(nrow(g) == 483, abs(z99 - 456333.51046685106) < 1e-4)
org <- unique(p[, .(Data, Install, Plot, Origin)]); stopifnot(!anyDuplicated(org[, .(Data, Install, Plot)]))
g <- merge(g, org, by = c("Data", "Install", "Plot"), all.x = TRUE); cat("origin missing:", sum(is.na(g$Origin)), "\n")
g[, inst := paste(Data, Install, sep = "|")]; g[, plot := paste(Data, Install, Plot, sep = "|")]
g[, SDI_eng := N * (QMD / 25)^1.605]; g[, QMD_live := QMD]
print(g[, .(pm = .N, plots = uniqueN(plot), inst = uniqueN(inst)), by = .(Data, Origin)][order(Origin, Data)])
cat(sprintf("TOTAL: %d plot-measures, %d plots, %d installations\n", nrow(g), uniqueN(g$plot), uniqueN(g$inst)))
fwrite(g[, .(Data, Install, Plot, Measure, inst, plot, Origin, N, QMD, QMD_live, SDI_eng, Age)], file.path(O, "analysis_frame_v104_DATA.csv"))
