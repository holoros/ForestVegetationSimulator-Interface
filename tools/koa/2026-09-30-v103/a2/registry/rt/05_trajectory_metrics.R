## 05_trajectory_metrics.R: net and gross MAI, PAI, crossover and culmination ages, cap-bound cells,
## Reineke slopes, site ordering and Eichhorn CV from engine trajectories (red team majors 2 and 4).
source("common.R")
metrics <- function(path, label) {
  tj <- std(utils::read.csv(path, stringsAsFactors = FALSE), TCOL)
  need(tj, c("scenario", "site", "age", "qmd", "ht", "baph", "tph", "vol"), paste("trajectory file", label))
  tj <- tj[tj$age > 0, ]; tj$site <- site_std(tj$site)
  gate(all(tj$vol >= 0, na.rm = TRUE) && max(tj$qmd, na.rm = TRUE) < 200, paste(label, "volumes non-negative, QMD below 200 cm (F5, F7)"))
  if (!("rep" %in% names(tj))) tj$rep <- 0
  pt <- if (any(tj$rep == 0)) tj[tj$rep == 0, ] else aggregate(. ~ scenario + site + age, data = tj[setdiff(names(tj), "rep")], FUN = stats::median)
  out <- list(); cross <- list(); bak <- list()
  for (sc in unique(pt$scenario)) for (si in unique(pt$site)) {
    x <- pt[pt$scenario == sc & pt$site == si, ]; x <- x[order(x$age), ]
    if (nrow(x) < 5) next
    gross <- x$vol + if ("mort_vol" %in% names(x)) cumsum(ifelse(is.na(x$mort_vol), 0, x$mort_vol)) else NA
    x$mai_net <- x$vol / x$age
    x$mai_gross <- gross / x$age
    x$pai_gross <- c(NA, diff(gross) / diff(x$age))
    x$pai_net <- c(NA, diff(x$vol) / diff(x$age))
    cap <- if (grepl("plant", sc, ignore.case = TRUE)) CAP_DBH[["planted"]] else CAP_DBH[["natural"]]
    x$cap_bound <- x$qmd >= cap - 0.5
    x$beyond_calibration_age <- x$age > CALIB_AGE_MAX
    x$beyond_observed_qmd <- x$qmd > OBS_MAX_QMD
    out[[paste(sc, si)]] <- x
    ## an initial list carries volume at the first step, so MAI starts high and falls; the biological
    ## crossover is the first downward crossing of MAI by PAI after PAI has risen above MAI
    cr_age <- function(pai, mai) {
      up <- which(!is.na(pai) & pai > mai)[1]; if (is.na(up)) return(NA)
      i <- which(seq_along(pai) > up & !is.na(pai) & pai < mai)[1]; if (is.na(i)) NA else x$age[i]
    }
    cul_age <- function(pai, mai) {
      if (all(is.na(mai))) return(NA)
      up <- which(!is.na(pai) & pai > mai)[1]; if (is.na(up)) up <- 1
      k <- seq(up, length(mai)); x$age[k[which.max(mai[k])]]
    }
    cross[[paste(sc, si)]] <- data.frame(scenario = sc, site = si,
      culmination_net_mai = cul_age(x$pai_net, x$mai_net), culmination_gross_mai = cul_age(x$pai_gross, x$mai_gross),
      crossover_net = cr_age(x$pai_net, x$mai_net), crossover_gross = cr_age(x$pai_gross, x$mai_gross),
      first_cap_age = if (any(x$cap_bound)) min(x$age[x$cap_bound]) else NA)
    ## realized Reineke slope over the self-thinning phase (tph falling, qmd rising)
    st <- x[c(FALSE, diff(x$tph) < 0) & x$age > 10, ]
    slope <- if (nrow(st) >= 5) unname(coef(lm(log(tph) ~ log(qmd), data = st))[2]) else NA
    bak[[paste(sc, si)]] <- data.frame(scenario = sc, site = si, reineke_slope = slope,
                                       in_band = !is.na(slope) && slope <= -1.2 && slope >= -2.2,
                                       eichhorn_vol_per_ht = stats::median(x$vol / x$ht, na.rm = TRUE))
  }
  traj <- do.call(rbind, out); cr <- do.call(rbind, cross); bk <- do.call(rbind, bak)
  ## site ordering of standing volume at each age within scenario
  ord <- do.call(rbind, lapply(split(traj, list(traj$scenario, traj$age), drop = TRUE), function(z) {
    z <- z[order(SITE_BYI[z$site]), ]; data.frame(scenario = z$scenario[1], age = z$age[1], ordered = all(diff(z$vol) >= 0), capped_any = any(z$cap_bound))
  }))
  eich <- do.call(rbind, lapply(split(bk, bk$scenario), function(z) data.frame(scenario = z$scenario[1],
           eichhorn_cv_pct = 100 * stats::sd(z$eichhorn_vol_per_ht) / mean(z$eichhorn_vol_per_ht))))
  ## interval table for the ages of Table 6
  iv <- NULL
  if (length(unique(tj$rep)) > 1) {
    reps <- tj[tj$rep != 0, ]
    iv <- aggregate(cbind(qmd, vol) ~ scenario + site + age, data = reps[reps$age %in% c(20, 40, 60, 100), ],
                    FUN = function(v) stats::quantile(v, c(0.025, 0.975)))
    iv <- do.call(data.frame, iv)
  }
  wcsv(traj, paste0("05_", label, "_trajectories_with_mai_pai.csv"))
  wcsv(cr, paste0("05_", label, "_crossover_culmination.csv"))
  wcsv(bk, paste0("05_", label, "_bakuzis_slopes.csv"))
  wcsv(ord, paste0("05_", label, "_site_ordering.csv"))
  wcsv(eich, paste0("05_", label, "_eichhorn_cv.csv"))
  if (!is.null(iv)) wcsv(iv, paste0("05_", label, "_table6_intervals.csv"))
  tab6 <- traj[traj$age %in% c(20, 40, 60, 100), c("scenario", "site", "age", "qmd", "ht", "baph", "tph", "vol", "mai_net", "mai_gross", "cap_bound")]
  tab6$carbon_Mg_ha <- tab6$vol * WOOD_BASIC_DENSITY / 1000 * CARBON_FRACTION
  wcsv(tab6, paste0("05_", label, "_table6_points.csv"))
  invisible(list(traj = traj, cross = cr, bak = bk))
}
res <- list()
if (nzchar(F_TRAJ_REF) && file.exists(F_TRAJ_REF)) res$ref <- metrics(F_TRAJ_REF, "engine_of_record")
if (nzchar(F_TRAJ) && file.exists(F_TRAJ)) res$new <- metrics(F_TRAJ, "refit")
if (length(res) == 0) logmsg("skip 05: no trajectory file configured")
if (length(res) == 2) {
  a <- res$ref$traj; b <- res$new$traj
  m <- merge(a[, c("scenario", "site", "age", "qmd", "ht", "vol")], b[, c("scenario", "site", "age", "qmd", "ht", "vol")],
             by = c("scenario", "site", "age"), suffixes = c("_record", "_refit"))
  m$vol_change_pct <- 100 * (m$vol_refit / m$vol_record - 1)
  wcsv(m[m$age %in% c(20, 40, 60, 100), ], "05_before_after_refit.csv")
}
cat("done\n")
