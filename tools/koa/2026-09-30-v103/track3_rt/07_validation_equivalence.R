## 07_validation_equivalence.R: bootstrap equivalence tests on the 23-plot integrated validation,
## plot as the resampling unit, regions fixed a priori at 25% (red team major 6; philosophy principle 16).
source("common.R")
v <- std(read_dep(F_VALID), VCOL)
if (is.null(v)) { logmsg("skip 07: validation file not configured"); cat("done\n"); quit(save = "no") }
need(v, c("plot", "obs_surv", "pred_surv", "obs_ba", "pred_ba"), "validation file")
rows <- list()
for (q in c("surv", "ba", "qmd")) {
  o <- paste0("obs_", q); p <- paste0("pred_", q)
  if (!all(c(o, p) %in% names(v))) next
  rows[[q]] <- cbind(quantity = q, equiv_boot(v[[o]], v[[p]], v$plot))
  if ("interval" %in% names(v)) {
    long <- v$interval >= stats::median(v$interval)
    rows[[paste0(q, "_long")]] <- cbind(quantity = paste(q, "long intervals"), equiv_boot(v[[o]][long], v[[p]][long], v$plot[long]))
    rows[[paste0(q, "_short")]] <- cbind(quantity = paste(q, "short intervals"), equiv_boot(v[[o]][!long], v[[p]][!long], v$plot[!long]))
  }
}
wcsv(do.call(rbind, rows), "07_validation_equivalence.csv")
cat("done\n")
