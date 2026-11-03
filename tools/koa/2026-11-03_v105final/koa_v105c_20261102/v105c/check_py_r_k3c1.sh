#!/bin/bash
# K3c1 consistency: one-step increment of the fitting recursion (inc_v103.R pa_pred, K3c1 columns) vs the engine LineageA.dDBH (K3c1, RD from the engine sdi)
# divided by CF x CAL, on the YIP = 1 rows of the dDBH NO frame, deployed vector. Rows where the engine cap binds are excluded.
cd ~/jobs/koa_v105c_20261102
Rscript --vanilla -e 'src <- readLines("track2/inc/inc_v103.R"); commandArgs <- function(trailingOnly = TRUE) "none"; suppressPackageStartupMessages(library(nlme)); eval(parse(text = src[1:112])); GUARD <- 45
d <- model_cols(read.csv("frames/final/dDBH_NO_v103_model.csv", stringsAsFactors = FALSE), "l"); d <- d[d$YIP == 1, ]; J <- jsonlite::fromJSON("out/v105_constants.json"); b <- unlist(J$DDBH$coef)[paste0("b", 0:9)]
d$r_inc <- pa_pred("dDBH", d, b); write.csv(d[, c("DBH.0", "BAPH.0", "BALx.0", "CRx.0", "BYI", "Planted", "TPH.0", "QMD.0", "r_inc")], "v105c/out/k3c1_check_rows.csv", row.names = FALSE); cat("rows", nrow(d), "\n")'
python3 - <<'P'
import os, sys, numpy as np, pandas as pd
E = os.path.expanduser("~/jobs/koa_v105c_20261102/engine_v103"); sys.path.insert(0, E); os.chdir(E)
import koa_params as KP, koa_equations as KE, koa_projector as PR
D = pd.read_csv("../v105c/out/k3c1_check_rows.csv"); L = KE.LineageA
sdi = PR.sdi_of(D["TPH.0"].values, D["QMD.0"].values)
cal = np.where(D.Planted.values == 1, L.CAL_DDBH[1], L.CAL_DDBH[0])
py = L.dDBH(D["DBH.0"].values, D["BAPH.0"].values, D["BALx.0"].values, D["CRx.0"].values, D["BYI"].values, D["Planted"].values, sdi=sdi) / (L.CF_DDBH * cal)
ok = (py * L.CF_DDBH * cal) < L.ddbh_cap - 1e-12
rel = np.abs(py[ok] / D.r_inc.values[ok] - 1)
print("DDBH_FORM", KP.DDBH_FORM, "rows", len(D), "cap binds", int((~ok).sum()), "max rel diff engine vs fit recursion", rel.max(), "median", np.median(rel))
pd.DataFrame(dict(check=["K3c1 engine vs fitting recursion, one step, max relative diff"], rows=[int(ok.sum())], value=[float(rel.max())])).to_csv("../v105c/out/k3c1_engine_vs_fit.csv", index=False)
P
