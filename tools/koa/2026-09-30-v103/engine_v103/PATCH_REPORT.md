## refit copy: /home/aaron/jobs/koa_origin_20260916/output/engine_origin

- run_candidates.py: `expf_new = np.maximum(expf * ps, 1e-5)` -> `expf_new = np.maximum(expf * ps, 1e-5)
        _mort_ba = float(np.sum((dbh ** 2 *`
- run_candidates.py: `bal_conv=float(np.sum(bal_conv * expf) / max(np.sum(expf), 1e-9))` -> `bal_conv=float(np.sum(bal_conv * expf) / max(np.sum(expf), 1e-9))`
- run_candidates.py: `d["VOL"] = d.BAPH * d.HT * 0.40` -> `d["VOL"] = d.BAPH * d.HT * 0.40
    d["MORT_VOL"] = d.MORT_BA * d.HT * 0.40   # output`
- koa_projector.py: `traj = []; recs = []` -> `traj = []; recs = []; _mortba = []; _dbhmax = []`
- koa_projector.py: `if return_traj:
            traj.append((baph, tph, qmd, sdi))` -> `if return_traj:
            traj.append((baph, tph, qmd, sdi)); _dbhmax.append(flo`
- koa_projector.py: `expf = np.maximum(expf*ps, 1e-5)` -> `_eo = expf
        expf = np.maximum(expf*ps, 1e-5)
        _mortba.append(float((`
- koa_projector.py: `tj["ingrowth"] = recs[:len(tj)]` -> `tj["ingrowth"] = recs[:len(tj)]
        tj["MORT_BA"] = _mortba[:len(tj)]; tj["DBH`
- regenerate_uneven_aged.py: `tj2["MAI"] = tj2["Vol"]/tj2["age"]` -> `tj2["MAI"] = tj2["Vol"]/tj2["age"]
        tj2["MORT_VOL"] = tj2["MORT_BA"] * tj2[`
- regen_m1.py: `d = RC.project(RC.wlist(planted, byi), byi, bool(planted), 100, "M0")` -> `d = RC.project(RC.wlist(planted, byi), byi, bool(planted), 100, "M0")`
- regen_m1.py: `def table8_evenaged():` -> `_REPS = []


def table8_evenaged():`
- regen_m1.py: `T.to_csv(os.path.join(OUT, "table8_evenaged_M1.csv"), index=False)` -> `T.to_csv(os.path.join(OUT, "table8_evenaged_M1.csv"), index=False)
    pd.concat(_REPS`
- regen_m1.py: `for f in ("uneven_aged_table8.csv", "uneven_aged_traj.csv"):` -> `for f in ("uneven_aged_table8.csv", "uneven_aged_traj.csv", "uneven_aged_reps.csv"):`
- regenerate_uneven_aged.py: `vr, _, _, _ = guarded_vol(byi, tjr)` -> `vr, _, _, _ = guarded_vol(byi, tjr)
            _UREPS.append(pd.DataFrame(dic`
- regenerate_uneven_aged.py: `def main():` -> `_UREPS = []


def main():`
- regenerate_uneven_aged.py: `pd.concat(trajs).to_csv("uneven_aged_traj.csv", index=False)` -> `pd.concat(trajs).to_csv("uneven_aged_traj.csv", index=False)
    pd.concat(_UREPS, ign`

Refit vector: a0 30.188188, a1 1.426287, b 0.018401, c 0.817994, g1 0.051108, g2 -0.35086
MC standard errors: a0 1.358658, a1 0.143993, b 0.000936, c 0.011012

- koa_equations.py: `HT_P = dict(a0=19.832, a1=0.106, b=0.044, c=0.863, g1=-0.198, g2=0.479)` -> `HT_P = dict(a0=30.188188, a1=1.426287, b=0.018401, c=0.817994, g1=0.051108, g2=-0.35086)`
- koa_equations.py: `def predict_HT(dbh, baph, qmd, byi, use_byi=True):` -> `def predict_HT(dbh, baph, qmd, byi, use_byi=True, dbhmax=None):`
- koa_equations.py: `rdbh = dbh / np.maximum(qmd, 1e-6)` -> `if dbhmax is None:
        HT_FALLBACK_CALLS[0] += 1
        dbhmax = dbh
    rdbh = n`
