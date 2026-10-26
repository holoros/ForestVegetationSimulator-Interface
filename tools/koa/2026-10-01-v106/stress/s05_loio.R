## Stress test script 5: independent leave-one-installation-out refit of Eq. 2 (nlme, random a0 by source/installation),
## population-average prediction on each held-out installation. Background job; writes s05_loio.csv and s05_loio_summary.csv.
suppressMessages(library(nlme))
O <- path.expand("~/jobs/koa_v103_20260930/a3/pending/v106/stress")
d <- read.csv(file.path(O, "s04_height_frame.csv")); d$src <- factor(d$Data); d$inst <- factor(paste(d$Data, d$Install, sep="|"))
st <- c(a0=28.93, a1=0.967, b=0.0170, c=0.792, g1=0.0768, g2=-0.343)
frm <- HT ~ (a0 + a1*byi/100) * (1 - exp(-b*DBH))^c * exp(g1*log(BAPH+1) + g2*rDBH)
st <- coef(nls(frm, data=d, start=as.list(st), control=nls.control(maxiter=500, warnOnly=TRUE))); print(st)
fitf <- function(dd) nlme(frm, data=dd, fixed=a0+a1+b+c+g1+g2~1, random=a0~1|src/inst, start=st,
                          control=nlmeControl(maxIter=200, msMaxIter=200, pnlsMaxIter=50, returnObject=TRUE))
full <- fitf(d); print(fixef(full)); print(full$numIter); write.csv(data.frame(t(fixef(full))), file.path(O, "s05_full_fixef.csv"), row.names=FALSE)
out <- list(); k <- 0
for (I in levels(d$inst)) {
  k <- k + 1; tr <- droplevels(d[d$inst != I, ]); te <- d[d$inst == I, ]
  f <- try(fitf(tr), silent=TRUE)
  if (inherits(f, "try-error")) { out[[k]] <- data.frame(inst=I, n=nrow(te), ok=FALSE, pred=NA, obs=NA); next }
  b <- fixef(f); p <- with(te, (b["a0"] + b["a1"]*byi/100) * (1 - exp(-b["b"]*DBH))^b["c"] * exp(b["g1"]*log(BAPH+1) + b["g2"]*rDBH))
  out[[k]] <- data.frame(inst=I, n=nrow(te), ok=TRUE, pred=p, obs=te$HT)
  if (k %% 10 == 0) cat(format(Sys.time()), k, "\n")
}
o <- do.call(rbind, out); write.csv(o, file.path(O, "s05_loio.csv"), row.names=FALSE)
oo <- o[o$ok, ]; e <- oo$pred - oo$obs
s <- data.frame(folds=length(unique(o$inst)), folds_ok=length(unique(oo$inst)), n=nrow(oo), r2=1-sum(e^2)/sum((oo$obs-mean(oo$obs))^2), rmse=sqrt(mean(e^2)), bias_pred_minus_obs=mean(e))
write.csv(s, file.path(O, "s05_loio_summary.csv"), row.names=FALSE); print(s); cat("DONE\n")
