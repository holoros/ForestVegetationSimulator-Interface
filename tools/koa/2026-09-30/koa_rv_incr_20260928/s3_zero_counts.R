## s3_zero_counts.R (R1 c4). How the v102 frames treat zero, negative and implausible increments, from the builder rule of
## ~/jobs/koa_v102_20260918/builders/build_frames_incr.R (dDBH: DBH.0 > 0, live at both, YIP > 0, 0 < dDBH/YIP < 10;
## dHT: additionally 0 < dHT/YIP < 10). Counts on AK.TREE.incr_v102.csv joined to the plot keys of PLT.GEO.V2_v102.csv
## (key columns only are read; no coordinate is read or written).
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
A <- read.csv(file.path(Sys.getenv("HOME"), "jobs/koa_v102_20260918/inputs/AK.TREE.incr_v102.csv"), stringsAsFactors = FALSE)
G <- read.csv(file.path(Sys.getenv("HOME"), "jobs/koa_v102_20260918/inputs/PLT.GEO.V2_v102.csv"), stringsAsFactors = FALSE)[, c("Data", "Install", "Plot")]
names(A)[names(A) == "Data.0"] <- "Data"; names(A)[names(A) == "Install.0"] <- "Install"; names(A)[names(A) == "Plot.0"] <- "Plot"
A <- merge(A, unique(G), by = c("Data", "Install", "Plot"))
A$YIP <- A$t.1 - A$t.0; A$da <- A$dDBH / A$YIP; A$ha <- A$dHT / A$YIP
base <- with(A, DBH.0 > 0 & Status.0 == "live" & DBH.1 > 0 & Status.1 == "live" & YIP > 0); base[is.na(base)] <- FALSE
B <- A[base, ]
r <- data.frame(stage = c("live-live pairs with DBH > 0", "dDBH annual < 0", "dDBH annual == 0", "dDBH annual >= 10", "dDBH annual NA",
                          "retained dDBH frame (pre complete-case)", "of retained, dHT annual < 0", "of retained, dHT annual == 0", "of retained, dHT annual >= 10", "of retained, dHT NA",
                          "retained dHT frame (pre complete-case)"),
  n = c(nrow(B), sum(B$da < 0, na.rm = TRUE), sum(B$da == 0, na.rm = TRUE), sum(B$da >= 10, na.rm = TRUE), sum(is.na(B$da)),
        sum(B$da > 0 & B$da < 10, na.rm = TRUE), NA, NA, NA, NA, NA))
K <- B[which(B$da > 0 & B$da < 10), ]
r$n[7:11] <- c(sum(K$ha < 0, na.rm = TRUE), sum(K$ha == 0, na.rm = TRUE), sum(K$ha >= 10, na.rm = TRUE), sum(is.na(K$ha)), sum(K$ha > 0 & K$ha < 10, na.rm = TRUE))
## by interval length and origin among the dropped non-positive dDBH records
B$short <- B$YIP < 3
r2t <- as.data.frame(table(nonpos_dDBH = B$da <= 0, short_interval = B$short, useNA = "no"))
print(r); print(r2t)
for (resp in c("dDBH", "dHT")) { d <- prep(resp); cat(resp, "n", nrow(d), "annual quantiles", round(quantile(d$ann, c(0, .01, .5, .99, 1)), 3), "n > 5/yr", sum(d$ann > 5), "\n")
  print(table(d$org, cut(d$ann, c(0, 0.05, 0.1, 5, 10)))) }
write.csv(r, file.path(OUT, "zero_negative_counts.csv"), row.names = FALSE); write.csv(r2t, file.path(OUT, "zero_negative_by_interval.csv"), row.names = FALSE)
