## 01_data_envelope.R  koa self-thinning QR test, step 1 (no fitting).
## Reproduces (a) the Section 6 observed envelope of envelope_check_v82.py (QMD, BAPH, SDI maxima over
## plot-years with >= 5 stems, KeyDupFlag 0, recorded plot-year columns) and (b) the C5 beta anchor of
## fit_allometry.py / beta_anchored_v102.json (99th percentile of N * H_QMD^2 over live plot-measures),
## both from the deployed engine_v102/AK_TREE.csv, then writes the analysis frame used by step 2.
## Read-only on every input. Outputs only under ~/jobs/koa_selfthin_qr_20260927/out.
suppressPackageStartupMessages(library(data.table))
J  <- path.expand("~/jobs")
E  <- file.path(J, "koa_v102_20260918/track2/engine_v102")
O  <- file.path(J, "koa_selfthin_qr_20260927/out")
dir.create(O, showWarnings = FALSE)
A_ALLOM <- -0.16863070512157105; K_HD <- 1.1719473700506686; BETA_DEP <- 0.16019053617304435
REC <- list(QMD = 69.6786879496591, BAPH = 76.0621351844664, SDI = 1453.46727427237,
            z99 = 389696.30682452075, n_anchor = 471L)
coord_pat <- "^(lat|lon|long|latitude|longitude|x|y|utm.*|easting|northing|coord.*|geom.*|lat_.*|lon_.*)$"
chk_coords <- function(d, nm) { bad <- grep(coord_pat, tolower(names(d)), value = TRUE)
  if (length(bad)) stop("coordinate-like columns in ", nm, ": ", paste(bad, collapse = ","))
  cat(sprintf("no coordinate columns in %s (%d columns checked)\n", nm, ncol(d))) }

t <- fread(file.path(E, "AK_TREE.csv")); chk_coords(t, "AK_TREE.csv")
p <- fread(file.path(E, "AK_PLT.csv"));  chk_coords(p, "AK_PLT.csv")
t <- t[is.na(KeyDupFlag) | KeyDupFlag == 0]
for (d in list(t, p)) d[, `:=`(Data = as.character(Data), Install = as.character(Install), Plot = as.character(Plot))]
K <- c("Data", "Install", "Plot", "Measure")
f1 <- function(v) v[!is.na(v)][1]     # pandas groupby first() skips NaN
t[, EXPF := as.numeric(EXPF)]; t[, DBH := as.numeric(DBH)]
nall <- t[, .(n = .N, QMD = f1(QMD), BAPH = f1(BAPH), SDI = f1(SDI), Age = median(Age, na.rm = TRUE)), by = K]

## (a) Section 6 envelope, envelope_check_v82.py derivation (all-status plot-year columns, >= 5 stems)
py <- nall[n >= 5]
env <- py[, .(n_plot_years = .N, QMD_max = max(QMD, na.rm = TRUE), BAPH_max = max(BAPH, na.rm = TRUE),
              SDI_max = max(SDI, na.rm = TRUE))]
env[, `:=`(dQMD = QMD_max - REC$QMD, dBAPH = BAPH_max - REC$BAPH, dSDI = SDI_max - REC$SDI)]
cat("\n(a) Section 6 envelope reproduced from AK_TREE.csv:\n"); print(env)

## (b) C5 beta anchor, fit_allometry.py derivation (live, DBH > 0, N = sum EXPF, QMD = plot-year column)
lv <- t[tolower(Status) == "live" & DBH > 0]
g <- lv[, .(N = sum(EXPF, na.rm = TRUE), QMD = f1(QMD), QMD_live = sqrt(sum(EXPF * DBH^2, na.rm = TRUE) / sum(EXPF, na.rm = TRUE)),
            BAPH_live = sum(EXPF * DBH^2, na.rm = TRUE) * pi / 40000, Age = median(Age, na.rm = TRUE)), by = K]
g <- merge(g, nall[, c(K, "n"), with = FALSE], by = K)
g <- g[n >= 5 & N > 0 & QMD > 0]
HQ <- function(q) exp((log(q) - A_ALLOM) / K_HD)
z <- g$N * HQ(g$QMD)^2
## numpy/pandas quantile default is type 7, which is R's default
z99 <- unname(quantile(z, 0.99, type = 7)); beta_rep <- 100 / sqrt(z99)
cat(sprintf("\n(b) anchor: n = %d (record %d); z99 = %.8f (record %.8f); beta = %.17g (deployed %.17g); |d beta| = %.3e\n",
            nrow(g), REC$n_anchor, z99, REC$z99, beta_rep, BETA_DEP, abs(beta_rep - BETA_DEP)))
stopifnot(nrow(g) == REC$n_anchor, abs(beta_rep - BETA_DEP) < 1e-12,
          abs(env$BAPH_max - REC$BAPH) < 1e-8, abs(env$SDI_max - REC$SDI) < 1e-6, abs(env$QMD_max - REC$QMD) < 1e-8)

## analysis frame: anchor set + origin (AK_PLT, by Data|Install|Plot) + installation cluster id
org <- unique(p[, .(Data, Install, Plot, Origin)])
stopifnot(!anyDuplicated(org[, .(Data, Install, Plot)]))
g <- merge(g, org, by = c("Data", "Install", "Plot"), all.x = TRUE)
cat("origin missing after join:", sum(is.na(g$Origin)), "\n")
g[, inst := paste(Data, Install, sep = "|")]
g[, plot := paste(Data, Install, Plot, sep = "|")]
g[, SDI_eng := N * (QMD / 25)^1.605]                 # engine sdi_of: index 25 cm, exponent 1.605
g[, SDI_eng_live := N * (QMD_live / 25)^1.605]
cat(sprintf("QMD plot column vs live-only QMD: median ratio %.4f, range %.4f to %.4f\n",
            median(g$QMD / g$QMD_live), min(g$QMD / g$QMD_live), max(g$QMD / g$QMD_live)))
cat("\nplot-measures, plots, installations by source and origin:\n")
print(g[, .(pm = .N, plots = uniqueN(plot), inst = uniqueN(inst), QMD_max = round(max(QMD), 2),
            N_max = round(max(N), 1)), by = .(Data, Origin)][order(Origin, Data)])
cat(sprintf("TOTAL: %d plot-measures, %d plots, %d installations\n", nrow(g), uniqueN(g$plot), uniqueN(g$inst)))
fwrite(g[, .(Data, Install, Plot, Measure, inst, plot, Origin, N, QMD, QMD_live, BAPH_live, SDI_eng, SDI_eng_live, Age)],
       file.path(O, "analysis_frame_DATA.csv"))
fwrite(cbind(env, n_anchor = nrow(g), z99 = z99, beta_reproduced = beta_rep, beta_deployed = BETA_DEP),
       file.path(O, "envelope_reproduction.csv"))
cat("wrote out/analysis_frame_DATA.csv and out/envelope_reproduction.csv\n")
