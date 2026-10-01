## diag_c_by_source.R (red team diagnostic): recursion-consistent natural and planted c of the deployed vectors under l on the v103 NO frame,
## pooled and by source, and with FIA dropped; plus the same on the v102 d frame reference. Explains where the natural multiplier comes from.
suppressPackageStartupMessages(library(nlme)); W <- path.expand("~/jobs/koa_v103_20260930"); setwd(W)
src <- readLines("track2/inc/inc_v103.R"); eval(parse(text = src[grep("^HCB_P <- c\\(", src)[1]:grep("^taus <- function", src)[1]]))
J <- jsonlite::fromJSON("out/v103_constants.json"); VEC <- list(dDBH = unlist(J$DDBH$coef), dHT = unlist(J$DHT$coef))
out <- list()
for (resp in c("dDBH", "dHT")) { GUARD <- if (resp == "dDBH") 45 else 20
  d <- read.csv(sprintf("frames/final/%s_NO_v103_model.csv", resp), stringsAsFactors = FALSE); d <- model_cols(d, "l")
  sets <- c(list(all = unique(d$Data), noFIA = setdiff(unique(d$Data), "FIA")), setNames(as.list(unique(d$Data)), unique(d$Data)))
  for (nm in names(sets)) { dd <- d[d$Data %in% sets[[nm]], ]
    cc <- sapply(c(natural = 0, planted = 1), function(pl) { x <- dd[dd$Planted == pl, ]; if (nrow(x) < 20) return(NA_real_)
      f <- function(lc) { bb <- VEC[[resp]]; bb["b0"] <- bb["b0"] + lc; sum(pa_pred(resp, x, bb)) - sum(x[[resp]]) }; exp(uniroot(f, c(-4, 4), tol = 1e-8)$root) })
    out[[paste(resp, nm)]] <- data.frame(resp = resp, set = nm, n_nat = sum(dd$Planted == 0), n_pl = sum(dd$Planted == 1), c_natural = cc[["natural"]], c_planted = cc[["planted"]],
      med_BAPH0_nat = median(dd$BAPH.0[dd$Planted == 0]), med_BAL0_nat = median(dd$BALx.0[dd$Planted == 0])) } }
R <- do.call(rbind, out); write.csv(R, "a2/out/diag_c_by_source.csv", row.names = FALSE); print(R, digits = 4)
