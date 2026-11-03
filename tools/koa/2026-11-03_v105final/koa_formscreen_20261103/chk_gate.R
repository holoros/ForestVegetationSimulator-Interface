source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/lib_c.R")); M3 <- "none"
dK <- frameK("dDBH", "K3p"); bb <- readRDS(path.expand("~/jobs/koa_formscreen_20261103/out/inc_dDBH_B_pop923.rds"))$b
p_theirs <- pa_pred("dDBH", dK, bb)
e <- new.env(); Sys.setenv(KOA_POP = "923"); sys.source(path.expand("~/jobs/koa_formscreen_20261103/lib_inc.R"), envir = e)
d2 <- e$base_frame("dDBH"); assign("FORM", "K3c1", e); assign("GUARD", 45, e)
p_mine <- e$pa_pred("dDBH", d2, bb)
cat("rows", nrow(dK), nrow(d2), "keys identical", identical(paste(dK$TreeID, dK$t.0), paste(d2$TreeID, d2$t.0)), "max abs pred diff", max(abs(p_theirs - p_mine)), "\n")
cat("max|XK - BALx(rdcomp)|", max(abs(d2$XK.0 - dK$BALx.0)), max(abs(d2$RD.0 - dK$BAPH.0)), "CR", max(abs(d2$CRx.0 - dK$CRx.0)), "\n")
m <- fit_c(dK, bb); cat("rdcomp lib_c refit from my vector: logLik", format(as.numeric(logLik(m)), digits = 10), "\n"); print(nlme::fixef(m), digits = 8)
