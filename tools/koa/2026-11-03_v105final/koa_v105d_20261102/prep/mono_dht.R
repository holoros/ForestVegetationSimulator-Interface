## mono_dht.R (v105d prep): monotonicity of dHT K3p (koa_rdcomp_20261102 out/fit_K3p.rds dHT vector) in competition over the observed range of the dHT frame.
## x = share x RD; d ln g/dx = 2 b3 x / ln(HT+5) + b4/(x+1) (analytic, form of gr.hat2g) must be <= 0 for x in [0, max observed x], HT at observed p1/p25/p50/p75/p99.
## Also RD at fixed share: d ln g/dRD = b6 sqrt(HT)/(2 sqrt(RD)) + share (2 b3 x/ln(HT+5) + b4/(x+1)), reported (K0 has b6 > 0 on BAPH as well).
source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R"))
d <- frameK("dHT", "K3p"); cf <- read.csv(file.path(OB, "coefficients.csv")); b <- setNames(cf$est[cf$resp == "dHT" & cf$cand == "K3p"], cf$term[cf$resp == "dHT" & cf$cand == "K3p"])
x <- c(d$BALx.0, d$BALx.1); rd <- c(d$BAPH.0, d$BAPH.1); ht <- c(d$HT.0); sh <- ifelse(d$BAPHo.0 > 0, d$BALo.0 / d$BAPHo.0, 0)
cat("dHT frame rows", nrow(d), "x quantiles (0,.5,.95,.99,1):", round(quantile(x, c(0, .5, .95, .99, 1)), 4), "\n")
cat("RD quantiles:", round(quantile(rd, c(0, .01, .5, .99, 1)), 4), " HT quantiles:", round(quantile(ht, c(0, .01, .25, .5, .75, .99, 1)), 3), "\n")
der_x <- function(b3, b4, X, H) 2 * b3 * X / log(H + 5) + b4 / (X + 1)
H <- quantile(ht, c(.01, .25, .5, .75, .99), names = FALSE); H <- c(min(ht), H)
out <- list()
for (lab in c("obsmax", "grid0to2", "p99")) { xm <- switch(lab, obsmax = max(x), grid0to2 = 2, p99 = quantile(x, .99, names = FALSE)); X <- seq(0, xm, length.out = 401)
  for (h in H) { g <- der_x(b[["b3"]], b[["b4"]], X, h); out[[length(out) + 1]] <- data.frame(range = lab, xmax = xm, HT = h, max_deriv = max(g), n_pos = sum(g > 0), x_first_pos = if (any(g > 0)) min(X[g > 0]) else NA) } }
O <- do.call(rbind, out); print(O, digits = 5)
## rows of the frame beyond the turning point: 2 b3 x(1+x) > -b4 ln(HT+5)
tp <- 2 * b[["b3"]] * d$BALx.0 * (1 + d$BALx.0) > -b[["b4"]] * log(d$HT.0 + 5); cat("frame rows (t.0) beyond turning point:", sum(tp), "of", nrow(d), "\n")
## RD direction at fixed share (share p10/p50/p90, RD grid p1..p99, HT as above)
R <- seq(quantile(rd, .01), quantile(rd, .99), length.out = 200); o2 <- list()
for (s in quantile(sh, c(0, .1, .5, .9))) for (h in H) { X <- s * R; g <- b[["b6"]] * sqrt(h) / (2 * sqrt(R)) + s * der_x(b[["b3"]], b[["b4"]], X, h)
  o2[[length(o2) + 1]] <- data.frame(share = s, HT = h, max_dRD = max(g), min_dRD = min(g)) }
print(do.call(rbind, o2), digits = 4)
write.csv(O, file.path(path.expand("~/jobs/koa_v105d_20261102/prep/out"), "mono_dht_K3p.csv"), row.names = FALSE)
cat("MONO_DHT_K3P", if (all(O$n_pos[O$range == "obsmax"] == 0)) "PASS" else "FAIL", "\n")
