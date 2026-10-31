#!/usr/bin/env bash
# rebuild numbers_v104.json, the comparison md and the gate section in order
cd $HOME/jobs/koa_v104_20261030/a2/registry
python3 koa_numbers_v104.py > logs/koa_numbers_v104.log 2>&1
python3 compare_v104_vs_v103.py > logs/compare_v104_vs_v103.log 2>&1
python3 gate_v104.py > logs/gate_v104.log 2>&1
python3 - <<'P'
import pandas as pd
R='/home/aaron/jobs/koa_v104_20261030/a2/registry'
D=pd.read_csv(f'{R}/build/gate_v104.csv')
with open(f'{R}/numbers_v104_vs_v103.md','a') as f:
    f.write(f"\n## Gate: headline numbers derived two independent ways ({int(D.agree.sum())} of {len(D)} agree)\n\n| quantity | way A | source A | way B | source B | relative difference | agree |\n|---|---|---|---|---|---|---|\n")
    for r in D.itertuples(): f.write(f"| {r.quantity} | {r.way_a:.6g} | {r.source_a} | {r.way_b:.6g} | {r.source_b} | {r.rel_diff:.2e} | {r.agree} |\n")
P
