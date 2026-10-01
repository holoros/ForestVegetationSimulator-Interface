#!/usr/bin/env python3
"""Patch a2/higy/engine/HiGy.R (the COPY) with the expf-weighted live percentile BAL
of koa_equations.bal_percentile_fraction_weighted (engine_v103, 2026-09-30).
Red team 2, R1 and R12. engine_v103 itself is not touched."""
import sys, os
F = os.path.join(os.path.dirname(os.path.abspath(__file__)), "engine", "HiGy.R")
s = open(F).read()

def rep(old, new, count=1):
    global s
    n = s.count(old)
    if n != count:
        sys.exit(f"patch anchor found {n} times, expected {count}: {old[:70]!r}")
    s = s.replace(old, new)

# 1. header note
rep("""# version 0.5.0
  # koa mortality ported""", """# v103 BAL, 30 September 2026 (red team 2, R1)
  # The tree list path now computes BAL as the expf-weighted live percentile of
  # the Python engine (koa_equations.bal_percentile_fraction_weighted and
  # stand_bal with KP.BAL_PERCENTILE_WEIGHTED = True): BAL_i = BA_plot *
  # (W_ge_i - w_i) / (W - w_i), ties counted as at least as large. See
  # koa_bal_percentile_weighted() and calc_bal_percentile(). HiGYOneStand() calls
  # calc_bal_koa(), which dispatches on KOA_BAL_DEFINITION. The conventional
  # calc_bal() (cumsum(ba) - ba) is kept unchanged and reachable with
  # KOA_BAL_DEFINITION = "conventional". Mortality code is not changed.

# version 0.5.0
  # koa mortality ported""")

# 2. constants
rep('''KOA_BAL_DEFINITION = "percentile"   # engine and fits: live list percentile; calc_bal() here is conventional (recorded mismatch)''',
'''KOA_BAL_DEFINITION = "percentile"   # engine and fits: live list percentile. HiGYOneStand() routes through
                                    # calc_bal_koa(): "percentile" -> calc_bal_percentile() (the engine rule),
                                    # "conventional" -> calc_bal(), cumsum(ba) - ba, kept for comparison. v103, 2026-09-30
KOA_BAL_PERCENTILE_WEIGHTED = TRUE  # expf-weighted percentile, mirrors koa_params.BAL_PERCENTILE_WEIGHTED (v103);
                                    # FALSE gives the unweighted minimum-tie rule of record, koa_bal_percentile_fraction()''')

