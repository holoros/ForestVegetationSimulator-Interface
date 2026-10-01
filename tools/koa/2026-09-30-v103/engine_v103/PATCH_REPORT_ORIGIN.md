# Origin patch (2026-09-16)

- AK_PLT.csv: 325 PSP rows set to planted (were planted: 0)
- AK_PLT_GEO.csv: 31 PSP rows set to planted (were planted: 0)
- AK_SURV.csv: 4460 PSP rows set to planted (were planted: 0)
- koa_equations.py: '    DDBH = dict(b0=-2.4704737, b1=0.2072221, b2=-0.0159616, ' -> '    DDBH = dict(b0=-2.0972488, b1=0.3105931, b2=-0.0085285, '
- koa_equations.py: '    DHT = dict(b0=-3.382162, b1=0.272454, b2=-0.105319, b3=-' -> '    DHT = dict(b0=-4.0426171, b1=0.9238575, b2=-0.1099897, b'
- koa_equations.py: '              + p["b7"] * planted * dbh_planted + p["b8"] * ' -> '              + p["b7"] * planted * dbh_planted + p["b8"] * '
- koa_equations.py: '              + p["b7"] * _sqrt(planted * np.minimum(ht, KP.' -> '              + p["b7"] * planted * np.minimum(ht, KP.DDBH_H'
- koa_params.py: 'CF_DDBH_MARGINAL = 1.369\n' -> 'CF_DDBH_MARGINAL = 1.48254   # exp(0.5 * (0.750^2 + 0.475^2)'
- out_stage1/stage1_fit.json replaced: stage1 {'intercept': -1.66075872826506, 'lnSDI': 0.165634277461637, 'planted': -0.217554491233639}, pbar 0.3173
- koa_params.py: 'ING_B0 = 5.3836\n' -> 'ING_B0 = 3.525984   # origin refit 2026-09-16\n'
- koa_params.py: 'ING_B_SDI = -0.0061866\n' -> 'ING_B_SDI = -0.005438318   # origin refit 2026-09-16 (-2.719'
- koa_params.py: 'ING_B_PLANTED = -1.6359\n' -> 'ING_B_PLANTED = 1.558192   # origin refit 2026-09-16\n'
- regen_m1.py: 'ddbh_lnBYI=0.089, dht_lnBYI=0.081' -> 'ddbh_lnBYI=0.0820, dht_lnBYI=0.0799'
- regenerate_uneven_aged.py: 'dd=0.089, dh=0.081' -> 'dd=0.0820, dh=0.0799'
- regen_t8_chunked.py: 'ddbh_lnBYI=0.089, dht_lnBYI=0.081' -> 'ddbh_lnBYI=0.0820, dht_lnBYI=0.0799'
- regen_figS4S5.py: 'ddbh_lnBYI=0.089, dht_lnBYI=0.081' -> 'ddbh_lnBYI=0.0820, dht_lnBYI=0.0799'
- koa_longterm_validation.py: '        t0, t1 = meas[0], meas[-1]; ny = int(t1 - t0)' -> '        t0, t1 = meas[0], meas[-1]\n        _rm = _REMOVAL.ge'
- koa_longterm_validation.py: 'TPH_FAC = 0.00007854  # pi/4 * 1e-4 : m2 per (cm^2) per tree' -> 'TPH_FAC = 0.00007854  # pi/4 * 1e-4 : m2 per (cm^2) per tree'
