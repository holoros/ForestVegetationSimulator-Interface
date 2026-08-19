"""koa_ingrowth.py -- koa-only annualized ingrowth as a function of ABSOLUTE
stand density index and origin. Transcribed from the equation of record
final/koa_ingrowth.R (koa.ingrowth, lines 225-292).

    E[ingrowth, trees ha-1 yr-1] = exp( 5.3836 - 0.0061866*SDI - 1.6359*planted )

Reconstructed from AK.HT.csv remeasurements (363 plot-periods, 22 percent with
ingrowth) and fit with a quasi-Poisson log model. Absolute stand density is the
dominant driver (p < 1e-4); plantations have about 5x less ingrowth (rate ratio
0.195, p = 0.029), managed and weeded. BYI is NOT included: neither a BYI main
effect (p = 0.28) nor a BYI by density interaction (p = 0.56) is significant,
and percent koa basal area has no variation because koa PSPs are close to pure
koa. BYI acts on ingrowth indirectly through growth, which raises density
faster. An OPTIONAL, UNTESTED BYI multiplier (byi_c, default 0 = off) is kept
for when richer data allow testing the hypothesis that BYI raises ingrowth.
Annualized by construction (rate per year).

RESPECIFIED 2026-08-07. This module previously carried SDI_MAX = 500.0 and the
relative-density coefficient B_RD = -3.0933, computing rd = sdi/SDI_MAX. That
form is algebraically identical to the present one WHEN sdi is supplied, since
-3.0933/500 = -0.0061866, so no ingrowth prediction in the deposited pipeline
changes. What changes is that the withdrawn scalar is gone from the prediction
path, so the failure mode of swapping SDImax while leaving B_RD alone is now
structurally impossible, and the basal area fallback is re-anchored through the
Reineke identity instead of the unprovenanced baph/60 divisor. Every constant
now comes from koa_params.py.

The module level name SDI_MAX is retained but bound to a poisoned sentinel.
"""
import numpy as np

import koa_params as P

# --- Withdrawn scalar, name retained so importers fail loudly, not silently ---
SDI_MAX = P.SDIMAX_WITHDRAWN

B0 = P.ING_B0                # 5.3836,     final/koa_ingrowth.R line 232
B_SDI = P.ING_B_SDI          # -0.0061866, final/koa_ingrowth.R line 233
B_PLANTED = P.ING_B_PLANTED  # -1.6359,    final/koa_ingrowth.R line 242
KR = P.KR                    # Reineke constant, final/koa_ingrowth.R line 261

# Retained ONLY so a reader can reproduce the withdrawn parameterisations. Not
# in the prediction path. final/koa_ingrowth.R lines 237-241.
B_RD = None
B_RD_AT_500 = P.RETIRED_B_RD
B_RD_AT_933 = P.RETIRED_B_RD_AT_933
B_RD_AT_1350 = P.RETIRED_B_RD_AT_1350


def sdi_from_baph(baph, qmd=None):
    """Basal area fallback through the Reineke identity, exact at the stand's own
    quadratic mean diameter when supplied and at QMD_REF_CM = 20 cm otherwise.
    final/koa_ingrowth.R lines 264-269 and 210-223. The old fallback divisor of
    60 (and the 49 that preceded the 42 anchor) is withdrawn: 49 was the
    withdrawn 933 evaluated at Dq 30 cm and was circular."""
    dq = P.QMD_REF_CM if qmd is None else max(float(qmd), 0.1)
    return float(baph) / (KR * dq ** P.DQ_EXPONENT)


def ingrowth_annual(sdi=None, baph=None, planted=0, byi=P.ING_BYI_DEFAULT,
                    byi_c=P.ING_BYI_C_DEFAULT, byi_ref=P.ING_BYI_REF,
                    rd=None, cap=P.ING_CAP, qmd=None, b_rd=None, sdimax=None):
    """Expected annual koa ingrowth (trees ha-1 yr-1) entering at threshold DBH
    2.5 cm.

    Signature is backward compatible with the deposited version. The rd and
    b_rd arguments are the relative-density diagnostics path of the R source
    (lines 271-281) and they now REQUIRE a named sdimax, because no default
    exists: 500, 933 and 1350 metric are all withdrawn. Supplying rd or b_rd
    without sdimax raises. Do not use the RD path in production.

    cap is carried from the equation of record. [UNPROVENANCED: no derivation
    for 160 trees ha-1 yr-1 appears in final/koa_ingrowth.R; see
    koa_params.ING_CAP.]
    """
    if rd is not None or b_rd is not None:
        if sdimax is None:
            raise RuntimeError(
                "The relative-density path (rd= or b_rd=) needs a named SDImax, "
                "and no default exists: 500, 933 and 1350 metric are all "
                "withdrawn (final/koa_ingrowth.R lines 17-23, 278-279). Pass "
                "sdimax=<value you are prepared to name and label a reporting "
                "choice>, or use the production path and pass sdi= in absolute "
                "SDI."
            )
        rd_use = rd if rd is not None else (float(sdi) / float(sdimax))
        coef = b_rd if b_rd is not None else (B_SDI * float(sdimax))
        dens_term = coef * rd_use
    else:
        if sdi is None:
            if baph is None:
                raise ValueError("supply sdi (absolute SDI) or baph (m2 ha-1)")
            sdi_use = sdi_from_baph(baph, qmd)
        else:
            sdi_use = float(sdi)
        dens_term = B_SDI * sdi_use

    e = np.exp(B0 + dens_term + B_PLANTED * int(planted))
    if byi_c:
        e = e * (max(byi, 1.0) / byi_ref) ** byi_c
    return float(np.clip(e, 0.0, cap))
