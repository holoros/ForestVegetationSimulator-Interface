source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R"))
for (resp in c("dDBH","dHT")) { GUARD <- if (resp == "dDBH") 45 else 20; d <- frameK(resp, "K0"); m <- fitS(resp, d, START[[resp]])
 cat(resp, nrow(d), "max abs diff vs deployed", max(abs(fixef(m)[names(DEP[[resp]])] - DEP[[resp]])), "logLik", logLik(m), "\n") }
