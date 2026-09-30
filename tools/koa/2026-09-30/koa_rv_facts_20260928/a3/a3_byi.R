suppressMessages(library(ranger))
mk <- readRDS("~/jobs/koa_fig2unc_20260927/in/BYI_srf_fit.RDS"); ms <- readRDS("~/jobs/koa_fig2unc_20260927/in/BYI_srf_fit_HI.RDS")
g <- read.csv("~/jobs/koa_v102_20260918/inputs/PLT.GEO.V2_v102.csv", stringsAsFactors=FALSE)
stopifnot(!any(tolower(names(g)) %in% c("lat","lon","long","latitude","longitude","x","y")))
g <- unique(g[, c("Data","Install","Plot", intersect(names(g), unique(c(mk$forest$independent.variable.names, ms$forest$independent.variable.names, "BYI"))))])
cat("geo plots", nrow(g), " have Kona preds:", all(mk$forest$independent.variable.names %in% names(g)), " statewide preds:", all(ms$forest$independent.variable.names %in% names(g)), "\n")
cat("missing Kona:", setdiff(mk$forest$independent.variable.names, names(g)), " missing statewide:", setdiff(ms$forest$independent.variable.names, names(g)), "\n")
dep <- read.csv("~/jobs/koa_zenodo_180/stage_v190/AK_PLT_GEO.csv", stringsAsFactors=FALSE)
d <- merge(dep[, c("Data","Install","Plot","BYI")], g, by=c("Data","Install","Plot"), suffixes=c("", ".geo"))
cat("merged", nrow(d), "\n")
if ("BYI.geo" %in% names(d)) cat("deposit BYI vs PLT.GEO BYI max abs diff", max(abs(d$BYI - d$BYI.geo), na.rm=TRUE), "\n")
ok <- complete.cases(d[, ms$forest$independent.variable.names])
ps <- rep(NA, nrow(d)); ps[ok] <- predict(ms, d[ok, ], num.threads=2)$predictions
okk <- complete.cases(d[, mk$forest$independent.variable.names])
pk <- rep(NA, nrow(d)); if (any(okk)) pk[okk] <- predict(mk, d[okk, ], num.threads=2)$predictions
d$ps <- ps; d$pk <- pk
for (src in unique(d$Data)) { e <- d[d$Data==src, ]
  cat(sprintf("%-10s n=%d  |BYI-statewide pred| median %.3g max %.3g  |BYI-Kona pred| median %.3g max %.3g  n exact(1e-6) stw %d kona %d\n", src, nrow(e),
   median(abs(e$BYI-e$ps),na.rm=T), max(abs(e$BYI-e$ps),na.rm=T), median(abs(e$BYI-e$pk),na.rm=T), max(abs(e$BYI-e$pk),na.rm=T), sum(abs(e$BYI-e$ps)<1e-6,na.rm=T), sum(abs(e$BYI-e$pk)<1e-6,na.rm=T))) }
y <- mk$ranger.arguments$data$Schmoldt_Index; fia <- d$BYI[d$Data=="FIA"]
cat("FIA koa-plot BYI values equal to a Schmoldt training value:", sum(sapply(fia, function(v) any(abs(y - v) < 1e-6))), "of", length(fia), "\n")
ins <- predict(mk, mk$ranger.arguments$data, num.threads=2)$predictions
cat("FIA koa-plot BYI equal to an in-sample Kona prediction:", sum(sapply(fia, function(v) any(abs(ins - v) < 1e-6))), "\n")
k <- d[d$Install=="Kulani", c("Plot","BYI","ps","pk")]; print(round(k[, -1], 2))
