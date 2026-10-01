#!/usr/bin/env Rscript
## rt_q1q2_c_equiv.R (red team, 2026-09-30). READ ONLY on koa_v103_20260930. Q1: seed robustness of the equivalence regions of the v102 dDBH
## vector under BAL l (and d, c); CS vs NO constants. Q2: decomposition of the natural c: d vs l vs c vs an engine-consistent covariate set
## "k" (BAPH = live koa BA of the plot-year, BAL = BALl x BA.AK / BAPH, i.e. the koa-only percentile path the engine computes at t0, CR by HCB_P).
suppressPackageStartupMessages(library(nlme))
W <- path.expand("~/jobs/koa_v103_20260930"); OUT <- path.expand("~/jobs/rt_koa_v103_scratch")
src <- readLines(file.path(W, "track2/inc/inc_v103.R"))
i0 <- grep("^HCB_P <- c\\(", src)[1]; i1 <- grep("^taus <- function", src)[1]
e <- new.env(); eval(parse(text = src[i0:i1]), envir = e); attach(e, warn.conflicts = FALSE)
PL <- read.csv(file.path(W, "inputs/AK_PLT_v103.csv"), stringsAsFactors = FALSE)[, c("Data","Install","Plot","Measure","BAPH","BA.AK")]
stopifnot(!any(tolower(names(PL)) %in% c("lat","lon","long","latitude","longitude","x","y")))
PL$key <- paste(PL$Data, PL$Install, PL$Plot, PL$Measure); PL <- PL[!duplicated(PL$key), ]
rd <- function(resp, fr) { d <- read.csv(file.path(W, sprintf("frames/final/%s_%s_v103_model.csv", resp, fr)), stringsAsFactors = FALSE)
  d$icls <- factor(d$icls, levels = c("1-2","3-5","6-10","11-20","21+"))
  k0 <- match(paste(d$Data, d$Install, d$Plot, d$t.0), PL$key); k1 <- match(paste(d$Data, d$Install, d$Plot, d$t.1), PL$key)
  d$BAK.0 <- PL$BA.AK[k0]; d$BAK.1 <- PL$BA.AK[k1]; d$chk0 <- PL$BAPH[k0] - d$BAPH.0
  d$sh.0 <- pmin(1, d$BAK.0 / pmax(d$BAPH.0, 1e-9)); d$sh.1 <- pmin(1, d$BAK.1 / pmax(d$BAPH.1, 1e-9))
  d$BALk.0 <- d$BALl.0 * d$sh.0; d$BALk.1 <- d$BALl.1 * d$sh.1
  d$CRk.0 <- (d$HT.0 - engine.HCB(d$HT.0, d$DBH.0, d$BALk.0, d$BAK.0, d$BYI)) / d$HT.0
  d$CRk.1 <- (d$HT.1 - engine.HCB(d$HT.1, d$DBH.1, d$BALk.1, d$BAK.1, d$BYI)) / d$HT.1
  d }
res <- list(); eqr <- list(); shr <- list()
for (fr in c("CS","NO")) {
  d <- rd("dDBH", fr)
  cat(fr, "rows", nrow(d), "unmatched BA.AK t0", sum(is.na(d$BAK.0)), "t1", sum(is.na(d$BAK.1)), "max |BAPH frame - PLT|", max(abs(d$chk0), na.rm = TRUE), "\n")
  nat <- d$Planted == 0
  shr[[fr]] <- aggregate(cbind(sh.0, BAPH.0, BAK.0, BALl.0, BALd.0, BALk.0) ~ Data + Planted, data = d, FUN = median)
  assign("GUARD", 45, envir = e)
  for (b in c("d","l","c","k")) {
    de <- d
    if (b == "k") { de$BAPH.0 <- de$BAK.0; de$BAPH.1 <- de$BAK.1; de$BALk.0 -> de$BALk.0 }
    de <- model_cols(de, b)
    cc <- solve_c("dDBH", de, START$dDBH)
    res[[paste(fr, b)]] <- data.frame(frame = fr, bal = b, n = nrow(de), n_nat = sum(de$Planted == 0), c_nat = cc[["natural"]], c_pl = cc[["planted"]])
    if (fr == "NO" || b %in% c("l","k")) {
      reps <- if (b %in% c("l","k")) 30 else 10
      for (s in seq_len(reps)) { set.seed(1000 + s)
        sc <- score("dDBH", de, START$dDBH, cc, paste(b, fr))
        eqr[[paste(fr, b, s)]] <- data.frame(frame = fr, bal = b, seed = s, r_int = sc$equiv$min_region_int, r_slope = sc$equiv$min_region_slope, slope = sc$equiv$slope)
        if (s == 1) { st <- sc$strata; st$bal <- b; st$frame <- fr; write.csv(st, file.path(OUT, sprintf("rt_strata_%s_%s.csv", b, fr)), row.names = FALSE) } }
    }
    cat(format(Sys.time()), fr, b, "c", round(cc, 4), "\n")
  }
}
R <- do.call(rbind, res); E <- do.call(rbind, eqr); write.csv(R, file.path(OUT, "rt_c_by_bal.csv"), row.names = FALSE); write.csv(E, file.path(OUT, "rt_equiv_seeds.csv"), row.names = FALSE)
print(R); print(do.call(rbind, shr))
agg <- do.call(rbind, lapply(split(E, paste(E$frame, E$bal)), function(x) data.frame(frame = x$frame[1], bal = x$bal[1], n = nrow(x),
  int_mean = mean(x$r_int), int_sd = sd(x$r_int), int_max = max(x$r_int), slope_mean = mean(x$r_slope), slope_sd = sd(x$r_slope), slope_max = max(x$r_slope), p_fail = mean(pmax(x$r_int, x$r_slope) > 0.25))))
print(agg); write.csv(agg, file.path(OUT, "rt_equiv_seed_summary.csv"), row.names = FALSE)
write.csv(do.call(rbind, shr), file.path(OUT, "rt_koa_share_frames.csv"), row.names = FALSE)
cat("RT DONE\n")
