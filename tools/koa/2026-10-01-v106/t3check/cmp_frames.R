## t3check/cmp_frames.R: compare job height frame (tree_join_v103 + job prep) with stress frame and static_height_frame_v103
suppressPackageStartupMessages(library(nlme))
J <- "~/jobs/koa_v103_20260930"; T <- file.path(J, "a3/pending/v106/t3check")
cat("nlme", as.character(packageVersion("nlme")), R.version.string, "\n")
tj <- read.csv(file.path(J, "frames/final/tree_join_v103.csv"), stringsAsFactors = FALSE, check.names = FALSE)
ak <- read.csv(file.path(J, "inputs/AK_TREE_v103.csv"), stringsAsFactors = FALSE, check.names = FALSE)
sh <- read.csv(file.path(J, "frames/final/static_height_frame_v103.csv"), stringsAsFactors = FALSE, check.names = FALSE)
st <- read.csv(file.path(J, "a3/pending/v106/stress/s04_height_frame.csv"), stringsAsFactors = FALSE)
cat("rows tj", nrow(tj), "ak", nrow(ak), "sh", nrow(sh), "stress", nrow(st), "\n")
k_tj <- paste(tj$source, tj$inst, tj$plot, tj$year, tj$tree, sep = "|")
k_ak <- paste(ak$Data, ak$Install, ak$Plot, ak$Measure, ak$Tree, sep = "|")
k_sh <- paste(sh$Data, sh$Install, sh$Plot, sh$Measure, sh$Tree, sep = "|")
cat("positional key match tj vs ak:", if (nrow(tj) == nrow(ak)) mean(k_tj == k_ak) else NA, "\n")
cat("dup keys tj", sum(duplicated(k_tj)), "ak", sum(duplicated(k_ak)), "sh", sum(duplicated(k_sh)), "\n")
cat("sh rows vs ak rows identical (common cols)? \n")
cc <- intersect(names(sh), names(ak)); cat(" common cols", length(cc), "; ak-only:", setdiff(names(ak), names(sh)), "; sh-only:", setdiff(names(sh), names(ak)), "\n")
if (nrow(sh) == nrow(ak)) for (v in cc) { a <- sh[[v]]; b <- ak[[v]]; ne <- sum(!((is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b))); if (ne) cat("  col", v, "differs in", ne, "rows\n") }
## job prep
prep <- function(tr) {
  lv <- tr[is.finite(tr$dbh) & tr$dbh > 0, ]; lv <- lv[tolower(lv$status) == "live", ]; lv <- lv[is.finite(lv$expf) & lv$expf > 0, ]
  lkey <- interaction(lv$source, lv$inst, lv$plot, lv$year, drop = TRUE); lv$rd_max <- lv$dbh / ave(lv$dbh, lkey, FUN = max)
  d <- lv[is.finite(lv$ht) & lv$ht > 0 & is.finite(lv$byi) & is.finite(lv$baph), ]
  d$grp_src <- factor(d$source); d$grp_inst <- factor(paste(d$source, d$inst, sep = "/")); d
}
dj <- prep(tj); dj$key <- paste(dj$source, dj$inst, dj$plot, dj$year, dj$tree, sep = "|")
st$key <- paste(st$Data, st$Install, st$Plot, st$Measure, st$Tree, sep = "|")
cat("job n", nrow(dj), "inst", nlevels(dj$grp_inst), "; stress n", nrow(st), "inst", length(unique(paste(st$Data, st$Install))), "\n")
cat("keys job not in stress", sum(!dj$key %in% st$key), "; stress not in job", sum(!st$key %in% dj$key), "\n")
m <- merge(dj, st, by = "key")
cmp <- function(a, b, lab) { dd <- abs(a - b); cat(sprintf("  %-5s rows differing (>1e-9): %5d  max abs diff %.6g\n", lab, sum(dd > 1e-9, na.rm = TRUE), max(dd, na.rm = TRUE))) }
cmp(m$dbh, m$DBH, "dbh"); cmp(m$ht, m$HT, "ht"); cmp(m$baph, m$BAPH, "baph"); cmp(m$rd_max, m$rDBH, "rDBH"); cmp(m$byi, m$byi.y, "byi")
cat("source of stress rDBH: AK_TREE DBH.max; job rDBH: max over live expf>0 stems in tree_join plot-year\n")
## Frame-level diffs: show some differing rDBH rows (no coordinates exist in these files)
dr <- m[abs(m$rd_max - m$rDBH) > 1e-9, c("key", "dbh", "rd_max", "rDBH", "baph", "BAPH")]; print(head(dr, 8))
db <- m[abs(m$baph - m$BAPH) > 1e-9, c("key", "baph", "BAPH")]; print(head(db, 8))
## population-average statistics of printed Table 3 vector on both frames
P <- c(a0 = 28.929, a1 = 0.9668, b = 0.01703, c = 0.7922, g1 = 0.07684, g2 = -0.3433)
h <- function(p, dbh, byi, baph, rd) (p[["a0"]] + p[["a1"]] * byi / 100) * (1 - exp(-p[["b"]] * dbh))^p[["c"]] * exp(p[["g1"]] * log(baph + 1) + p[["g2"]] * rd)
pj <- h(P, dj$dbh, dj$byi, dj$baph, dj$rd_max); ps <- h(P, st$DBH, st$byi, st$BAPH, st$rDBH)
cat(sprintf("printed vector PA on job frame: R2 %.4f RMSE %.4f bias(obs-pred) %.4f\n", 1 - sum((dj$ht - pj)^2) / sum((dj$ht - mean(dj$ht))^2), sqrt(mean((dj$ht - pj)^2)), mean(dj$ht - pj)))
cat(sprintf("printed vector PA on stress frame: R2 %.4f RMSE %.4f bias(obs-pred) %.4f\n", 1 - sum((st$HT - ps)^2) / sum((st$HT - mean(st$HT))^2), sqrt(mean((st$HT - ps)^2)), mean(st$HT - ps)))
## start-value experiment: 2 frames x 2 starts
V92 <- c(a0 = 25.37, a1 = 1.042, b = 0.0220, c = 0.814, g1 = 0.0556, g2 = -0.282)
T3 <- c(a0 = 28.93, a1 = 0.967, b = 0.0170, c = 0.792, g1 = 0.0768, g2 = -0.343)
sf <- data.frame(ht = st$HT, dbh = st$DBH, baph = st$BAPH, rd_max = st$rDBH, byi = st$byi, grp_src = factor(st$Data), grp_inst = factor(paste(st$Data, st$Install, sep = "/")))
form <- ht ~ (a0 + a1 * byi / 100) * (1 - exp(-b * dbh))^c * exp(g1 * log(baph + 1) + g2 * rd_max)
runfit <- function(d, s0, lab) {
  f1 <- tryCatch(nls(form, data = d, start = as.list(s0), control = nls.control(maxiter = 500, warnOnly = TRUE)), error = function(e) NULL)
  s2 <- if (!is.null(f1)) coef(f1) else s0
  w <- character()
  f <- withCallingHandlers(nlme(form, data = d, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = s2,
         control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)),
         warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
  cat(lab, "\n  nls :", sprintf("%.5f", s2), " RSS", if (!is.null(f1)) sprintf("%.2f", deviance(f1)) else NA, "\n  nlme:", sprintf("%.5f", fixef(f)), " logLik", sprintf("%.3f", logLik(f)), " iter", f$numIter, " warn:", paste(unique(w), collapse = ";"), "\n")
  data.frame(run = lab, t(fixef(f)), logLik = as.numeric(logLik(f)), nls_rss = if (!is.null(f1)) deviance(f1) else NA)
}
R <- rbind(runfit(dj, V92, "job frame, job start (v92 vector)"), runfit(dj, T3, "job frame, stress start (Table 3 vector)"),
           runfit(sf, V92, "stress frame, job start (v92 vector)"), runfit(sf, T3, "stress frame, stress start (Table 3 vector)"))
