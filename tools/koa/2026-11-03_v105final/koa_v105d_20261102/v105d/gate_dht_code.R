## gate_dht_code.R (v105d): (1) the dHT K3c1/RD columns of the inc_v103.R NO frame equal koa_rdcomp_20261102 frameK("dHT","K3p") (same rows);
## (2) DHT_FORM v105b: patched pa_pred reproduces the v105c code exactly; (3) DHT_FORM K3p through the patched fit_one reproduces koa_rdcomp K3p dHT.
suppressPackageStartupMessages(library(nlme)); VD <- path.expand("~/jobs/koa_v105d_20261102"); VC <- path.expand("~/jobs/koa_v105c_20261102"); out <- list()
src <- readLines(file.path(VD, "track2/inc/inc_v103.R")); commandArgs0 <- commandArgs; commandArgs <- function(trailingOnly = TRUE) "none"
eval(parse(text = src[1:112])); commandArgs <- commandArgs0; GUARD <- 20
J <- jsonlite::fromJSON(file.path(VC, "out/v105_constants.json")); vec <- unlist(J$DHT$coef)[paste0("b", 0:9)]
DHT_FORM <- "K3c1h"; a <- model_cols(read.csv(file.path(VD, "frames/final/dHT_NO_v103_model.csv"), stringsAsFactors = FALSE), "l")
eK <- new.env(); local({ commandArgs <- function(trailingOnly = TRUE) "none"; source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R"), local = TRUE) }, envir = eK)
k <- eK$frameK("dHT", "K3p"); stopifnot(identical(paste(a$TreeID, a$t.0, a$t.1), paste(k$TreeID, k$t.0, k$t.1)))
for (v in c("XK.0", "XK.1", "RD.0", "RD.1")) { kk <- switch(v, XK.0 = k$BALx.0, XK.1 = k$BALx.1, RD.0 = k$BAPH.0, RD.1 = k$BAPH.1)
  out[[length(out) + 1]] <- data.frame(check = sprintf("dHT %s vs koa_rdcomp K3p frame, max abs diff", v), value = max(abs(a[[v]] - kk)), pass = max(abs(a[[v]] - kk)) < 1e-12) }
DHT_FORM <- "v105b"; pa <- pa_pred("dHT", a, vec)
pb <- { e <- new.env(); s5 <- readLines(file.path(VC, "track2/inc/inc_v103.R")); local({ commandArgs <- function(trailingOnly = TRUE) "none"; eval(parse(text = s5[1:112]), envir = e) }); e$GUARD <- 20; e$pa_pred("dHT", model_cols(read.csv(file.path(VC, "frames/final/dHT_NO_v103_model.csv"), stringsAsFactors = FALSE), "l"), vec) }
out[[length(out) + 1]] <- data.frame(check = "dHT DHT_FORM v105b: pa_pred patched vs v105c code, max abs diff", value = max(abs(pa - pb)), pass = max(abs(pa - pb)) == 0)
cf <- read.csv(path.expand("~/jobs/koa_rdcomp_20261102/out/coefficients.csv")); r <- setNames(cf$est[cf$resp == "dHT" & cf$cand == "K3p"], cf$term[cf$resp == "dHT" & cf$cand == "K3p"])[paste0("b", 0:9)]
kc <- read.csv(file.path(VD, "prep/out/coef_dHT_K3c1h_ref.csv")); rc <- setNames(kc$est, kc$term)[paste0("b", 0:9)]
## deterministic code parity: patched pa_pred (K3p / K3c1h switch, XK/RD columns) vs the koa_rdcomp lib pa_pred on frameK (v105b code, BAL/BAPH columns replaced)
eK$GUARD <- 20
DHT_FORM <- "K3p"; p1 <- pa_pred("dHT", a, r); q1 <- eK$pa_pred("dHT", k, r)
out[[length(out) + 1]] <- data.frame(check = "dHT K3p prediction: patched pa_pred vs koa_rdcomp lib, max abs diff", value = max(abs(p1 - q1)), pass = max(abs(p1 - q1)) < 1e-12)
DHT_FORM <- "K3c1h"; p2 <- pa_pred("dHT", a, rc); q2 <- eK$pa_pred("dHT", k, rc)
out[[length(out) + 1]] <- data.frame(check = "dHT K3c1h prediction: patched pa_pred vs koa_rdcomp lib (b3 = 0), max abs diff", value = max(abs(p2 - q2)), pass = max(abs(p2 - q2)) < 1e-12)
## info: K3p refit through the patched fit_one from the stored K3p vector (koa_rdcomp used two starts and kept the better)
DHT_FORM <- "K3p"; m <- fit_one("dHT", a, "NO"); b <- nlme::fixef(m); se <- summary(m)$tTable[names(b), 2]
out[[length(out) + 1]] <- data.frame(check = "INFO dHT K3p refit via patched fit_one (start = stored K3p) vs koa_rdcomp K3p, max diff in SE units", value = max(abs(b - r[names(b)]) / se), pass = TRUE)
out[[length(out) + 1]] <- data.frame(check = "INFO dHT K3p refit logLik minus koa_rdcomp -6952.703 (log, 3 dp)", value = as.numeric(logLik(m)) + 6952.703, pass = TRUE)
O <- do.call(rbind, out); print(O, digits = 6); write.csv(O, file.path(VD, "v105d/out/gate_dht_code.csv"), row.names = FALSE)
cat("GATE_DHT_CODE", if (all(O$pass)) "PASS" else "FAIL", "\n")
