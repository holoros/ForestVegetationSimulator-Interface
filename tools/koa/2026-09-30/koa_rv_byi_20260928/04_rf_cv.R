## Spatially blocked cross-validation of the two BYI random forests (R1 c10, R2 c14).
## ranger with the stored arguments of each spatialRF fit (500 trees, mtry 3, min.node.size 5, seed 42).
## Coordinates are used on firebreather only to build blocks and distance bands; none are written.
suppressMessages({library(data.table); library(ranger)})
set.seed(20260928); NREP <- 10; B <- 2000
fr <- readRDS("work_frames_RESTRICTED.rds")
mods <- list(Kona = list(f = "in/BYI_srf_fit.RDS", d = fr$k), Statewide = list(f = "in/BYI_srf_fit_HI.RDS", d = fr$w))
met <- function(o, p) c(R2 = 1 - sum((o - p)^2) / sum((o - mean(o))^2), RMSE = sqrt(mean((o - p)^2)), bias = mean(p - o), n = length(o))
allrows <- list(); vg <- list(); mor <- list()
for (mn in names(mods)) {
  m <- readRDS(mods[[mn]]$f); a <- m$ranger.arguments; sd <- a$data; X <- mods[[mn]]$d
  cat("\n==", mn, " stored y identical in order to rebuilt:", identical(sd$Schmoldt_Index, X$SI), "\n")
  pv <- a$predictor.variable.names
  D <- as.data.frame(X[, c("SI", pv), with = FALSE]); names(D)[1] <- "y"
  if ("PTYPE" %in% pv) D$PTYPE <- factor(D$PTYPE)
  lat0 <- mean(X$LAT); x <- (X$LON - mean(X$LON)) * 111.32 * cos(lat0 * pi / 180); yk <- (X$LAT - lat0) * 110.57
  fit1 <- function(tr, te, seed = 42) { r <- ranger(y ~ ., data = D[tr, ], num.trees = 500, mtry = 3, min.node.size = 5, seed = seed, num.threads = 6)
    predict(r, D[te, ])$predictions }
  full <- ranger(y ~ ., data = D, num.trees = 500, mtry = 3, min.node.size = 5, seed = 42, num.threads = 6)
  oob <- full$predictions; res <- D$y - oob
  cat(sprintf("refit OOB R2 %.3f RMSE %.1f (stored %.3f, %.1f)\n", 1 - full$prediction.error / var(D$y) * (nrow(D) - 1) / nrow(D) * 0 + full$r.squared, sqrt(full$prediction.error), m$performance$r.squared.oob, m$performance$rmse.oob))
  nz <- D$y > 0
  rows <- list(data.table(model = mn, scheme = "Out-of-bag (refit, seed 42)", rep = 1, subset = c("all", "BYI > 0", "BYI = 0"),
                          rbind(met(D$y, oob), met(D$y[nz], oob[nz]), met(D$y[!nz], oob[!nz]))))
  ## residual variogram and Moran's I by distance band (OOB residuals)
  dm <- as.matrix(dist(cbind(x, yk))); ut <- upper.tri(dm)
  br <- c(0, 0.5, 1, 2, 3, 4, 5, 7.5, 10, 15, 20, 30, 40, 60, 100, 200)
  bi <- cut(dm[ut], br); g2 <- outer(res, res, function(u, v) (u - v)^2 / 2)[ut]
  v1 <- data.table(model = mn, band = levels(bi), pairs = as.integer(table(bi)), semivar = as.numeric(tapply(g2, bi, mean)))
  vg[[mn]] <- v1
  z <- res - mean(res)
  moranI <- function(W, z) { s0 <- sum(W); if (s0 == 0) return(NA); (length(z) / s0) * sum(W * outer(z, z)) / sum(z^2) }
  for (k in seq_len(length(br) - 1)) { W <- (dm > br[k] & dm <= br[k + 1]) * 1; diag(W) <- 0; np <- sum(W) / 2
    if (np < 10) { mor[[length(mor) + 1]] <- data.table(model = mn, band = levels(bi)[k], pairs = np, I = NA, p = NA); next }
    I0 <- moranI(W, z); perm <- replicate(499, moranI(W, sample(z))); p <- (sum(abs(perm - mean(perm)) >= abs(I0 - mean(perm))) + 1) / 500
    mor[[length(mor) + 1]] <- data.table(model = mn, band = levels(bi)[k], pairs = np, I = I0, E = -1 / (length(z) - 1), p = p) }
  ## CV schemes
  schemes <- list()
  schemes[["Random 10-fold"]] <- function(r) sample(rep_len(1:10, nrow(D)))
  for (bs in c(5, 10, 20)) schemes[[sprintf("Spatial blocks %d km, 10 folds", bs)]] <- local({ bs <- bs; function(r) {
    ox <- runif(1, 0, bs); oy <- runif(1, 0, bs); blk <- paste(floor((x + ox) / bs), floor((yk + oy) / bs))
    ub <- unique(blk); fb <- sample(rep_len(1:10, length(ub))); fb[match(blk, ub)] } })
  schemes[["Leave one region out (k-means, 4 regions)"]] <- function(r) kmeans(cbind(x, yk), 4, nstart = 20)$cluster
  schemes[["Leave one region out (k-means, 8 regions)"]] <- function(r) kmeans(cbind(x, yk), 8, nstart = 20)$cluster
  for (sn in names(schemes)) for (r in 1:NREP) {
    fo <- schemes[[sn]](r); p <- numeric(nrow(D))
    for (f in unique(fo)) { te <- which(fo == f); p[te] <- fit1(setdiff(seq_len(nrow(D)), te), te, seed = 42 + r) }
    rows[[length(rows) + 1]] <- data.table(model = mn, scheme = sn, rep = r, subset = c("all", "BYI > 0", "BYI = 0"),
                                           rbind(met(D$y, p), met(D$y[nz], p[nz]), met(D$y[!nz], p[!nz])))
    if (r == 1) { ## block bootstrap interval on the pooled predictions of the first repetition
      bl <- fo; ub <- unique(bl)
      bt <- t(replicate(B, { s <- sample(ub, length(ub), TRUE); i <- unlist(lapply(s, function(q) which(bl == q)))
        j <- i[D$y[i] > 0]; c(met(D$y[i], p[i])[1:2], met(D$y[j], p[j])[1:2]) }))
      rows[[length(rows)]][, `:=`(boot_lo_R2 = c(quantile(bt[, 1], .025), quantile(bt[, 3], .025), NA), boot_hi_R2 = c(quantile(bt[, 1], .975), quantile(bt[, 3], .975), NA),
                                  boot_lo_RMSE = c(quantile(bt[, 2], .025), quantile(bt[, 4], .025), NA), boot_hi_RMSE = c(quantile(bt[, 2], .975), quantile(bt[, 4], .975), NA))]
    }
  }
  ## forest trained on BYI > 0 plots only, same predictors (skill among plots that carry an asymptote)
  Dn <- D[nz, ]; xn <- x[nz]; yn <- yk[nz]
  rn <- ranger(y ~ ., data = Dn, num.trees = 500, mtry = 3, min.node.size = 5, seed = 42, num.threads = 6)
  rows[[length(rows) + 1]] <- data.table(model = paste(mn, "trained on BYI > 0"), scheme = "Out-of-bag", rep = 1, subset = "BYI > 0", t(met(Dn$y, rn$predictions)))
  for (bs in c(10, 20)) for (r in 1:NREP) { ox <- runif(1, 0, bs); oy <- runif(1, 0, bs); blk <- paste(floor((xn + ox) / bs), floor((yn + oy) / bs))
    ub <- unique(blk); fo <- sample(rep_len(1:10, length(ub)))[match(blk, ub)]; p <- numeric(nrow(Dn))
    for (f in unique(fo)) { te <- which(fo == f); tr <- setdiff(seq_len(nrow(Dn)), te)
      rr <- ranger(y ~ ., data = Dn[tr, ], num.trees = 500, mtry = 3, min.node.size = 5, seed = 42 + r, num.threads = 6); p[te] <- predict(rr, Dn[te, ])$predictions }
    rows[[length(rows) + 1]] <- data.table(model = paste(mn, "trained on BYI > 0"), scheme = sprintf("Spatial blocks %d km, 10 folds", bs), rep = r, subset = "BYI > 0", t(met(Dn$y, p))) }
  allrows[[mn]] <- rbindlist(rows, fill = TRUE)
}
R <- rbindlist(allrows, fill = TRUE); fwrite(R, "out_rf_cv_all_reps.csv")
S <- R[, .(n = n[1], R2_mean = mean(R2), R2_lo_rep = min(R2), R2_hi_rep = max(R2), RMSE_mean = mean(RMSE), RMSE_lo_rep = min(RMSE), RMSE_hi_rep = max(RMSE),
           bias_mean = mean(bias), boot_lo_R2 = boot_lo_R2[1], boot_hi_R2 = boot_hi_R2[1], boot_lo_RMSE = boot_lo_RMSE[1], boot_hi_RMSE = boot_hi_RMSE[1]), by = .(model, scheme, subset)]
num <- names(S)[sapply(S, is.numeric)]; S[, (num) := lapply(.SD, function(v) round(v, 3)), .SDcols = num]
options(width = 250); print(S); fwrite(S, "out_T3_rf_cv_summary.csv")
V <- rbindlist(vg); print(V); fwrite(V, "out_T4a_residual_semivariogram.csv")
M <- rbindlist(mor, fill = TRUE); M[, I := round(I, 4)]; print(M); fwrite(M, "out_T4b_residual_moran_bands.csv")
cat("done\n")
