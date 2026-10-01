## stage1_auc_v103.R: apparent AUC of the v103 Stage 1 cloglog (same frame and screen as stage1_garcia_v103.R), reproduced first on v102
## against the stage1_auc of record (0.66683). Writes stage1_auc_v103.txt.
suppressPackageStartupMessages(library(jsonlite)); setwd("~/jobs/koa_v103_20260930/track2/stage1")
src <- readLines("stage1_garcia_v103.R"); i1 <- grep("^d103 <- p103", src); eval(parse(text = src[1:i1]))
auc <- function(y, s) { r <- rank(s); n1 <- sum(y); n0 <- sum(!y); (sum(r[y]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
a102 <- auc(p102[!p102$removal, ]$any_mort, predict(b102$s1, type = "link")); a103 <- auc(d103$any_mort, predict(fitB(d103)$s1, type = "link"))
cat(sprintf("AUC v102 %.6f (record %.6f) v103 %.6f\n", a102, js$stage1_auc, a103)); cat(a103, file = "stage1_auc_v103.txt")
