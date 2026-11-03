## registry_s02_v105d.R: registry stage s02 (height) for v105d. Writes a2/registry/s02/v105/ files in the registry layout from the Eq. 2 H1a fit on the
## 8,914-record v105b frame (same fit path as track3_rt/02_height_refit_v105d.R, which reproduces the compscreen H1a to 7e-15):
## 02_height_coefficients.csv (estimate, se, t, p, lo95, hi95; b, c, g2 fixed at v104 with their v104 SE, flagged), 02_height_fit_stats.csv (refit conditional and
## population-average), 02_height_equivalence.csv (track3_s02/v105d), 02_height_loio.csv (leave-one-installation-out, nls per fold with a0, a1, g1 free and the
## shape fixed, as the registry LOIO), 02_height_bias_by_class.csv, 02_height_vcov.csv, 02_height_fit.rds. Base form file stays CARRIED (README).
suppressPackageStartupMessages({ library(nlme); library(data.table); library(parallel) }); J <- path.expand("~/jobs/koa_v105d_20261102"); O <- file.path(J, "a2/registry/s02/v105")
src <- readLines(file.path(J, "track2/height_refit_v103.R")); eval(parse(text = src[grep("^prep <- function", src):(grep("^fit_ht <- function", src) - 1)]))
V104 <- c(a0 = 28.9288306400629, a1 = 0.966787802291731, b = 0.017026137590269, c = 0.792246824594636, g1 = 0.0768405891389797, g2 = -0.343309808337385)
V104SE <- c(a0 = 1.44686668787868, a1 = 0.140508155369922, b = 0.0009851460242017, c = 0.0119698588817608, g1 = 0.0064589335528098, g2 = 0.0168948766473951)
S <- fread(path.expand("~/jobs/koa_rdcomp_20261102/out/stand_plotyear.csv"), colClasses = list(character = c("Install", "Plot")))
d <- prep(file.path(J, "frames/final/tree_join_v103.csv")); d$RD <- S$SDI_qmd[match(paste(d$source, d$inst, d$plot, d$year), paste(S$Data, S$Install, S$Plot, S$Measure))] / 923
d$Fs <- (1 - exp(-V104[["b"]] * d$dbh))^V104[["c"]] * exp(V104[["g2"]] * d$rd_max); d$lrd <- log(d$RD)
fH <- ht ~ (a0 + a1 * byi / 100) * Fs * exp(g1 * lrd); s0 <- replace(V104, "g1", 0.05)[c("a0", "a1", "g1")]
r0 <- tryCatch(coef(nls(fH, data = d, start = as.list(s0), control = nls.control(maxiter = 500, warnOnly = TRUE))), error = function(e) NULL); if (!is.null(r0)) s0 <- r0
m <- nlme(fH, data = d, fixed = a0 + a1 + g1 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = s0, control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE))
H <- read.csv(file.path(J, "prep/out/height_coefficients_H1a.csv")); stopifnot(max(abs(fixef(m) - setNames(H$estimate, H$parameter)[c("a0", "a1", "g1")])) < 1e-6)
tt <- summary(m)$tTable; est <- V104; est[c("a0", "a1", "g1")] <- fixef(m); se <- V104SE; se[c("a0", "a1", "g1")] <- tt[c("a0", "a1", "g1"), 2]
tv <- est / se; pv <- rep(NA_real_, 6); names(pv) <- names(est); pv[c("a0", "a1", "g1")] <- tt[c("a0", "a1", "g1"), 5]
cf <- data.frame(parameter = names(est), estimate = est, se = se, t = tv, p = pv, lo95 = est - 1.96 * se, hi95 = est + 1.96 * se, printed_v92 = c(25.37, 1.042, 0.0220, 0.814, 0.0556, -0.282),
                 engine_of_record = c(19.832, 0.106, 0.044, 0.863, -0.198, 0.479), fixed_at_v104 = !(names(est) %in% c("a0", "a1", "g1")))
write.csv(cf, file.path(O, "02_height_coefficients.csv"), row.names = FALSE)
r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2); rmse <- function(o, p) sqrt(mean((o - p)^2)); orig <- if ("planted" %in% names(d)) ifelse(d$planted == 1, "planted", "natural") else rep("all", nrow(d))
sr <- function(lab, p) data.frame(prediction = lab, n = nrow(d), r2 = r2(d$ht, p), rmse = rmse(d$ht, p), mae = mean(abs(d$ht - p)), bias = mean(d$ht - p),
  bias_natural = mean((d$ht - p)[orig != "planted"]), bias_planted = if (any(orig == "planted")) mean((d$ht - p)[orig == "planted"]) else NA)
write.csv(rbind(sr("refit, conditional", as.numeric(fitted(m))), sr("refit, population-average", as.numeric(fitted(m, level = 0)))), file.path(O, "02_height_fit_stats.csv"), row.names = FALSE)
e <- read.csv(file.path(J, "track3_s02/v105d/02_height_equivalence.csv")); write.csv(e[e$vector == "refit, population-average", ], file.path(O, "02_height_equivalence.csv"), row.names = FALSE)
file.copy(file.path(J, "track3_s02/v105d/02_height_bias_by_class.csv"), file.path(O, "02_height_bias_by_class.csv"), overwrite = TRUE)
VC <- readRDS(file.path(J, "track3_s02/v105d/02_height_fit.rds")); write.csv(as.data.frame(VC$vcov), file.path(O, "02_height_vcov.csv"), row.names = FALSE); saveRDS(VC, file.path(O, "02_height_fit.rds"))
insts <- levels(d$grp_inst); st <- fixef(m)[c("a0", "a1", "g1")]
one <- function(k) { tr <- d$grp_inst != k; f <- tryCatch(nls(fH, data = d[tr, ], start = as.list(st), control = nls.control(maxiter = 200, warnOnly = TRUE)), error = function(e) NULL)
  if (is.null(f)) return(NULL); data.frame(inst = k, obs = d$ht[!tr], pred = predict(f, d[!tr, ])) }
lo <- do.call(rbind, mclapply(insts, one, mc.cores = 2))
write.csv(data.frame(folds = length(insts), folds_fitted = length(unique(lo$inst)), n = nrow(lo), r2 = r2(lo$obs, lo$pred), rmse = rmse(lo$obs, lo$pred), bias = mean(lo$obs - lo$pred)), file.path(O, "02_height_loio.csv"), row.names = FALSE)
cat(paste0("\nv105d (2026-11-03, v105d/registry_s02_v105d.R): 02_height_coefficients, fit_stats, equivalence, loio, bias_by_class, vcov, fit.rds = Eq. 2 H1a (g1 on ln RD).\n",
           "02_height_vector_contrast.csv is the v105b-form file (not regenerated). 02_height_coefficients_base.csv remains CARRIED from v104.\n"), file = file.path(O, "README_v105.txt"), append = TRUE)
print(cf); print(read.csv(file.path(O, "02_height_loio.csv"))); cat("REGISTRY S02 V105D DONE\n")
