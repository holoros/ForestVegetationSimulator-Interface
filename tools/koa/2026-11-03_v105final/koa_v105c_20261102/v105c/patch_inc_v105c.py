#!/usr/bin/env python3
"""patch_inc_v105c.py: implement the adopted K3c1 dDBH form (koa_rdcomp_20261102/constrained/PREREG_K3c.md) in track2/inc/inc_v103.R and boot_v103.R.
K3c1: x = (BALl/BAPH) x RD in the b4 term, RD in the b6 term, RD = SDI/923, SDI = TPH (QMD/25.4)^1.605 (TPH 0 -> 0), b3 fixed at 0.
Switch DDBH_FORM (env KOA_DDBH_FORM, default "K3c1"; "v105b" restores the deployed v105b form exactly). Applies to dDBH frames that carry TPH/QMD (the NO frames);
CS frames (no stand columns) keep the v105b form. Lines 1-112 keep their count (consumers evaluate src[1:112] or HCB_P..taus)."""
import os, re, subprocess
W = os.path.expanduser("~/jobs/koa_v105c_20261102"); p = f"{W}/track2/inc/inc_v103.R"
subprocess.run(["bash", f"{W}/v105c/backup_c.sh", p, f"{W}/track2/inc/boot_v103.R"], check=True)
L = open(p).read().split("\n"); n0 = len(L)
def rep(i, old, new):
    assert L[i - 1].count(old) == 1, (i, old[:60], L[i - 1][:120]); L[i - 1] = L[i - 1].replace(old, new)
assert L[63].endswith("& d$CRx.0 > 0 & d$CRx.1 > 0, ]; d }"), L[63]
rep(64, "& d$CRx.0 > 0 & d$CRx.1 > 0, ]; d }", "& d$CRx.0 > 0 & d$CRx.1 > 0, ]; k3c_cols(d) }   # v105c: K3c1 columns added when the frame carries TPH/QMD")
assert L[66].startswith("  gr.hat3(size, d$BALx.0, d$BALx.1, d$CRx.0, d$CRx.1, d$BAPH.0, d$BAPH.1,"), L[66]
L[66] = ('  k <- k3c_on(resp, d); gr.hat3(size, if (k) d$XK.0 else d$BALx.0, if (k) d$XK.1 else d$BALx.1, d$CRx.0, d$CRx.1, if (k) d$RD.0 else d$BAPH.0, if (k) d$RD.1 else d$BAPH.1, '
         'd$Planted, d$BYI, d$YIP, b["b0"], b["b1"], b["b2"], if (k) 0 else b["b3"], b["b4"], b["b5"], b["b6"], b["b7"], b["b8"], b["b9"]) }   # v105c K3c1 switch')
assert L[103] == "", repr(L[103])
L[103] = ('DDBH_FORM <- Sys.getenv("KOA_DDBH_FORM", "K3c1"); SDIMAX_POP <- 923; '   # v105c (K3c1 adopted, PREREG_K3c); "v105b" restores the deployed form
  'START_K3C1 <- c(b0 = -0.54141063693918268, b1 = 0.3621753596463001, b2 = -0.022054909414051985, b3 = 0, b4 = -2.2593632745658652, b5 = 0.83966241962506827, '
  'b6 = -0.12255255004315455, b7 = -0.017816201367110273, b8 = 0.27793350329740146, b9 = 0.24552687012503349); '
  'k3c_cols <- function(d) { if (!all(c("TPH.0", "TPH.1", "QMD.0", "QMD.1") %in% names(d))) return(d); '
  's0 <- ifelse(d$TPH.0 > 0 & is.finite(d$QMD.0), d$TPH.0 * (d$QMD.0 / 25.4)^1.605, 0); s1 <- ifelse(d$TPH.1 > 0 & is.finite(d$QMD.1), d$TPH.1 * (d$QMD.1 / 25.4)^1.605, 0); '
  'd$SDIk.0 <- s0; d$SDIk.1 <- s1; d$RD.0 <- s0 / SDIMAX_POP; d$RD.1 <- s1 / SDIMAX_POP; '
  'd$XK.0 <- ifelse(d$BAPH.0 > 0, d$BALx.0 / d$BAPH.0, 0) * d$RD.0; d$XK.1 <- ifelse(d$BAPH.1 > 0, d$BALx.1 / d$BAPH.1, 0) * d$RD.1; d }; '
  'k3c_on <- function(resp, d) resp == "dDBH" && DDBH_FORM == "K3c1" && all(c("XK.0", "XK.1", "RD.0", "RD.1") %in% names(d)); '
  'fixef <- function(object, ...) { b <- nlme::fixef(object, ...); if (is.numeric(b) && all(paste0("b", c(0:2, 4:9)) %in% names(b)) && !("b3" %in% names(b))) '
  'b <- c(b[c("b0", "b1", "b2")], b3 = 0, b[paste0("b", 4:9)]); b }   # v105c: K3c1 fits have no b3 parameter; b3 = 0 is reported')
