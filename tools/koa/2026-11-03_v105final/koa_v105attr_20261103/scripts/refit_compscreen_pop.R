## koa_v105attr_20261103 copy of koa_v105d_20261102/prep/refit_compscreen.R: POP from env SDIMAX_POP, output dir from env OUTDIR (gates vs compscreen are meaningful at POP 923 only).
## refit_compscreen.R (v105d prep, gate "refit parity"): refit H1a (Eq. 2), C2h (Eq. 3), M3a (Stage 3) exactly as koa_compscreen_20261102 05_height.R,
## 04_hcb.R, 02_stage3.R (their lib.R; inputs read only) and compare with out/height_results.csv, hcb_results.csv, stage3_results.csv. Writes the full
## vectors (incl. Stage 3 intercept, height vcov of a0 a1 g1) and the minimum RD of each fitting frame (used as the engine floor of ln RD).
source(path.expand("~/jobs/koa_compscreen_20261102/lib.R")); suppressPackageStartupMessages(library(nlme))
POP <- as.numeric(Sys.getenv("SDIMAX_POP")); stopifnot(is.finite(POP)); cat("POP", sprintf("%.12g", POP), "\n")   # koa_v105attr: divisor from env
P <- Sys.getenv("OUTDIR"); dir.create(P, recursive = TRUE, showWarnings = FALSE); CS <- path.expand("~/jobs/koa_compscreen_20261102/out"); G <- list()
## ---- height H1a
src <- readLines(file.path(W, "track2/height_refit_v103.R")); eval(parse(text = src[1:33]))
V104 <- c(a0 = 28.9288306400629, a1 = 0.966787802291731, b = 0.017026137590269, c = 0.792246824594636, g1 = 0.0768405891389797, g2 = -0.343309808337385)
d <- prep(file.path(W, "frames/final/tree_join_v103.csv")); nocoord(d)
d$SDI <- sdi_of(d$source, d$inst, d$plot, d$year); d$RD <- d$SDI / POP; stopifnot(all(is.finite(d$RD) & d$RD > 0))
d$Fs <- (1 - exp(-V104[["b"]] * d$dbh))^V104[["c"]] * exp(V104[["g2"]] * d$rd_max); d$lrd <- log(d$RD)
CTL <- nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)
fH <- ht ~ (a0 + a1 * byi / 100) * Fs * exp(g1 * lrd)
s <- replace(V104, "g1", 0.05)[c("a0", "a1", "g1")]
r <- tryCatch(coef(nls(fH, data = d, start = as.list(s), control = nls.control(maxiter = 500, warnOnly = TRUE))), error = function(e) NULL); if (!is.null(r)) s <- r
mH <- nlme(fH, data = d, fixed = a0 + a1 + g1 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = s, control = CTL)
hr <- read.csv(file.path(CS, "height_results.csv")); h1 <- hr[hr$cand == "H1a", ]
fh <- fixef(mH); gH <- max(abs(fh - unlist(h1[c("a0", "a1", "g1")])))
G[[1]] <- data.frame(check = "Height H1a refit vs compscreen a0 a1 g1, max abs diff", value = gH, pass = gH < 1e-6)
G[[2]] <- data.frame(check = "Height H1a logLik minus compscreen", value = as.numeric(logLik(mH)) - h1$logLik, pass = abs(as.numeric(logLik(mH)) - h1$logLik) < 1e-6)
HT <- c(a0 = fh[["a0"]], a1 = fh[["a1"]], b = V104[["b"]], c = V104[["c"]], g1 = fh[["g1"]], g2 = V104[["g2"]])
vc <- matrix(0, 6, 6, dimnames = list(names(HT), names(HT))); vc[c("a0", "a1", "g1"), c("a0", "a1", "g1")] <- vcov(mH)[c("a0", "a1", "g1"), c("a0", "a1", "g1")]
write.csv(vc, file.path(P, "height_vcov_H1a.csv"), row.names = FALSE)
write.csv(data.frame(frame = "H1a", parameter = names(HT), estimate = HT, se = sqrt(diag(vc)), fixed = !(names(HT) %in% c("a0", "a1", "g1"))), file.path(P, "height_coefficients_H1a.csv"), row.names = FALSE)
saveRDS(list(fixef = fh, logLik = as.numeric(logLik(mH)), AIC = AIC(mH), n = nrow(d), tau = as.numeric(VarCorr(mH)[, "StdDev"][c(2, 4)])), file.path(P, "fit_H1a.rds"))
rdmin <- c(height = min(d$RD))
## ---- HCB C2h
HCB_P <- c(b0 = 0.1684, b1 = 1.0146, b2 = -0.376, b3 = -0.0078, b4 = -0.3734, b5 = -0.221)
rd_prep <- function(f) { d <- read.csv(f, stringsAsFactors = FALSE, colClasses = c(Install = "character", Plot = "character")); nocoord(d)
  d <- d[is.finite(d$HCB) & is.finite(d$HT) & d$HT > 0 & is.finite(d$BYI), ]; d$plot <- paste(d$Install, d$Plot)
  d$BAL <- d$BALl; d$BAPH <- d$BAPH_hi; d$QMD <- sqrt(d$BAPH_hi / d$TPH_hi / (pi / 40000)); d$SDI <- d$TPH_hi * (d$QMD / 25.4)^1.605; d$RD <- d$SDI / POP
  d$share <- ifelse(d$BAPH > 0, d$BAL / d$BAPH, 0); d }
