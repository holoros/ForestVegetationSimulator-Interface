## s3_nonpos_build.R (R1 c4). Frames that RESTORE the non-positive increments the builder drops. Same steps as
## builders/build_frames_incr.R (geo merge by Data, Install, Plot, koa.HCB crown, YIP) with the lower bound removed:
## dDBH: live at both, DBH > 0 at both, YIP > 0, dDBH/YIP < 10;  dHT: of those, dHT/YIP < 10. Rows already in the v102 frames are
## kept exactly as they are (verified by key) and the restored rows are appended, so the frames differ only by the restored rows.
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
bsrc <- readLines(file.path(Sys.getenv("HOME"), "jobs/koa_v102_20260918/builders/build_frames_incr.R"))
A <- read.csv(file.path(Sys.getenv("HOME"), "jobs/koa_v102_20260918/inputs/AK.TREE.incr_v102.csv"), stringsAsFactors = FALSE)
PLT.GEO <- read.csv(file.path(Sys.getenv("HOME"), "jobs/koa_v102_20260918/inputs/PLT.GEO.V2_v102.csv"), stringsAsFactors = FALSE)
stopifnot(!any(tolower(names(PLT.GEO)) %in% c("lat", "lon", "long", "latitude", "longitude")))
AK.TREE.incr <- A
eval(parse(text = bsrc[grep('^names\\(AK.TREE.incr\\)\\[names\\(AK.TREE.incr\\) == "Data.0"\\]', bsrc):(grep("^## dDBH frame", bsrc) - 1)]))
sel <- with(AK.TREE.incr, DBH.0 > 0 & Status.0 == "live" & DBH.1 > 0 & Status.1 == "live" & YIP > 0 & dDBH.ann < 10)
X <- addcrown(AK.TREE.incr[which(sel), ])
for (resp in c("dDBH", "dHT")) {
  F <- read.csv(file.path(IN, sprintf("%s_v102.csv", resp)), stringsAsFactors = FALSE)
  Y <- if (resp == "dDBH") X else X[which(X$dHT / X$YIP < 10), ]
  kF <- paste(F$Data, F$Install, F$Plot, F$Tree, F$t.0, F$t.1); kY <- paste(Y$Data, Y$Install, Y$Plot, Y$Tree, Y$t.0, Y$t.1)
  new <- Y[!(kY %in% kF), names(F)]
  logm(resp, "v102 frame", nrow(F), "candidate", nrow(Y), "in frame", sum(kY %in% kF), "restored", nrow(new),
       "restored with annual <= 0", sum(new[[resp]] / new$YIP <= 0), "restored > 0 (e.g. dHT rows whose dDBH was <= 0)", sum(new[[resp]] / new$YIP > 0))
  out <- rbind(F, new); out$restored <- c(rep(0, nrow(F)), rep(1, nrow(new)))
  write.csv(out, file.path(IN, sprintf("%s_nonpos.csv", resp)), row.names = FALSE)
}
logm("NONPOS BUILD DONE")
