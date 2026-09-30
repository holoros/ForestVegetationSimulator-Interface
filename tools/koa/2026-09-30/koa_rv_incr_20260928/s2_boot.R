## s2_boot.R <resp> <B> <cores>. Installation-cluster bootstrap of Eq. 4 (R1 comment 3).
## Clusters are Data x Install (the unit of the installation random effect). Each resample draws installations with replacement,
## relabels duplicated installations so each copy is its own random-effect level, and refits with the reference path from the
## reference optimum. Resample index sets are generated up front from seed 20260928 (draw b is the same for any B >= b), so
## results do not depend on scheduling. Results are appended in chunks to out/boot_<resp>.csv so a partial run is usable.
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
a <- commandArgs(trailingOnly = TRUE); resp <- a[1]; B <- as.integer(a[2]); cores <- as.integer(a[3])
REF <- load_ref(); m0 <- REF[[resp]]; st <- fixef(m0)
d <- prep(resp); ids <- unique(d$InstID); sp <- split(seq_len(nrow(d)), d$InstID)
set.seed(20260928); DRAWS <- lapply(seq_len(B), function(b) sample(ids, replace = TRUE))
of <- file.path(OUT, sprintf("boot_%s.csv", resp))
done <- if (file.exists(of)) unique(read.csv(of)$draw) else integer(0)
todo <- setdiff(seq_len(B), done); logm(resp, "B", B, "todo", length(todo), "cores", cores, "clusters", length(ids))
one <- function(b) {
  s <- DRAWS[[b]]
  dd <- do.call(rbind, lapply(seq_along(s), function(j) { x <- d[sp[[s[j]]], ]; x$Install <- paste(x$Install, j, sep = "#"); x }))
  t0 <- Sys.time()
  m <- tryCatch(suppressWarnings(fit_ref(resp, dd, st)), error = function(e) NULL)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  if (is.null(m)) return(data.frame(draw = b, ok = 0, secs = el, logLik = NA, tau_source = NA, tau_inst = NA, t(setNames(rep(NA, 10), TERMS))))
  tau <- vc_taus(m)
  data.frame(draw = b, ok = 1, secs = el, logLik = as.numeric(logLik(m)), tau_source = tau[1], tau_inst = tau[2], t(fixef(m)[TERMS]))
}
chunk <- cores * 4
for (i in seq(1, length(todo), by = chunk)) {
  idx <- todo[i:min(length(todo), i + chunk - 1)]
  r <- do.call(rbind, parallel::mclapply(idx, one, mc.cores = cores, mc.preschedule = FALSE))
  write.table(r, of, sep = ",", row.names = FALSE, col.names = !file.exists(of), append = file.exists(of))
  logm(resp, "done", max(idx), "of", B, "ok", sum(r$ok), "/", nrow(r), "median s", round(median(r$secs)))
}
logm("BOOT DONE", resp)
