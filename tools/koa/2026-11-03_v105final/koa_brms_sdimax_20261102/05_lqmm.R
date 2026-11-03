## 05_lqmm.R (AMENDMENT 2b): lqmm random-intercept quantile mixed model, tau 0.95 and 0.99, CONUS control; plot-cluster bootstrap.
## args: B (default 500), cores (default 4)
args <- commandArgs(TRUE); B <- if (length(args) >= 1) as.integer(args[1]) else 500L; NC <- if (length(args) >= 2) as.integer(args[2]) else 4L
suppressPackageStartupMessages({library(data.table); library(lqmm); library(parallel)})
J <- path.expand("~/jobs/koa_brms_sdimax_20261102"); setwd(J)
D <- as.data.frame(fread("out/fit_frame.csv")[, .(ID, ltph, lqmd)])
L25 <- log(25.4); TAU <- c(0.95, 0.99)
ctrl <- lqmmControl(LP_max_iter = 100000)
fit1 <- function(d) {
  w <- character(0)
  m <- withCallingHandlers(tryCatch(lqmm(fixed = ltph ~ lqmd, random = ~1, group = ID, tau = TAU, data = d, control = ctrl, na.action = na.omit),
                                    error = function(e) e), warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
  list(m = m, w = w)
}
conv_of <- function(m, j) {   # per tau j
  op <- m[[as.character(TAU[j])]]$opt   # multi-tau lqmm stores each tau's fit under its name
  list(low = op$low_loop, upp = op$upp_loop)
}
t0 <- Sys.time(); r <- fit1(D); el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
if (inherits(r$m, "error")) stop("lqmm main fit error: ", conditionMessage(r$m))
m <- r$m; saveRDS(m, "fits/LQMM_tau95_99.rds")
cat("main fit seconds", round(el, 1), "| warnings:", if (length(r$w)) paste(unique(r$w), collapse = " || ") else "none", "\n")
for (tt in TAU) { cat("tau", tt, "\n"); str(m[[as.character(tt)]]$opt) }
cf <- coef(m); re <- ranef(m)   # multi-tau: cf matrix (2 x ntau); re list by tau
if (!is.matrix(cf)) cf <- matrix(cf, ncol = 1)
EST <- list(); PL <- list()
for (j in seq_along(TAU)) {
  b0 <- cf[1, j]; b1 <- cf[2, j]
  u <- if (is.data.frame(re)) re else re[[j]]
  cv <- conv_of(m, j)
  psi <- tryCatch(as.numeric(VarCorr(m)[[j]]), error = function(e) tryCatch(as.numeric(VarCorr(m)[j]), error = function(e) NA_real_))
  sc <- m[[as.character(TAU[j])]]$scale
  ok <- !is.null(cv$upp) && cv$upp > 0 && cv$low != -1 && all(is.finite(c(b0, b1, sc, psi))) && all(is.finite(u[, 1]))
  cat(sprintf("tau %.2f: b0 %.4f b1 %.4f scale %.4f psi %.4f | low_loop %s upp_loop %s | converged %s | pop SDImax %.0f | logLik %s\n",
              TAU[j], b0, b1, sc, psi, cv$low, cv$upp, ok, exp(b0 + b1 * L25), format(tryCatch(logLik(m)[j], error = function(e) NA))))
  P <- data.table(ID = rownames(u), u = u[, 1]); P[, `:=`(b0 = b0, b1 = b1, SDImax = exp(b0 + u + b1 * L25))]
  P[, tau := TAU[j]]; PL[[j]] <- P
  EST[[j]] <- data.table(tau = TAU[j], b0 = b0, b1 = b1, scale = sc, psi_ranef_var = psi, low_loop = cv$low, upp_loop = cv$upp, converged = ok,
                         SDImax_pop = exp(b0 + b1 * L25), n_rows = nrow(D), n_plots = nrow(u), seconds_main = el)
}
E <- rbindlist(EST); PP <- rbindlist(PL)
fwrite(PP, "out/lqmm_plot_raw.csv")
## bootstrap
ids <- unique(D$ID); sp <- split(D, D$ID)
RNGkind("L'Ecuyer-CMRG"); set.seed(20261102)
bt <- function(b) {
  s <- sample(ids, length(ids), replace = TRUE)
  d <- do.call(rbind, lapply(seq_along(s), function(k) { x <- sp[[s[k]]]; x$ID <- paste0("b", k); x }))
  r <- fit1(d); if (inherits(r$m, "error")) return(data.table(b = b, tau = TAU, b0 = NA_real_, b1 = NA_real_, ok = FALSE, err = conditionMessage(r$m)))
  cfb <- coef(r$m); if (!is.matrix(cfb)) cfb <- matrix(cfb, ncol = 1); reb <- ranef(r$m)
  rbindlist(lapply(seq_along(TAU), function(j) { cv <- conv_of(r$m, j); u <- if (is.data.frame(reb)) reb else reb[[j]]
    data.table(b = b, tau = TAU[j], b0 = cfb[1, j], b1 = cfb[2, j],
               ok = !is.null(cv$upp) && cv$upp > 0 && cv$low != -1 && all(is.finite(c(cfb[, j], r$m[[as.character(TAU[j])]]$scale))) && all(is.finite(u[, 1])), err = "") }))
}
t1 <- Sys.time()
BT <- rbindlist(mclapply(seq_len(B), bt, mc.cores = NC, mc.set.seed = TRUE))
cat("bootstrap B", B, "seconds", round(as.numeric(difftime(Sys.time(), t1, units = "secs"))), "\n")
BT[, SDImax_pop := exp(b0 + b1 * L25)]
fwrite(BT, "out/lqmm_boot.csv")
BS <- BT[ok == TRUE, .(B_ok = .N, SDImax_pop_q2.5 = quantile(SDImax_pop, .025), SDImax_pop_q97.5 = quantile(SDImax_pop, .975),
                      b1_q2.5 = quantile(b1, .025), b1_q97.5 = quantile(b1, .975), SDImax_pop_bootmedian = median(SDImax_pop)), by = tau]
BS[, B_failed := B - B_ok]
E <- merge(E, BS, by = "tau"); fwrite(E, "out/lqmm_estimates.csv"); print(E)
cat("done\n")
