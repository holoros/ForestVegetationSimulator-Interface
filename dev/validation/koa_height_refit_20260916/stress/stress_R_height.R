## Stress test of the patched koa height functions (FVS-HI HiGy.R pred_ht/calc_ht and
## koa_prediction_functions.R koa.HT) against the patched Python engine predict_HT.
## September 16, 2026. Headless. Writes stress_R_height_results.csv and a text log.
suppressPackageStartupMessages({library(dplyr); library(tibble)})
P <- Sys.getenv("KOA_RDIR", ".")
env_h <- new.env(); env_k <- new.env()
stand <- list(byi = 264)
res_src_h <- tryCatch({sys.source(file.path(P, Sys.getenv("KOA_HIGY", "HiGy.R")), envir = env_h); "ok"}, error = function(e) conditionMessage(e))
res_src_k <- tryCatch({sys.source(file.path(P, "koa_prediction_functions.R"), envir = env_k); "ok"}, error = function(e) conditionMessage(e))
cat("source HiGy.R:", res_src_h, "\nsource koa_prediction_functions.R:", res_src_k, "\n")
out <- list(); add <- function(test, pass, detail) out[[length(out) + 1]] <<- tibble(test = test, pass = pass, detail = detail)

g <- read.csv(file.path(Sys.getenv("KOA_STRESS_DIR", "."), "ht_grid_python.csv.gz"))
hp <- env_h$ht.pred.parm
site <- hp[hp$type == "site", ]; base <- hp[hp$type == "base", ]
# 1. koa.HT vs python on the BYI > 0 grid
gs <- g[g$byi > 0, ]
k <- with(gs, env_k$koa.HT(dbh, baph, BYI = byi, DBH.max = dbhmax))
d1 <- max(abs(k - gs$ht_py))
add("koa.HT equals Python predict_HT, 1,620 grid points with BYI > 0", d1 < 1e-3, sprintf("max abs diff %.2e m", d1))
# 2. pred_ht site row vs python
p <- with(gs, env_h$pred_ht(dbh, ba = baph, bal = 0, qmd = 1, byi = byi, site$a0, site$a1, site$b, site$c, site$g1, site$g2, dbh.max = dbhmax))
d2 <- max(abs(p - gs$ht_py))
add("HiGy pred_ht (site row) equals Python predict_HT", d2 < 1e-3, sprintf("max abs diff %.2e m", d2))
# 3. base row vs python use_byi = FALSE (different vectors by design?)
gb <- g[g$byi == 0, ]
pb <- with(gb, env_h$pred_ht(dbh, ba = baph, bal = 0, qmd = 1, byi = 0, base$a0, base$a1, base$b, base$c, base$g1, base$g2, dbh.max = dbhmax))
d3 <- max(abs(pb - gb$ht_py)); r3 <- range((pb - gb$ht_py) / gb$ht_py)
add("HiGy base row (no BYI) matches Python engine without BYI", d3 < 1e-3,
    sprintf("max abs diff %.2f m, relative %.1f%% to %.1f%%; FVS-HI base row is the separately fitted base form, the Python engine drops a1 from the site vector", d3, 100 * r3[1], 100 * r3[2]))
# 4. finite, bounded, >= 1.37 across the grid
add("All grid heights finite and >= 1.37 m", all(is.finite(k)) && all(k >= 1.37), sprintf("min %.2f, max %.2f m", min(k), max(k)))
# 5. shape at a fixed plot DBH.max: where does height peak (negative g2)?
pk <- sapply(c(30, 45, 60, 69.7, 90, 150, 250), function(m) { d <- seq(0.5, m, by = 0.1); d[which.max(env_k$koa.HT(d, 20, BYI = 264, DBH.max = m))] })
add("Within a plot, height is non-decreasing in DBH up to DBH.max for DBH.max <= 90 cm (both harness ceilings)",
    all(pk[1:5] >= c(30, 45, 60, 69.7, 90) - 0.1),
    paste0("peak DBH at DBH.max 30/45/60/69.7/90/150/250 cm = ", paste(round(pk, 1), collapse = "/"), "; above about 90 cm the largest trees are predicted shorter than the peak"))
# 6. site ordering in BYI
sb <- sapply(c(50, 100, 264, 450, 813), function(b) env_k$koa.HT(25, 20, BYI = b, DBH.max = 42.8))
add("Height increases with BYI", all(diff(sb) > 0), paste(round(sb, 2), collapse = ", "))
# 7. relative diameter effect: DBH.max larger -> taller subject tree (g2 < 0)
rd <- sapply(c(25, 30, 50, 100), function(m) env_k$koa.HT(25, 20, BYI = 264, DBH.max = m))
add("Subordinate tree (smaller rDBH) is taller at equal DBH, g2 negative", all(diff(rd) > 0), paste(round(rd, 2), collapse = ", "))
# 8. DBH.max below DBH is bounded at rDBH = 1
add("DBH.max smaller than DBH is bounded (rDBH capped at 1)",
    isTRUE(all.equal(env_k$koa.HT(40, 20, BYI = 264, DBH.max = 10), env_k$koa.HT(40, 20, BYI = 264, DBH.max = 40))), "koa.HT(40, DBH.max = 10) == koa.HT(40, DBH.max = 40)")
