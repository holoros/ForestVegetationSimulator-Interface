## common.R: helpers shared by every stage. Base R plus nlme only.
source("config.R")
set.seed(SEED)
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)
OUT_DIR <- normalizePath(OUT_DIR)
DEPOSIT_DIR <- normalizePath(DEPOSIT_DIR, mustWork = FALSE)
LOG <- file.path(OUT_DIR, "error_log.txt")

logmsg <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " ", paste0(...))
  cat(msg, "\n"); cat(msg, "\n", file = LOG, append = TRUE)
}
gate <- function(ok, what) {
  if (isTRUE(ok)) { logmsg("GATE PASS ", what); return(invisible(TRUE)) }
  logmsg("GATE FAIL ", what); stop("gate failed: ", what, call. = FALSE)
}
safely <- function(expr, what) {
  tryCatch(expr, error = function(e) { logmsg("ERROR in ", what, ": ", conditionMessage(e)); NULL })
}
dep <- function(f) if (grepl("^/", f)) f else file.path(DEPOSIT_DIR, f)
read_dep <- function(f) {
  p <- dep(f); if (!nzchar(f) || !file.exists(p)) return(NULL)
  utils::read.csv(p, stringsAsFactors = FALSE, check.names = FALSE)
}
## rename deposit columns to the internal names in COL, keep everything else
std <- function(d, map = COL) {
  if (is.null(d)) return(NULL)
  for (k in names(map)) if (map[[k]] %in% names(d) && !(k %in% names(d))) names(d)[names(d) == map[[k]]] <- k
  d
}
## installation cluster id that stays unique when installation numbers repeat across sources
clus <- function(d) if ("source" %in% names(d)) paste(d$source, d$inst, sep = "/") else as.character(d$inst)
need <- function(d, cols, what) {
  miss <- setdiff(cols, names(d))
  gate(length(miss) == 0, paste0(what, " has columns ", paste(cols, collapse = ","),
                                 if (length(miss)) paste0(" (missing: ", paste(miss, collapse = ","), ")") else ""))
}
## map any site label ("low", "Low (100)", 100) to Low/Medium/High
site_std <- function(x) {
  v <- suppressWarnings(as.numeric(x)); out <- rep(NA_character_, length(x))
  out[!is.na(v)] <- names(SITE_BYI)[match(v[!is.na(v)], SITE_BYI)]
  lx <- tolower(as.character(x))
  out[is.na(out) & grepl("^low", lx)] <- "Low"; out[is.na(out) & grepl("^med", lx)] <- "Medium"; out[is.na(out) & grepl("^high", lx)] <- "High"
  if (anyNA(out)) logmsg("WARNING unmatched site labels: ", paste(unique(x[is.na(out)]), collapse = ", "))
  out
}
wcsv <- function(x, f) utils::write.csv(x, file.path(OUT_DIR, f), row.names = FALSE)
r2   <- function(o, p) 1 - sum((o - p)^2) / sum((o - mean(o))^2)
rmse <- function(o, p) sqrt(mean((o - p)^2))
auc  <- function(y, s) {  # Mann-Whitney AUC, y in {0,1}
  r <- rank(s); n1 <- sum(y == 1); n0 <- sum(y == 0)
  if (n1 == 0 || n0 == 0) return(NA_real_)
  (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
rmvn <- function(n, mu, S) {  # multivariate normal draws without MASS
  L <- chol(S + diag(1e-12, nrow(S)))
  sweep(matrix(stats::rnorm(n * length(mu)), n) %*% L, 2, mu, "+")
}
## Chapman-Richards height of Eq. 2
ht_eq2 <- function(p, dbh, byi, baph, rd)
  (p[["a0"]] + p[["a1"]] * byi / 100) * (1 - exp(-p[["b"]] * dbh))^p[["c"]] *
    exp(p[["g1"]] * log(baph + 1) + p[["g2"]] * rd)

## Cluster-bootstrap equivalence test on observed ~ predicted (Robinson et al. 2005).
## Intercept test is on mean bias at the mean prediction; slope test on proportionality.
equiv_boot <- function(obs, pred, cluster, region = EQ_REGION, nboot = NBOOT, alpha = 0.05) {
  ok <- is.finite(obs) & is.finite(pred); obs <- obs[ok]; pred <- pred[ok]; cluster <- cluster[ok]
  cl <- split(seq_along(obs), cluster); ids <- names(cl)
  stat <- function(idx) {
    o <- obs[idx]; p <- pred[idx]; pc <- p - mean(p)
    f <- stats::lm.fit(cbind(1, pc), o)$coefficients
    c(b0 = unname(f[1]) - mean(p), b1 = unname(f[2]))   # b0: mean bias at mean prediction
  }
  est <- stat(seq_along(obs))
  bs <- t(replicate(nboot, stat(unlist(cl[sample(ids, length(ids), replace = TRUE)], use.names = FALSE))))
  q <- function(v) stats::quantile(v, c(alpha, 1 - alpha), na.rm = TRUE)  # TOST: 1 - 2 alpha interval
  ci0 <- q(bs[, "b0"]); ci1 <- q(bs[, "b1"])
  ybar <- mean(obs); r0 <- region[["b0"]] * abs(ybar); r1 <- region[["b1"]]
  ## smallest region at which each test still passes
  min0 <- max(abs(ci0)) / abs(ybar); min1 <- max(abs(ci1 - 1))
  data.frame(n = length(obs), clusters = length(ids), nboot = nboot, mean_obs = ybar,
             bias_obs_minus_pred = est[["b0"]], bias_lo = ci0[[1]], bias_hi = ci0[[2]], region_bias = r0,
             pass_bias = ci0[[1]] > -r0 && ci0[[2]] < r0, min_region_bias = min0,
             slope = est[["b1"]], slope_lo = ci1[[1]], slope_hi = ci1[[2]], region_slope = r1,
             pass_slope = ci1[[1]] > 1 - r1 && ci1[[2]] < 1 + r1, min_region_slope = min1,
             rmse = rmse(obs, pred), mae = mean(abs(obs - pred)))
}
