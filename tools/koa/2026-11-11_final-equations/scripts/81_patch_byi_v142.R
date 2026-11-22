# 81_patch_byi_v142.R  koa v142 working copy: replaces every plot's BYI in the frames with BYI_v142 from out/byi_oob_80.csv (script 80):
#   C2 index rebuilt without the 474 duplicate Eq. 1 rows, both forests retrained, FIA training plots predicted out of bag, all other plots
#   predicted by the full retrained forest (Kap from its own climate and soils, as 66). Nothing else in the frames changes.
# Run from ~/jobs/koa_1150_20261121 of the v142 copy. No plot or installation identifier is printed.
suppressMessages(library(data.table)); setwd("~/jobs/koa_1150_20261121")
B <- fread("out/byi_oob_80.csv", colClasses = list(character = c("Install", "Plot"))); stopifnot(!anyNA(B$BYI_v142)); bk <- paste(B$Data, B$Install, B$Plot)
fix <- function(x, nm) { if (!is.data.frame(x) || !all(c("Data", "Install", "Plot", "BYI") %in% names(x))) return(x); x <- as.data.table(x)
  m <- match(paste(x$Data, as.character(x$Install), as.character(x$Plot)), bk)
  cat(sprintf("%-10s rows %6d | unmatched rows %d | median ratio new/old %.3f\n", nm, nrow(x), sum(is.na(m)), median(B$BYI_v142[m] / x$BYI, na.rm = TRUE)))
  stopifnot(all(!is.na(m))); x[, BYI := B$BYI_v142[m]]; x }
f <- readRDS("frames/frames.rds"); file.copy("frames/frames.rds", "frames/frames_1150_PREV_20261121.rds", overwrite = FALSE)
for (n in names(f)) f[[n]] <- fix(f[[n]], n); saveRDS(f, "frames/frames.rds")
mf <- readRDS("frames/mf_confirmed.rds"); file.copy("frames/mf_confirmed.rds", "frames/mf_confirmed_1150_PREV_20261121.rds", overwrite = FALSE); mf2 <- fix(mf, "mf")
saveRDS(if (is.data.table(mf) || !is.data.frame(mf)) mf2 else as.data.frame(mf2), "frames/mf_confirmed.rds")
u <- unique(as.data.table(f$tr)[, .(Data, Install, Plot, planted, BYI)])
cat("natural BYI percentiles (10, 50, 90) after patch:", round(quantile(u[planted == 0, BYI], c(.1, .5, .9)), 1), "| planted:", round(quantile(u[planted == 1, BYI], c(.1, .5, .9)), 1), "\n"); cat("81 done\n")