# 9. scalar call without DBH.max is refused
e9 <- tryCatch(env_k$koa.HT(20, 20, BYI = 264), error = function(e) "refused")
add("Single-tree koa.HT call without DBH.max is refused (was silently rDBH = 1)", identical(e9, "refused"), "stop() with guidance")
v9 <- env_k$koa.HT(c(10, 20, 45), 20, BYI = 264)
add("Vector koa.HT call without DBH.max uses max(DBH) of the list", isTRUE(all.equal(v9, env_k$koa.HT(c(10, 20, 45), 20, BYI = 264, DBH.max = 45))), "plot list convention")
# 10. pred_ht without dbh.max is refused
e10 <- tryCatch(env_h$pred_ht(20, 20, 0, 25, 264, site$a0, site$a1, site$b, site$c, site$g1, site$g2), error = function(e) "refused")
add("pred_ht without dbh.max is refused (was silently rDBH = DBH/QMD)", identical(e10, "refused"), "stop() with guidance")
# 11. NA handling
add("koa.HT with BYI = NA returns NA (not silently base form)", is.na(env_k$koa.HT(20, 20, BYI = NA, DBH.max = 40)), "NA propagates")
add("pred_ht with byi = NA uses the intercept a0 alone", is.finite(env_h$pred_ht(20, 20, 0, 1, NA, site$a0, site$a1, site$b, site$c, site$g1, site$g2, dbh.max = 40)), "ifelse(byi %in% c(NA, 0), a0, ...)")
# 12. negative / zero inputs
z <- env_k$koa.HT(c(-1, 0), 20, BYI = 264, DBH.max = 40)
add("Negative or zero DBH returns 1.37 m (no NaN)", all(is.finite(z)) && all(z == 1.37), paste(round(z, 3), collapse = ", "))
nb <- env_k$koa.HT(20, -2, BYI = 264, DBH.max = 40)
add("Negative BAPH is floored at zero (no NaN)", is.finite(nb), sprintf("koa.HT(BAPH = -2) = %.2f", nb))
# 13. calc_ht on a two-plot tree list: dbh.max is per plot
tr <- tibble(plot = c(1, 1, 1, 2, 2), sp = "AK", dbh = c(10, 20, 40, 10, 12), bal = c(5, 3, 0, 1, 0))
pl <- tibble(plot = c(1, 2), ba.plot = c(20, 5), qmd = c(25, 11))
ch <- tryCatch(env_h$calc_ht(tr, pl, byi = 264), error = function(e) e)
if (inherits(ch, "error")) add("calc_ht runs on a two-plot list", FALSE, conditionMessage(ch)) else {
  ref <- c(env_k$koa.HT(c(10, 20, 40), 20, BYI = 264, DBH.max = 40), env_k$koa.HT(c(10, 12), 5, BYI = 264, DBH.max = 12))
  add("calc_ht uses per-plot DBH.max and matches koa.HT", max(abs(ch$pht - ref)) < 1e-6, sprintf("max abs diff %.2e; plot 2 tree of 10 cm gets rDBH = 10/12", max(abs(ch$pht - ref))))
}
# 14. calc_ht with a dead or zero-diameter record in the list
tr2 <- bind_rows(tr, tibble(plot = 1, sp = "AK", dbh = NA_real_, bal = 0))
ch2 <- tryCatch(env_h$calc_ht(tr2, pl, byi = 264), error = function(e) e)
add("calc_ht tolerates an NA diameter", !inherits(ch2, "error") && all(is.finite(ch2$pht[1:5])), if (inherits(ch2, "error")) conditionMessage(ch2) else "na.rm in dbh.max")
# 15. coefficients match manuscript Table 3 (numbers_v94.json)
tab3 <- c(a0 = 30.1882, a1 = 1.4263, b = 0.018401, c = 0.81799, g1 = 0.051108, g2 = -0.35086)
got <- unlist(site[1, c("a0", "a1", "b", "c", "g1", "g2")])
add("HiGy site row equals Table 3 to printed precision", all(abs(got - tab3) / abs(tab3) < 5e-4), paste(signif(got, 6), collapse = ", "))
R <- bind_rows(out)
write.csv(R, "stress_R_height_results.csv", row.names = FALSE)
print(as.data.frame(R), right = FALSE)
