suppressMessages(library(ranger))
for (f in c("~/jobs/koa_fig2unc_20260927/in/BYI_srf_fit.RDS","~/jobs/koa_fig2unc_20260927/in/BYI_srf_fit_HI.RDS")) {
 m <- readRDS(f); a <- m$ranger.arguments; d <- a$data
 cat("\n==", basename(f), " nrow", nrow(d), " ncol", ncol(d), "\n")
 nm <- names(d); cat("cols:", paste(nm, collapse=" "), "\n")
 cat("dep:", m$dependent.variable.name, " preds:", paste(m$forest$independent.variable.names, collapse=" "), "\n")
 y <- d[[m$dependent.variable.name]]
 cat("n zero", sum(y==0), " n>0", sum(y>0), " quantiles nonzero:", round(quantile(y[y>0], c(0,.5,1)),1), " sd", round(sd(y[y>0]),1), "\n")
 cat("unique rows", nrow(unique(d)), "\n")
 # categorical preds: tabulate by zero status (no coordinates printed)
 for (v in nm) { x <- d[[v]]; if (grepl("lat|lon|^x$|^y$|coord|east|north|utm", v, ignore.case=TRUE)) {cat(v, ": coordinate-like, not printed\n"); next}
   if (is.factor(x) || is.character(x) || length(unique(x)) <= 12) { cat(v, "\n"); print(table(x, zero = y==0, useNA="ifany")) } else {
     cat(sprintf("%s  zero median %.3g  nonzero median %.3g\n", v, median(x[y==0],na.rm=T), median(x[y>0],na.rm=T))) } }
 cat("OOB R2 ranger", m$r.squared, " OOB RMSE", sqrt(m$prediction.error), " num.trees", m$num.trees, " mtry", m$mtry, "\n")
}
p <- read.csv("~/jobs/koa_fig2unc_20260927/out_oob_pairs_DATA.csv")
for (g in unique(p$model)) { q <- p[p$model==g,]; for (s in c("all","nonzero","zero")) {
 r <- if (s=="all") q else if (s=="nonzero") q[q$obs>0,] else q[q$obs==0,]
 rmse <- sqrt(mean((r$obs-r$oob)^2)); r2 <- 1 - sum((r$obs-r$oob)^2)/sum((r$obs-mean(r$obs))^2)
 cat(sprintf("%s %s n=%d OOB RMSE=%.1f OOB R2=%.3f mean oob=%.1f\n", g, s, nrow(r), rmse, r2, mean(r$oob))) } }
