#!/usr/bin/env python3
"""patch_figs_v105d.py: figure scripts that evaluate the replaced equations in R with literal forms.
a4/figs/fig_main_v104.R (Fig. 3): increment curves evaluated in the deployed forms read from koa_params (DDBH_FORM K3c1, DHT_FORM K3c1h: x = share RD,
b6 sqrt(RD size)); the v105c script evaluated the v105b form with the K3c1 vector for dDBH (defect, fixed here). Fixed stand for the curves: BAPH 30, RD of
that stand at QMD 25 cm (stated). Height curves and panel f: Eq. 2 H1a (track3_s02/v105d/02_height_fit.rds; RD per plot-year from koa_rdcomp stand_plotyear).
a4/figs/figS12_v104.R (Fig. S1): height panel H1a; HCB panel C2h (share = BALl/BAPH_hi, RD from TPH_hi, BAPH_hi)."""
import os, subprocess
W = os.path.expanduser("~/jobs/koa_v105d_20261102")
def backup(*ps): subprocess.run(["bash", f"{W}/v105d/backup_d.sh", *ps], check=True)
def rep(t, a, b, n=1): assert t.count(a) == n, (t.count(a), a[:90]); return t.replace(a, b)
p = f"{W}/a4/figs/fig_main_v104.R"; backup(p); t = open(p).read()
t = rep(t, "py_scalar <- function(txt, name) {", 'py_str <- function(txt, name) sub(\'^[^"]*"([^"]*)".*$\', "\\\\1", txt[grep(sprintf("^%s\\\\s*=", name), txt)[1]])   # v105d\npy_scalar <- function(txt, name) {')
t = rep(t, "  inc_b <- function(resp, b, cmult, size, bal, cr, baph, planted, byi) {\n",
        "  FORMS <- c(ddbh = py_str(par_txt, \"DDBH_FORM\"), dht = py_str(par_txt, \"DHT_FORM\")); stopifnot(FORMS[[\"ddbh\"]] == \"K3c1\", FORMS[[\"dht\"]] %in% c(\"K3c1h\", \"K3p\"))   # v105d\n"
        "  RD30 <- (30 / (pi / 40000 * 25^2)) * (25 / 25.4)^1.605 / 923   # v105d: RD of the fixed stand (BAPH 30) at QMD 25 cm (stated assumption of the curves)\n"
        "  inc_b <- function(resp, b, cmult, size, bal, cr, baph, planted, byi) {\n"
        "    if (FORMS[[resp]] %in% c(\"K3c1\", \"K3c1h\", \"K3p\")) { x <- (bal / baph) * RD30; b3 <- if (FORMS[[resp]] == \"K3p\") b[[\"b3\"]] else 0   # v105d RD x competition forms\n"
        "      y <- exp(b[[\"b0\"]] + b[[\"b1\"]] * log(size + 1) + b[[\"b2\"]] * size + b3 * x^2 / log(size + 5) + b[[\"b4\"]] * log(x + 1) +\n"
        "            b[[\"b5\"]] * log(cr) + b[[\"b6\"]] * sqrt(RD30 * size) + b[[\"b7\"]] * planted * pmin(size, GUARD[[resp]]) + b[[\"b8\"]] * log(byi) + b[[\"b9\"]] * planted) * cmult\n"
        "      return(pmin(y, CLIP[[resp]])) }\n")
t = rep(t, 'H <- readRDS(file.path(J, "track3_s02/v105/02_height_fit.rds"))', 'H <- readRDS(file.path(J, "track3_s02/v105d/02_height_fit.rds")); stopifnot(py_str(par_txt, "HT_FORM") == "H1a"); RDF <- py_scalar(par_txt, "RD_FLOOR_HT")')
t = rep(t, '  ht_eq2 <- function(p, dbh, byi, baph, rd) (p[["a0"]] + p[["a1"]] * byi / 100) * (1 - exp(-p[["b"]] * dbh))^p[["c"]] * exp(p[["g1"]] * log(baph + 1) + p[["g2"]] * rd)',
        '  ht_eq2 <- function(p, dbh, byi, baph, rd, RDs = RD30) (p[["a0"]] + p[["a1"]] * byi / 100) * (1 - exp(-p[["b"]] * dbh))^p[["c"]] * exp(p[["g1"]] * log(pmax(RDs, RDF)) + p[["g2"]] * rd)   # v105d H1a (baph unused; RDs = stand RD)')
