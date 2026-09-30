# koa_rv_kulani_20260928

Date 2026-09-28; RUN.md written and k2.py rerun 2026-09-29 (k2.log). Host ifm-kershaw (firebreather).
Engine of record ~/jobs/koa_v102_20260918/track2/engine_v102 (MORT_CAL 2.64629), read only.
Purpose: Kulani DOFAW plot 12 long-term validation under the v102 engine, deployed BYI versus BYI 92.67.

k.py inspects the koa_longterm_validation.load() cache. k2.py sets V.stand_mortality = regen_m1._gated,
set_params(None), and runs V.validate() on Kulani 12 with the deployed BYI (25.15) and with BYI 92.67.

Result, observed minus predicted:
- deployed BYI 25.15: survival -0.355, QMD -1.98 cm, BA -29.86 m2 ha-1
- BYI 92.67: survival -0.221, QMD -10.75 cm, BA -38.61 m2 ha-1

Run: cd ~/jobs/koa_rv_kulani_20260928 && python3 k2.py > k2.log 2>&1
No coordinates are read or written.
