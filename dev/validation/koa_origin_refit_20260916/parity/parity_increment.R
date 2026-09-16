## parity_increment.R: the R increment carriers against the Python projection engine after the origin refit.
## KOA_HIGY=path/to/HiGy.R KOA_KPF=path/to/koa_prediction_functions.R Rscript parity_increment.R
## The grid (increment_grid_python.csv, 540 points) was generated from koa_equations.LineageA with
## CF_dDBH 1.48254, CF_dHT 1.030 and the origin calibration (0.38479 and 1.58591, 0.52127 and 2.65956), both origins, DBH 2 to 70 cm, BAL 0 to 30, BAPH 5 to 60, CR 0.3 and 0.7,
## BYI 50 to 813, HT = 1.5 + 0.35 DBH.
suppressPackageStartupMessages(library(dplyr))
here <- dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)))
g <- read.csv(file.path(here, "increment_grid_python.csv"))
e2 <- new.env(); sys.source(Sys.getenv("KOA_HIGY", "fvsOL/inst/extdata/HiGy.R"), e2)
p <- e2$ddbh.parm[e2$ddbh.parm$type == "site", ]; q <- e2$dht.parm[e2$dht.parm$type == "site", ]
g$h_dd <- with(g, e2$ddbh(dbh, bal, baph, cr, byi, pl, p$b0, p$b1, p$b2, p$b3, p$b4, p$b5, p$b6, p$b7, p$b8, p$b9))
g$h_dh <- with(g, e2$dht(dbh, ht, bal, baph, cr, byi, pl, q$b0, q$b1, q$b2, q$b3, q$b4, q$b5, q$b6, q$b7, q$b8, q$b9))
out <- data.frame(check = c("HiGy ddbh vs engine", "HiGy dht vs engine"),
                  max_abs_diff = c(max(abs(g$h_dd - g$py_dd)), max(abs(g$h_dh - g$py_dh))))
kpf <- Sys.getenv("KOA_KPF", "")
if (nzchar(kpf)) {
  e1 <- new.env(); sys.source(kpf, e1)
  out <- rbind(out, data.frame(check = c("koa.dDBH.annual vs engine", "koa.dHT.annual vs engine"),
    max_abs_diff = c(max(abs(with(g, e1$koa.dDBH.annual(dbh, bal, cr, baph, pl, byi)) - g$py_dd)),
                     max(abs(with(g, e1$koa.dHT.annual(ht, bal, cr, baph, pl, byi)) - g$py_dh)))))
}
out$pass <- out$max_abs_diff < 1e-8
print(out); write.csv(out, file.path(here, "parity_increment_results.csv"), row.names = FALSE)
if (!all(out$pass)) quit(status = 1)
