#!/usr/bin/env python3
"""check_literals_v105d.py: fail loudly (exit 1) if any literal of the replaced v105c vectors (Eq. 2 HT_P, Eq. 3 HCB_P, dHT_L_NO, STAGE3_COEF) or a
v105b-form Stage 3 expression survives in the active code: engine_v103 (+ registry engine copies), and every .py/.R/.sh under a2, a4, a5, track2, scripts
except archives and regenerated copies (pairmc/engine_a5/ is deleted and recopied from engine_v103 by run_pairmc_v105.sh; closeout/validation/engine_v102 is the v102 before-engine; export/, pr/, loio/engines/, pairmc/engine/ (stale v104 copy), s28/engine, closeout/*/engine, higy/engine, registry/v102_scripts) and _PREV_ backups.
Allowed hits are listed with their reason in ALLOW (printed); everything else fails."""
import os, re, sys
W = os.path.expanduser("~/jobs/koa_v105d_20261102")
PAT = {"HT_P a0": r"28\.9904|28\.99042", "HT_P a1": r"1\.142886|1\.1428857", "HT_P g1": r"0\.076841(?!0)|0\.07684058", "HCB_P b0/b1/b4": r"0\.1684\b|1\.0146\b|-0\.3734\b",
       "dHT b0/b1/b6/b9": r"-2\.2488611|-2\.24886113|1\.1616505|0\.0642563|0\.06425626|0\.6930402|0\.69304021", "STAGE3 c0/c3/c4": r"-2\.45353544|0\.80187372|0\.16426374",
       "Stage 3 v105b expression": r"STAGE3_COEF\['c3'\] \* np\.log\(baph"}
SKIP = re.compile(r"_PREV_|/export/|/pr/|/loio/engines/|/pairmc/engine/|/pairmc/engine_a5/|/closeout/validation/engine_v102/|/s28/engine/|/closeout/[^/]+/engine/|/higy/engine/|/registry/v102_scripts/|/__pycache__/|\.py_PREV|/stageB/|/repair_v105b/|/track3_rt/|/a3/")
ALLOW = {  # path suffix -> reason
  "track2/inc/inc_v103.R": "HCB_P builds the crown ratio of the increment fitting frames (kept: v105c frames, declared); dHT START of the v103 candidate fits",
  "track2/inc/boot_v103.R": "same HCB_P frame block as inc_v103.R; private copy overwritten at run time by the inc_v103.R block (v105c patch)",
  "track2/hcb/hcb_v103.R": "historical HCB_P fit script (v103), not run",
  "track2/height_refit_v105.R": "historical v105b height partial-refit script (gate literal), not run",
  "track2/height_refit_v103.R": "historical v103 height refit, not run (its lines 1-33 define prep() only)",
  "a5/rerun/h/h_boot_v105.R": "v105b height bootstrap script, superseded by a5/rerun/h/h_boot_v105d.R",
  "a5/rerun/h/h_boot_v105d.R": "V104 shape vector: b, c, g2 are held at v104 in H1a (g1 of V104 not used; H1a start read from prep/out)",
  "engine_v103/HiGy.R": "FVS-HI mirror, v105d forms not mirrored (header note)", "a2/registry/engine/HiGy.R": "registry copy of the HiGy.R mirror",
  "a2/registry/engine_nocal/HiGy.R": "registry copy of the HiGy.R mirror",
  "scripts/make_report.py": "v103 report builder (historical), not run in v105d",
  "a2/patch_engine_v103.py": "historical v103 patch script, not run", "a2/patch_higy_v103.py": "historical v103 patch script, not run",
  "a4/patch_engine_v104.py": "historical v104 patch script, not run", "a5/stage3fix/patch_stage3_rc.py": "historical A5 Stage 3 patch script, not run"}
hits = []; allowed = []
roots = ["engine_v103", "a2", "a4", "a5", "track2", "scripts"]
for r0 in roots:
    for dp, dn, fn in os.walk(f"{W}/{r0}"):
        for f in fn:
            if not f.endswith((".py", ".R", ".sh")): continue
            p = os.path.join(dp, f); rel = os.path.relpath(p, W)
            if SKIP.search("/" + rel): continue
            if r0 == "engine_v103" and "/" in rel[len("engine_v103/"):] : continue
            try: t = open(p, errors="replace").read()
            except Exception: continue
            for k, pat in PAT.items():
                for m in re.finditer(pat, t):
                    line = t[:m.start()].count("\n") + 1; ln = t.split("\n")[line - 1].strip()
                    if ln.startswith("#") or ln.startswith("##"): continue
                    rec = (rel, line, k, ln[:140])
                    (allowed if rel in ALLOW else hits).append(rec)
for a in sorted(set(x[0] for x in allowed)): print("ALLOWED", a, "|", ALLOW[a])
for h in hits: print("HIT", *h)
print("LITERALS", "FAIL" if hits else "PASS", "hits", len(hits), "allowed files", len(set(x[0] for x in allowed)))
sys.exit(1 if hits else 0)
