# 65_s1_kap_predicted.R  S1 with the 53 Kap plots carrying BYI predicted from their own predictors by the deployed statewide C2 forest
# (koa_kapbyi_20261121/kap_byi.R; median 394, range 206 to 409 Mg/ha) in place of the imputed 64.45, beside S1 of record and S1 without Kap.
# Sensitivity only: E4r and E6r of record are used in the benchmark. No plot or installation identifier is printed.
source("scripts/28_common.R")
K <- fread("~/jobs/koa_kapbyi_20261121/kap_byi_predicted.csv", colClasses = list(character = c("Install", "Plot")))
cat("M columns:", paste(head(names(M), 30), collapse = ","), "\n")
stopifnot("pid" %in% names(M))
kp <- paste("Kap", K$Install, K$Plot, sep = "|"); mk <- M[Data == "Kap", pid]
cat("Kap rows in M:", length(mk), "; matched to predictions:", sum(mk %in% kp), "; example key", mk[1], "\n"); stopifnot(all(mk %in% kp))
M2 <- copy(M); M2[Data == "Kap", lbyi := log(K$BYI_pred[match(pid, kp)])]
b0 <- s1fit(M); b1 <- s1fit(M2); b2 <- s1fit(M[Data != "Kap"])
m1 <- lm(ls ~ lbyi + planted, data = M2, weights = w); print(round(summary(m1)$coefficients, 4))
cat("\nS1 of record:", round(b0, 4), "\nS1 with Kap BYI predicted:", round(b1, 4), "\nS1 without Kap:", round(b2, 4), "\n")
lv <- c(64.45, 178.9, 247.67, 306.7, 386.18, 418.1); pl <- c(121.4, 156.1, 308.5)
cat("SDImax natural at BYI", lv, ":\n  record", round(s1p(b0, log(lv), 0)), "\n  Kap predicted", round(s1p(b1, log(lv), 0)), "\n  without Kap", round(s1p(b2, log(lv), 0)), "\n")
cat("SDImax planted at BYI", pl, ":\n  record", round(s1p(b0, log(pl), 1)), "\n  Kap predicted", round(s1p(b1, log(pl), 1)), "\n")
u <- unique(tr[, .(pid, planted, BYI, Data)]); u[Data == "Kap", BYI := K$BYI_pred[match(pid, kp)]]
cat("natural BYI percentiles (10, 50, 90) with Kap predicted:", round(quantile(u[planted == 0, BYI], c(.1, .5, .9), na.rm = TRUE), 1), " (record:", round(quantile(unique(tr[, .(pid, planted, BYI)])[planted == 0, BYI], c(.1, .5, .9)), 1), ")\n")
bk <- benchrun(function(x) list(sm = s1p(b1, log(x$byi), x$pl), bg = bg, bm = bm)); cat("\nbenchmark, S1 with Kap predicted (E4r and E6r of record):\n"); print(sm1(bk))
bk0 <- benchrun(function(x) list(sm = s1p(b0, log(x$byi), x$pl), bg = bg, bm = bm)); cat("benchmark, S1 of record:\n"); print(sm1(bk0))
saveRDS(list(b0 = b0, b1 = b1, b2 = b2, M2 = M2), "out/s1_kap_predicted_65.rds"); cat("65 done\n")
