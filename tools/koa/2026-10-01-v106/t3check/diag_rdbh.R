## t3check/diag_rdbh.R: where the deposited DBH.max differs from the job rDBH denominator; local optimum checks
suppressPackageStartupMessages(library(nlme))
J <- "~/jobs/koa_v103_20260930"; T <- file.path(J, "a3/pending/v106/t3check")
tj <- read.csv(file.path(J, "frames/final/tree_join_v103.csv"), stringsAsFactors = FALSE, check.names = FALSE)
ak <- read.csv(file.path(J, "inputs/AK_TREE_v103.csv"), stringsAsFactors = FALSE, check.names = FALSE)
sh <- read.csv(file.path(J, "frames/final/static_height_frame_v103.csv"), stringsAsFactors = FALSE, check.names = FALSE)
st <- read.csv(file.path(J, "a3/pending/v106/stress/s04_height_frame.csv"), stringsAsFactors = FALSE)
k_tj <- paste(tj$source, tj$inst, tj$plot, tj$year, tj$tree, sep = "|")
st$key <- paste(st$Data, st$Install, st$Plot, st$Measure, st$Tree, sep = "|")
cat("byi stress vs tree_join max abs diff:", max(abs(st$byi - tj$byi[match(st$key, k_tj)])), "\n")
cat("tree_join vs AK_TREE: dbh equal", all.equal(tj$dbh, ak$DBH), "; status equal", mean(tolower(tj$status) == tolower(ak$Status)), "; expf equal", isTRUE(all.equal(tj$expf, ak$EXPF)), "; baph equal", isTRUE(all.equal(tj$baph, ak$BAPH)), "\n")
pk <- paste(tj$source, tj$inst, tj$plot, tj$year, sep = "|")
liv <- is.finite(tj$dbh) & tj$dbh > 0 & tolower(tj$status) == "live" & is.finite(tj$expf) & tj$expf > 0
mx_job <- tapply(tj$dbh[liv], pk[liv], max)
mx_all <- tapply(tj$dbh[is.finite(tj$dbh)], pk[is.finite(tj$dbh)], max)
mx_live_anyexpf <- tapply(tj$dbh[liv | (tolower(tj$status) == "live" & is.finite(tj$dbh))], pk[liv | (tolower(tj$status) == "live" & is.finite(tj$dbh))], max)
dm <- tapply(ak$DBH.max, pk, function(x) unique(x)[1])
pp <- names(mx_job); cmpv <- data.frame(pk = pp, job = as.numeric(mx_job[pp]), dep = as.numeric(dm[pp]), all = as.numeric(mx_all[pp]), live_anyexpf = as.numeric(mx_live_anyexpf[pp]))
bad <- cmpv[abs(cmpv$job - cmpv$dep) > 1e-9, ]
cat("plot-years with live stems:", nrow(cmpv), "; DBH.max differs from job max:", nrow(bad), "\n")
cat("  of those, DBH.max equals max over ALL stems (any status):", sum(abs(bad$dep - bad$all) < 1e-9), "; equals max over live stems ignoring expf:", sum(abs(bad$dep - bad$live_anyexpf) < 1e-9), "; DBH.max < job max:", sum(bad$dep < bad$job), "\n")
## which stems carry the deposited DBH.max in the differing plot-years
for (p in head(bad$pk, 12)) { i <- which(pk == p & abs(tj$dbh - bad$dep[bad$pk == p]) < 1e-9)
  cat("  ", p, " job max", bad$job[bad$pk == p], " DBH.max", bad$dep[bad$pk == p], " carrier status/expf/ht:", paste(tj$status[i], tj$expf[i], tj$ht[i], sep = "/"), "\n") }
st_status <- table(sapply(bad$pk, function(p) { i <- which(pk == p & abs(tj$dbh - bad$dep[bad$pk == p]) < 1e-9); if (length(i)) paste(unique(paste(tolower(tj$status[i]), ifelse(is.finite(tj$expf[i]) & tj$expf[i] > 0, "expf>0", "expf<=0/NA"))), collapse = "+") else "no stem carries DBH.max" }))
print(st_status)
cat("height-frame records affected:", sum(st$key %in% k_tj[pk %in% bad$pk & liv]), "rows in", length(unique(sub("\\|[^|]*$", "", st$key[abs(st$rDBH - tj$dbh[match(st$key, k_tj)] / mx_job[pk[match(st$key, k_tj)]]) > 1e-9]))), "plot-years\n")
## static frame: is its rDBH column the DBH.max definition, and why 10 rows differ when job prep is applied to it
cat("static frame rDBH == DBH/DBH.max:", max(abs(sh$rDBH - sh$DBH / sh$DBH.max), na.rm = TRUE), "\n")
form <- ht ~ (a0 + a1 * byi / 100) * (1 - exp(-b * dbh))^c * exp(g1 * log(baph + 1) + g2 * rd_max)
ctl <- nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = TRUE)
JOB <- c(a0 = 28.928831, a1 = 0.966788, b = 0.017026, c = 0.792247, g1 = 0.076841, g2 = -0.343310)
sf <- data.frame(ht = st$HT, dbh = st$DBH, baph = st$BAPH, rd_max = st$rDBH, byi = st$byi, grp_src = factor(st$Data), grp_inst = factor(paste(st$Data, st$Install, sep = "/")))
f1 <- nlme(form, data = sf, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = JOB, control = ctl)
cat("stress frame, nlme started at the job optimum:", sprintf("%.5f", fixef(f1)), " logLik", sprintf("%.3f", logLik(f1)), "\n")
## deposited static frame with its own rDBH column (DBH/DBH.max) and BYI from tree_join
k_sh <- paste(sh$Data, sh$Install, sh$Plot, sh$Measure, sh$Tree, sep = "|")
ds <- data.frame(ht = sh$HT, dbh = sh$DBH, baph = sh$BAPH, rd_max = sh$rDBH, byi = tj$byi[match(k_sh, k_tj)], status = sh$Status, expf = sh$EXPF, src = sh$Data, inst = sh$Install)
ds <- ds[is.finite(ds$dbh) & ds$dbh > 0 & tolower(ds$status) == "live" & is.finite(ds$expf) & ds$expf > 0 & is.finite(ds$ht) & ds$ht > 0 & is.finite(ds$byi) & is.finite(ds$baph), ]
ds$grp_src <- factor(ds$src); ds$grp_inst <- factor(paste(ds$src, ds$inst, sep = "/"))
cat("static frame (own rDBH) n", nrow(ds), "\n")
f2 <- nlme(form, data = ds, fixed = a0 + a1 + b + c + g1 + g2 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = JOB, control = ctl)
cat("static frame with deposited rDBH:", sprintf("%.5f", fixef(f2)), " logLik", sprintf("%.3f", logLik(f2)), "\n")
cat("DIAG DONE\n")
