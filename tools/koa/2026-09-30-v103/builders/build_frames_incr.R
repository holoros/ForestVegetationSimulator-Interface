#!/usr/bin/env Rscript
# build_frames_incr.R (koa v101). Port of the frame construction steps of the fitting scripts
# "Koa  Increment Models.r" (dDBH.csv, dHT.csv) and "AK_SURV.r" (AK.SURV.csv), which are Project documents and
# are not on firebreather. Only the data steps are ported, no model is fitted. The port was verified by running it
# on the record inputs and comparing with inputs/dDBH_record.csv, inputs/dHT_record.csv and inputs/AK_SURV_record.csv.
# Usage: Rscript build_frames_incr.R <AK.TREE.incr csv> <PLT.GEO csv> <outdir> <tag>
args <- commandArgs(trailingOnly = TRUE)
incr_csv <- args[1]; geo_csv <- args[2]; outdir <- args[3]; tag <- args[4]
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
AK.TREE.incr <- read.csv(incr_csv, stringsAsFactors = FALSE)
PLT.GEO <- read.csv(geo_csv, stringsAsFactors = FALSE)
stopifnot(!any(tolower(names(PLT.GEO)) %in% c("lat", "lon", "long", "latitude", "longitude")))
cat("incr rows", nrow(AK.TREE.incr), "geo rows", nrow(PLT.GEO), "\n")
## Koa  Increment Models.r, lines 24 to 33
names(AK.TREE.incr)[names(AK.TREE.incr) == "Data.0"] <- "Data"
names(AK.TREE.incr)[names(AK.TREE.incr) == "Install.0"] <- "Install"
names(AK.TREE.incr)[names(AK.TREE.incr) == "Plot.0"] <- "Plot"
names(AK.TREE.incr)[names(AK.TREE.incr) == "Tree.0"] <- "Tree"
AK.TREE.incr <- AK.TREE.incr[, !(names(AK.TREE.incr) %in% c("Data.1", "Install.1", "Plot.1", "Tree.1"))]
AK.TREE.incr <- merge(AK.TREE.incr, PLT.GEO, by = c("Data", "Install", "Plot"))
cat("merged rows", nrow(AK.TREE.incr), "\n")
AK.TREE.incr$HT.DBH.0 <- AK.TREE.incr$HT.0 / (AK.TREE.incr$DBH.0 / 100)
AK.TREE.incr$HT.DBH.1 <- AK.TREE.incr$HT.0 / (AK.TREE.incr$DBH.1 / 100)   # as in the source script
AK.TREE.incr$YIP <- AK.TREE.incr$t.1 - AK.TREE.incr$t.0
AK.TREE.incr$dDBH.ann <- AK.TREE.incr$dDBH / AK.TREE.incr$YIP
koa.HCB <- function(HT, DBH, BAL, BAPH, rain, temp) {
  b0 <- -0.507760; b1 <- -1.565361; b2 <- 0.434077; b3 <- 0.039878; b4 <- 0.295514; b5 <- 0.284263; b6 <- -0.379219
  slender <- log(pmax(HT / DBH, 0.01))
  exponent <- b0 + b1 * sqrt(HT / 100) + b2 * slender + b3 * log(BAL * BAPH + 1) + b4 * log(BAPH + 1) + b5 * log(rain + 1) + b6 * log(temp + 1)
  HT / (1 + exp(exponent))
}
addcrown <- function(d) {
  d$HCB.0 <- koa.HCB(d$HT.0, d$DBH.0, d$BAL.0, d$BAPH.0, d$rain, d$temp)
  d$HCB.1 <- koa.HCB(d$HT.1, d$DBH.1, d$BAL.1, d$BAPH.1, d$rain, d$temp)
  d$CL.0 <- d$HT.0 - d$HCB.0; d$CL.1 <- d$HT.1 - d$HCB.1
  d$CR.0 <- d$CL.0 / d$HT.0; d$CR.1 <- d$CL.1 / d$HT.1
  d$Planted <- ifelse(d$Origin != "Natural", 1, 0)
  d
}
## dDBH frame (Koa  Increment Models.r lines 34 to 36, 105 to 116, 165)
sel <- with(AK.TREE.incr, DBH.0 > 0 & Status.0 == "live" & DBH.1 > 0 & Status.1 == "live" & YIP > 0 & dDBH.ann > 0 & dDBH.ann < 10)
cat("dDBH selector NA count", sum(is.na(sel)), "\n")
dDBH <- AK.TREE.incr[which(sel), ]
dDBH <- addcrown(dDBH)
write.csv(dDBH, file.path(outdir, paste0("dDBH_", tag, ".csv")), row.names = FALSE)
cat("dDBH rows", nrow(dDBH), "\n")
## dHT frame (line 291)
sel2 <- dDBH$dHT / dDBH$YIP > 0 & dDBH$dHT / dDBH$YIP < 10
cat("dHT selector NA count", sum(is.na(sel2)), "\n")
dHT <- dDBH[which(sel2), ]
write.csv(dHT, file.path(outdir, paste0("dHT_", tag, ".csv")), row.names = FALSE)
cat("dHT rows", nrow(dHT), "\n")
## survival table (AK_SURV.r lines 8 to 55, 160), deposit column set of AK_SURV.csv
S <- addcrown(AK.TREE.incr)
sel3 <- with(S, DBH.0 > 0 & Status.0 == "live" & YIP > 0 & dDBH.ann > 0 & dDBH.ann < 10)
cat("SURV selector NA count", sum(is.na(sel3)), "\n")
SURV <- S[which(sel3), ]
SURV$Alive <- ifelse(SURV$Status.1 == "live", 1, 0)
## deposit 1.8.0 convention (README line 40): Planted of PSP rows follows Origin_new of the 2026-09-16 origin
## revision table, Origin itself is left as recorded. Verified to reproduce inputs/AK_SURV_record.csv exactly.
ort <- read.csv("inputs/psp_origin_thinning_2026-09-16_DATA.csv", stringsAsFactors = FALSE)
isp <- SURV$Data == "PSP"
onew <- ort$Origin_new[match(as.character(SURV$Install[isp]), as.character(ort$Install))]
onew[is.na(onew)] <- SURV$Origin[isp][is.na(onew)]
SURV$Planted[isp] <- ifelse(onew != "Natural", 1, 0)
cat("PSP survival rows with Planted recoded", sum(isp & SURV$Planted != ifelse(SURV$Origin != "Natural", 1, 0)), "\n")
hdr <- names(read.csv("inputs/AK_SURV_record.csv", nrows = 1))
missing <- setdiff(hdr, names(SURV)); if (length(missing)) stop("missing columns ", paste(missing, collapse = ","))
SURV <- SURV[, hdr]
## deposit 1.2.0 step: exact full row duplicates collapse (520 rows in the record, the FIA fourfold and 7 DOFAW pairs)
ndup <- sum(duplicated(SURV)); cat("exact full row duplicates removed from SURV", ndup, "\n"); SURV <- SURV[!duplicated(SURV), ]
write.csv(SURV, file.path(outdir, paste0("AK_SURV_", tag, ".csv")), row.names = FALSE)
cat("SURV rows", nrow(SURV), "deaths", sum(SURV$Alive == 0), "\n")
for (nm in c("dDBH", "dHT", "AK_SURV")) {
  d <- get(if (nm == "AK_SURV") "SURV" else nm)
  k <- paste(d$Data, d$Install, d$Plot, d$Tree, d$t.0, d$t.1)
  nd <- sum(duplicated(k)); cat("GATE", nm, tag, "one row per (Data, Install, Plot, Tree, t.0, t.1):", ifelse(nd == 0, "PASS", "FAIL"), "| offending keys", length(unique(k[duplicated(k)])), "\n")
}
cat("DONE build_frames_incr", tag, "\n")
