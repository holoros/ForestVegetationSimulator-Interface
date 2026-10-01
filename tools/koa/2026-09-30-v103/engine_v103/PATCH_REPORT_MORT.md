# Natural mortality level patch (2026-09-16)

- koa_params.py: 'CAL_MC_SEED = 20260916\n' -> 'CAL_MC_SEED = 20260916\nMORT_CAL = (2.59367, 1.0)   # natural mortality level calibration ('
- threestage.py: 'SDI_FLOOR = 1.0\n' -> 'SDI_FLOOR = 1.0\nimport koa_params as _KP\n\n\ndef mort_cal(planted=0):\n    """Origin mortalit'
- regen_m1.py: '    if sdi is None or not np.isfinite(sdi):\n      ' -> '    if sdi is None or not np.isfinite(sdi):\n        return float(np.clip(m * TS.mort_cal(p'
- regen_figS4S5.py: '    if sdi is None or not np.isfinite(sdi):\n      ' -> '    if sdi is None or not np.isfinite(sdi):\n        return float(np.clip(m * TS.mort_cal(p'
- koa_equations.py: '_CALRNG = [None]\n' -> '_CALRNG = [None]\n_MORTRNG = [None]\n'
- koa_equations.py: '    _CALRNG[0] = np.random.default_rng(KP.CAL_MC_S' -> '    _CALRNG[0] = np.random.default_rng(KP.CAL_MC_SEED)\n    KP.MORT_CAL_LIVE[:] = list(KP.M'
- koa_equations.py: '    LineageA.CAL_DHT = (KP.CAL_DHT[0] * float(np.e' -> '    LineageA.CAL_DHT = (KP.CAL_DHT[0] * float(np.exp(KP.CAL_DHT_SE_LOG[0] * z[2])), KP.CAL'