t = rep(t, "filter(ht > 0, is.finite(byi), is.finite(baph)) |> mutate(pred = ht_eq2(H$coef, dbh, byi, baph, rd))",
        "filter(ht > 0, is.finite(byi), is.finite(baph))\n  SPY <- data.table::fread(path.expand(\"~/jobs/koa_rdcomp_20261102/out/stand_plotyear.csv\"), colClasses = list(character = c(\"Install\", \"Plot\")))\n"
        "  tj$RDs <- SPY$SDI_qmd[match(paste(tj$source, tj$inst, tj$plot, tj$year), paste(SPY$Data, SPY$Install, SPY$Plot, SPY$Measure))] / 923; stopifnot(all(is.finite(tj$RDs) & tj$RDs > 0))   # v105d\n"
        "  tj <- tj |> mutate(pred = ht_eq2(H$coef, dbh, byi, baph, rd, RDs))")
t = rep(t, 'eq <- read_csv(file.path(J, "track3_s02/v105/02_height_equivalence.csv")', 'eq <- read_csv(file.path(J, "track3_s02/v105d/02_height_equivalence.csv")')
open(p, "w").write(t); print("fig_main patched")
p = f"{W}/a4/figs/figS12_v104.R"; backup(p); t = open(p).read()
t = rep(t, 'H <- readRDS(file.path(J, "track3_s02/v105/02_height_fit.rds"))', 'H <- readRDS(file.path(J, "track3_s02/v105d/02_height_fit.rds"))   # v105d H1a')
t = rep(t, '  p <- H$coef; pa <- (p[["a0"]] + p[["a1"]] * tj$byi / 100) * (1 - exp(-p[["b"]] * tj$dbh))^p[["c"]] * exp(p[["g1"]] * log(tj$baph + 1) + p[["g2"]] * tj$rd)',
        '  SPY <- data.table::fread(path.expand("~/jobs/koa_rdcomp_20261102/out/stand_plotyear.csv"), colClasses = list(character = c("Install", "Plot")))\n'
        '  tj$RDs <- SPY$SDI_qmd[match(paste(tj$source, tj$inst, tj$plot, tj$year), paste(SPY$Data, SPY$Install, SPY$Plot, SPY$Measure))] / 923; stopifnot(all(is.finite(tj$RDs) & tj$RDs > 0))\n'
        '  par_txt <- readLines(file.path(J, "engine_v103/koa_params.py")); pnum <- function(nm) as.numeric(sub(sprintf("^%s = ([0-9.eE+-]+).*", nm), "\\\\1", grep(sprintf("^%s = ", nm), par_txt, value = TRUE)[1]))\n'
        '  p <- H$coef; pa <- (p[["a0"]] + p[["a1"]] * tj$byi / 100) * (1 - exp(-p[["b"]] * tj$dbh))^p[["c"]] * exp(p[["g1"]] * log(pmax(tj$RDs, pnum("RD_FLOOR_HT"))) + p[["g2"]] * tj$rd)   # v105d H1a')
t = rep(t, 'stats$ht <- opst("height, HT_P v103 population average", HT$obs, HT$pa)', 'stats$ht <- opst("height, Eq. 2 H1a (v105d) population average", HT$obs, HT$pa)')
t = rep(t, '  eta <- HCB[1] + HCB[2] * sqrt(hc$HT / 100) + HCB[3] * log(pmax(hc$HT / pmax(hc$DBH, 0.1), 0.5)) + HCB[4] * sqrt(hc$BALl * hc$BAPH_hi + 1) + HCB[5] * log(hc$BAPH_hi + 1) + HCB[6] * log(pmax(hc$BYI, 1) / 100)',
        '  hc$RD <- hc$TPH_hi * (sqrt(hc$BAPH_hi / hc$TPH_hi / (pi / 40000)) / 25.4)^1.605 / 923; hc$share <- ifelse(hc$BAPH_hi > 0, hc$BALl / hc$BAPH_hi, 0); stopifnot(all(is.finite(hc$RD)))\n'
        '  eta <- HCB[1] + HCB[2] * sqrt(hc$HT / 100) + HCB[3] * log(pmax(hc$HT / pmax(hc$DBH, 0.1), 0.5)) + HCB[4] * sqrt(hc$share * hc$RD + 1) + HCB[5] * log(pmax(hc$RD, pnum("RD_FLOOR_HCB"))) + HCB[6] * log(pmax(hc$BYI, 1) / 100)   # v105d C2h')
t = rep(t, 'stats$hcb <- opst("HCB, HCB_P deployed, BAL l, repaired BAPH", HCd$obs, HCd$pa)', 'stats$hcb <- opst("HCB, Eq. 3 C2h (v105d), BAL l share x RD", HCd$obs, HCd$pa)')
open(p, "w").write(t); print("figS12 patched")
