set.seed(20260926)
v <- read.csv("validation_23.csv", stringsAsFactors=FALSE)
NB <- 5000
tst <- function(d, lab){
  qs <- c("surv","ba","qmd"); nm <- c("Cohort survival fraction","Basal area (m2 ha-1)","QMD (cm)")
  for (i in seq_along(qs)){
    o <- d[[paste0("obs_",qs[i])]]; p <- d[[paste0("pred_",qs[i])]]
    k <- is.finite(o) & is.finite(p); o <- o[k]; p <- p[k]; n <- length(o)
    if (n < 3) next
    diff <- p - o; mo <- mean(o)
    bs <- replicate(NB, { j <- sample(n, n, TRUE); mean(p[j]-o[j]) })
    ci <- stats::quantile(bs, c(0.05,0.95))          # 90% CI, the TOST-equivalent band
    smallest <- max(abs(ci))/mo
    pass25 <- all(abs(ci) <= 0.25*mo)
    cat(sprintf("%-22s %-26s n=%2d  obs mean %8.3f  mean diff %+8.3f (%+.3f to %+.3f)  +/-25%% = %.3f  %-12s smallest passing region %5.1f%%\n",
        lab, nm[i], n, mo, mean(diff), ci[1], ci[2], 0.25*mo,
        if (pass25) "EQUIVALENT" else "not equiv", 100*smallest))
  }
  cat("\n")
}
tst(v, "all 23 plots")
tst(v[v$origin=="natural",], "natural (12)")
tst(v[v$origin=="planted",], "planted (11)")
fia <- v[grepl("FIA", v$PLOT, ignore.case=TRUE),]
cat("FIA-only rows found:", nrow(fia), " PLOT examples:", paste(head(unique(v$PLOT),4), collapse=", "), "\n\n")
if (nrow(fia) >= 3) tst(fia, "FIA only (independent)")
