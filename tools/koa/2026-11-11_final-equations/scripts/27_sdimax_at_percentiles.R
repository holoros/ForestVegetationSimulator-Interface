# 27_sdimax_at_percentiles.R  Equation S1 at the exact scenario BYI percentiles (10th, 50th, 90th of each origin's plots with tree records, as in 23t), with
# 95% percentile intervals from the joint bootstrap of 22t. Log 22t printed the same quantities at BYI rounded to whole numbers. No fitting.
suppressMessages(library(data.table)); setwd("~/jobs/koa_final_eq_20261110"); f <- readRDS("frames/frames.rds"); tr <- f$tr; FT <- readRDS("out/rdbyi2_fits.rds"); K <- readRDS("out/rdbyi2_boot.rds")$K; bs <- FT$bs
u <- unique(tr[, .(pid, planted, BYI)]); cat("plots with tree records:", nrow(u), "; natural", u[planted == 0, .N], "; planted", u[planted == 1, .N], "; BYI range", round(min(u$BYI), 1), "to", round(max(u$BYI), 1), "; median", round(median(u$BYI), 1), "; bootstrap rows", nrow(K), "\n")
q <- u[, .(lo = quantile(BYI, .1), md = quantile(BYI, .5), hi = quantile(BYI, .9)), by = planted]
for (p in 0:1) for (l in c("lo", "md", "hi")) { b <- q[planted == p][[l]]; ci <- quantile(exp(K[, 1] + K[, 2] * log(b) + K[, 3] * p), c(.025, .975), na.rm = TRUE)
  cat(c("natural", "planted")[p + 1], l, "BYI", round(b, 2), "SDImax", round(exp(bs[[1]] + bs[[2]] * log(b) + bs[[3]] * p)), "95% interval", round(ci[1]), "to", round(ci[2]), "\n") }
