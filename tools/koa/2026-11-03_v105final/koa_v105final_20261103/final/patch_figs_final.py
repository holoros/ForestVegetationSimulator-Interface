#!/usr/bin/env python3
"""patch_figs_final.py: Fig. 3 (a4/figs/fig_main_v104.R) and Fig. S1 (figS12_v104.R) for the final engine (v105final = D742 with Eq. 2 reverted to the
v105c form). Increment curves keep the deployed K3c1 dDBH / K3c1h dHT forms (FORMS read from koa_params), with RD of the fixed stand divided by the
engine's DDBH_RD_SDIMAX (brms 741.997) in place of 923. Height panels revert to the v105c Eq. 2 code (ln(BAPH+1); track3_s02/v105 fit, = deployed HT_P;
the code is copied from koa_v105c_20261102/a4/figs). HCB panel keeps C2h with RD = SDI/DDBH_RD_SDIMAX. Each replacement asserts exactly one match."""
import os, re
F = os.path.expanduser("~/jobs/koa_v105final_20261103/a4/figs")
def sub1(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:90]); return t.replace(a, b)
p = f"{F}/fig_main_v104.R"; t = open(p).read(); open(p.replace(".R", "_PREV_v105d.R"), "w").write(t)
t = sub1(t, "RD30 <- (30 / (pi / 40000 * 25^2)) * (25 / 25.4)^1.605 / 923   # v105d", "SDIMAX <- py_scalar(par_txt, \"DDBH_RD_SDIMAX\"); stopifnot(abs(SDIMAX - 741.996871565) < 1e-6)   # v105final: brms SDImax of record\n  RD30 <- (30 / (pi / 40000 * 25^2)) * (25 / 25.4)^1.605 / SDIMAX   # v105final")
old_h = re.search(r"  H <- readRDS\(file\.path\(J, \"track3_s02/v105d/02_height_fit\.rds\"\)\);.*?\n", t).group(0)
t = sub1(t, old_h, "  H <- readRDS(file.path(J, \"track3_s02/v105/02_height_fit.rds\")); stopifnot(py_str(par_txt, \"HT_FORM\") == \"v105b\"); stopifnot(max(abs(H$coef[names(HT_P)] - HT_P)) < 1e-5)   # v105final: v105c Eq. 2\n")
old_e = re.search(r"  ht_eq2 <- function\(p, dbh, byi, baph, rd, RDs = RD30\).*?\n", t).group(0)
t = sub1(t, old_e, "  ht_eq2 <- function(p, dbh, byi, baph, rd) (p[[\"a0\"]] + p[[\"a1\"]] * byi / 100) * (1 - exp(-p[[\"b\"]] * dbh))^p[[\"c\"]] * exp(p[[\"g1\"]] * log(baph + 1) + p[[\"g2\"]] * rd)   # v105final: v105c Eq. 2 (ln(BAPH+1))\n")
old_r = re.search(r"  tj\$RDs <- SPY\$SDI_qmd.*?\n", t).group(0); t = sub1(t, old_r, "")
t = sub1(t, "pred = ht_eq2(H$coef, dbh, byi, baph, rd, RDs)", "pred = ht_eq2(H$coef, dbh, byi, baph, rd)")
t = sub1(t, "track3_s02/v105d/02_height_equivalence.csv", "track3_s02/v105/02_height_equivalence.csv")
assert "923" not in re.sub(r"#.*", "", t), "923 left in fig_main"
open(p, "w").write(t)
p = f"{F}/figS12_v104.R"; t = open(p).read(); open(p.replace(".R", "_PREV_v105d.R"), "w").write(t)
t = sub1(t, "  H <- readRDS(file.path(J, \"track3_s02/v105d/02_height_fit.rds\"))   # v105d H1a", "  H <- readRDS(file.path(J, \"track3_s02/v105/02_height_fit.rds\"))   # v105final: v105c Eq. 2")
old = re.search(r"  tj\$RDs <- SPY\$SDI_qmd.*?\n", t).group(0); t = sub1(t, old, "")
t = sub1(t, "  par_txt <- readLines(file.path(J, \"engine_v103/koa_params.py\"));", "  par_txt <- readLines(file.path(J, \"engine_v103/koa_params.py\")); SDIMAX <- as.numeric(sub(\"^DDBH_RD_SDIMAX = ([0-9.eE+-]+).*\", \"\\\\1\", grep(\"^DDBH_RD_SDIMAX = \", par_txt, value = TRUE)[1])); stopifnot(abs(SDIMAX - 741.996871565) < 1e-6);")
old = re.search(r"  p <- H\$coef; pa <- .*?# v105d H1a\n", t).group(0)
t = sub1(t, old, "  p <- H$coef; pa <- (p[[\"a0\"]] + p[[\"a1\"]] * tj$byi / 100) * (1 - exp(-p[[\"b\"]] * tj$dbh))^p[[\"c\"]] * exp(p[[\"g1\"]] * log(tj$baph + 1) + p[[\"g2\"]] * tj$rd)   # v105final: v105c Eq. 2\n")
t = sub1(t, "\"height, Eq. 2 H1a (v105d) population average\"", "\"height, Eq. 2 v105c form (ln(BAPH+1)), v105final population average\"")
t = sub1(t, "(pi / 40000)) / 25.4)^1.605 / 923;", "(pi / 40000)) / 25.4)^1.605 / SDIMAX;")
t = t.replace("\"HCB, Eq. 3 C2h (v105d), BAL l share x RD\"", "\"HCB, Eq. 3 C2h (RD = SDI/741.997), BAL l share x RD\"")
assert "/ 923" not in re.sub(r"#.*", "", t), "923 left in figS12"
open(p, "w").write(t); print("FIG PATCH DONE")
