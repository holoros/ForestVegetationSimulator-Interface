# 80_byi_oob.R  koa v142 BYI integrity check (red team A1). Server side only on firebreather; no coordinate is printed or written.
# Question 1: the deployed BYI (C2 index, ranger forests in koa_byi2_20261101/v2/01_index.R) is predicted with the full forest at every plot.
#   FIA plots that are also forest training plots therefore carry in-bag predictions. Recompute their BYI out of bag
#   (trees in which no visit of that plot was in the bootstrap sample).
# Question 2: the Eq. 1 frame (AGB.FIA.csv) holds 474 exact duplicate rows. Rebuild C2 and both forests without them.
# Output: out/byi_oob_80.csv (one row per plot in the koa 1.15.0 frames; plot keys and BYI only), out/byi_oob_80_summary.csv.
args <- commandArgs(TRUE); OUT <- path.expand("~/jobs/koa_1150_20261121/out"); TMP <- path.expand("~/jobs/koa_1150_20261121/work80")
dir.create(TMP, showWarnings = FALSE)
L <- readLines("~/jobs/koa_byi2_20261101/v2/01_index.R"); iq <- grep("quit(status = 1)", L, fixed = TRUE); L[iq] <- "if (!G2) logm(\"G2 below 0.975: expected once duplicates are removed, since the archived index carried them; continuing\")"
suppressMessages({library(data.table); library(ranger)})
frames <- readRDS("~/jobs/koa_1150_20261121/frames/frames.rds")
U <- unique(as.data.table(frames$tr)[, .(Data, Install, Plot, planted, BYI_frames = BYI)])
U[Data == "FIA", key := vapply(strsplit(Install, "-"), function(s) paste(as.integer(s[3]), as.integer(s[4]), sep = "/"), "")]
kap <- fread("~/jobs/koa_kapbyi_20261121/kap_byi_predicted.csv", colClasses = list(character = c("Install", "Plot")))
res <- list(); summ <- list()
for (mode in c("orig", "dedup")) {
  env <- new.env()
  eval(parse(text = L[1:6]), envir = env); env$O <- file.path(TMP, mode); dir.create(env$O, showWarnings = FALSE)
  eval(parse(text = L[7]), envir = env)
  nd <- sum(duplicated(env$a)); if (mode == "dedup") env$a <- env$a[!duplicated(env$a), ]
  eval(parse(text = L[8:79]), envir = env)       # index fits, forests helpers, g and fp
  with(env, {
    Dk <- mkD(fr$k, kv, "C2"); Dw <- mkD(fr$w, wv, "C2")
    fk <- ranger(y ~ ., data = Dk, num.trees = 500, mtry = 3, min.node.size = 5, seed = 42, num.threads = NT, keep.inbag = TRUE)
    fw <- ranger(y ~ ., data = Dw, num.trees = 500, mtry = 3, min.node.size = 5, seed = 42, num.threads = NT, keep.inbag = TRUE)
  })
  fk <- env$fk; fw <- env$fw; Dk <- env$Dk; Dw <- env$Dw; kv <- env$kv; wv <- env$wv; g <- env$g
  kk <- paste(env$fr$k$COUNTYCD, env$fr$k$PLOT, sep = "/"); kw <- paste(env$fr$w$COUNTYCD, env$fr$w$PLOT, sep = "/")
  oobp <- function(f, D, keys, key) { R <- which(keys == key); if (!length(R)) return(c(NA, NA, 0))
    pa <- predict(f, D[R[1], -1, drop = FALSE], predict.all = TRUE)$predictions[1, ]
    ib <- sapply(f$inbag.counts, function(v) sum(v[R])); c(mean(pa), if (any(ib == 0)) mean(pa[ib == 0]) else NA, sum(ib == 0)) }
  # non-training plots: full-forest prediction from PLT.GEO.V2 covariates (Kona rule first, statewide otherwise), as 01_index.R lines 89 to 91
  nk <- g[, kv]; okk <- complete.cases(nk) & as.character(nk$PTYPE) %in% levels(Dk$PTYPE); nk$PTYPE <- factor(nk$PTYPE, levels = levels(Dk$PTYPE))
  nw <- g[, wv]; okw <- complete.cases(nw)
  pg <- rep(NA_real_, nrow(g)); if (any(okk)) pg[okk] <- predict(fk, nk[okk, ])$predictions; if (any(okw & !okk)) pg[okw & !okk] <- predict(fw, nw[okw & !okk, ])$predictions
  G <- data.table(Data = g$Data, Install = as.character(g$Install), Plot = as.character(g$Plot), pg = pg, forest = ifelse(okk, "Kona", ifelse(okw, "statewide", NA)))
  X <- copy(U)
  for (i in seq_len(nrow(X))) {
    if (X$Data[i] == "FIA") {
      inK <- X$key[i] %in% kk; f <- if (inK) fk else fw; D <- if (inK) Dk else Dw; ks <- if (inK) kk else kw
      o <- oobp(f, D, ks, X$key[i])
      if (o[3] == 0 && is.na(o[1])) { # not a training plot: use PLT.GEO.V2 row
        j <- which(G$Data == "FIA" & G$Install == X$Install[i]); if (!length(j)) j <- which(G$Data == "FIA" & sub("^.*-", "", G$Install) == sub("^.*-", "", X$Install[i]))
        set(X, i, c("full", "oob", "n_oob_trees", "member", "forest"), list(if (length(j)) G$pg[j[1]] else NA_real_, NA_real_, NA_real_, FALSE, if (length(j)) G$forest[j[1]] else NA_character_))
      } else set(X, i, c("full", "oob", "n_oob_trees", "member", "forest"), list(o[1], o[2], o[3], TRUE, if (inK) "Kona" else "statewide"))
    } else if (X$Data[i] == "Kap") {
      j <- which(kap$Install == X$Install[i] & kap$Plot == X$Plot[i])
      p <- if (length(j)) predict(fw, as.data.frame(kap[j[1], ..wv]))$predictions else NA_real_
      set(X, i, c("full", "oob", "n_oob_trees", "member", "forest"), list(p, NA_real_, NA_real_, FALSE, "statewide"))
    } else {
      j <- which(G$Data == X$Data[i] & G$Install == X$Install[i] & G$Plot == X$Plot[i]); if (!length(j)) { jj <- which(G$Data == X$Data[i] & G$Plot == X$Plot[i]); if (length(jj) == 1) j <- jj }  # Kahikinui ids differ between files; plot number is unique
      set(X, i, c("full", "oob", "n_oob_trees", "member", "forest"), list(if (length(j)) G$pg[j[1]] else NA_real_, NA_real_, NA_real_, FALSE, if (length(j)) G$forest[j[1]] else NA_character_))
    }
  }
  X[, use := ifelse(member & !is.na(oob), oob, full)]
  setnames(X, c("full", "oob", "n_oob_trees", "member", "forest", "use"), paste0(c("full", "oob", "n_oob_trees", "member", "forest", "use"), "_", mode))
  res[[mode]] <- X
  sm <- fread(file.path(env$O, "eq1_index_summary.csv")); g2 <- fread(file.path(env$O, "gate_G2.csv"))
  summ[[mode]] <- data.table(mode = mode, eq1_rows = nrow(env$a), dup_rows_in_input = nd, plots = sm$plots, k = sm$k, p = sm$p, gamma = sm$gamma, C2_slope = sm$C2_slope,
    G2_r = g2$pearson_r, oobR2_kona = fk$r.squared, oobR2_statewide = fw$r.squared, med_C2 = sm$med_C2)
  cat(mode, ": rows", nrow(env$a), "OOB R2 Kona", round(fk$r.squared, 3), "statewide", round(fw$r.squared, 3), "\n"); flush.console()
}
Z <- merge(res$orig, res$dedup[, c("Data", "Install", "Plot", grep("_dedup$", names(res$dedup), value = TRUE)), with = FALSE], by = c("Data", "Install", "Plot"))
Z[, BYI_v142 := use_dedup]
fwrite(Z[, !"key"], file.path(OUT, "byi_oob_80.csv")); S <- rbindlist(summ, fill = TRUE); fwrite(S, file.path(OUT, "byi_oob_80_summary.csv")); print(S)
cat("\nreproduction of frames BYI (orig full forest): by source, n, max |diff|, r\n")
print(Z[, .(n = .N, n_na = sum(is.na(full_orig)), maxdiff = max(abs(full_orig - BYI_frames), na.rm = TRUE), r = cor(full_orig, BYI_frames, use = "complete.obs")), by = Data])
cat("\nFIA subplots that are forest training plots:", Z[Data == "FIA", sum(member_orig)], "of", Z[Data == "FIA", .N], "; plots", Z[Data == "FIA" & member_orig, uniqueN(key)], "\n")
q <- function(x) round(quantile(x, c(.1, .5, .9), na.rm = TRUE), 1)
cat("FIA members: in-bag BYI", q(Z[Data == "FIA" & member_orig, full_orig]), "| OOB", q(Z[Data == "FIA" & member_orig, oob_orig]), "| ratio OOB/in-bag", round(q(Z[Data == "FIA" & member_orig, oob_orig / full_orig]), 2), "| OOB trees", q(Z[Data == "FIA" & member_orig, n_oob_trees_orig]), "\n")
cat("v142 BYI vs frames BYI, all plots: r", round(Z[, cor(BYI_v142, BYI_frames, use = "complete.obs")], 4), "| median ratio by source:\n"); print(Z[, .(n = .N, med_ratio = round(median(BYI_v142 / BYI_frames, na.rm = TRUE), 3), p10 = round(quantile(BYI_v142 / BYI_frames, .1, na.rm = TRUE), 3), p90 = round(quantile(BYI_v142 / BYI_frames, .9, na.rm = TRUE), 3)), by = Data])
cat("done 80\n")
