## t2_extra.R (deviation): dHT T2 failed from both preregistered starts (singular backsolve). One extra start from T1 with lg = log(1e-3).
source(path.expand("~/jobs/koa_formscreen_20261103/lib_inc.R")); FORM <- "MODRD"; GUARD <- 20; resp <- "dHT"
d <- base_frame(resp); M <- readRDS(file.path(OUT, "inc_dHT_T1.rds"))$b; m <- fitF(resp, d, c(M, lg = log(1e-3)))
if (is.null(m)) { logm("T2 extra start: no converged fit"); writeLines("T2 extra start (T1 vector, lg = log(1e-3)): no converged fit", file.path(OUT, "t2_extra.txt")) } else {
  b <- nlme::fixef(m); logm("T2 extra start logLik", round(as.numeric(logLik(m)), 4), "AIC", round(AIC(m), 3), paste(sprintf("%s %.5g", names(b), b), collapse = " "))
  writeLines(sprintf("T2 extra start (T1 vector, lg = log(1e-3)): logLik %.4f AIC %.3f df %d; %s", as.numeric(logLik(m)), AIC(m), attr(logLik(m), "df"), paste(sprintf("%s %.5g", names(b), b), collapse = " ")), file.path(OUT, "t2_extra.txt")) }
