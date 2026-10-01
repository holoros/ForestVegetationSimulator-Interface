#!/usr/bin/env Rscript
# build_pairs_m1.R (koa v101). Lines 26 to 81 of ~/jobs/koa_mort3/koa_mortality_3stage_FINAL_2026-09-04.R, the survivor
# cohort plot interval pair table (plot_interval_pairs_DATA.csv, the M1 gated REG_MORT frame), unchanged apart from
# the file arguments. Usage: Rscript build_pairs_m1.R <AK_TREE csv> <AK_PLT csv> <out csv>
args <- commandArgs(trailingOnly = TRUE); IRREG_THRESHOLD <- 0.10
tree <- read.csv(args[1], stringsAsFactors = FALSE)
plt  <- read.csv(args[2],  stringsAsFactors = FALSE)
tree$key <- paste(tree$Data, tree$Install, tree$Plot, sep = "|")
plt$key  <- paste(plt$Data,  plt$Install,  plt$Plot,  sep = "|")
stopifnot(all(tree$SPP == "AK"))            # gate: koa only, N is koa density
# F5 magnitude gate: plausible tree count and plot count
stopifnot(nrow(tree) > 10000, nrow(tree) < 100000, length(unique(tree$key)) > 100)

h40 <- function(d) {                       # EXPF-weighted mean height of the 40 largest DBH per ha
  d <- d[d$Status == "live" & d$DBH > 0 & !is.na(d$HT) & d$HT > 0 & d$EXPF > 0, ]
  if (nrow(d) == 0) return(NA_real_)
  d <- d[order(-d$DBH), ]; ce <- cumsum(d$EXPF); w <- d$EXPF
  ov <- which(ce > 40)
  if (length(ov)) { i <- ov[1]; w[i] <- max(40 - (if (i > 1) ce[i - 1] else 0), 0); if (i < length(w)) w[(i + 1):length(w)] <- 0 }
  if (sum(w) == 0) return(NA_real_)
  sum(d$HT * w) / sum(w)
}
lastlive <- aggregate(Measure ~ key + Tree, data = tree[tree$Status == "live", ], FUN = max)
names(lastlive)[3] <- "lastlive"
rows <- list()
for (k in unique(tree$key)) {
  g <- tree[tree$key == k, ]; ms <- sort(unique(g$Measure)); if (length(ms) < 2) next
  ll <- lastlive[lastlive$key == k, ]
  for (j in seq_len(length(ms) - 1)) {
    m0 <- ms[j]; m1 <- ms[j + 1]
    g0 <- g[g$Measure == m0 & g$Status == "live" & g$DBH > 0 & g$EXPF > 0, ]
    if (nrow(g0) == 0) next
    g1 <- g[g$Measure == m1, ]
    st <- sapply(seq_len(nrow(g0)), function(i) {
      tr <- g0$Tree[i]; r1 <- g1[g1$Tree == tr, ]
      if (nrow(r1) == 0) return("absent")
      r1 <- r1[1, ]
      if (r1$Status == "live") return("live")
      if (r1$Status == "dead") {
        lv <- ll$lastlive[ll$Tree == tr]
        if (length(lv) && lv > m1) return("notfound")      # recorded dead then live again: not a death
        return(if (r1$DBH > 0) "dead_meas" else "dead_sent")
      }
      "other"
    })
    dead <- st %in% c("dead_meas", "dead_sent"); abs_ <- st == "absent"
    rows[[length(rows) + 1]] <- data.frame(
      key = k, Data = g0$Data[1], Install = g0$Install[1], Plot = g0$Plot[1], m0 = m0, m1 = m1, YIP = m1 - m0,
      ntree = sum(!abs_), N0 = sum(g0$EXPF[!abs_]), N1 = sum(g0$EXPF[!abs_ & !dead]),
      ndead = sum(dead), ndead_meas = sum(st == "dead_meas"), n_absent = sum(abs_),
      H40_0 = h40(g[g$Measure == m0, ]), H40_1 = h40(g[g$Measure == m1, ]), stringsAsFactors = FALSE)
  }
}
pairs <- do.call(rbind, rows)
p0 <- plt[, c("key", "Measure", "Origin", "SDI", "QMD", "BAPH")]; names(p0) <- c("key", "m0", "Origin", "SDI0", "QMD0", "BAPH0")
pairs <- merge(pairs, p0, by = c("key", "m0"), all.x = TRUE)
pairs$planted <- as.integer(pairs$Origin == "Planted")
pairs$mort_ann <- 1 - (pairs$N1 / pairs$N0)^(1 / pairs$YIP)
pairs$irreg <- pairs$mort_ann > IRREG_THRESHOLD
pairs$inst <- paste(pairs$Data, pairs$Install, sep = "|")
write.csv(pairs, args[3], row.names = FALSE)
cat(sprintf("pairs %d, plots %d, deaths (reading A, absorbing) %d, irregular intervals %d carrying %d deaths (%.1f%%)\n",
            nrow(pairs), length(unique(pairs$key)), sum(pairs$ndead), sum(pairs$irreg),
            sum(pairs$ndead[pairs$irreg]), 100 * sum(pairs$ndead[pairs$irreg]) / sum(pairs$ndead)))
k <- paste(pairs$key, pairs$m0, pairs$m1); cat("GATE pairs one row per (Data, Install, Plot, m0, m1):", ifelse(any(duplicated(k)), "FAIL", "PASS"), "| offending keys", length(unique(k[duplicated(k)])), "\n")