assert L[106].startswith('  f3 <- as.formula(sprintf("%s ~ gr.hat3(d1 = %s, bal1 = BALx.0'), L[106]
L[106] = ('  k <- k3c_on(resp, d); f3 <- as.formula(sprintf(if (k) "%s ~ gr.hat3(d1 = %s, bal1 = XK.0, bal2 = XK.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = RD.0, bapa2 = RD.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, 0, b4, b5, b6, b7, b8, b9)" else '
          '"%s ~ gr.hat3(d1 = %s, bal1 = BALx.0, bal2 = BALx.1, cr1 = CRx.0, cr2 = CRx.1, bapa1 = BAPH.0, bapa2 = BAPH.1, Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9)", resp, size)); '
          'if (k && identical(start, START[[resp]])) start <- START_K3C1')
assert L[108].startswith("  nlme(f3, data = d, fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = rnd, start = start,"), L[108]
rep(109, "fixed = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = rnd, start = start,",
    'fixed = if (k) b0 + b1 + b2 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1 else b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 ~ 1, random = rnd, start = if (k) start[c("b0", "b1", "b2", "b4", "b5", "b6", "b7", "b8", "b9")] else start,')
assert L[110].startswith("taus <- function(m)"), L[110]
# frames: stand columns for the NO frames
t = "\n".join(L)
old = "BAPH.0 = x$BAPH[i], BAPH.1 = x$BAPH[j], BAPH_dep.0"
assert t.count(old) == 1; t = t.replace(old, "BAPH.0 = x$BAPH[i], BAPH.1 = x$BAPH[j], TPH.0 = x$TPH[i], TPH.1 = x$TPH[j], QMD.0 = x$QMD[i], QMD.1 = x$QMD[j], BAPH_dep.0")
old = 'if (fr == "NO") keep <- c(keep, "firstlast", "BAPH_dep.0", "BAPH_dep.1")'
assert t.count(old) == 1; t = t.replace(old, 'if (fr == "NO") keep <- c(keep, "firstlast", "BAPH_dep.0", "BAPH_dep.1", "TPH.0", "TPH.1", "QMD.0", "QMD.1")   # TPH/QMD added v105c (K3c1 RD)')
old = "bb <- fixef(m); s <- summary(m)$tTable;"
assert t.count(old) == 1; t = t.replace(old, 'bb <- fixef(m); s <- summary(m)$tTable; if (!("b3" %in% rownames(s))) s <- rbind(s[1:3, , drop = FALSE], b3 = c(0, 0, NA, NA), s[4:nrow(s), , drop = FALSE]);')
assert len(t.split("\n")) == n0
open(p, "w").write(t); print("inc_v103.R patched; lines", n0)
# boot_v103.R: replace its private machinery by the patched inc_v103.R block (HCB_P .. taus)
b = f"{W}/track2/inc/boot_v103.R"; s = open(b).read()
old = '\nload(file.path(OUT, "fits_v103.rda")); tag <- DEC$deployed[DEC$resp == resp]'
assert s.count(old) == 1
s = s.replace(old, '\nsrc <- readLines(file.path(W, "track2/inc/inc_v103.R")); eval(parse(text = src[grep("^HCB_P <- c\\\\(", src)[1]:grep("^taus <- function", src)[1]]))   # v105c: K3c1-aware machinery of inc_v103.R\n'
              'load(file.path(OUT, "fits_v103.rda")); tag <- DEC$deployed[DEC$resp == resp]')
s = s.replace('m <- tryCatch(fit_one(resp, dd, cal$frame, start = cal$b), error = function(e) NULL)', 'm <- tryCatch(fit_one(resp, dd, cal$frame, start = cal$b), error = function(e) NULL)   # cal$b carries b3 = 0 for K3c1')
open(b, "w").write(s); print("boot_v103.R patched")
