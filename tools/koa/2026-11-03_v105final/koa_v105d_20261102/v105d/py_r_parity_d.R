## py_r_parity_d.R: R side of the Python-vs-R engine parity of every v105d component. Writes v105d/out/pyr_<comp>.csv with the inputs and the R prediction.
## dDBH K3c1 and dHT K3c1h: inc_v103.R pa_pred (fitting recursion) on the YIP = 1 rows of the NO frames, deployed vectors (one annual step, no CF/CAL).
## Eq. 2 H1a: compscreen formula on the 8,914 height records (RD = SDI_qmd/923 per plot-year). Eq. 3 C2h: the nls formula on the 360 HCB records.
## Stage 3 M3a: glm(cloglog) prediction with ln(YIP) = 0 on the 4,223 Stage 3 records (refit of prep/refit_compscreen.R).
suppressPackageStartupMessages({ library(nlme); library(data.table) }); VD <- path.expand("~/jobs/koa_v105d_20261102"); O <- file.path(VD, "v105d/out")
src <- readLines(file.path(VD, "track2/inc/inc_v103.R")); commandArgs0 <- commandArgs; commandArgs <- function(trailingOnly = TRUE) "none"; eval(parse(text = src[1:112])); commandArgs <- commandArgs0
J <- jsonlite::fromJSON(file.path(VD, "out/v105_constants.json"))
for (resp in c("dDBH", "dHT")) { GUARD <- if (resp == "dDBH") 45 else 20
  d <- model_cols(read.csv(file.path(VD, sprintf("frames/final/%s_NO_v103_model.csv", resp)), stringsAsFactors = FALSE), "l"); d <- d[d$YIP == 1, ]
  b <- unlist(J[[if (resp == "dDBH") "DDBH" else "DHT"]]$coef)[paste0("b", 0:9)]; d$r_inc <- pa_pred(resp, d, b)
  write.csv(d[, c("DBH.0", "HT.0", "BAPH.0", "BALx.0", "CRx.0", "BYI", "Planted", "TPH.0", "QMD.0", "r_inc")], file.path(O, sprintf("pyr_%s.csv", resp)), row.names = FALSE) }
S <- fread(path.expand("~/jobs/koa_rdcomp_20261102/out/stand_plotyear.csv"), colClasses = list(character = c("Install", "Plot")))
hsrc <- readLines(file.path(VD, "track2/height_refit_v103.R")); eval(parse(text = hsrc[grep("^prep <- function", hsrc):(grep("^fit_ht <- function", hsrc) - 1)]))
h <- prep(file.path(VD, "frames/final/tree_join_v103.csv")); k <- match(paste(h$source, h$inst, h$plot, h$year), paste(S$Data, S$Install, S$Plot, S$Measure))
h$RD <- S$SDI_qmd[k] / 923; h$TPHs <- S$TPH[k]; h$QMDs <- S$QMD[k]; p <- unlist(J$HT_P)
h$r_ht <- (p[["a0"]] + p[["a1"]] * h$byi / 100) * (1 - exp(-p[["b"]] * h$dbh))^p[["c"]] * exp(p[["g1"]] * log(h$RD) + p[["g2"]] * h$rd_max)
h$dbhmax <- h$dbh / h$rd_max; write.csv(h[, c("dbh", "baph", "byi", "rd_max", "dbhmax", "RD", "TPHs", "QMDs", "r_ht")], file.path(O, "pyr_height.csv"), row.names = FALSE)
hc <- read.csv(file.path(VD, "frames/final/AK_HCB_v103.csv"), stringsAsFactors = FALSE); hc <- hc[is.finite(hc$HCB) & is.finite(hc$HT) & hc$HT > 0 & is.finite(hc$BYI), ]
hc$QMD <- sqrt(hc$BAPH_hi / hc$TPH_hi / (pi / 40000)); hc$RD <- hc$TPH_hi * (hc$QMD / 25.4)^1.605 / 923; hc$share <- ifelse(hc$BAPH_hi > 0, hc$BALl / hc$BAPH_hi, 0); q <- unlist(J$HCB_P)
eta <- q[["b0"]] + q[["b1"]] * sqrt(hc$HT / 100) + q[["b2"]] * log(pmax(hc$HT / pmax(hc$DBH, 0.1), 0.5)) + q[["b3"]] * sqrt(pmax(hc$share * hc$RD + 1, 0)) + q[["b4"]] * log(hc$RD) + q[["b5"]] * log(pmax(hc$BYI, 1) / 100)
hc$r_hcb <- hc$HT / (1 + exp(-eta)); write.csv(hc[, c("DBH", "HT", "BALl", "BAPH_hi", "TPH_hi", "BYI", "RD", "r_hcb")], file.path(O, "pyr_hcb.csv"), row.names = FALSE)
s3 <- as.data.frame(fread(path.expand("~/jobs/koa_v105_20261102/frames/final/surv_recovered_ii_v103.csv"), colClasses = list(character = c("inst", "plot"))))
ok <- Reduce(`&`, lapply(c("yip", "ht", "dbh", "cr", "byi", "rht", "alive"), function(k) is.finite(s3[[k]]))); s3 <- s3[ok & s3$yip > 0 & s3$ht > 0 & s3$dbh > 0 & s3$cr > 0 & s3$byi > 0, ]
s3$RD <- S$SDI_qmd[match(paste(s3$source, s3$inst, s3$plot, s3$t0), paste(S$Data, S$Install, S$Plot, S$Measure))] / 923; s3$share <- ifelse(s3$baph > 0, s3$bal / s3$baph, 0); c3 <- unlist(J$STAGE3$coef)
s3$r_w <- 1 - exp(-exp(c3[["c0"]] + c3[["c1"]] * log(s3$dbh) + c3[["c2"]] * s3$rht + c3[["c3_lnRD"]] * log(s3$RD) + c3[["c4_lnshareRD"]] * log(s3$share * s3$RD + 1)))
write.csv(s3[, c("dbh", "rht", "baph", "bal", "RD", "r_w")], file.path(O, "pyr_stage3.csv"), row.names = FALSE); cat("R side done\n")
