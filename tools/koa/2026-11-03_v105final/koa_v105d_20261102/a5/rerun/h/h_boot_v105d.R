## a5/rerun/h/h_boot_v105d.R <B> <cores>: installation-cluster bootstrap of the v105d Eq. 2 H1a (koa_compscreen_20261102: ln(RD) in place of ln(BAPH+1);
## a0, a1, g1 refitted with random a0 on source/installation, b c g2 held at v104) on the v105 height frame. Same resampling as h_boot_v105.R
## (installations with replacement, copies distinct, seed 20261031, draws generated up front, per-draw checkpoints in draws/). RD per plot-year from
## koa_rdcomp_20261102/out/stand_plotyear.csv (SDI_qmd / 923), as the compscreen. b, c, g2 constant in every draw by construction.
suppressPackageStartupMessages({ library(nlme); library(data.table) })
J <- path.expand("~/jobs/koa_v105d_20261102"); O <- file.path(J, "a5/rerun/h")
a <- commandArgs(trailingOnly = TRUE); B <- as.integer(a[1]); cores <- as.integer(a[2])
src <- readLines(file.path(J, "track2/height_refit_v103.R")); eval(parse(text = src[1:33]))
V104 <- c(a0 = 28.9288306400629, a1 = 0.966787802291731, b = 0.017026137590269, c = 0.792246824594636, g1 = 0.0768405891389797, g2 = -0.343309808337385)
H1A <- read.csv(file.path(J, "prep/out/height_coefficients_H1a.csv")); H1A <- setNames(H1A$estimate, H1A$parameter)
f0 <- file.path(J, "frames/final/tree_join_v103.csv"); f5 <- path.expand("~/jobs/koa_v105_20261102/frames/final/tree_join_v103.csv")
stopifnot(unname(tools::md5sum(f0)) == unname(tools::md5sum(f5)))   # same frame as the compscreen fit
S <- fread(path.expand("~/jobs/koa_rdcomp_20261102/out/stand_plotyear.csv"), colClasses = list(character = c("Install", "Plot")))
d <- prep(f0); d$RD <- S$SDI_qmd[match(paste(d$source, d$inst, d$plot, d$year), paste(S$Data, S$Install, S$Plot, S$Measure))] / 923; stopifnot(all(is.finite(d$RD) & d$RD > 0))
d$Fs <- (1 - exp(-V104[["b"]] * d$dbh))^V104[["c"]] * exp(V104[["g2"]] * d$rd_max); d$lrd <- log(d$RD)
fitp <- function(dd, ro = FALSE) nlme(ht ~ (a0 + a1 * byi / 100) * Fs * exp(g1 * lrd), data = dd, fixed = a0 + a1 + g1 ~ 1, random = a0 ~ 1 | grp_src/grp_inst, start = H1A[c("a0", "a1", "g1")],
                          control = nlmeControl(maxIter = 200, msMaxIter = 200, pnlsMaxIter = 50, returnObject = ro))
m0 <- tryCatch(fitp(d), error = function(e) { cat("reference strict fit failed:", conditionMessage(e), "; returnObject TRUE used\n"); fitp(d, TRUE) }); tt <- summary(m0)$tTable
ref <- data.frame(term = names(V104), est = c(fixef(m0)[["a0"]], fixef(m0)[["a1"]], V104[["b"]], V104[["c"]], fixef(m0)[["g1"]], V104[["g2"]]),
                  wald_se = c(tt["a0", 2], tt["a1", 2], NA, NA, tt["g1", 2], NA), n = nrow(d), n_inst = nlevels(d$grp_inst))
write.csv(ref, file.path(O, "h_ref_final.csv"), row.names = FALSE); cat("reference a0", ref$est[1], "a1", ref$est[2], "g1", ref$est[5], "| H1a", H1A[c("a0", "a1", "g1")], "max diff", max(abs(ref$est - H1A[names(V104)])), "\n")
ids <- levels(d$grp_inst); sp <- split(seq_len(nrow(d)), d$grp_inst)
set.seed(20261031); DRAWS <- lapply(seq_len(B), function(b) sample(ids, replace = TRUE))
one <- function(b) { s <- DRAWS[[b]]
  dd <- do.call(rbind, lapply(seq_along(s), function(j) { x <- d[sp[[s[j]]], ]; x$grp_inst <- paste(x$grp_inst, j, sep = "#"); x }))
  dd$grp_inst <- factor(dd$grp_inst); dd$grp_src <- factor(dd$grp_src)
  m <- tryCatch(suppressWarnings(fitp(dd)), error = function(e) NULL)
  if (is.null(m)) return(c(draw = b, ok = 0, setNames(rep(NA, 6), names(V104))))
  c(draw = b, ok = 1, a0 = fixef(m)[["a0"]], a1 = fixef(m)[["a1"]], b = V104[["b"]], c = V104[["c"]], g1 = fixef(m)[["g1"]], g2 = V104[["g2"]]) }
DD <- file.path(O, "draws"); dir.create(DD, showWarnings = FALSE)
one_ck <- function(b) { fn <- file.path(DD, sprintf("draw_%04d.csv", b)); if (file.exists(fn)) return(invisible(NULL))
  r <- one(b); write.csv(as.data.frame(t(r)), paste0(fn, ".tmp"), row.names = FALSE); file.rename(paste0(fn, ".tmp"), fn); invisible(NULL) }
todo <- which(!file.exists(file.path(DD, sprintf("draw_%04d.csv", seq_len(B))))); cat("draws to do", length(todo), "cores", cores, "\n")
invisible(parallel::mclapply(todo, one_ck, mc.cores = cores, mc.preschedule = FALSE))
cat("HEIGHT BOOT v105d DONE", format(Sys.time()), "\n")
