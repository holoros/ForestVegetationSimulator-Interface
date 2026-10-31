## summary of the draws completed so far (reads draws/draw_*.csv); percentile intervals and SE ratios among converged draws
J <- path.expand("~/jobs/koa_v104_20261030"); O <- file.path(J, "a5/rerun/h")
ref <- read.csv(file.path(O, "h_ref_final.csv"))
fs <- list.files(file.path(O, "draws"), pattern = "^draw_[0-9]+\\.csv$", full.names = TRUE)
bs <- do.call(rbind, lapply(fs, read.csv)); bs <- bs[order(bs$draw), ]; write.csv(bs, file.path(O, "h_boot_final.csv"), row.names = FALSE)
ok <- bs[bs$ok == 1, ]
s <- do.call(rbind, lapply(ref$term, function(p) { x <- ok[[p]]
  data.frame(term = p, est = ref$est[ref$term == p], wald_se = ref$wald_se[ref$term == p], boot_se = sd(x),
    ratio = sd(x) / ref$wald_se[ref$term == p], lo = unname(quantile(x, .025)), hi = unname(quantile(x, .975)), row.names = NULL) }))
s$draws_done <- nrow(bs); s$converged <- nrow(ok); s$draws_planned <- 500
write.csv(s, file.path(O, "h_boot_summary_final.csv"), row.names = FALSE); print(s)
