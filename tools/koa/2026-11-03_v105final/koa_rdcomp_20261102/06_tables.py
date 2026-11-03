#!/usr/bin/env python3
"""06_tables.py: markdown tables for RESULTS.md from out/results_table.csv and out/coefficients.csv (no new numbers)."""
import csv
T = list(csv.DictReader(open("out/results_table.csv"))); C = list(csv.DictReader(open("out/coefficients.csv")))
def f(x, n=3):
    try: return f"{float(x):.{n}f}"
    except: return "NA"
def ci(r):
    return "not run" if r["boot_n"] in ("0", "0.0", "NA", "") else f'{f(r["b8_lo"])} to {f(r["b8_hi"])} ({int(float(r["boot_n"]))}/200)'
out = []
for resp in ("dDBH", "dHT"):
    key = "40-60 cm" if resp == "dDBH" else "20-30 m"
    out.append(f"\n### {resp}\n")
    out.append(f"| cand | logLik | dAIC | signs | b3 | b4 | b6 | b8 (C2) | b8 boot 95% | LOSO RMSE DOFAW / FIA / KMR PSP / PSP | better (of 4) | ratio all | ratio {key} | ratio BAL Q1..Q5 | verdict |")
    out.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for r in [x for x in T if x["resp"] == resp]:
        sg = "pass" if r["sign_pass"] == "TRUE" else "FAIL (" + ",".join(s.split()[0] for s in r["sign_detail"].split(";") if s.endswith("FALSE")) + ")"
        lo = " / ".join(f(r[k], 4) for k in ("loso_DOFAW", "loso_FIA", "loso_KMRPSP", "loso_PSP"))
        q = " / ".join(f(r[f"ratio_BALQ{i}"]) for i in range(1, 6))
        out.append(f'| {r["cand"]} | {f(r["logLik"])} | {f(r["dAIC"], 2)} | {sg} | {float(r["b3"]):.4g} | {f(r["b4"], 4)} | {f(r["b6"], 4)} | {f(r["b8"], 4)} | {ci(r)} | {lo} | {r["n_better"]} ({r["better_sources"] or "-"}) | {f(r["ratio_all"])} | {f(r["ratio_size_key"])} | {q} | {r["verdict"]} |')
    out.append("\nReasons:\n")
    for r in [x for x in T if x["resp"] == resp and x["cand"] != "K0"]: out.append(f'- {r["cand"]}: {r["reasons"]}')
out.append("\n### Bootstrap 95% intervals, all terms (candidates bootstrapped)\n")
out.append("| resp | cand | term | estimate (model SE) | boot 95% (converged) |"); out.append("|---|---|---|---|---|")
for c in C:
    if c["boot_n"] in ("0", "0.0", "NA", ""): continue
    out.append(f'| {c["resp"]} | {c["cand"]} | {c["term"]} | {float(c["est"]):.5g} ({float(c["se"]):.3g}) | {float(c["boot_lo"]):.5g} to {float(c["boot_hi"]):.5g} ({int(float(c["boot_n"]))}) |')
open("out/results_tables.md", "w").write("\n".join(out) + "\n"); print("\n".join(out[:12]))
