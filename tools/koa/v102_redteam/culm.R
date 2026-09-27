tj <- read.csv("trajectories.csv", stringsAsFactors=FALSE)
tj <- tj[tj$age > 0, ]
cul <- function(x){
  x <- x[order(x$age),]
  mai <- x$VOL/x$age
  pai <- c(NA, diff(x$VOL)/diff(x$age))
  up <- which(!is.na(pai) & pai > mai)[1]; if (is.na(up)) up <- 1
  k <- seq(up, length(mai)); x$age[k[which.max(mai[k])]]
}
res <- do.call(rbind, lapply(split(tj, list(tj$scenario, tj$site, tj$rep), drop=TRUE), function(x)
  data.frame(scenario=x$scenario[1], site=x$site[1], rep=x$rep[1], cul=cul(x))))
pt <- res[res$rep==0,]; bs <- res[res$rep!=0,]
cat(sprintf("%-22s %-7s %6s %18s %10s\n","scenario","site","point","95% MC interval","n reps"))
for (sc in c("Even-aged natural","Even-aged planted","Uneven-aged natural"))
 for (si in c("Low","Medium","High")) {
   p <- pt$cul[pt$scenario==sc & pt$site==si]
   b <- bs$cul[bs$scenario==sc & bs$site==si]
   q <- stats::quantile(b, c(0.025,0.975))
   cat(sprintf("%-22s %-7s %6.0f %18s %10d\n", sc, si, p, sprintf("%.0f to %.0f", q[1], q[2]), length(b)))
 }
