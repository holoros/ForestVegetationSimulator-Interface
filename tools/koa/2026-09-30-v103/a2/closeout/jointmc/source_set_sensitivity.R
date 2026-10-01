## source_set_sensitivity.R: multiplier medians and 95 percent intervals by which sources are present, from the CURRENT joint draws
## (a2/mc/out/K_joint_draws.csv, source resampling design). Read only; writes a2/closeout/jointmc/source_set_sensitivity.csv.
W <- path.expand("~/jobs/koa_v103_20260930"); setwd(W)
K <- read.csv("a2/mc/out/K_joint_draws.csv", stringsAsFactors = FALSE)
S <- read.csv("a2/mc/out/K_joint_summary.csv", stringsAsFactors = FALSE); base <- setNames(S$base, S$term)
v <- c("cal_dd_nat", "cal_dd_plt", "cal_dh_nat", "cal_dh_plt", "kmort")
srcs <- c("DOFAW", "FIA", "KMR PSP", "PSP")
pres <- t(sapply(strsplit(K$sources, "|", fixed = TRUE), function(x) srcs %in% x)); colnames(pres) <- srcs
K$present <- apply(pres, 1, function(r) paste(srcs[r], collapse = "+"))
summ <- function(idx, grouping, level) { r <- data.frame(grouping = grouping, level = level, n_draws = length(idx))
  for (x in v) { y <- K[[x]][idx]; r[[paste0(x, "_med")]] <- median(y); r[[paste0(x, "_lo95")]] <- if (length(y) > 1) quantile(y, 0.025, names = FALSE) else y
    r[[paste0(x, "_hi95")]] <- if (length(y) > 1) quantile(y, 0.975, names = FALSE) else y }; r }
out <- list(summ(seq_len(nrow(K)), "all", "all 500 draws"))
b <- data.frame(grouping = "base", level = "engine constants (all sources)", n_draws = NA); for (x in v) { b[[paste0(x, "_med")]] <- base[[x]]; b[[paste0(x, "_lo95")]] <- NA; b[[paste0(x, "_hi95")]] <- NA }
out <- c(list(b), out)
for (s in srcs) { out[[length(out) + 1]] <- summ(which(pres[, s]), "source marginal", paste(s, "present")); out[[length(out) + 1]] <- summ(which(!pres[, s]), "source marginal", paste(s, "absent")) }
out[[length(out) + 1]] <- summ(which(!pres[, "DOFAW"] & !pres[, "FIA"]), "origin support", "natural from PSP only (no DOFAW, no FIA)")
out[[length(out) + 1]] <- summ(which(!pres[, "KMR PSP"] & !pres[, "PSP"]), "origin support", "planted from DOFAW only (no KMR PSP, no PSP)")
for (p in sort(unique(K$present))) out[[length(out) + 1]] <- summ(which(K$present == p), "sources present", p)
for (p in sort(unique(K$sources))) out[[length(out) + 1]] <- summ(which(K$sources == p), "multiset drawn", p)
R <- do.call(rbind, out); num <- sapply(R, is.numeric); R[num] <- lapply(R[num], signif, 5)
write.csv(R, "a2/closeout/jointmc/source_set_sensitivity.csv", row.names = FALSE)
cat("multisets", length(unique(K$sources)), "presence patterns", length(unique(K$present)), "\n")
print(R[R$grouping != "multiset drawn", c("level", "n_draws", "cal_dd_nat_med", "cal_dd_nat_lo95", "cal_dd_nat_hi95", "cal_dh_nat_med", "cal_dh_plt_med", "cal_dd_plt_med", "kmort_med")], row.names = FALSE)