dh <- rd_prep(file.path(W, "frames/final/AK_HCB_v103.csv"))
FM <- list(C1 = HCB ~ HT / (1 + exp(-(b0 + b1 * sqrt(HT / 100) + b2 * log(pmax(HT / pmax(DBH, 0.1), 0.5)) + b3 * sqrt(pmax(BAL * BAPH + 1, 0)) + b4 * log(BAPH + 1) + b5 * log(pmax(BYI, 1) / 100)))),
           C2h = HCB ~ HT / (1 + exp(-(b0 + b1 * sqrt(HT / 100) + b2 * log(pmax(HT / pmax(DBH, 0.1), 0.5)) + b3 * sqrt(pmax(share * RD + 1, 0)) + b4 * log(RD) + b5 * log(pmax(BYI, 1) / 100)))))
fitn <- function(f, dd, starts) { best <- NULL
  for (s in starts) { m <- tryCatch(nls(f, data = dd, start = as.list(s), control = nls.control(maxiter = 500)), error = function(e) NULL)
    if (!is.null(m) && (is.null(best) || deviance(m) < deviance(best))) best <- m }
  best }
C1 <- fitn(FM$C1, dh, list(HCB_P)); C2 <- fitn(FM$C2h, dh, list(HCB_P, coef(C1), replace(coef(C1), c("b3", "b4"), 0)))
hc <- read.csv(file.path(CS, "hcb_results.csv")); c2 <- hc[hc$cand == "C2h", ]; gC <- max(abs(coef(C2) - unlist(c2[paste0("b", 0:5)])))
G[[3]] <- data.frame(check = "HCB C2h refit vs compscreen b0..b5, max abs diff", value = gC, pass = gC < 1e-6)
write.csv(data.frame(term = names(coef(C2)), estimate = coef(C2), se = summary(C2)$coefficients[, 2]), file.path(P, "hcb_coefficients_C2h.csv"), row.names = FALSE)
rdmin["hcb"] <- min(dh$RD)
## ---- Stage 3 M3a
.src <- parse(path.expand("~/jobs/koa_origin_20260916/s06/deposit/regenerate_table6.R"))
for (.e in .src) if (is.call(.e) && identical(.e[[1]], as.name("<-")) && is.name(.e[[2]]) && as.character(.e[[2]]) %in% c("cll_loglik", "cll_pieces", "fit_cloglog")) eval(.e, globalenv())
cglm <- function(f, data) { X <- model.matrix(f, data); y <- model.response(model.frame(f, data)); pre <- fit_cloglog(X, as.numeric(y), log(data$yip))
  m <- suppressWarnings(glm(f, family = binomial(link = "cloglog"), data = data, offset = log(yip), start = pre$beta, control = glm.control(maxit = 200, epsilon = 1e-8)))
  if (!m$converged) stop("nonconv"); m }
s3 <- fread(file.path(W, "frames/final/surv_recovered_ii_v103.csv"), colClasses = list(character = c("inst", "plot"))); nocoord(s3); s3 <- as.data.frame(s3)
ok <- Reduce(`&`, lapply(c("yip", "ht", "dbh", "cr", "byi", "rht", "alive"), function(k) is.finite(s3[[k]]))); s3 <- s3[ok & s3$yip > 0 & s3$ht > 0 & s3$dbh > 0 & s3$cr > 0 & s3$byi > 0, ]
s3$dead <- 1 - s3$alive; s3$SDI <- sdi_of(s3$source, s3$inst, s3$plot, s3$t0); s3$RD <- s3$SDI / POP; s3$share <- ifelse(s3$baph > 0, s3$bal / s3$baph, 0)
mD <- cglm(dead ~ log(dbh) + rht + log(baph + 1) + log(bal + 1), s3); mA <- cglm(dead ~ log(dbh) + rht + log(RD) + log(share * RD + 1), s3)
S3 <- c(-2.45353544308563, -1.24379127899638, -0.245835518593837, 0.801873721680337, 0.164263748192269)
st <- read.csv(file.path(CS, "stage3_results.csv")); ma <- st[st$cand == "M3a", ]
gS <- max(abs(coef(mA)[2:5] - unlist(ma[c("c_lndbh", "c_rht", "c_density", "c_competition")])))
G[[4]] <- data.frame(check = "Stage 3 deployed refit vs STAGE3_COEF, max abs diff", value = max(abs(coef(mD) - S3)), pass = max(abs(coef(mD) - S3)) < 1e-6)
G[[5]] <- data.frame(check = "Stage 3 M3a refit vs compscreen slopes, max abs diff", value = gS, pass = gS < 1e-6)
G[[6]] <- data.frame(check = "Stage 3 M3a logLik minus compscreen", value = as.numeric(logLik(mA)) - ma$logLik, pass = abs(as.numeric(logLik(mA)) - ma$logLik) < 1e-6)
write.csv(data.frame(term = c("c0", "c1", "c2", "c3", "c4"), estimate = unname(coef(mA)), se = unname(sqrt(diag(vcov(mA))))), file.path(P, "stage3_coefficients_M3a.csv"), row.names = FALSE)
rdmin["stage3"] <- min(s3$RD)
write.csv(data.frame(frame = names(rdmin), rd_min = rdmin), file.path(P, "rd_min_fitframes.csv"), row.names = FALSE)
O <- do.call(rbind, G); print(O, digits = 6); write.csv(O, file.path(P, "gate_refit_parity_compscreen.csv"), row.names = FALSE)
cat("H1a", sprintf("%.10g", HT), "\nC2h", sprintf("%.10g", coef(C2)), "\nM3a", sprintf("%.15g", coef(mA)), "\nRDmin", rdmin, "\n")
cat("REFIT_PARITY_COMPSCREEN", if (all(O$pass)) "PASS" else "FAIL", "\n")