# 3. new functions after calc_bal
rep('''    dplyr::mutate(bal = cumsum(ba) - ba) %>%
    dplyr::ungroup()

  tree
}
''', '''    dplyr::mutate(bal = cumsum(ba) - ba) %>%
    dplyr::ungroup()

  tree
}
# NOTE 30 September 2026. calc_bal() above is the CONVENTIONAL expansion-weighted
# basal area in strictly larger trees, cumsum(ba) - ba. It is not the quantity the
# dDBH, dHT and HCB coefficients were fitted on and it is no longer what
# HiGYOneStand() uses; it is kept, unchanged, for comparison and is reached with
# KOA_BAL_DEFINITION = "conventional" through calc_bal_koa().


#' Unweighted live percentile BAL fraction, minimum tie rule of record
#'
#' Mirrors koa_equations.bal_percentile_fraction: 1 - (r_min - 1) / (n - 1), with
#' r_min the ascending rank under the minimum tie rule. n < 2 gives 0.
#'
#' @param dbh Numeric: diameters of the record set (cm)
#' @return Numeric: fraction of the other records with DBH >= DBH_i
koa_bal_percentile_fraction = function(dbh) {
  d = as.numeric(dbh)
  n = length(d)
  if (n < 2) return(numeric(n))
  r = rank(d, ties.method = "min")
  1 - (r - 1) / (n - 1)
}

#' Expansion-factor-weighted live percentile BAL fraction (v103)
#'
#' Mirrors koa_equations.bal_percentile_fraction_weighted of engine_v103 exactly:
#' the share, by expf, of the OTHER records with DBH >= DBH_i,
#' (W_ge_i - w_i) / (W - w_i), where W is the total weight and W_ge_i the weight of
#' every record with DBH >= DBH_i, record i and its ties included. Tied records
#' therefore count each other as at least as large, the minimum-rank convention of
#' the rule of record, and equal expf reduces to (r_ge - 1) / (n - 1), identical to
#' koa_bal_percentile_fraction(). Weights are clipped at 0; n < 2 or W <= 0 gives 0;
#' the result is clipped to [0, 1] and the denominator floored at 1e-12, as in the
#' Python source. The cumulative sum is taken in sequential double precision
#' (Reduce), as numpy's cumsum is, rather than R's long double cumsum().
#'
#' Edge case (red team 2, R12): the projectors floor decayed records at
#' expf = 1e-5 rather than dropping them. When a single live record is left among
#' such decayed records, its "others" are all decayed, so its fraction is taken over
#' 1e-5 weights only: [10, 20, 30] cm with expf [50, 1e-5, 1e-5] gives 1, 0, 0, i.e.
#' the one live tree is scored as fully overtopped. BAL is BA_plot times that
#' fraction, and the decayed records carry almost no basal area, so the effect is
#' harmless in practice, but it is a property of the rule and not an error.
#'
#' @param dbh Numeric: diameters of the record set (cm)
#' @param expf Numeric: expansion factors (trees ha-1)
#' @return Numeric: fraction in [0, 1], same order as dbh
koa_bal_percentile_weighted = function(dbh, expf) {
  d = as.numeric(dbh)
  w = pmax(as.numeric(expf), 0)
  n = length(d)
  if (n < 2) return(numeric(n))
  W = sum(w)
  if (isTRUE(W <= 0)) return(numeric(n))
  o  = order(d, method = "radix")                 # stable ascending, as argsort(kind = "mergesort")
  sd = d[o]; sw = w[o]
  cw = c(0, Reduce(`+`, sw, accumulate = TRUE))   # sequential double, as np.cumsum
  first = match(sd, sd)                           # first tied position, as searchsorted(side = "left") + 1
  ge = W - cw[first]
  fr = pmin(pmax((ge - sw) / pmax(W - sw, 1e-12), 0), 1)
  out = numeric(n)
  out[o] = fr
  out
}

#' Calculate BAL on the percentile rule of the engine (tree list path, v103)
#'
#' Mirrors koa_equations.stand_bal(baph, dbh, expf) on the exact path: BAL_i =
#' BA_plot * fraction_i, with BA_plot = sum(ba) over the plot's records and the
#' fraction from koa_bal_percentile_weighted() (KOA_BAL_PERCENTILE_WEIGHTED = TRUE)
#' or koa_bal_percentile_fraction() (FALSE). Every record in the plot enters,
#' decayed records at expf 1e-5 included, as in project_psp. The list is returned
#' sorted as calc_bal() sorts it (plot, descending dbh). A mixed species list is
#' ranked over all its records; koa lists hold AK only.
#'
#' @param tree.data Dataframe: Tree list with plot, dbh, ba, expf
#' @param weighted Logical: use the expf-weighted percentile
#' @return Dataframe: Tree data with added BAL column
calc_bal_percentile = function(tree.data, weighted = KOA_BAL_PERCENTILE_WEIGHTED) {

  required.cols = c('plot', 'dbh', 'ba', 'expf')
  missing.cols = setdiff(required.cols, names(tree.data))
  if (length(missing.cols) > 0) {
    stop(paste("Missing required columns:", paste(missing.cols, collapse = ", ")))
  }

  tree = tree.data %>%
    dplyr::arrange(plot,
                   desc(dbh)) %>%
    dplyr::group_by(plot) %>%
    dplyr::mutate(bal = sum(ba) * (if (isTRUE(weighted))
                                     koa_bal_percentile_weighted(dbh, expf)
                                   else koa_bal_percentile_fraction(dbh))) %>%
    dplyr::ungroup()

  tree
}

#' BAL on the definition of record, KOA_BAL_DEFINITION
#'
#' @param tree.data Dataframe: Tree list
#' @param definition Character: "percentile" (engine rule, default) or "conventional"
#' @return Dataframe: Tree data with added BAL column
calc_bal_koa = function(tree.data, definition = KOA_BAL_DEFINITION) {
  if (identical(definition, "percentile"))   return(calc_bal_percentile(tree.data))
  if (identical(definition, "conventional")) return(calc_bal(tree.data))
  stop(paste("unknown KOA_BAL_DEFINITION:", definition))
}
''')

# 4. route HiGYOneStand
rep("""      # Calculate BAL
    calc_bal()
""", """      # Calculate BAL on the definition of record (percentile, v103)
    calc_bal_koa()
""")
rep("""  tree=tree %>%
    calc_bal()
""", """  tree=tree %>%
    calc_bal_koa()
""")
open(F, "w").write(s)
print("patched", F)
