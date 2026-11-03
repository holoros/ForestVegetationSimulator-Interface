## gate_s3_923.R: Stage 3 code gate. The s3_fit.R baseline formula and frame with RD = SDI/923 must reproduce the v105d M3a vector (prep/out/stage3_coefficients_M3a.csv).
source(path.expand("~/jobs/koa_formscreen_20261103/lib_cs.R"))
.src <- parse(path.expand("~/jobs/koa_origin_20260916/s06/deposit/regenerate_table6.R"))
for (.e in .src) if (is.call(.e) && identical(.e[[1]], as.name("<-")) && is.name(.e[[2]]) && as.character(.e[[2]]) %in% c("cll_loglik", "cll_pieces", "fit_cloglog")) eval(.e, globalenv())
cglm <- function(f, data) { X <- model.matrix(f, data); y <- model.response(model.frame(f, data)); pre <- fit_cloglog(X, as.numeric(y), log(data$yip))
  suppressWarnings(glm(f, family = binomial(link = "cloglog"), data = data, offset = log(yip), start = pre$beta, control = glm.control(maxit = 200, epsilon = 1e-8))) }
d <- fread(file.path(W, "frames/final/surv_recovered_ii_v103.csv"), colClasses = list(character = c("inst", "plot"))); nocoord(d); d <- as.data.frame(d)
ok <- Reduce(`&`, lapply(c("yip", "ht", "dbh", "cr", "byi", "rht", "alive"), function(k) is.finite(d[[k]]))); d <- d[ok & d$yip > 0 & d$ht > 0 & d$dbh > 0 & d$cr > 0 & d$byi > 0, ]
d$dead <- 1 - d$alive; d$RD <- sdi_of(d$source, d$inst, d$plot, d$t0) / 923; d$share <- ifelse(d$baph > 0, d$bal / d$baph, 0); d$shRD <- d$share * d$RD
m <- cglm(dead ~ log(dbh) + rht + log(RD) + log(shRD + 1), d); ref <- read.csv(path.expand("~/jobs/koa_v105d_20261102/prep/out/stage3_coefficients_M3a.csv"))
g <- max(abs(unname(coef(m)) - ref$estimate)); cat("GATE Stage 3 baseline code at SDImax 923 vs v105d M3a: max abs diff", format(g, digits = 3), if (g < 1e-6) "PASS" else "FAIL", "\n")
writeLines(sprintf("Stage 3 code gate (SDImax 923 vs v105d prep/out/stage3_coefficients_M3a.csv): max abs diff %.3g %s", g, if (g < 1e-6) "PASS" else "FAIL"), file.path(OUT, "gate_stage3_923.txt"))
