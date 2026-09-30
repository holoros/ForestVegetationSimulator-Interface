## a1_stage12.R  koa R1 c12: Stage 1 occurrence and Stage 2 magnitude refits with stems-at-risk / plot-area
## adjustment, pooled and by origin, plot-cluster bootstrap 2,000. Headless, base R + jsonlite.
suppressPackageStartupMessages(library(jsonlite))
set.seed(20260928)
OUT <- "out_a1"; dir.create(OUT, showWarnings = FALSE)
B <- 2000L
pi <- read.csv("inputs/plot_intervals_origin_span.csv", stringsAsFactors = FALSE)
pi <- pi[!as.logical(pi$removal), ]
pi$any_mort <- as.logical(pi$any_mort)
pi$key <- paste(pi$Data, pi$Install, pi$Plot)
pi$lnsdi <- log(pmax(pi$sdi, 1))
pi$lnn <- log(pi$n_alive)
pi$area <- pi$n_alive / pi$expf_alive          # ha, from expansion factor
pi$lnarea <- log(pi$area)
js <- fromJSON("inputs/stage1_fit.json")
cat("rows", nrow(pi), "plots", length(unique(pi$key)), "with mortality", sum(pi$any_mort), "\n")

## ---- reproduction gate
g1 <- glm(any_mort ~ lnsdi + planted, family = binomial(link = "cloglog"), offset = log(yip), data = pi)
dm <- pi[pi$any_mort & pi$m_ann > 0, ]
g2 <- lm(log(m_ann) ~ lnsdi + planted, data = dm)
gate <- c(s1 = max(abs(coef(g1) - unlist(js$stage1_beta))), s2 = max(abs(coef(g2) - unlist(js$stage2_beta))))
cat("GATE max abs diff S1", gate[1], "S2", gate[2], "\n")
stopifnot(all(gate < 1e-8))

## ---- model specifications
S1 <- list(
  S1_base      = list(f = any_mort ~ lnsdi + planted,          off = function(d) log(d$yip)),
  S1_lnN_cov   = list(f = any_mort ~ lnsdi + planted + lnn,    off = function(d) log(d$yip)),
  S1_lnN_off   = list(f = any_mort ~ lnsdi + planted,          off = function(d) log(d$yip) + log(d$n_alive)),
  S1_lnA_cov   = list(f = any_mort ~ lnsdi + planted + lnarea, off = function(d) log(d$yip)),
  S1_binom     = list(f = cbind(n_died, n_alive - n_died) ~ lnsdi + planted, off = function(d) log(d$yip)))
S2 <- list(
  S2_base      = log(m_ann) ~ lnsdi + planted,
  S2_lnN_cov   = log(m_ann) ~ lnsdi + planted + lnn,
  S2_lnA_cov   = log(m_ann) ~ lnsdi + planted + lnarea)

drop_pl <- function(f) update(f, . ~ . - planted)
fit1 <- function(sp, d, byorigin) {
  f <- if (byorigin) drop_pl(sp$f) else sp$f
  d$.off <- sp$off(d)
  m <- suppressWarnings(glm(f, family = binomial(link = "cloglog"), offset = .off, data = d,
                            control = glm.control(maxit = 100)))
  if (!m$converged) stop("nonconv")
  coef(m)
}
fit2 <- function(f, d, byorigin) {
  if (byorigin) f <- drop_pl(f)
  dm <- d[d$any_mort & d$m_ann > 0, ]
  coef(lm(f, data = dm))
}
boot <- function(d, fun) {
  keys <- unique(d$key); idx <- split(seq_len(nrow(d)), d$key)
  est <- fun(d)
  M <- matrix(NA_real_, B, length(est), dimnames = list(NULL, names(est)))
  nfail <- 0L
  for (b in seq_len(B)) {
    s <- sample(keys, length(keys), TRUE); db <- d[unlist(idx[s], use.names = FALSE), ]
    r <- tryCatch(fun(db), error = function(e) NULL)
    if (is.null(r) || length(r) != length(est) || any(!is.finite(r))) { nfail <- nfail + 1L; next }
    M[b, ] <- r
  }
  data.frame(term = names(est), estimate = unname(est),
             lo95 = apply(M, 2, quantile, 0.025, na.rm = TRUE),
             hi95 = apply(M, 2, quantile, 0.975, na.rm = TRUE),
             p_boot_gt0 = colMeans(M > 0, na.rm = TRUE),
             n_boot_ok = B - nfail, row.names = NULL)
}
subsets <- list(pooled = pi, natural = pi[pi$planted == 0, ], planted = pi[pi$planted == 1, ])
res <- list()
for (sn in names(subsets)) {
  d <- subsets[[sn]]; byo <- sn != "pooled"
  for (mn in names(S1)) {
    cat(sn, mn, format(Sys.time(), "%H:%M:%S"), "\n"); flush.console()
    r <- tryCatch(boot(d, function(x) fit1(S1[[mn]], x, byo)), error = function(e) { cat("  FAILED", conditionMessage(e), "\n"); NULL })
    if (!is.null(r)) res[[length(res) + 1]] <- cbind(subset = sn, model = mn, r)
  }
  for (mn in names(S2)) {
    cat(sn, mn, format(Sys.time(), "%H:%M:%S"), "\n"); flush.console()
    r <- tryCatch(boot(d, function(x) fit2(S2[[mn]], x, byo)), error = function(e) { cat("  FAILED", conditionMessage(e), "\n"); NULL })
    if (!is.null(r)) res[[length(res) + 1]] <- cbind(subset = sn, model = mn, r)
  }
}
R <- do.call(rbind, res)
write.csv(R, file.path(OUT, "a1_stage12_coefficients.csv"), row.names = FALSE)

## ---- counts per origin and source
cnt <- do.call(rbind, lapply(split(pi, list(pi$planted, pi$Data), drop = TRUE), function(d)
  data.frame(origin = ifelse(d$planted[1] == 1, "planted", "natural"), source = d$Data[1],
             intervals = nrow(d), plots = length(unique(d$key)), installations = length(unique(paste(d$Data, d$Install))),
             with_mortality = sum(d$any_mort), yip_median = median(d$yip), n_alive_median = median(d$n_alive),
             area_ha_median = median(d$area), sdi_median = median(d$sdi))))
tot <- do.call(rbind, lapply(split(pi, pi$planted), function(d)
  data.frame(origin = ifelse(d$planted[1] == 1, "planted", "natural"), source = "all",
             intervals = nrow(d), plots = length(unique(d$key)), installations = length(unique(paste(d$Data, d$Install))),
             with_mortality = sum(d$any_mort), yip_median = median(d$yip), n_alive_median = median(d$n_alive),
             area_ha_median = median(d$area), sdi_median = median(d$sdi))))
write.csv(rbind(cnt, tot), file.path(OUT, "a1_counts_by_origin.csv"), row.names = FALSE)
## collinearity
cc <- sapply(subsets, function(d) c(cor_lnsdi_lnn = cor(d$lnsdi, d$lnn), cor_lnsdi_lnarea = cor(d$lnsdi, d$lnarea),
                                    cor_lnn_lnarea = cor(d$lnn, d$lnarea)))
write.csv(cc, file.path(OUT, "a1_collinearity.csv"))
print(cc); print(rbind(cnt, tot))
print(R[R$term %in% c("lnsdi", "lnn", "lnarea", "planted"), ], digits = 3)
cat("DONE", format(Sys.time()), "\n")
