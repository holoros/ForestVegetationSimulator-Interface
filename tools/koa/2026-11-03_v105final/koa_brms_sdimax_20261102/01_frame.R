## 01_frame.R: subplot-visit (FIA) + plot-year (network) frame for brms SDImax; plot-visit SDI for RD. No coordinates read.
suppressPackageStartupMessages(library(data.table))
J <- path.expand("~/jobs/koa_brms_sdimax_20261102"); B1 <- path.expand("~/jobs/koa_rv_byi_20260928"); MS <- path.expand("~/jobs/koa_maxsdi_20261102")
coord_pat <- "^(lat|lon|long|latitude|longitude|x|y|utm.*|easting|northing|coord.*|geom.*|lat_.*|lon_.*)$"
tr <- fread(file.path(B1, "in/HI_TREE.csv"), select = c("INVYR","STATECD","UNITCD","COUNTYCD","PLOT","SUBP","STATUSCD","DIA","TPA_UNADJ","SPCD"))
stopifnot(!any(grepl(coord_pat, tolower(names(tr)))))
tr <- tr[STATUSCD == 1 & !is.na(DIA) & DIA >= 1 & !is.na(TPA_UNADJ) & TPA_UNADJ > 0]
tr <- tr[!(STATECD == 15 & UNITCD == 1 & COUNTYCD == 1 & PLOT == 2628)]
cat("FIA live trees DIA>=1 (burned plot removed):", nrow(tr), "\n")
## subplot frame exactly as CONUS FIA.sum (TPA_UNADJ x 4), no condition split
tr[, w4 := TPA_UNADJ * 4]
fs <- tr[, .(TPA = sum(w4), wtdbh2 = sum(DIA^2 * w4), wt = sum(w4), n = .N), by = .(STATECD, UNITCD, COUNTYCD, PLOT, SUBP, INVYR)]
fs[, qmd := sqrt(wtdbh2 / wt)]
fs[, `:=`(ID = paste(STATECD, UNITCD, COUNTYCD, PLOT, sep = "-"), TPH = TPA * 2.48, QMD.cm = qmd * 2.54)]
fs[, `:=`(ltph = log(TPH), lqmd = log(QMD.cm))]
n0 <- nrow(fs)
fs <- fs[TPH > 0 & is.finite(ltph) & is.finite(lqmd) & INVYR >= 1999 & INVYR <= 2023 & TPH < 50000]
cat("FIA subplot visits:", n0, "-> after CONUS filters", nrow(fs), "| plots", uniqueN(fs$ID), "\n")
fs[, `:=`(source = "FIA", row_id = paste(ID, SUBP, INVYR, sep = "|"))]
## network plot-years from koa_maxsdi frame
nf <- fread(file.path(MS, "out/frame_plot_all_n1.csv"))[source == "Network" & flag_excl == "" & TPH > 0]
pp <- tstrsplit(nf$id, "|", fixed = TRUE); stopifnot(length(pp) == 4)
nf[, `:=`(Data = pp[[1]], Install = pp[[2]], Plot = pp[[3]])]
nf[, ID := paste(Data, Install, Plot, sep = "|")]
nf[, `:=`(QMD.cm = QMD, ltph = log(TPH), lqmd = log(QMD), INVYR = year, row_id = id)]
cat("Network plot-years:", nrow(nf), "| plots", uniqueN(nf$ID), "| installations", uniqueN(nf$cluster), "\n")
cols <- c("source","ID","row_id","INVYR","n","TPH","QMD.cm","ltph","lqmd")
D <- rbind(fs[, ..cols], nf[, ..cols])
stopifnot(!anyDuplicated(D$row_id), all(is.finite(D$ltph)), all(is.finite(D$lqmd)))
cat("FIT FRAME rows", nrow(D), "IDs", uniqueN(D$ID), "| mean lqmd", round(mean(D$lqmd), 3), "| rows per ID median", median(D[, .N, by = ID]$N), "\n")
print(D[, .(rows = .N, IDs = uniqueN(ID), TPH_med = round(median(TPH)), QMD_med = round(median(QMD.cm), 1)), by = source])
fwrite(D, file.path(J, "out/fit_frame.csv"))
## plot-visit level SDI (all species, metric) for RD and attributes
tr[, `:=`(w = TPA_UNADJ * 2.48, dbh = DIA * 2.54, ak = SPCD == 6006)]
fp <- tr[, .(n_live = .N, TPH = sum(w), QMD = sqrt(sum(w * dbh^2) / sum(w)), SDI_sum = sum(w * (dbh / 25.4)^1.605),
             BA = sum(w * pi * (dbh / 200)^2), BA_AK = sum(w * pi * (dbh / 200)^2 * ak)), by = .(STATECD, UNITCD, COUNTYCD, PLOT, INVYR)]
fp[, `:=`(source = "FIA", ID = paste(STATECD, UNITCD, COUNTYCD, PLOT, sep = "-"), Year = INVYR, pBA_AK = BA_AK / BA)]
cond <- fread(file.path(B1, "in/HI_COND.csv"), select = c("STATECD","UNITCD","COUNTYCD","PLOT","INVYR","COND_STATUS_CD","STDORGCD"))
stopifnot(!any(grepl(coord_pat, tolower(names(cond)))))
org <- cond[COND_STATUS_CD == 1, .(planted = any(STDORGCD == 1, na.rm = TRUE)), by = .(STATECD, UNITCD, COUNTYCD, PLOT)]
fp <- merge(fp, org, by = c("STATECD","UNITCD","COUNTYCD","PLOT"), all.x = TRUE)
fp[, Origin := fifelse(is.na(planted), "Unknown", fifelse(planted, "Planted", "Natural"))]
fp[, island := as.character(COUNTYCD)]
na <- fread(file.path(MS, "out/frame_plot_all_n1.csv"))[source == "Network" & TPH > 0]
pp <- tstrsplit(na$id, "|", fixed = TRUE)
na[, `:=`(ID = paste(pp[[1]], pp[[2]], pp[[3]], sep = "|"), Year = year, n_live = n, SDI_sum = NA_real_, island = "network (not recorded)")]
na[is.na(Origin) | Origin == "", Origin := "Unknown"]
c2 <- c("source","ID","Year","n_live","TPH","QMD","SDI_sum","pBA_AK","Origin","island")
P <- rbind(fp[, ..c2], na[, c(c2, "flag_excl"), with = FALSE], fill = TRUE)
P[is.na(flag_excl), flag_excl := ""]
P[, SDI := TPH * (QMD / 25.4)^1.605]
cat("plot visits for RD:", nrow(P), "\n"); print(P[, .N, by = .(source, Origin)])
cat("FIA origin (plots):"); print(unique(fp[, .(ID, Origin)])[, .N, by = Origin])
fwrite(P, file.path(J, "out/plot_visit_sdi.csv"))
