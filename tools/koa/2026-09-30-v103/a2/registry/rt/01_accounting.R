## 01_accounting.R: one reconciling table for every sample size the paper quotes (red team minor 1)
## plus the survival-sample median BYI marked on Fig. 4.
source("common.R")
tr <- std(read_dep(F_TREE)); sv <- std(read_dep(F_SURV)); hc <- std(read_dep(F_HCB))
gate(!is.null(tr), "tree file readable")
need(tr, c("source", "inst", "plot", "tree", "dbh", "ht"), "tree file")
cnt <- function(d, lab) {
  if (is.null(d)) return(NULL)
  g <- function(k) if (k %in% names(d)) length(unique(d[[k]])) else NA
  data.frame(sample = lab, rows = nrow(d), trees = if ("tree" %in% names(d)) nrow(unique(d[intersect(c("source","inst","plot","tree"), names(d))])) else NA,
             plots = if ("plot" %in% names(d)) nrow(unique(d[intersect(c("source","inst","plot"), names(d))])) else NA,
             installations = if ("inst" %in% names(d)) nrow(unique(d[intersect(c("source","inst"), names(d))])) else NA,
             sources = g("source"))
}
live <- tr[is.finite(tr$dbh) & tr$dbh > 0 & (!("status" %in% names(tr)) | tolower(tr$status) == "live"), ]   # 2026-09-16: live status filter
hfit <- live[is.finite(live$ht) & live$ht > 0, ]
inc_d <- if ("ddbh" %in% names(tr)) tr[is.finite(tr$ddbh), ] else NULL
inc_h <- if ("dht" %in% names(tr)) tr[is.finite(tr$dht), ] else NULL
parts <- list(list(tr, "tree file, all rows", "18,850"), list(live, "live, DBH > 0", "10,087"),
              list(hfit, "live with height (height fit)", "10,060 (Table 2) / 10,706 (Table S7)"),
              list(inc_d, "diameter increment records", "6,209"), list(inc_h, "height increment records", "5,012"),
              list(hc, "crown subset", "360"), list(std(read_dep("AK_SURV.csv")), "survival table as deposited", "5,969 (6,489 before dedup)"),
              list(sv, "survival table rebuilt (AK_SURV.r)", "5,969"), list(read_dep(F_SURV_RECOVERED), "recovered survival sample, variant ii", "5,293 records / 1,080 events"),
              list(if ("byi" %in% names(live)) live[is.finite(live$byi), ] else NULL, "live, DBH > 0, BYI joined", "height and increment fits"))
tab <- do.call(rbind, lapply(parts, function(x) { r <- cnt(x[[1]], x[[2]]); if (!is.null(r)) r$quoted_in_paper <- x[[3]]; r }))
wcsv(tab, "01_sample_accounting.csv")
by_src <- do.call(rbind, lapply(split(live, live$source), function(d)
  data.frame(source = d$source[1], records = nrow(d), plots = nrow(unique(d[c("inst", "plot")])),
             dbh_mean = mean(d$dbh), ht_mean = mean(d$ht[d$ht > 0], na.rm = TRUE), byi_mean = mean(d$byi, na.rm = TRUE),
             years = paste(range(d$year, na.rm = TRUE), collapse = "-"))))
wcsv(by_src, "01_by_source.csv")
if (!is.null(sv) && "byi" %in% names(sv)) {
  s <- unique(sv)
  wcsv(data.frame(survival_median_byi = stats::median(s$byi, na.rm = TRUE),
                  tree_record_median_byi = stats::median(live$byi, na.rm = TRUE)), "01_byi_medians.csv")
}
logmsg("accounting rows: ", nrow(tab)); cat("done\n")
