#!/usr/bin/env python3
"""check_literals_attr.py RUN: grep the code executed by this job's pipeline for surviving literals of the replaced vectors (v105d K3c1 dDBH, K3c1h dHT,
H1a, C2h, M3a at SDImax 923) and of the 923 divisor. Comment text is reported but not failed; any code hit fails (exit 1)."""
import os, re, sys, glob
J = os.path.expanduser("~/jobs/koa_v105attr_20261103"); RUN = sys.argv[1]; W = os.path.expanduser("~/jobs/koa_v105final_20261103") if RUN == "FINAL" else f"{J}/{RUN}"
PATS = ["-0.5585878", "0.2914738", "-3.0978100", "-3.09781", "0.4772009", "-2.2559249", "0.8956536", "-1.1383338", "-1.13833", "0.3375523",
        "36.878367", "36.87836672", "1.756565", "0.045154", "0.0451544", "-0.9912204678", "0.1485828466", "-0.1504298095", "-0.6319110712",
        "-0.814302686820062", "2.08683986849611", "0.115178151642855", "-0.680325725635804", "0.0009084993576", "0.02688425903", "1.58466", "2.38913", "0.23463, 0.76098", "0.17619", "36.542911", "1.734106", "0.045727", "-0.9295571021", "0.1191977462", "-0.1492764358"]
P923 = re.compile(r"(/\s*923\b|\b923\.0\b|<-\s*923\b|=\s*923\b)")
SCOPE = ["engine_v103/*.py", "a2/registry/engine/*.py", "a2/registry/engine_nocal/*.py", "a2/*.py", "a2/*.sh", "a2/mort/*.py", "a2/closeout/validation/*.py", "a2/fin/*.py",
         "a2/registry/*.py", "a2/registry/*.sh", "a2/registry/*/*.py", "a2/registry/*/*.R", "a2/figs/scripts/lt_v103.py", "a4/*.R", "a4/*.py", "a4/*.sh", "a4/bakuzis/bakuzis_v105_vs_v104.R",
         "a5/rerun/cov/*.py", "a5/rerun/cov/*.sh", "track2/inc/inc_v103.R", "v105d/realism_check_d.py", "v105d/set_mortcal_v105d.py", "a5/pairmc/*.py", "a5/pairmc/*.R", "a5/loio/*.py", "a5/loio/*.R", "a4/figs/fig_main_v104.R", "a4/figs/figS12_v104.R", "a4/figs/figS34_v104.R", "stageB/boot_resolve_dht_v105.R", "track2/inc/boot_v103.R"]
files = sorted({f for s in SCOPE for f in glob.glob(f"{W}/{s}") if "_PREV_" not in f and ".bak" not in f})
code, comm = [], []
for f in files:
    for i, line in enumerate(open(f, errors="replace"), 1):
        hit = [p for p in PATS if p in line] + (["923"] if P923.search(line) else [])
        if not hit: continue
        body = line.split("#", 1)[0]
        incode = [p for p in PATS if p in body] + (["923"] if P923.search(body) else [])
        s = body.strip()
        if s.startswith(('"""', "'''")) or (s.startswith('"') and s.endswith('"')): incode = []
        if f.endswith("HiGy.R"):   # FVS-HI R mirror: not executed by any script of this pipeline (Python engine of record; v105d RUN note 2)
            comm.append(("ALLOWED-not-executed " + os.path.relpath(f, W), i, ",".join(hit), line.strip()[:160])); continue
        (code if incode else comm).append((os.path.relpath(f, W), i, ",".join(incode or hit), line.strip()[:160]))
print(RUN, "files scanned", len(files))
for c in comm: print("COMMENT", *c)
for c in code: print("CODE", *c)
print("LITERALS", "PASS" if not code else "FAIL", "code hits", len(code), "comment hits", len(comm))
sys.exit(1 if code else 0)
