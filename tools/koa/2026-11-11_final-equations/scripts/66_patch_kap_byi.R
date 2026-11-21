# 66_patch_kap_byi.R  koa 1.15.0 working copy: replaces the single imputed BYI (64.45216) of the Kap plots in every frame with the BYI predicted from
# each plot's own climate and soils by the deployed statewide C2 forest (koa_kapbyi_20261121/kap_byi_predicted.csv). Nothing else in the frames changes.
# Run from ~/jobs/koa_1150_20261121 after the copy. No plot or installation identifier is printed.
suppressMessages(library(data.table)); setwd("~/jobs/koa_1150_20261121")
K <- fread("~/jobs/koa_kapbyi_20261121/kap_byi_predicted.csv", colClasses = list(character = c("Install", "Plot"))); kk <- paste(K$Install, K$Plot)
fix <- function(x, nm) { if (!is.data.frame(x) || !all(c("Data", "Install", "Plot", "BYI") %in% names(x))) return(x); x <- as.data.table(x)
  i <- which(x$Data == "Kap"); if (!length(i)) return(x); m <- match(paste(x$Install[i], as.character(x$Plot[i])), kk)
  cat(sprintf("%-10s Kap rows %5d | plots %3d | matched plots %3d | old BYI %s\n", nm, length(i), uniqueN(paste(x$Install[i], x$Plot[i])), uniqueN(paste(x$Install[i], x$Plot[i])[!is.na(m)]), paste(unique(round(x$BYI[i], 3)), collapse = ",")))
  stopifnot(all(!is.na(m))); x[i, BYI := K$BYI_pred[m]]; x }
f <- readRDS("frames/frames.rds"); file.copy("frames/frames.rds", "frames/frames_PREV_20261121.rds")
for (n in names(f)) f[[n]] <- fix(f[[n]], n); saveRDS(f, "frames/frames.rds")
mf <- readRDS("frames/mf_confirmed.rds"); file.copy("frames/mf_confirmed.rds", "frames/mf_confirmed_PREV_20261121.rds"); mf2 <- fix(mf, "mf"); saveRDS(if (is.data.table(mf) || !is.data.frame(mf)) mf2 else as.data.frame(mf2), "frames/mf_confirmed.rds")
u <- unique(as.data.table(f$tr)[, .(Data, Install, Plot, planted, BYI)]); cat("natural BYI percentiles (10, 50, 90) after patch:", round(quantile(u[planted == 0, BYI], c(.1, .5, .9)), 1), "\n"); cat("66 done\n")
