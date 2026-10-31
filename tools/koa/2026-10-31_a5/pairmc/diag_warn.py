# a5/pairmc: attribute the renormalize_to_stand_rate warnings of the first A5 main run to variants (reps 3 and 6, worker 0 order)
import os, sys, warnings
sys.argv = ["x"]; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pairmc_a5 as M
import numpy as np
M.P.JOINT_DRAWS_FILE = M.JOINT_1K; M.KE._JOINT[0] = None
al, cf = M.streams(10); D = np.load(M.PREP); BD, BH, H = M.load_boot()
for r in (0, 3, 6, 9):
    for var in ("P", "PP", "PPB", "B"):
        for o in M.ORIG:
            for j, lev in enumerate(M.LEVELS):
                if var == "B": M.R.set_params(None)
                else: M.set_rep(r, al[r], cf[r])
                kw = {}
                if var in ("PP", "PPB"):
                    kw = dict(fD=M.mult(D["I_D"][r, o, j], M.TAU["I_D"]), fH=M.mult(D["I_H"][r, o, j], M.TAU["I_H"]), tD=M.mult(D["T_D"][r, o, j], M.TAU["T_D"]), tH=M.mult(D["T_H"][r, o, j], M.TAU["T_H"]))
                b = float(D["byi"][r, o, j]) if var in ("PPB", "B") else float(lev)
                with warnings.catch_warnings(record=True) as w:
                    warnings.simplefilter("always"); M.run(o, b, **kw)
                n = sum("failed to bracket" in str(x.message) for x in w)
                if n: print("rep", r, var, "planted", o, "level", lev, "warnings", n, flush=True)
print("diag done")