## static_height_frame_v103 + byi/planted from tree_join by key, job definition
shj <- sh; names(shj)[match(c("Data", "Install", "Plot", "Measure", "Tree", "DBH", "HT", "EXPF", "Status", "BAPH"), names(shj))] <- c("source", "inst", "plot", "year", "tree", "dbh", "ht", "expf", "status", "baph")
shj$byi <- tj$byi[match(k_sh, k_tj)]
cat("static frame rows with byi joined", sum(is.finite(shj$byi)), "of", nrow(shj), "\n")
ds <- prep(shj); ds$key <- paste(ds$source, ds$inst, ds$plot, ds$year, ds$tree, sep = "|")
cat("static-frame job-def n", nrow(ds), "inst", nlevels(ds$grp_inst), "; keys identical to job frame:", setequal(ds$key, dj$key), "\n")
m2 <- merge(dj, ds, by = "key"); cmp(m2$dbh.x, m2$dbh.y, "dbh"); cmp(m2$ht.x, m2$ht.y, "ht"); cmp(m2$baph.x, m2$baph.y, "baph"); cmp(m2$rd_max.x, m2$rd_max.y, "rDBH")
R <- rbind(R, runfit(ds, V92, "static_height_frame_v103 + tree_join byi, job definition and start"))
write.csv(R, file.path(T, "cmp_fits.csv"), row.names = FALSE); cat("CMP DONE\n")
