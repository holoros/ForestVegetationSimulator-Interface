## s1c_kulani.R (R1 c1b). The DOFAW planted records are all Kulani plot 12, and Kulani also carries natural plot 23, so the one
## within-installation planted vs natural contrast in the data is Kulani 12 vs Kulani 23. Same covariate-adjusted ratio as
## s1b_within.R (reference Eq. 4, natural form, population average), 2,000 tree-cluster bootstrap resamples stratified by origin.
source(file.path(Sys.getenv("HOME"), "jobs/koa_rv_incr_20260928/common.R"))
REF <- load_ref(); set.seed(20260928); KDEP <- list(dDBH = c(natural = 0.40548, planted = 1.43606), dHT = c(natural = 0.51917, planted = 2.64739))
res <- list()
for (resp in c("dDBH", "dHT")) { m0 <- REF[[resp]]; d <- prep(resp); x <- d[d$Data == "DOFAW" & d$Install == "Kulani", ]
  x0 <- x; x0$Planted <- 0; x1 <- x; x1$Planted <- 1
  pn <- predict(m0, newdata = x0, level = 0) / x$YIP * CFX[[resp]]; pp <- predict(m0, newdata = x1, level = 0) / x$YIP * CFX[[resp]]
  kn <- KDEP[[resp]][["natural"]]; kp <- KDEP[[resp]][["planted"]]
  st <- function(j) { o <- x$org[j]; a <- x$ann[j]; Rp <- sum(a[o == "planted"]) / sum(pn[j][o == "planted"]); Rn <- sum(a[o == "natural"]) / sum(pn[j][o == "natural"])
    imp <- sum(pp[j][o == "planted"] * kp) / sum(pn[j][o == "planted"] * kn); c(R_planted = Rp, R_natural = Rn, contrast_obs = Rp / Rn, contrast_implied_deployed = imp, obs_over_implied = Rp / Rn / imp) }
  tr <- split(seq_len(nrow(x)), paste(x$org, x$TreeID)); tp <- names(tr)[startsWith(names(tr), "planted")]; tn <- names(tr)[startsWith(names(tr), "natural")]
  e <- st(seq_len(nrow(x))); bs <- t(replicate(2000, st(unlist(tr[c(sample(tp, replace = TRUE), sample(tn, replace = TRUE))], use.names = FALSE))))
  ci <- apply(bs, 2, quantile, c(0.025, 0.975))
  res[[resp]] <- data.frame(resp = resp, quantity = names(e), estimate = e, lo95_treeboot = ci[1, ], hi95_treeboot = ci[2, ],
    n_planted = sum(x$org == "planted"), n_natural = sum(x$org == "natural"), trees_planted = length(tp), trees_natural = length(tn),
    yip_planted = median(x$YIP[x$org == "planted"]), yip_natural = median(x$YIP[x$org == "natural"]),
    years_planted = paste(range(c(x$t.0, x$t.1)[rep(x$org == "planted", 2)]), collapse = "-"), years_natural = paste(range(c(x$t.0, x$t.1)[rep(x$org == "natural", 2)]), collapse = "-"), row.names = NULL) }
r <- do.call(rbind, res); print(r, digits = 3); write.csv(r, file.path(OUT, "within_kulani_contrast.csv"), row.names = FALSE)
