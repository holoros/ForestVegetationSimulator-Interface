## g0b: K3p through gr.hat3c from the start the parent screen kept (start b = K0 fitted vector), to check code-path identity independent of start.
source(path.expand("~/jobs/koa_rdcomp_20261102/constrained/lib_c.R")); M3 <- "sq"
d <- frameK("dDBH", "K3p"); K0 <- readRDS(file.path(OB, "fit_K0.rds"))$dDBH; K3p <- readRDS(file.path(OB, "fit_K3p.rds"))$dDBH
m <- fitS("dDBH", d, K0$b); b <- fixef(m)[names(K3p$b)]
cat("K3p via gr.hat3c start b: logLik", logLik(m), "stored", K3p$logLik, "max abs diff", max(abs(b - K3p$b)), "\n")
p0 <- pa_pred("dDBH", d, K3p$b); M3 <- "sq"; cat("pa_pred identity check vs ../lib.R gr.hat3: computed below\n")
