#!/usr/bin/env python3
"""patch_inc_v105d.py: dHT RD x competition forms in track2/inc/inc_v103.R (and boot_v103.R, which evaluates the same block).
Switch DHT_FORM (env KOA_DHT_FORM, default "K3c1h"; "v105b" restores the v105b/v105c dHT form; "K3p" = koa_rdcomp_20261102 K3p with b3 free):
x = (BALl/BAPH) RD in the b4 (and K3p b3) term, RD in the b6 term (the K3c1 columns XK, RD already built for every NO frame with TPH/QMD).
K3c1h: b3 fixed at 0 (constrained analogue of the dDBH K3c1, koa_rdcomp_20261102/constrained). Line count unchanged."""
import os, subprocess
W = os.path.expanduser("~/jobs/koa_v105d_20261102"); p = f"{W}/track2/inc/inc_v103.R"
subprocess.run(["bash", f"{W}/v105d/backup_d.sh", p], check=True)
t = open(p).read(); n0 = len(t.split("\n"))
def rep(old, new, n=1):
    global t; assert t.count(old) == n, (t.count(old), old[:80]); t = t.replace(old, new)
K3P = "c(b0 = -2.20353420728778, b1 = 0.89683183130556, b2 = -0.111469907293064, b3 = 0.116464450588204, b4 = -1.19019622294889, b5 = 0.222612960320726, b6 = 0.332319984100771, b7 = -0.111161161933452, b8 = 0.109859490697339, b9 = 0.641132772863902)"
rep('k3c_on <- function(resp, d) resp == "dDBH" && DDBH_FORM == "K3c1" && all(c("XK.0", "XK.1", "RD.0", "RD.1") %in% names(d)); ',
    'DHT_FORM <- Sys.getenv("KOA_DHT_FORM", "K3c1h"); START_K3C1H <- ' + K3P + '; '   # v105d: start = koa_rdcomp K3p dHT vector (b3 dropped for K3c1h)
    'k3c_on <- function(resp, d) ((resp == "dDBH" && DDBH_FORM == "K3c1") || (resp == "dHT" && DHT_FORM %in% c("K3c1h", "K3p"))) && all(c("XK.0", "XK.1", "RD.0", "RD.1") %in% names(d)); '
    'k3c_b3zero <- function(resp) resp == "dDBH" || DHT_FORM == "K3c1h"; ')
rep('  k <- k3c_on(resp, d); f3 <- as.formula(sprintf(if (k) "%s ~ gr.hat3(',
    '  k <- k3c_on(resp, d); z <- k && k3c_b3zero(resp); f3 <- as.formula(sprintf(if (k) sub(", b0, b1, b2, 0, b4", if (z) ", b0, b1, b2, 0, b4" else ", b0, b1, b2, b3, b4", fixed = TRUE, x = "%s ~ gr.hat3(')
rep('Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, 0, b4, b5, b6, b7, b8, b9)" else "%s ~ gr.hat3(',
    'Planted = Planted, rain = BYI, n = YIP, b0, b1, b2, 0, b4, b5, b6, b7, b8, b9)") else "%s ~ gr.hat3(')
rep('if (k && identical(start, START[[resp]])) start <- START_K3C1\n', 'if (k && identical(start, START[[resp]])) start <- if (resp == "dDBH") START_K3C1 else START_K3C1H   # v105d dHT start\n')
rep('nlme(f3, data = d, fixed = if (k) b0 + b1 + b2 + b4', 'nlme(f3, data = d, fixed = if (z) b0 + b1 + b2 + b4')
rep('random = rnd, start = if (k) start[c("b0", "b1", "b2", "b4"', 'random = rnd, start = if (z) start[c("b0", "b1", "b2", "b4"')
rep('if (k) 0 else b["b3"]', 'if (k && k3c_b3zero(resp)) 0 else b["b3"]')
assert len(t.split("\n")) == n0; open(p, "w").write(t); print("inc_v103.R patched for DHT_FORM; lines", n0)
