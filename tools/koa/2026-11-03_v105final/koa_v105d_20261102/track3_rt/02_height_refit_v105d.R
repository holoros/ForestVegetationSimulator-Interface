## 02_height_refit_v105d.R: Eq. 2 H1a (koa_compscreen_20261102; g1 on ln RD, a0 a1 g1 refitted, b c g2 at v104; random a0 by source/installation) on the
## v105b height frame (8,914 records; track2/height_refit_v103.R prep), with the v105c form (D: a0 a1 refitted, g1 ln(BAPH+1)) on the same rows for comparison.
## Writes track3_s02/v105d/: 02_height_fit.rds (coef, vcov 6x6, sigma), 02_height_coefficients.csv, 02_height_fit_stats.csv, 02_height_equivalence.csv
## (installation-cluster bootstrap, common.R equiv_boot, NBOOT 5000, seed of common.R), 02_height_bias_by_class.csv. RD per plot-year = SDI_qmd/923
## (koa_rdcomp_20261102/out/stand_plotyear.csv), as the compscreen.
Sys.setenv(KOA_OUT = path.expand("~/jobs/koa_v105d_20261102/track3_s02/v105d")); setwd(path.expand("~/jobs/koa_v105d_20261102/track3_rt")); source("common.R")
suppressPackageStartupMessages({ library(nlme); library(data.table) }); J <- path.expand("~/jobs/koa_v105d_20261102")
src <- readLines(file.path(J, "track2/height_refit_v103.R")); eval(parse(text = src[grep("^prep <- function", src):(grep("^fit_ht <- function", src) - 1)]))
V104 <- c(a0 = 28.9288306400629, a1 = 0.966787802291731, b = 0.017026137590269, c = 0.792246824594636, g1 = 0.0768405891389797, g2 = -0.343309808337385)
S <- fread(path.expand("~/jobs/koa_rdcomp_20261102/out/stand_plotyear.csv"), colClasses = list(character = c("Install", "Plot")))
d <- prep(file.path(J, "frames/final/tree_join_v103.csv")); d$RD <- S$SDI_qmd[match(paste(d$source, d$inst, d$plot, d$year), paste(S$Data, S$Install, S$Plot, S$Measure))] / 923
stopifnot(all(is.finite(d$RD) & d$RD > 0), nrow(d) == 8914)
d$Fs <- (1 - exp(-V104[["b"]] * d$dbh))^V104[["c"]] * exp(V104[["g2"]] * d$rd_max); d$lrd <- log(d$RD); d$F <- d$Fs * exp(V104[["g1"]] * log(d$baph + 1))
CTL <- nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)
H1A <- read.csv(file.path(J, "prep/out/height_coefficients_H1a.csv")); H1A <- setNames(H1A$estimate, H1A$parameter)
fH <- ht ~ (a0 + a1 * byi / 100) * Fs * exp(g1 * lrd); s0 <- replace(V104, "g1", 0.05)[c("a0", "a1", "g1")]   # compscreen start path (nls from g1 0.05, then nlme)
r0 <- tryCatch(coef(nls(fH, data = d, start = as.list(s0), control = nls.control(maxiter = 500, warnOnly = TRUE))), error = function(e) NULL); if (!is.null(r0)) s0 <- r0
mA <- nlme(fH, data = d, fixed = a0 + a1 + g1 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = s0, control = CTL)
mD <- nlme(ht ~ (a0 + a1 * byi / 100) * F, data = d, fixed = a0 + a1 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = V104[c("a0", "a1")], control = CTL)
CF6 <- V104; CF6[c("a0", "a1", "g1")] <- fixef(mA)[c("a0", "a1", "g1")]; gH <- max(abs(CF6 - H1A[names(CF6)])); logmsg("H1a max abs diff vs prep/compscreen: ", signif(gH, 3)); stopifnot(gH < 1e-6)
## vcov: b, c, g2 carry the v104 vcov block (as track3_rt/02_height_refit_v105.R did for its fixed shape parameters; used only for the Fig. 3 bands), a0, a1, g1 the H1a nlme vcov
V104VC <- as.matrix(read.csv(file.path(J, "track2/height/height_vcov_v103_PREV_20261102.csv"))); rownames(V104VC) <- colnames(V104VC)
VC6 <- V104VC[names(V104), names(V104)]; fr <- c("a0", "a1", "g1"); VC6[fr, ] <- 0; VC6[, fr] <- 0; VC6[fr, fr] <- vcov(mA)[fr, fr]
saveRDS(list(coef = CF6, vcov = VC6, vcov_note = "b, c, g2 rows: v104 vcov block (figure bands only); engine and joint draws hold them fixed (zero variance, track2/height/height_vcov_v103.csv)", sigma = mA$sigma, re = "intercept by data source and installation (v105d H1a: a0, a1, g1 refitted on ln RD; b, c, g2 fixed at v104)", form = "H1a"), file.path(OUT_DIR, "02_height_fit.rds"))
tt <- summary(mA)$tTable; se6 <- sqrt(diag(VC6))
wcsv(data.frame(parameter = names(CF6), estimate = CF6, se = se6, fixed_at_v104 = !(names(CF6) %in% c("a0", "a1", "g1"))), "02_height_coefficients.csv")
pA <- as.numeric(fitted(mA, level = 0)); pD <- as.numeric(fitted(mD, level = 0)); cA <- as.numeric(fitted(mA)); cD <- as.numeric(fitted(mD))
orig <- if ("planted" %in% names(d)) ifelse(d$planted == 1, "planted", "natural") else rep("all", nrow(d))
sr <- function(lab, p) data.frame(prediction = lab, n = nrow(d), r2 = r2(d$ht, p), rmse = rmse(d$ht, p), mae = mean(abs(d$ht - p)), bias = mean(d$ht - p),
  bias_natural = mean((d$ht - p)[orig != "planted"]), bias_planted = if (any(orig == "planted")) mean((d$ht - p)[orig == "planted"]) else NA)
wcsv(rbind(sr("v105d H1a, conditional", cA), sr("v105d H1a, population-average", pA), sr("v105c form (D), conditional", cD), sr("v105c form (D), population-average", pD),
           data.frame(prediction = "logLik H1a / D", n = nrow(d), r2 = as.numeric(logLik(mA)), rmse = as.numeric(logLik(mD)), mae = NA, bias = NA, bias_natural = NA, bias_planted = NA)), "02_height_fit_stats.csv")
set.seed(SEED); eA <- equiv_boot(d$ht, pA, d$grp_inst); set.seed(SEED); eD <- equiv_boot(d$ht, pD, d$grp_inst)
wcsv(rbind(cbind(vector = "refit, population-average", eA), cbind(vector = "v105c form (D), population-average", eD)), "02_height_equivalence.csv")
hc <- cut(d$dbh, c(0, 10, 20, 40, 60, Inf), right = FALSE)
st <- aggregate(cbind(obs = d$ht, H1a = pA, D = pD), list(dbh_class = hc, origin = orig), mean); st$n <- aggregate(d$ht, list(hc, orig), length)$x; wcsv(st, "02_height_bias_by_class.csv")
logmsg("v105d height done: ", paste(names(CF6), signif(CF6, 6), collapse = " ")); cat("HEIGHT V105D DONE\n")