- run_candidates.py: `ht = np.array([float(predict_HT(x, max(baph, 0.1), max(qmd, 1.0), byi)) for x in dbh])` -> `ht = np.array([float(predict_HT(x, max(baph, 0.1), max(qmd, 1.0), byi, dbhmax=float(db`
- run_candidates.py: `HT=float(predict_HT(qmd, max(baph, 0.1), max(qmd, 1.0), byi))))` -> `HT=float(predict_HT(qmd, max(baph, 0.1), max(qmd, 1.0), byi, dbhmax=float(dbh.max())))))`
- koa_projector.py: `rh = float(predict_HT(recruit_dbh, baph, max(qmd,1.0), byi))` -> `rh = float(predict_HT(recruit_dbh, baph, max(qmd,1.0), byi, dbhmax=max(flo`
- koa_longterm_validation.py: `ht[miss] = [float(predict_HT(dd, baph0, max(qmd0, 1.0), B)) for dd in dbh[miss` -> `ht[miss] = [float(predict_HT(dd, baph0, max(qmd0, 1.0), B, dbhmax=float(np.nan`
- regenerate_uneven_aged.py: `ht=[float(predict_HT(d0, 1.0, d0, 264))]` -> `ht=[float(predict_HT(d0, 1.0, d0, 264, dbhmax=d0))]`
- regenerate_uneven_aged.py: `h = float(predict_HT(qmd, baph, qmd, byi))` -> `raise RuntimeError('hbar_vol is not on the executed path and has no list maximum')`
- regenerate_uneven_aged.py: `ht_raw = np.array([float(predict_HT(q, max(b, 0.1), max(q, 1.0), byi))` -> `ht_raw = np.array([float(predict_HT(q, max(b, 0.1), max(q, 1.0), byi, dbhmax=m))`
- regenerate_uneven_aged.py: `SE = dict(a0=0.614, a1=0.018, b=0.002, c=0.019, dd=0.089, dh=0.081)` -> `SE = dict(a0=1.358658, a1=0.143993, b=0.000936, c=0.011012, dd=0.089, dh=0.081)   # height`
- regen_m1.py: `SE = dict(ht_a0=0.614, ht_a1=0.018, ht_b=0.002, ht_c=0.019,` -> `SE = dict(ht_a0=1.358658, ht_a1=0.143993, ht_b=0.000936, ht_c=0.011012,   # refit SEs`
- regen_m1.py: `print("done in %.0fs" % (time.time() - t0))` -> `print("done in %.0fs" % (time.time() - t0))
    print("HT_FALLBACK_CALLS", KE.HT_FALLB`
- koa_params.py: `HARNESS_DBH_MAX_PLANTED_CM = 60.0` -> `HARNESS_DBH_MAX_PLANTED_CM = 69.7   # raised 2026-09-16 to the observed maximum QMD`
Stage 3 ordering: annual death = 1 - exp(-exp(-2.134680 + -0.818900 ln DBH + -0.813105 rHT + 0.382954 ln(BAPH+1) + 0.346317 ln(BAL+1)))
- run_candidates.py: `w = np.clip(1.0 - L.surv_annual(dbh, ht, cr, rht, byi), 1e-9, 1.0)` -> `w = np.clip(1.0 - np.exp(-np.exp(-2.13468022306448 + -0.818899541466801 * np.log(np.maximu`
- koa_projector.py: `w = np.clip(1.0 - L.surv_annual(dbh, ht, cr, rht, byi), 1e-9, 1.0)` -> `w = np.clip(1.0 - np.exp(-np.exp(-2.13468022306448 + -0.818899541466801 * np.log(np.maximu`
