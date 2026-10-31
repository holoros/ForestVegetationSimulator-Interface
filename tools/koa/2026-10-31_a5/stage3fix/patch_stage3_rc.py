"""A5-D1 (2026-10-31): make run_candidates.project and regen_figS4S5 read the A4-D3 Stage 3 ordering vector
(koa_params.STAGE3_COEF) instead of the hard-coded 4,911-record vector. Backups *_PREV_20261031."""
import re, shutil, sys, os
OLD = re.compile(r"-2\.13468022306448 \+ -0\.818899541466801 \* np\.log\(np\.maximum\(dbh, 0\.1\)\) \+ -0\.813105157217597 \* rht \+ 0\.382953931412773 \* np\.log\(baph \+ 1\.0\) \+ 0\.346317281270796 \* np\.log\(np\.maximum\(bal, 0\.0\) \+ 1\.0\)")
NEW = "P.STAGE3_COEF['c0'] + P.STAGE3_COEF['c1'] * np.log(np.maximum(dbh, 0.1)) + P.STAGE3_COEF['c2'] * rht + P.STAGE3_COEF['c3'] * np.log(baph + 1.0) + P.STAGE3_COEF['c4'] * np.log(np.maximum(bal, 0.0) + 1.0)"
for eng in ["engine_v103", "a2/registry/engine", "a2/registry/engine_nocal"]:
    for f in ["run_candidates.py", "regen_figS4S5.py"]:
        p = os.path.join(eng, f); s = open(p).read(); n = len(OLD.findall(s))
        if n == 0: print("NOMATCH", p); continue
        if "import koa_params as P" not in s: print("NO_P_IMPORT", p)
        b = p + "_PREV_20261031"
        if not os.path.exists(b): shutil.copy2(p, b)
        open(p, "w").write(OLD.sub(NEW, s)); print("patched", p, n)
