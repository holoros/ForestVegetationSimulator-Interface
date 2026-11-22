# 83a_coverage_heldout.R  koa v142, red team A2: coverage of the nominal 90% band at each benchmark plot's longest horizon, rescored with the
# equations refitted without each plot's installation fold (script 28a, out/check28a.rds). The Monte Carlo draws of script 51 are kept and shifted
# by the fold estimate minus the full-data estimate for S1, E4r and E6r, so the band keeps the bootstrap spread and is centred on the held-out fit.
# Everything else (draw count, binomial sampling of survivors, site deviation variant) is as script 51 section (4). No identifier printed.
L51 <- readLines("~/jobs/koa_1150_20261121/scripts/51_j1_items.R"); eval(parse(text = L51[1:(grep("^# ---- \\(2\\) gates", L51) - 1)]))
FK <- readRDS("out/check28a.rds")$FK; names(FK) <- sapply(FK, function(z) as.character(z$k)); fo <- setNames(P$fold, P$pid)
stopifnot(all(sapply(PI, function(x) as.character(fo[[x$p]]) %in% names(FK))))
CVH <- rbindlist(parallel::mclapply(seq_along(PI), function(j) { x <- PI[[j]]; hh <- max(x$obs$h); ob <- x$obs[h == hh]; q0 <- FK[[as.character(fo[[x$p]])]]
  rbindlist(lapply(c(FALSE, TRUE), function(site) { dr <- rbindlist(lapply(seq_len(NDc), function(k) { q <- draw(log(x$byi), x$pl, site)
      q$sm <- if (!site) q$sm * SMO[[x$p]] / s1p(bs, log(x$byi), x$pl) else q$sm * s1p(q0$bs, log(x$byi), x$pl) / s1p(bs, log(x$byi), x$pl)
      gb <- unname(q$bg) + unname(q0$bg) - unname(bg); gm <- unname(q$bm) + unname(q0$bm) - unname(bm); names(gb) <- names(bg); names(gm) <- names(bm)
      z <- simx(x$L$DBH, x$L$HT, x$L$EXPF_c, x$byi, x$pl, hh, q$sm, gb, gm, q$R, FT$sigma, FT$delta, q$ph)[hh + 1, ]; ps <- min(max(z[["TPH"]] / x$N0, 0), 1); sb <- rbinom(1, x$n0, ps) / x$n0
      data.table(surv = sb, qmd = z[["QMD"]], ba = z[["BA"]] * sb / max(ps, 1e-9)) }))
    data.table(planted = x$pl, h = hh, site_dev = site, var = c("surv", "qmd", "ba"), obs = c(ob$o_surv, ob$o_qmd, ob$o_ba), lo = sapply(dr, quantile, .05, na.rm = TRUE), hi = sapply(dr, quantile, .95, na.rm = TRUE)) })) }, mc.cores = NC, mc.set.seed = TRUE))
CVH[, inside := obs >= lo & obs <= hi]; fwrite(CVH, "out/coverage_heldout_83a.csv")
CVI <- fread("out/coverage_j1.csv"); S <- rbind(cbind(equations = "in-sample (script 51)", CVI[, .(plots = .N, coverage = mean(inside), width = mean(hi - lo)), by = .(site_dev, var, planted)]),
  cbind(equations = "held out by installation (28a folds)", CVH[, .(plots = .N, coverage = mean(inside), width = mean(hi - lo)), by = .(site_dev, var, planted)]))
S2 <- rbind(cbind(equations = "in-sample (script 51)", CVI[, .(plots = .N, coverage = mean(inside), width = mean(hi - lo)), by = .(site_dev, var)]),
  cbind(equations = "held out by installation (28a folds)", CVH[, .(plots = .N, coverage = mean(inside), width = mean(hi - lo)), by = .(site_dev, var)]), fill = TRUE)
fwrite(rbind(S, S2, fill = TRUE), "out/coverage_heldout_83a_summary.csv"); print(S2[order(site_dev, var, equations)], digits = 3); print(S[order(site_dev, var, planted, equations)], digits = 3); cat("83a done\n")
