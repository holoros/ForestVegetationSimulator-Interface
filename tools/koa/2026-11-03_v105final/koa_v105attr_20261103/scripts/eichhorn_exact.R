## eichhorn_exact.R: unrounded Eichhorn median and max CV (%) per stratum, exactly the computation of a4/bakuzis/bakuzis_v105_vs_v104.R (lines 30-34),
## from each run's a4/bakuzis/bakuzis_trajectories_v104_v105.csv (version v105 rows). Writes out/eichhorn_exact.csv.
J <- path.expand("~/jobs/koa_v105attr_20261103"); runs <- commandArgs(TRUE); O <- list()
for (r in runs) { f <- if (grepl("@", r)) file.path(path.expand(c("v105d@923" = "~/jobs/koa_v105d_20261102", "v105c@923" = "~/jobs/koa_v105c_20261102")[r]), "a4/bakuzis/bakuzis_trajectories_v104_v105.csv") else file.path(J, r, "a4/bakuzis/bakuzis_trajectories_v104_v105.csv")
  T <- read.csv(f); T$site <- factor(T$site, levels = c("Low", "Medium", "High"))
  for (g in unique(T$group)) { X <- T[T$version == "v105" & T$group == g, ]
    hr <- c(max(tapply(X$HT, X$site, min)), min(tapply(X$HT, X$site, max))); hh <- seq(hr[1], hr[2], length.out = 25)
    vi <- sapply(levels(X$site), function(s) { z <- X[X$site == s, ]; z <- z[order(z$HT), ]; z <- z[!duplicated(z$HT), ]; approx(z$HT, z$VOL, hh)$y })
    cv <- apply(vi, 1, function(q) 100 * sd(q) / mean(q))
    O[[length(O) + 1]] <- data.frame(run = r, group = g, ht_lo = hr[1], ht_hi = hr[2], median_cv = median(cv), max_cv = max(cv), result = ifelse(median(cv) <= 10, "PASS", "FLAG")) } }
O <- do.call(rbind, O); print(O, digits = 6); write.csv(O, file.path(J, "out/eichhorn_exact.csv"), row.names = FALSE)
