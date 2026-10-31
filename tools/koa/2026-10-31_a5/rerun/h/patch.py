s=open('h_boot.R').read()
old_start = s.index('f <- file.path(O, "h_boot_final.csv")')
new_tail = r'''## per-draw checkpoint: each worker writes draws/draw_<b>.csv, so an interrupted run loses at most the draws in flight
DD <- file.path(O, "draws"); dir.create(DD, showWarnings = FALSE)
one_ck <- function(b) { fn <- file.path(DD, sprintf("draw_%04d.csv", b)); if (file.exists(fn)) return(invisible(NULL))
  r <- one(b); write.csv(as.data.frame(t(r)), paste0(fn, ".tmp"), row.names = FALSE); file.rename(paste0(fn, ".tmp"), fn); invisible(NULL) }
todo <- which(!file.exists(file.path(DD, sprintf("draw_%04d.csv", seq_len(B)))))
logm("draws to do", length(todo), "cores", cores)
invisible(parallel::mclapply(todo, one_ck, mc.cores = cores, mc.preschedule = FALSE))
fs <- list.files(DD, pattern = "^draw_[0-9]+\\.csv$", full.names = TRUE)
bs <- do.call(rbind, lapply(fs, read.csv)); bs <- bs[order(bs$draw), ]
write.csv(bs, file.path(O, "h_boot_final.csv"), row.names = FALSE)
logm("HEIGHT BOOT DONE ok", sum(bs$ok), "of", nrow(bs))
'''
open('h_boot.R','w').write(s[:old_start] + new_tail)
open('h_summ.R','w').write(r'''## summary of the draws completed so far (reads draws/draw_*.csv); percentile intervals and SE ratios among converged draws
J <- path.expand("~/jobs/koa_v104_20261030"); O <- file.path(J, "a5/rerun/h")
ref <- read.csv(file.path(O, "h_ref_final.csv"))
fs <- list.files(file.path(O, "draws"), pattern = "^draw_[0-9]+\\.csv$", full.names = TRUE)
bs <- do.call(rbind, lapply(fs, read.csv)); bs <- bs[order(bs$draw), ]; write.csv(bs, file.path(O, "h_boot_final.csv"), row.names = FALSE)
ok <- bs[bs$ok == 1, ]
s <- do.call(rbind, lapply(ref$term, function(p) { x <- ok[[p]]
  data.frame(term = p, est = ref$est[ref$term == p], wald_se = ref$wald_se[ref$term == p], boot_se = sd(x),
    ratio = sd(x) / ref$wald_se[ref$term == p], lo = unname(quantile(x, .025)), hi = unname(quantile(x, .975)), row.names = NULL) }))
s$draws_done <- nrow(bs); s$converged <- nrow(ok); s$draws_planned <- 2000
write.csv(s, file.path(O, "h_boot_summary_final.csv"), row.names = FALSE); print(s)
''')
