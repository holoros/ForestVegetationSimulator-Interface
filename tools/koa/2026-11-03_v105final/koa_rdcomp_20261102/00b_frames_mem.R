## 00b_frames_mem.R: rebuild the v105b NO frames in memory with inc_v103.R lines 148-197 (v105b job, read only), write.csv masked to a no-op so nothing is written
## to the v105 job; saved as full-precision RDS in this job. Checks equality with the CSV model frames.
suppressPackageStartupMessages(library(nlme))
src <- readLines(path.expand("~/jobs/koa_v105_20261102/track2/inc/inc_v103.R"))
commandArgs0 <- commandArgs; commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112])); commandArgs <- commandArgs0
write.csv <- function(...) invisible(NULL)
eval(parse(text = src[148:197])); rm(write.csv)
OB <- path.expand("~/jobs/koa_rdcomp_20261102/out")
for (resp in c("dDBH", "dHT")) { m <- FR[[paste(resp, "NO")]]
  c <- read.csv(file.path(FRD, sprintf("%s_NO_v103_model.csv", resp)), stringsAsFactors = FALSE)
  num <- names(m)[sapply(m, is.numeric)]
  cat(resp, "rows mem", nrow(m), "csv", nrow(c), "| max abs diff over numeric cols", max(sapply(num, function(v) max(abs(m[[v]] - c[[v]]), na.rm = TRUE))),
      "| keys identical", identical(paste(m$TreeID, m$t.0, m$t.1), paste(c$TreeID, c$t.0, c$t.1)), "\n")
  saveRDS(m, file.path(OB, sprintf("frame_mem_%s_NO.rds", resp))) }
