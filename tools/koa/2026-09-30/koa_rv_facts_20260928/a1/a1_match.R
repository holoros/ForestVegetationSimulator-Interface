k <- readRDS("~/jobs/koa_fig2unc_20260927/in/BYI_srf_fit.RDS")$ranger.arguments$data
s <- readRDS("~/jobs/koa_fig2unc_20260927/in/BYI_srf_fit_HI.RDS")$ranger.arguments$data
sh <- intersect(names(k), names(s)); cat("shared cols:", sh, "\n")
kk <- do.call(paste, c(lapply(k[sh], function(x) signif(x, 8)), sep="|")); ss <- do.call(paste, c(lapply(s[sh], function(x) signif(x, 8)), sep="|"))
cat("Kona rows found in statewide:", sum(kk %in% ss), " statewide rows found in Kona:", sum(ss %in% kk), "\n")
miss <- which(!(kk %in% ss)); cat("Kona rows not in statewide:", length(miss), " their BYI:", k$Schmoldt_Index[miss], "\n")
cat("same row order for first 581?", isTRUE(all.equal(k[-miss, sh], s[, sh], check.attributes=FALSE)), "\n")
cat("GEO_YR summary zero:", summary(k$GEO_YR[k$Schmoldt_Index==0]), "\nGEO_YR nonzero:", summary(k$GEO_YR[k$Schmoldt_Index>0]), "\n")
cat("rain quartiles zero:", quantile(k$rain[k$Schmoldt_Index==0], c(.1,.25,.5,.75,.9)), "\nrain nonzero:", quantile(k$rain[k$Schmoldt_Index>0], c(.1,.25,.5,.75,.9)), "\n")
cat("nonzero BYI > 1000:", sum(k$Schmoldt_Index>1000), " > 813:", sum(k$Schmoldt_Index>813), "\n")
cat("nonzero quantiles:", quantile(k$Schmoldt_Index[k$Schmoldt_Index>0], c(.1,.25,.5,.75,.9)), " mean", mean(k$Schmoldt_Index[k$Schmoldt_Index>0]), "\n")
