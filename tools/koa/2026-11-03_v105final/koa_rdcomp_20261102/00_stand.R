## 00_stand.R: stand TPH, QMD, BAPH, SDI per plot-year from the v105b koa tree table (inputs/AK_TREE_v103.csv, whose stand columns were rebuilt by
## scripts/repair_v103.py from the live all-species list: BAPH = sum KBA DBH^2 EXPF, TPH = sum EXPF, QMD = sqrt(BAPH/TPH/KBA), SDI_sum = sum EXPF (DBH/25.4)^1.605).
## Read only. No coordinate column exists in the input (asserted).
suppressPackageStartupMessages(library(data.table))
W <- path.expand("~/jobs/koa_v105_20261102"); OB <- path.expand("~/jobs/koa_rdcomp_20261102/out")
T <- fread(file.path(W, "inputs/AK_TREE_v103.csv"), colClasses = list(character = c("Install", "Plot")))
stopifnot(!any(tolower(names(T)) %in% c("lat", "lon", "long", "latitude", "longitude", "x", "y")))
S <- T[, .(BAPH = BAPH[1], TPH = TPH[1], QMD = QMD[1], SDI_sum = SDI[1], nuniq_BAPH = uniqueN(BAPH)), by = .(Data, Install, Plot, Measure)]
cat("plot-years", nrow(S), "| plot-years with >1 distinct BAPH:", sum(S$nuniq_BAPH > 1), "\n")
S[, SDI_qmd := fifelse(TPH > 0 & is.finite(QMD), TPH * (QMD / 25.4)^1.605, 0)]
cat("SDI_qmd vs SDI_sum: cor", round(cor(S$SDI_qmd, S$SDI_sum, use = "complete"), 4), "| median ratio qmd/sum", round(median(S$SDI_qmd / S$SDI_sum, na.rm = TRUE), 4), "\n")
cat("TPH 0:", sum(S$TPH == 0, na.rm = TRUE), "| QMD NA:", sum(!is.finite(S$QMD)), "| BAPH NA:", sum(is.na(S$BAPH)), "\n")
fwrite(S, file.path(OB, "stand_plotyear.csv"))
