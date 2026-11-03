## fit_dht_k3c1.R (v105d prep): independent reference fit of the constrained dHT form (K3c1h = K3p dHT with the x^2/ln(HT+5) term dropped, b3 = 0),
## through the koa_rdcomp_20261102 lib (v105b inc_v103.R lines 1-112, in-memory frame, K3p columns). Also refits dHT K3p (parity with out/fit_K3p.rds).
source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R")); GUARD <- 20; P <- path.expand("~/jobs/koa_v105d_20261102/prep/out")
d <- frameK("dHT", "K3p"); cf <- read.csv(file.path(OB, "coefficients.csv")); k3p <- setNames(cf$est[cf$resp == "dHT" & cf$cand == "K3p"], cf$term[cf$resp == "dHT" & cf$cand == "K3p"])
logm("rows", nrow(d))
f9 <- dHT ~ gr.hat3(d1 = HT.0, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, 0, b4, b5, b6, b7, b8, b9)
p9 <- c("b0", "b1", "b2", "b4", "b5", "b6", "b7", "b8", "b9")
fitc <- function(st) tryCatch(nlme(f9, data = d, fixed = b0 + b1 + b2 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = b0 ~ 1 | Data/Install/TreeID, start = st[p9],
                                   weights = varPower(0.2, form = ~DBH.0), control = ctl), error = function(e) { logm("fail", conditionMessage(e)); NULL })
t0 <- Sys.time(); mA <- fitc(k3p); logm("start K3p: logLik", if (!is.null(mA)) logLik(mA) else NA, round(difftime(Sys.time(), t0, units = "mins"), 2), "min")
cfk <- read.csv(path.expand("~/jobs/koa_rdcomp_20261102/constrained/out/coefficients_K3c.csv")); print(head(cfk, 3))
m <- mA; b <- nlme::fixef(m); b10 <- c(b[c("b0", "b1", "b2")], b3 = 0, b[paste0("b", 4:9)])
cc <- solve_cK("dHT", d, b10); logm("K3c1h fixef", paste(names(b10), signif(b10, 7), collapse = " "), "logLik", as.numeric(logLik(m)), "AIC", AIC(m), "c", paste(signif(cc, 6), collapse = " "))
K0 <- readRDS(file.path(OB, "fit_K0.rds")); K3 <- readRDS(file.path(OB, "fit_K3p.rds"))
saveRDS(list(b = b10, logLik = as.numeric(logLik(m)), AIC = AIC(m), cc = cc, se = summary(m)$tTable[, 2], tau = taus(m)), file.path(P, "fit_dHT_K3c1h_ref.rds"))
write.csv(data.frame(term = names(b10), est = b10), file.path(P, "coef_dHT_K3c1h_ref.csv"), row.names = FALSE)
logm("signs b1>0", b10[["b1"]] > 0, "b4<0", b10[["b4"]] < 0, "; mono x: d ln g/dx = b4/(x+1) <= 0 everywhere iff b4 <= 0")
logm("REF DONE")
