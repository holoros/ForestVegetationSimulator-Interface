## static_height_frame_v103 + BYI joined from tree_join_v103 by tree key, job definition (prep, nls start from v92 vector, nlme control)
suppressPackageStartupMessages(library(nlme))
J <- "~/jobs/koa_v103_20260930"
tj <- read.csv(file.path(J, "frames/final/tree_join_v103.csv"), stringsAsFactors = FALSE, check.names = FALSE)
sh <- read.csv(file.path(J, "frames/final/static_height_frame_v103.csv"), stringsAsFactors = FALSE, check.names = FALSE)
k_tj <- paste(tj$source, tj$inst, tj$plot, tj$year, tj$tree, sep = "|"); k_sh <- paste(sh$Data, sh$Install, sh$Plot, sh$Measure, sh$Tree, sep = "|")
d <- data.frame(source = sh$Data, inst = sh$Install, plot = sh$Plot, year = sh$Measure, tree = sh$Tree, dbh = sh$DBH, ht = sh$HT, expf = sh$EXPF, status = sh$Status, baph = sh$BAPH, byi = tj$byi[match(k_sh, k_tj)])
lv <- d[is.finite(d$dbh) & d$dbh > 0, ]; lv <- lv[tolower(lv$status) == "live", ]; lv <- lv[is.finite(lv$expf) & lv$expf > 0, ]
lkey <- interaction(lv$source, lv$inst, lv$plot, lv$year, drop = TRUE); lv$rd_max <- lv$dbh / ave(lv$dbh, lkey, FUN = max)
d <- lv[is.finite(lv$ht) & lv$ht > 0 & is.finite(lv$byi) & is.finite(lv$baph), ]
d$grp_src <- factor(d$source); d$grp_inst <- factor(paste(d$source, d$inst, sep = "/"))
cat("n", nrow(d), "inst", nlevels(d$grp_inst), "\n")
form <- ht ~ (a0 + a1 * byi / 100) * (1 - exp(-b * dbh))^c * exp(g1 * log(baph + 1) + g2 * rd_max)
V92 <- c(a0 = 25.37, a1 = 1.042, b = 0.0220, c = 0.814, g1 = 0.0556, g2 = -0.282)
cat("nls skipped, nlme started at the job optimum\n")
f <- nlme(form, data = d, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = c(a0 = 28.928831, a1 = 0.966788, b = 0.017026, c = 0.792247, g1 = 0.076841, g2 = -0.343310),
          control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE))
tt <- summary(f)$tTable; print(round(tt[, 1:2], 6)); cat("logLik", logLik(f), "\n")
pa <- as.numeric(fitted(f, level = 0)); pc <- as.numeric(fitted(f))
r2 <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2)
cat(sprintf("r2_cond %.4f r2_pa %.4f rmse_pa %.4f bias_pa %.4f\n", r2(d$ht, pc), r2(d$ht, pa), sqrt(mean((d$ht - pa)^2)), mean(d$ht - pa)))
write.csv(data.frame(parameter = rownames(tt), estimate = tt[, 1], se = tt[, 2]), "static_jobdef_coefficients_jobstart.csv", row.names = FALSE)
cat("STATIC DONE\n")
