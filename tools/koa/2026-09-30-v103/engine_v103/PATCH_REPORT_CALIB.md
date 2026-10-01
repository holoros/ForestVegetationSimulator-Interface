# Origin calibration patch (2026-09-16)

- koa_params.py: 'CF_DDBH_MARGINAL = 1.48254' -> 'CAL_DDBH = (0.38479, 1.58591)   # origin calibration (natural, planted'
- koa_equations.py: '* planted)   # planted level shift, origin refit 2' -> '* planted)   # planted level shift, origin refit 2026-09-16\n        re'
- koa_equations.py: 'p.get("b9", 0.0) * planted)\n        return np.clip' -> 'p.get("b9", 0.0) * planted)\n        return np.clip(np.exp(lp) * cls.CF'
- koa_equations.py: '    CF_DDBH, CF_DHT = KP.CF_DDBH_MARGINAL, KP.CF_D' -> '    CF_DDBH, CF_DHT = KP.CF_DDBH_MARGINAL, KP.CF_DHT\n    CAL_DDBH, CAL'
- koa_equations.py: 'def _sqrt(x): return np.sqrt(np.maximum(x, 0.0))\n' -> 'def _sqrt(x): return np.sqrt(np.maximum(x, 0.0))\ndef _cal(pair, plante'
- regen_m1.py: '        _cf_reset(); return' -> '        _cf_reset(); KE.cal_reset(); return'
- regen_m1.py: '    _CFCLIP[0] += _cf_draw()' -> '    _CFCLIP[0] += _cf_draw()\n    KE.cal_draw()   # origin calibration,'
- regen_figS4S5.py: '        _cf_reset(); return' -> '        _cf_reset(); KE.cal_reset(); return'
- regen_figS4S5.py: '    _cf_draw()\n    P.GARCIA_ALPHA' -> '    _cf_draw()\n    KE.cal_draw()\n    P.GARCIA_ALPHA'
- regenerate_uneven_aged.py: '        _cf_reset()\n        return' -> '        _cf_reset()\n        KE.cal_reset()\n        return'
- regenerate_uneven_aged.py: '    _cf_draw()          # ADDED 6 September 2026' -> '    KE.cal_draw()\n    _cf_draw()          # ADDED 6 September 2026'
