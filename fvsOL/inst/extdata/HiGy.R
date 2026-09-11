# $Id: HiGy.R 3968 2026-02-10 10:36:05Z benrice $
################################################################################
# v0.5.0
#
# Hawaii Variant of the Forest Vegetation Simulator (FVS-HI)
#
# Developed by:
# Aaron Weiskittel, University of Maine, School of Forest Resources
# aaron.weiskittel@maine.edu
#
# Ben Rice, Midgard Natural Resources
# Midgard.Natural.Resources@gmail.com
#
################################################################################

library(dplyr) # needed arrange, mutate, left_join, tibble, select, group_by, summarise, ungroup, case_when, all_of
library(purrr) # needed for pmap_*

VersionTag = "HiGyV0.5.0"

##############################
#### major update summary ####
####

# version 0.5.0
  # koa mortality ported onto the deployed engine of record selected by
  # MORTALITY_RULE_2026-09-12.md AMENDMENT 1 (candidate M1), 11 September 2026.
  # Two changes, both in front of algebra that did not itself move.
  #   Stage 1 is now LIVE AS A GATE on the production stand rate. The deployed
  #   annual rate is m_garcia / p_bar * p(SDI, origin), with p the complementary
  #   log-log occurrence probability of koa_stage1_p() and p_bar the mean fitted
  #   annual occurrence over the fitting record, clipped to [0, 0.95]. Dividing
  #   by p_bar makes the incumbent rate conditional on occurrence and the
  #   multiplication gates it, so the expected rate over the fitting record is
  #   unchanged and only the density response moves. The gate is on the path
  #   calc_mortality() drives, via koa_step_deaths(gate = TRUE).
  #   Stage 3 now orders deaths by the FITTED TREE-LEVEL SURVIVOR WEIGHT
  #   w = 1 - koa_surv_annual(...) rather than by relative size. The
  #   as-published relative-size weight is retained and reachable with
  #   mode = 'rel_size'.
  # The Garcia (2009) recursion, the anchored beta, the H_QMD allometry and the
  # A1 background floor are unchanged. koa_mortality_step() and
  # koa_allocate_mortality(), the standalone non-production wrappers, keep the
  # 9 September 2026 behaviour by explicit default (ungated, unfloored, fitted
  # beta, relative-size weight), so every 0.4.0 arm stays separately
  # reproducible from this same file.

# version 0.4.0
  # koa mortality ported onto the deposit's deployed arm of record, 9 September
  # 2026: beta anchored at 0.16019053617304435 (was the fitted 0.117), the
  # Garcia (2009) step now driven by H_QMD via the new koa_h_qmd() (was H40),
  # and the A1 background floor now applied (0.003 yr-1 natural, 0.006 yr-1
  # planted, was unfloored). Ported from figshare_v66/koa_mortality_garcia.py
  # and koa_params.py, cross-validated against that Python source on
  # firebreather. Stage 1 and Stage 3 unchanged. koa_mortality_step(), the
  # standalone non-production wrapper, keeps the fitted-H40, unfloored arm by
  # explicit default so the two arms stay separately reproducible.

# version 0.3.0
  # three-stage Acacia koa A.Gray mortality component replaces the tree-level
  # survivor equation as the production mortality path, following the structure
  # of Chen et al. (2023): Stage 1 irregular event (stochastic, OFF by default),
  # Stage 2 regular stand-level survival on the Garcia (2009) form, Stage 3
  # allocation of the stand deaths to trees by relative diameter
  # calc_mortality() gains mort.engine, and mort.engine = 'cloglog' still runs
  # the version 0.2.0 body unchanged, so any earlier projection is recoverable
  # make_ops() gains mort.engine, irregular, mort.seed and planted.background,
  # and customRun_fvsRunHi.R exposes the first two in the run interface
  # surv_prob() and surv.parm are RETAINED unchanged and are no longer on the
  # production path; two divergences against the manuscript deposit are flagged
  # in the block above surv.parm and are for Aaron and Ben to settle, not for
  # this edit to decide

# version 0.2.0
  # updated equations- integration of biomass yield index (BYI) and planted indicator
  # planted indicator is derived from FVS_Standinit.StdOrgCd (Stand Origin Code; also used by the FIAVBC keyword)
    # Natural stand = 0 - established through natural regeneration
    # Plantation = 1 - established through planting

# version 0.1.0
  # initial version
  # designed to work with FVS-HI and customRun_fvsRunHi.R
  # contains equations for koa


##############################

##### Total height prediction ####
ht.pred.parm = dplyr::tribble(
  ~type,   ~species,  ~a0,      ~a1,    ~b,      ~c,     ~g1,      ~g2,
  'base',  'AK',      19.832,   0,      0.044,   0.863,   -0.198,   0.479,
  'site',  'AK',      19.832,   0.106,  0.044,   0.863,   -0.198,   0.479)



#' Predict total height
#'
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param bal Numeric: Plot basal area larger trees (m^2 per ha)
#' @param ba Numeric: Plot basal area (m^2 per ha)
#' @param byi Boolean: Biomass Yield Index (Mg per ha). If NULL or 0, uses basic model
#' @param  a0-g2 Numeric: Parameters
#' @return Numeric: Predicted height (m)
#'
#
pred_ht= function(dbh,  ba, bal, qmd, byi,
                  a0, a1, b, c, g1, g2){

  rdbh = dbh/qmd

  ht.intercept = ifelse(byi %in% c(NA, 0),
                      a0,
                      a0 + a1 * byi / 100)

  ht = pmax(ht.intercept * (1 - exp(-b * dbh))^c *
              exp(g1 * log(ba + 1) + g2 * rdbh),
            1.37) # enforce minimum of breast height


  ht
}


#' Wrapper to calculate predicted heights for tree list
#'
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data
#' @param byi Biomass Yield Index (Mg per ha). If NULL or 0, use base model
#' @param ht.spp.parms Dataframe: Dataframe of parameters (default ht.pred.parm)
#' @return Dataframe: Tree data with ht column added
#'
calc_ht = function(tree.data, plot.data, byi=stand$byi,
                   ht.pred.parm.df = ht.pred.parm) {

  tree.data.names= colnames(tree.data)

  ht.parm.type = ifelse(byi %in% c(NA, 0),
                        'base',
                        'site')

  ht.parm = ht.pred.parm.df %>%
    filter(type==ht.parm.type)

  tree = tree.data %>%
    dplyr::left_join(plot.data %>%
                       dplyr::select(plot, ba.plot, qmd),
                     by = 'plot') %>%
    # Match parameter estimates on species, Koa is currently the default
    # when the model extends to other species, the code may need to be updated to another default species
    dplyr::mutate(idx = match(sp, ht.parm$species, nomatch = match('AK', ht.parm$species)),
                  a0 = ht.parm$a0[idx],
                  a1 = ht.parm$a1[idx],
                  b  = ht.parm$b[idx],
                  c  = ht.parm$c[idx],
                  g1 = ht.parm$g1[idx],
                  g2 = ht.parm$g2[idx],
                  byi = coalesce(byi, 0), # maintains vectorized call of pred_ht()
                  pht = pred_ht(dbh, ba=ba.plot, bal, qmd, byi,
                                a0, a1, b, c, g1, g2)) %>%
    dplyr::select(dplyr::all_of(tree.data.names), pht)


  tree
}


##### Height to crown base prediction ####

# Height to crown base species parameters
  hcb.pred.parm = dplyr::tribble(
    ~type,   ~species,  ~b0,     ~b1,      ~b2,     ~b3,     ~b4,     ~b5,
    'base',  'AK',      0.1684,  1.0146,  -0.376, -0.0078, -0.3734,   0,
    'site',  'AK',      0.1684,  1.0146,  -0.376, -0.0078, -0.3734,  -0.221)


#' Predict height to crown base
#'
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param ht Numeric: Total tree height (m)
#' @param bal Numeric: Plot basal area larger trees (m^2 per ac)
#' @param ba Numeric: Plot basal area (m^2 per ac)
#' @param byi Biomass Yield Index (Mg per ha). If NULL or 0, uses basic model
#' @param b0-b4 Numeric: Species parameters
#' @return Numeric: Predicted height to crown base (m)
#'
  pred_hcb = function(dbh, ht, bal, ba, byi,
                      b0, b1, b2, b3, b4, b5) {

    eta = b0 +
      b1 * sqrt(ht/100) +
      b2 * log(pmax(ht/pmax(dbh, 0.1), 0.5)) +
      b3 * sqrt(bal*ba + 1) +
      b4 * log(ba + 1) +
      b5 * log(pmax(byi, 1) / 100)

    # Calculate height to crown base
    hcb = ht / (1 + exp(-eta))

    # constrain between 0 and 95% of height
    hcb = pmin(pmax(hcb,
                    0),
               0.95 * ht)

    hcb
  }


#' Wrapper to calculate height to crown base for tree list
#'
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data
#' @param hcb.spp.parms Dataframe: Species parameters (default hcb.pred.spp)
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @return Dataframe: Tree data with hcb column added
#'
  calc_hcb = function(tree.data, plot.data,
                      hcb.pred.parm.df = hcb.pred.parm,
                      byi = stand$byi) {

    tree.data.names= colnames(tree.data)

    hcb.parm.type = ifelse(byi %in% c(NA, 0),
                          'base',
                          'site')

    hcb.parm = hcb.pred.parm.df %>%
      filter(type==hcb.parm.type)

    tree=tree.data %>%
      dplyr::left_join(plot.data %>%
                         dplyr::select(plot, ba.plot),
                       by = 'plot') %>%
       # Match parameter estimates on species, Koa is currently the default
      dplyr::mutate(idx = match(sp, hcb.parm$species, nomatch = match('AK', hcb.parm$species)),
                    b0 = hcb.parm$b0[idx],
                    b1 = hcb.parm$b1[idx],
                    b2 = hcb.parm$b2[idx],
                    b3 = hcb.parm$b3[idx],
                    b4 = hcb.parm$b4[idx],
                    b5 = hcb.parm$b5[idx],
                    byi = coalesce(byi, 0),
                    phcb = pred_hcb(dbh, ht, bal, ba=ba.plot, byi,
                                    b0, b1, b2, b3, b4, b5)) %>%
      dplyr::select(dplyr::all_of(tree.data.names), phcb)

    tree
  }


#### Diameter increment ####

# Diameter increment parameters
  ddbh.parm = dplyr::tribble(
    ~type,    ~species,  ~b0,        ~b1,         ~b2,         ~b3,         ~b4,        ~b5,         ~b6,        ~b7,        ~b8,
    'base',    'AK',   -2.4704737,  0.2072221,  -0.0159616,  -0.0016893,  -0.2972574,  -0.4470330,  -0.0158403,  0.0188938,        0,
    'site',    'AK',   -2.4704737,  0.2072221,  -0.0159616,  -0.0016893,  -0.2972574,  -0.4470330,  -0.0158403,  0.0188938,   0.4530166)


#' Calculate annual diameter increment
#'
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param bal Numeric: Plot basal area larger trees (m^2 per ha)
#' @param ba Numeric: Plot basal area (m^2 per ha)
#' @param cr Numeric: Live crown ratio (0-1)
#' @param byi Numeric: Biomass Yield Index (Mg per ha). If NULL or 0, uses base model parameters
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param b0-b8 Numeric: Species parameters
#' @return Numeric: Diameter increment (cm)
#
# FLAGGED 8 September 2026, NOT CHANGED, and it is not part of the mortality
# change. Two constants below diverge from the manuscript deposit certified on
# this date, and the divergence acts on the diameter axis of every projection
# this file makes. The deposit carries cf = 1.369 rather than the 1.026 kept
# here, having rederived it as exp(0.5 (tau_D^2 + tau_I^2)) from the nested
# random intercepts of the recovered fitted object dDBH_BYI.rda, and it carries
# b7 * planted * pmin(dbh, 45.0) rather than the pmin(dbh, 40) kept here, 45.0
# being an extrapolation guard on the largest planted diameter in the fitting
# data rather than the withdrawn 40 cm truncation of the fitted form. Neither
# change is applied here, since each is a separate decision with its own control
# and folding either into a mortality edit would make both unreviewable. The
# mortality component reaches the diameter axis only through the projected
# end-of-cycle top height, so a decision on these two constants moves mortality
# as well and should be taken before this file is released.
ddbh = function(dbh, bal, ba, cr, byi, planted,
                b0, b1, b2, b3, b4, b5, b6, b7, b8) {

  cf = 1.026   # Duan (1983) smearing correction factor

  # diameter increment
  ddbh = exp(b0 + b1*log(dbh+1) +
               b2 * dbh +
               b3 * bal^2 / log(dbh + 5) +
               b4 * log(bal + 1) +
               b5 * log(pmax(cr, 0.01)) +
               b6 * sqrt(pmax(ba * dbh, 0)) +
               b7 * planted * pmin(dbh, 40) +
               b8 * log(pmax(byi, 1))) *cf

  # constrain to between 0 and 4 cm
  ddbh = pmin(pmax(ddbh, 0), 4)

  ddbh
}


#' Wrapper function to calculate diameter increment with modifiers and constraints
#'
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data
#' @param use.cap.dbh Logical: Apply maximum DBH constraint (default ops$use.cap.dbh)
#' @param ddbh.parm.df Dataframe: Species parameter table for diameter increment
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @return Dataframe: Tree data with diameter increment calculations
calc_ddbh = function(tree.data, plot.data,
                     use.cap.dbh = ops$use.cap.dbh,
                     ddbh.parm.df = ddbh.parm,
                     byi = stand$byi,
                     planted = stand$planted ) {

  # get tree list variable names
  tree.data.names= colnames(tree.data)

  # filter ddbh parameter estimate to type base or climate
  ddbh.parm.type = ifelse(byi %in% c(NA, 0),
                        'base',
                        'site')

  ddbh.parm = ddbh.parm.df %>%
    filter(type==ddbh.parm.type)

  # Calculate diameter increment
  tree = tree.data %>%
    dplyr::left_join(plot.data %>%
                       dplyr::select(plot, ba.plot),
                     by = 'plot') %>%
    # Match parameter estimates on species, Koa is currently the default
    dplyr::mutate(idx = match(sp, ddbh.parm$species, nomatch = match('AK', ddbh.parm$species)),
                  b0 = ddbh.parm$b0[idx],
                  b1 = ddbh.parm$b1[idx],
                  b2 = ddbh.parm$b2[idx],
                  b3 = ddbh.parm$b3[idx],
                  b4 = ddbh.parm$b4[idx],
                  b5 = ddbh.parm$b5[idx],
                  b6 = ddbh.parm$b6[idx],
                  b7 = ddbh.parm$b7[idx],
                  b8 = ddbh.parm$b8[idx],
                  byi = dplyr::coalesce(byi, 0),
                  planted = dplyr::coalesce(planted, 0),
                  #
                  ddbh = dplyr::case_when(ht<1.3716 ~0,
                                          TRUE ~ddbh(dbh, bal, ba=ba.plot, cr,
                                                     byi, planted,
                                                     b0, b1, b2, b3, b4, b5, b6, b7, b8)),
                  # apply dbh increment multiplier
                  ddbh = ddbh * ddbh.mult)

  # Apply diameter growth cap if requested
  if (use.cap.dbh == TRUE) {
    tree = tree %>%
      dplyr::mutate(ddbh = dplyr::case_when((ddbh + dbh) > max.dbh ~ 0,
                                            TRUE ~ ddbh))
  }

  # Clean up temporary columns
  tree = tree %>%
    dplyr::select(dplyr::all_of(tree.data.names), ddbh)


  tree
}


#### Height increment ####

# Height increment parameters
dht.parm = dplyr::tribble(
  ~type,   ~species,  ~b0,        ~b1,       ~b2,        ~b3,        ~b4,       ~b5,        ~b6,       ~b7,     ~b8,
  'base',  'AK',    -3.382162,  0.272454,  -0.105319,   -0.000829, -0.071718,  -1.483889,  0.033035,  0.017887,  0,
  'site',  'AK',    -3.382162,  0.272454,  -0.105319,   -0.000829, -0.071718,  -1.483889,  0.033035,  0.017887,  0.433224)


#' Calculate height increment
#'
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param ht Numeric: Tree height (m)
#' @param bal Numeric: Plot basal area larger (m^2 per ha)
#' @param ba Numeric: Plot basal area (m^2 per ha)
#' @param cr Numeric: Live crown ratio (0-1)
#' @param byi Numeric: Biomass Yield Index (Mg per ha). If NULL or 0, uses base model parameters
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param b0-b8 Numeric: Species parameters
#' @return Numeric: Height increment (m)
#
# NOTE ADDED 8 September 2026. This function is now upstream of mortality in a
# way it was not before. The three-stage component takes its end-of-cycle top
# height from ht + dht on the same trees, so the height increment sets the
# regular mortality of the cycle outright and a stand whose top height does not
# rise takes no regular mortality at all. The correction factor 1.030 agrees
# with the deposit and is unchanged, yet it remains the one unprovenanced
# correction factor in the koa system, since no fitting script or fitted object
# for this equation has been recovered. That provenance gap now propagates into
# mortality and is disclosed here rather than left in the height section alone.
dht = function(dbh, ht, bal, ba, cr, byi, planted,
               b0, b1, b2, b3, b4, b5, b6, b7, b8) {


  cf = 1.030   # Duan (1983) smearing correction factor


  dht = exp(b0 + b1 * log(ht+1) +
              b2 * ht +
              b3 * bal^2 / log(ht + 5) +
              b4 * log(bal + 1) +
              b5 * log(pmax(cr, 0.01)) +
              b6 * sqrt(pmax(ba * ht, 0)) +
              b7 * sqrt(planted * pmin(ht, 20)) +
              b8 * log(pmax(byi, 1))) *cf

  # constrain to between 0 and 2 m
  dht = pmin(pmax(dht, 0), 2)

  dht
}


#' Wrapper function to calculate height increment with modifiers and constraints
#'
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data
#' @param use.cap.ht Logical: Apply maximum total tree height constraint (default ops$use.cap.ht)
#' @param dht.parm.df Dataframe: Species parameter table for height increment (dht.parm)
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @return Dataframe: Tree data with height increment calculations
calc_dht = function(tree.data,
                    plot.data,
                    use.cap.ht = ops$use.cap.ht,
                    dht.parm.df = dht.parm,
                    byi=stand$byi,
                    planted=stand$planted ) {

  # get tree list variable names
  tree.data.names= colnames(tree.data)

  # filter dht parameter estimate to type base or climate
  dht.parm.type = ifelse(byi %in% c(NA, 0),
                         'base',
                         'site')

  dht.parm = dht.parm.df %>%
    filter(type==dht.parm.type)

  # Calculate height increment
  tree = tree.data %>%
    dplyr::left_join(plot.data %>%
                       dplyr::select(plot, ba.plot),
                     by = 'plot') %>%
    # Species parameters
    dplyr::mutate(idx = match(sp,
                              dht.parm$species,
                                 nomatch = match('AK', dht.parm$species)), #
                  b0 = dht.parm$b0[idx],
                  b1 = dht.parm$b1[idx],
                  b2 = dht.parm$b2[idx],
                  b3 = dht.parm$b3[idx],
                  b4 = dht.parm$b4[idx],
                  b5 = dht.parm$b5[idx],
                  b6 = dht.parm$b6[idx],
                  b7 = dht.parm$b7[idx],
                  b8 = dht.parm$b8[idx],
                  byi = dplyr::coalesce(byi, 0),
                  planted = dplyr::coalesce(planted, 0),
                  #
                  dht = dht(dbh, ht, bal, ba, cr, byi,
                               planted, b0, b1, b2, b3, b4, b5, b6, b7, b8),
      #apply ht increment multiplier
      dht = dht * dht.mult)

  # Apply height cap
  if (use.cap.ht == TRUE) {
    tree = tree %>%
      dplyr::mutate(dht = dplyr::case_when((dht + ht) > max.height ~ 0,
                                           TRUE ~ dht))
  }

  # Clean up temporary columns
  tree = tree %>%
    dplyr::select(dplyr::all_of(tree.data.names), dht)

  tree
}


### Crown recession ####

#### Mortality ####

# =============================================================================
# THREE-STAGE Acacia koa A.Gray MORTALITY COMPONENT
# Added 8 September 2026, version 0.3.0. Ported onto the deposit's deployed
# arm 9 September 2026, version 0.4.0, and it is the production mortality
# path from this version forward.
#
# Structure follows Chen et al. (2023), namely occurrence of an irregular
# event, regular stand-level survival, and allocation of the stand deaths to
# trees. Stage 2 is the whole-stand model of Garcia (2009) run on mean spacing
# S = 100 / sqrt(N) against top height H40, is deterministic, and is the
# default. Stage 3 spreads the plot deaths across that plot's trees on the
# as-published size weight and renormalizes. Stage 1 is stochastic and is OFF.
#
# SELF-CONTAINED BY REQUIREMENT. Every coefficient, the per-tree cap, the
# occurrence rate, the reference interval and the 60-element empirical
# magnitude vector are literals below. Nothing here reads a data file and
# nothing here sources another file, which is what lets HiGy.R remain the
# single drop-in customRun_fvsRunHi.R loads.
#
# Parameters of record: alpha = gamma = 2.96 with the ratio gamma/alpha fixed
# at 1, plot-cluster bootstrap 95% interval 1.64 to 4.99, and beta = 0.117 m⁻¹,
# interval 0.057 to 0.159, B = 2,000 retained replicates, seed 20260904. Fitted
# on the survivor cohort of the 360 regular plot intervals of the koa network,
# meaning 103 plots, 469 deaths and 15,562 tree-years at a pooled 3.0% yr⁻¹.
#
# SOURCES FOR EVERY NUMBER BELOW, none of them invented here:
#   ben-package-2026-09-04/koa_mortality_3stage_fvs.R (the reference
#     implementation, alpha, beta, cap, rate, reference interval, the size
#     weight and the magnitude vector)
#   ben-package-2026-09-04/koa-mortality-3stage-memo-for-ben_FINAL_2026-09-04.md
#     (the specification of record and the fit statistics quoted here)
#   ben-package-2026-09-04/plot_interval_pairs_DATA.csv (the survivor-cohort
#     interval table the fit and the magnitude vector rest on)
# Zenodo concept DOI 10.5281/zenodo.21081014.
#
# Chen, C., Kershaw, J.A., Weiskittel, A.R., McGarrigle, E., 2023. Can a
#   multistage approach improve individual tree mortality predictions across
#   the complex mixed-species and managed forests of eastern North America?
#   For. Ecosyst. 10, 100086. https://doi.org/10.1016/j.fecs.2023.100086
# Garcia, O., 2009. A simple and effective forest stand mortality model. Math.
#   Comput. For. Nat. Resour. Sci. 1, 1-9.
#
# PORTED ONTO THE DEPOSIT ARM, 9 September 2026. The Zenodo deposit moved its
# own deployed arm on 5 September 2026 to a variant that runs the same Garcia
# step on H_QMD, the allometric height equivalent of quadratic mean diameter,
# with beta anchored at 0.16019053617304435 rather than the fitted 0.117 run
# on H40. This file now implements that arm as the production default: the
# beta constant, the height variable driving the step (H_QMD via koa_h_qmd(),
# not H40), and the A1 background floor (0.003 yr-1 natural, 0.006 yr-1
# planted) all moved together, ported line for line from the deposit's
# figshare_v66/koa_mortality_garcia.py and koa_params.py (mort_garcia(),
# garcia_step(), h_from_qmd(), background_mortality(), and the
# GARCIA_BETA_ANCHORED / GARCIA_ALLOM_A / GARCIA_ALLOM_K_HD / BASE_NAT /
# BASE_PLT constants). Cross-validated against that Python source on
# firebreather, matched test case by test case; see
# koa_mortality_selftest_2026-09-09.R and
# HiGy_v040_parity_report_2026-09-09.md in this folder. Stage 1
# (koa_irregular_event) and Stage 3 (koa_renormalize_to_stand_rate,
# koa_alloc_frac, koa_allocate_mortality) are unchanged. koa_mortality_step(),
# the standalone wrapper documented as NOT on the production path, keeps its
# own explicit defaults (beta = KOA_GARCIA_BETA = 0.117, H40, no floor) and so
# still reproduces the 8 September 2026 numbers exactly; it is the fitted-H40
# arm kept on hand for comparison. koa_h40() is unchanged and still used by
# koa_mortality_step() and the self-test's cycle-invariance checks.
#
# STAGE 1 DEPLOYED AS A GATE, AND STAGE 3 MOVED TO THE FITTED SURVIVOR WEIGHT,
# 11 September 2026. The manuscript's mortality engine of record moved again on
# 12 September 2026 under MORTALITY_RULE_2026-09-12.md AMENDMENT 1, which scored
# five candidates on six pre-registered gates and selected M1. Two things in
# this file follow it and nothing else does.
#
#   1. THE GATE. Stage 1 is no longer only the optional stochastic event of
#      koa_irregular_event(). A deterministic complementary log-log occurrence
#      probability is now fitted and deployed, and it multiplies the stand rate:
#
#        m_deployed = clip( m_garcia / p_bar * p(SDI, origin),  0, 0.95 )
#        p(SDI, origin) = 1 - exp(-exp(eta)),  eta clipped to [-30, 5]
#        eta = b0 + b_lnSDI ln(max(SDI, 1)) + b_planted * planted + ln(YIP)
#
#      with p_bar = 0.3600578102962374 the mean fitted annual occurrence over
#      the fitting record. Dividing by p_bar makes the incumbent unconditional
#      rate CONDITIONAL on occurrence; multiplying by p gates it. The expected
#      rate over the fitting record is therefore unchanged by construction, and
#      the only thing that moves is the density response, which now enters
#      through occurrence rather than through magnitude. That is the finding the
#      rule rests on: on 326 plot intervals over 54 plots, koa mortality is
#      density dependent in HOW OFTEN it happens (ln SDI coefficient on
#      occurrence +0.1897, plot-clustered 95% interval [+0.0473, +0.3411], AUC
#      0.667) and density independent in HOW MUCH happens when it does (ln SDI
#      coefficient on the conditional rate -0.0610, interval [-0.2610, +0.1274]).
#
#      Chen et al. (2023) threshold p into a binary indicator that produces exact
#      zeros in a plot-level prediction. THAT THRESHOLD IS NOT DEPLOYED HERE AND
#      THE DEVIATION IS DELIBERATE: a projected mean stand over a century is not
#      a single plot realization, and a hard threshold would put a discontinuity
#      into a deterministic trajectory that nothing in the koa record supports.
#      p enters continuously.
#
#      The gate is applied AFTER the A1 background floor, because that is where
#      the deployed engine applies it (it wraps the Python stand_mortality(),
#      which floors before returning). A CONSEQUENCE WORTH STATING: at low
#      density, where p < p_bar, the gate scales the A1 floor DOWN, so a flat
#      stand no longer returns exactly 0.003 or 0.006 yr-1 but that value times
#      p/p_bar. This is the deployed behaviour and not an oversight.
#
#   2. THE STAGE 3 WEIGHT. Deaths are now ordered within the stand by the fitted
#      tree-level survivor equation, w = 1 - koa_surv_annual(...), rather than by
#      the as-published relative-size weight exp(-b (DBH/QMD - 1)). Per-tree
#      rates are still m_stand * w_i / wbar and still renormalized, so THE LEVEL
#      OF THAT EQUATION DOES NOT ACT: any constant multiplying w cancels between
#      w_i and wbar, and only the weight's spread across the tree list survives.
#      That is the same reason Chen uses his Stage 3 as a ranking, and it is why
#      deploying this equation here does not reopen its known level problems.
#      The relative-size weight is retained and reachable with mode = 'rel_size'.
#
#      koa_surv_annual() IS NOT surv_prob() AND DOES NOT RESOLVE THE TWO
#      DIVERGENCES FLAGGED ABOVE surv.parm. It is a separate function carrying
#      the separate constant vector KOA_S3_SURV, transcribed from the deposit's
#      figshare_v66/koa_equations.py LineageA.SURV, which is manuscript Table 6
#      on the ALIVE response. surv.parm and surv_prob() are untouched, still
#      carry the development-snapshot vector and the exp(-exp(eta)) sense, and
#      mort.engine = 'cloglog' still reproduces every pre-0.3.0 projection
#      byte for byte. The choice between those two lineages remains open and is
#      still for Aaron and Ben to settle; it is deliberately not decided here,
#      and it does not need to be, because a renormalized ordering weight is
#      insensitive to the level the two lineages disagree about.
# =============================================================================

# ---- Constants of record ----------------------------------------------------
KOA_GARCIA_ALPHA   = 2.96    # alpha = gamma, the ratio gamma/alpha fixed at 1
KOA_GARCIA_BETA    = 0.117   # m-1, limiting line S = beta * H40
KOA_REINEKE_EXP    = 1.605   # stand density index exponent, 1.605 and never 1.6
KOA_ALLOC_CAP      = 0.95    # per-tree mortality fraction cap, as deployed
KOA_IRREG_RATE     = 0.14    # irregular events per observed plot interval
KOA_IRREG_INTERVAL = 2.68    # mean observed interval length (yr) behind that rate
KOA_ALLOC_B        = 3       # steepness of the as-published size weight

# Anchored H_QMD arm of record, ported 9 September 2026 from the deposit's
# figshare_v66/koa_params.py (GARCIA_BETA_ANCHORED, GARCIA_ALLOM_A,
# GARCIA_ALLOM_K_HD, BASE_NAT, BASE_PLT). H_QMD = exp((ln(QMD) - a) / k_HD).
KOA_GARCIA_BETA_ANCHORED = 0.16019053617304435  # m-1, deployed arm of record
KOA_GARCIA_ALLOM_A       = -0.16863070512157105 # H_QMD allometry intercept
KOA_GARCIA_ALLOM_K_HD    = 1.1719473700506686   # H_QMD allometry slope
KOA_BASE_NAT             = 0.003    # yr-1, A1 background mortality floor, natural
KOA_BASE_PLT             = 0.006    # yr-1, A1 background mortality floor, planted

# Stage 1 occurrence gate, deployed 11 September 2026 as the engine of record
# (MORTALITY_RULE_2026-09-12.md AMENDMENT 1, candidate M1). Complementary
# log-log occurrence with an ln(YIP) offset, fitted on 326 consecutive plot
# intervals over 54 plots, AUC 0.6668306527909177. Transcribed AT FULL FITTED
# PRECISION from the fit's own out_stage1/stage1_fit.json (stage1_beta,
# stage1_mean_annual_p); no value here is rounded and none is invented.
# Plot-clustered 95% intervals, for the record and not used by any code path:
#   intercept [-2.7269211231135864, -1.1071172945674261]
#   lnSDI     [+0.04729187591110494, +0.34109027071589815]   excludes zero
#   planted   [-0.45582558486147245, +0.746073666295449]     includes zero
KOA_S1_INTERCEPT = -1.8660048476490962  # cloglog intercept
KOA_S1_LNSDI     =  0.18970168229495396 # coefficient on ln(max(SDI, 1))
KOA_S1_PLANTED   =  0.1833723331227772  # planted-origin offset
KOA_S1_PBAR      =  0.3600578102962374  # mean fitted ANNUAL occurrence, p_bar
KOA_S1_SDI_FLOOR = 1.0                  # ln argument floor, as deployed
KOA_S1_ETA_CLIP  = c(-30, 5)            # linear-predictor clip, as deployed
KOA_RATE_CAP     = 0.95                 # cap on the gated stand rate, as deployed

# Stage 3 ordering weight, fitted tree-level survivor equation, deployed
# 11 September 2026. Manuscript Table 6 on the ALIVE response, transcribed from
# the deposit's figshare_v66/koa_equations.py LineageA.SURV. READ THE HEADER
# NOTE ABOVE BEFORE COMPARING THIS WITH surv.parm: they are different vectors on
# different response senses from different lineages, both are deliberate, and
# this one is used ONLY as a renormalized within-stand ordering weight whose
# level cancels. It does not touch the retired cloglog path.
KOA_S3_SURV = c(b0 = 14.102,  b1 =  0.130, b2 = -4.516, b3 =   6.684,
                b4 = 14.218,  b5 = -2.806, b6 =  2.649, b7 = -21.188)
KOA_S3_W_FLOOR = 1e-9      # lower clip on the survivor weight, as deployed
KOA_ALLOC_MODE = "tree_eq" # Stage 3 default: 'tree_eq' fitted survivor weight,
                           # 'rel_size' the as-published exp(-b (DBH/QMD - 1))

# Empirical irregular-loss distribution: the cohort fraction lost in each of the
# 60 irregular intervals, meaning those above 0.10 yr-1, read as ndead / ntree
# from ben-package-2026-09-04/plot_interval_pairs_DATA.csv. Median 0.32, IQR 0.16
# to 0.69. EMBEDDED as literals rather than read, because this file may not open
# a data file, and checked against the source csv by the self-test.
KOA_IRREG_LOSS = c(0.1111, 0.1111, 0.1111, 0.1200, 0.1250, 0.1250, 0.1250, 0.1250,
                   0.1333, 0.1429, 0.1429, 0.1500, 0.1538, 0.1538, 0.1538, 0.1667,
                   0.1667, 0.1667, 0.1667, 0.1765, 0.2000, 0.2000, 0.2000, 0.2308,
                   0.2353, 0.2500, 0.2500, 0.2745, 0.3000, 0.3171, 0.3182, 0.3333,
                   0.3333, 0.4091, 0.4118, 0.4444, 0.4815, 0.5556, 0.5870, 0.6129,
                   0.6545, 0.6579, 0.6818, 0.6842, 0.6897, 0.7105, 0.7407, 0.7500,
                   0.8182, 0.8276, 0.8310, 0.8333, 0.8710, 0.9091, 0.9273, 1.0000,
                   1.0000, 1.0000, 1.0000, 1.0000)

#' Coerce stand origin to the planted indicator
#'
#' @param origin Character "Planted" or "Natural" (case-insensitive), or 0/1, or
#'   TRUE/FALSE, the same origin coding the rest of this file uses.
#' @return Integer: 1 for planted, 0 for natural.
koa_planted = function(origin) {
  if (is.character(origin)) return(as.integer(tolower(origin) == "planted"))
  as.integer(as.logical(origin))
}

#' Stand density index on the Reineke exponent of record
#'
#' The exponent is 1.605 and not 1.6. The two scales agree exactly at quadratic
#' mean diameter 25 cm and diverge by (Dq/25)^0.005, about 0.46 percent low at
#' Dq 10 cm and 0.44 percent high at Dq 60 cm. Stand density index is reported
#' only, since the Garcia step is driven by top height and not by density, yet
#' Stage 1 accepts it and a future covariate model would use it, so it is
#' computed on the scale everything else in the koa system is stated on. The
#' commented sdi line in HiGYOneStand() below shows the 1.6 form, is inert, and
#' must not be uncommented as written.
#'
#' @param tph Numeric: live trees ha-1.
#' @param qmd Numeric: quadratic mean diameter (cm).
#' @return Numeric: stand density index, tph * (qmd / 25)^1.605.
koa_sdi = function(tph, qmd) tph * (pmax(qmd, 0.1) / 25)^KOA_REINEKE_EXP

#' Top height H40 from a tree list
#'
#' Expansion-factor-weighted mean height of the 40 largest-diameter live trees
#' per ha, the manuscript Eq. 1 convention and the H the Garcia parameters were
#' fitted against. The record straddling the 40th tree takes the fractional
#' weight that completes 40 trees ha-1, so H40 is a continuous function of the
#' tree list and a stand does not step when one record crosses the boundary.
#' This is NOT calc_topht(), which orders by height over 100 trees ha-1; the two
#' are different quantities and the Garcia fit used this one.
#'
#' @param dbh Numeric: diameter at breast height (cm)
#' @param ht Numeric: total height (m)
#' @param expf Numeric: expansion factor (trees ha-1)
#' @return Numeric: H40 (m), or NA if no live tree carries a height.
koa_h40 = function(dbh, ht, expf) {
  ok = !is.na(dbh) & dbh > 0 & !is.na(ht) & ht > 0 & !is.na(expf) & expf > 0
  if (!any(ok)) return(NA_real_)
  o = order(-dbh[ok])
  h = ht[ok][o]
  w = expf[ok][o]
  ce = cumsum(w)
  ov = which(ce > 40)
  if (length(ov)) {
    i = ov[1]
    w[i] = max(40 - (if (i > 1) ce[i - 1] else 0), 0)
    if (i < length(w)) w[(i + 1):length(w)] = 0
  }
  if (sum(w) <= 0) return(NA_real_)
  sum(h * w) / sum(w)
}

#' Allometric height equivalent of quadratic mean diameter (H_QMD)
#'
#' H_QMD = exp((ln(QMD) - a) / k_HD), the state variable the deposit's
#' deployed garcia_qmd_anchored arm drives the Garcia (2009) step on, in place
#' of H40. Fitted by ordinary least squares on the same 360 regular plot
#' intervals as the mortality step itself. Ported line for line from
#' figshare_v66/koa_mortality_garcia.py:h_from_qmd(), 9 September 2026.
#'
#' @param qmd Numeric: quadratic mean diameter (cm).
#' @param a Numeric: allometry intercept, -0.16863070512157105 as deployed.
#' @param k_hd Numeric: allometry slope, 1.1719473700506686 as deployed.
#' @return Numeric: H_QMD (m).
koa_h_qmd = function(qmd, a = KOA_GARCIA_ALLOM_A, k_hd = KOA_GARCIA_ALLOM_K_HD) {
  q = pmax(as.numeric(qmd), 1e-6)
  exp((log(q) - a) / k_hd)
}

### Stage 1 gate: deterministic occurrence probability ####

#' Annual probability that a stand experiences any mortality
#'
#' Complementary log-log occurrence with an ln(YIP) offset,
#'
#'   p = 1 - exp(-exp(eta)),
#'   eta = b0 + b_lnSDI ln(max(SDI, 1)) + b_planted * planted + ln(YIP),
#'
#' with eta clipped to [-30, 5] before exponentiation exactly as the deployed
#' source clips it. Ported line for line from the deployed threestage.py
#' stage1_p(), 11 September 2026. The offset is an exposure term: a longer
#' interval carries a higher chance of seeing any mortality at all.
#'
#' @param sdi Numeric: stand density index at the start of the step, on the
#'   Reineke exponent koa_sdi() uses. Floored at 1 inside the logarithm.
#' @param origin Character "Planted"/"Natural" or numeric 1/0.
#' @param yip Numeric: interval length in years, the ln(YIP) offset. Default 1.
#'   See koa_gate_rate() for why the GATE is always evaluated at yip = 1.
#' @param intercept,b_lnsdi,b_planted Numeric: fitted coefficients, defaults
#'   KOA_S1_INTERCEPT, KOA_S1_LNSDI, KOA_S1_PLANTED.
#' @param sdi_floor,eta_clip Numeric: deployed guards, KOA_S1_SDI_FLOOR and
#'   KOA_S1_ETA_CLIP.
#' @return Numeric: annual occurrence probability on 0 to 1.
koa_stage1_p = function(sdi, origin = "Natural", yip = 1,
                        intercept = KOA_S1_INTERCEPT,
                        b_lnsdi   = KOA_S1_LNSDI,
                        b_planted = KOA_S1_PLANTED,
                        sdi_floor = KOA_S1_SDI_FLOOR,
                        eta_clip  = KOA_S1_ETA_CLIP) {
  s   = pmax(as.numeric(sdi), sdi_floor)
  y   = pmax(as.numeric(yip), 1e-9)
  eta = intercept + b_lnsdi * log(s) + b_planted * koa_planted(origin) + log(y)
  eta = pmin(pmax(eta, eta_clip[1]), eta_clip[2])
  1 - exp(-exp(eta))
}

#' Gate the stand mortality rate on the Stage 1 occurrence probability
#'
#' THE DEPLOYED RATE OF RECORD, M1 of MORTALITY_RULE_2026-09-12.md AMENDMENT 1:
#'
#'   m_deployed = clip( m_stand / p_bar * p(SDI, origin), 0, 0.95 )
#'
#' Dividing the incumbent rate by the mean fitted annual occurrence p_bar makes
#' it conditional on occurrence, which is the footing Chen's Stage 2 is fitted
#' on; multiplying by the fitted occurrence then gates it. The mean deployed
#' rate over the fitting record is unchanged from the ungated engine by
#' construction, so nothing published moves except through the gate, and the
#' density response now enters through occurrence. Ported line for line from the
#' deployed threestage.py rate_M1().
#'
#' THE GATE IS ALWAYS EVALUATED AT YIP = 1 AND DOES NOT TAKE A yip ARGUMENT.
#' What multiplies the rate is the ratio p(SDI) / p_bar, a mean-one relative
#' density adjustment, and p_bar is an ANNUAL mean. Numerator and denominator
#' have to sit on the same annual footing or the ratio stops being mean one, so
#' feeding a multi-year YIP into the numerator alone would silently inflate
#' every rate. The ratio is dimensionless and applies to a step of any length,
#' which is what lets the Garcia step keep its exactness in step length. The
#' deployed engine steps annually and was scored only there.
#'
#' WHEN SDI IS NOT AVAILABLE THE RATE PASSES THROUGH UNGATED, which is what the
#' deployed wrapper does (it returns the raw rate whenever sdi is None or not
#' finite). It is a silent pass-through there and it is a silent pass-through
#' here so the two cannot disagree, but it means a caller who wants the gate
#' must supply SDI. calc_mortality() always does.
#'
#' @param m_stand Numeric: the stand step mortality fraction from
#'   koa_regular_survival(), AFTER the A1 background floor. The gate is applied
#'   after the floor because the deployed engine applies it there, so at low
#'   density the floor is scaled down by p / p_bar rather than held.
#' @param sdi Numeric: stand density index at the start of the step.
#' @param origin Character "Planted"/"Natural" or numeric 1/0.
#' @param p_bar Numeric: mean fitted annual occurrence, KOA_S1_PBAR.
#' @param cap Numeric: upper clip on the gated rate, KOA_RATE_CAP (0.95).
#' @return Numeric: the gated stand step mortality fraction.
koa_gate_rate = function(m_stand, sdi, origin = "Natural",
                         p_bar = KOA_S1_PBAR, cap = KOA_RATE_CAP) {
  m = as.numeric(m_stand)
  s = suppressWarnings(as.numeric(sdi))
  if (length(s) == 0L || !is.finite(s[1])) return(m)
  p = koa_stage1_p(s[1], origin, yip = 1)
  pmin(pmax(m / p_bar * p, 0), cap)
}

### Stage 2: regular stand-level survival (Garcia 2009) ####

#' Regular stand-level survival, Garcia (2009) form with gamma/alpha = 1
#'
#' Garcia's model is S^alpha - (beta H)^gamma constant along a stand's path, with
#' S = 100 / sqrt(N) the mean spacing in m and H the top height H40 in m. The
#' ratio gamma/alpha is not identified on the koa record, the free-fit bootstrap
#' interval running 0.33 to 11.6, so it is fixed at 1, which is Garcia's own
#' remedy for sparse data. With that ratio the survivors at the end of a step are
#'
#'   S1^alpha = S0^alpha - (beta H40_0)^alpha + (beta H40_1)^alpha
#'   N1       = 10000 / S1^2
#'
#' Three properties matter for a projector and are worth stating plainly. The
#' solution is EXACT for any step length, because the state variable is height
#' and not time, so one 10-year cycle and ten 1-year cycles on the same height
#' path return the same N1 and no annualization is needed anywhere in the
#' component. No regular mortality occurs when H40 does not increase, since
#' mortality is driven entirely by the height increment FVS-HI projects. And the
#' limiting line is S = beta H40, equivalently log N + 2 log H40 constant, which
#' a stand approaches from below and cannot cross.
#'
#' Origin does not enter the fitted form and that is a known gap rather than a
#' finding. Under leave-one-installation-out the fit predicts 0.4% yr⁻¹ for
#' planted stands against 2.2% observed over 41 intervals, because planted H40
#' growth is small in those intervals. planted_background is exposed as a TODO
#' hook, default NA and off, so the hook exists without a number anyone can yet
#' defend. When a value is supplied it applies (1 - planted_background)^yip as an
#' additional annual survival factor to planted stands only, which needs yip.
#'
#' THE A1 BACKGROUND FLOOR IS APPLIED HERE, ported 9 September 2026 to match
#' the Zenodo deposit's background_mortality()/mort_garcia(): the step
#' mortality fraction cannot fall below base_nat (0.003 yr⁻¹ natural) or
#' base_plt (0.006 yr⁻¹ planted), so a stand whose top height is flat still
#' returns the background rate rather than zero. Set base_nat = base_plt = NA
#' to reproduce the unfloored 8 September 2026 behaviour exactly, which is
#' what koa_mortality_step() below still does by explicit default.
#'
#' @param N0 Numeric: live koa trees ha-1 at the start of the step (dbh > 0).
#' @param H40_0 Numeric: top height (m) at the start of the step.
#' @param H40_1 Numeric: top height (m) FVS-HI projects for the end of the step.
#' @param origin Character "Planted"/"Natural" or numeric 1/0.
#' @param alpha,beta Numeric: Garcia parameters of record. alpha is 2.96.
#'   beta defaults to the anchored H_QMD arm, 0.16019053617304435; pass
#'   beta = KOA_GARCIA_BETA (0.117) for the fitted H40 arm.
#' @param planted_background Numeric: TODO, annual background mortality for
#'   planted stands, default NA and OFF. Not fitted, see the comment above.
#' @param yip Numeric: step length in years, needed only when
#'   planted_background is set.
#' @param base_nat,base_plt Numeric: A1 background mortality floor (yr⁻¹),
#'   the step mortality fraction cannot fall below this. Default
#'   KOA_BASE_NAT (0.003) and KOA_BASE_PLT (0.006), the deposit's deployed
#'   values. Pass NA to turn the floor off and reproduce the unfloored
#'   8 September 2026 arm exactly.
#' @return List: N1, deaths, m_step (the step mortality fraction deaths / N0,
#'   after the A1 floor), S0, S1, N_limit (the limiting density at the
#'   end-of-step top height).
koa_regular_survival = function(N0, H40_0, H40_1, origin = "Natural",
                                alpha = KOA_GARCIA_ALPHA,
                                beta = KOA_GARCIA_BETA_ANCHORED,
                                planted_background = NA, yip = NA,
                                base_nat = KOA_BASE_NAT, base_plt = KOA_BASE_PLT) {
  stopifnot(length(N0) == 1, is.finite(N0), N0 >= 0,
            is.finite(H40_0), is.finite(H40_1), H40_0 > 0, alpha > 0, beta > 0)
  planted = koa_planted(origin)
  base = if (isTRUE(planted == 1L)) base_plt else base_nat
  if (N0 <= 0) return(list(N1 = 0, deaths = 0, m_step = 0, S0 = Inf, S1 = Inf,
                           N_limit = 10000 / (beta * H40_1)^2))
  H1 = max(H40_1, H40_0)                  # no regular mortality without height growth
  S0 = 100 / sqrt(N0)
  # Short circuit on a flat or falling top height, so that "no height growth
  # means no regular mortality" holds EXACTLY rather than to rounding. Evaluating
  # the general expression on H1 == H40_0 subtracts and then re-adds the same
  # (beta H)^alpha term, which loses low bits and returns deaths of order
  # 1e-13 trees ha-1 instead of zero. The residue is physically nothing, yet it
  # accumulates over a long projection and it makes a stated property of the
  # component untestable, so it is removed here rather than tolerated. Added
  # 8 September 2026 after the self-test caught it; no growing stand is affected.
  if (H1 <= H40_0) {
    N1 = N0; m_step = 0; S1 = S0
  } else {
    inner = S0^alpha - (beta * H40_0)^alpha + (beta * H1)^alpha
    S1 = max(inner, 1e-9)^(1 / alpha)
    N1 = 10000 / S1^2
    N1 = min(N1, N0)                      # numerical guard; cannot exceed N0 analytically
    m_step = (N0 - N1) / N0
  }
  # A1 background mortality floor, ported 9 September 2026 to match the
  # deposit's background_mortality()/mort_garcia(): the stand step rate
  # cannot fall below base_nat (natural) or base_plt (planted). See the
  # component header and the doc paragraph above.
  if (!is.na(base)) {
    m_step = max(m_step, base)
    N1 = N0 * (1 - m_step)
  }
  if (!is.na(planted_background) && planted == 1L) {
    if (is.na(yip)) stop("planted_background needs yip (step length in years)")
    N1 = N1 * (1 - planted_background)^yip
    m_step = (N0 - N1) / N0
  }
  list(N1 = N1, deaths = N0 - N1, m_step = m_step, S0 = S0, S1 = S1,
       N_limit = 10000 / (beta * H1)^2)
}

### Stage 3: allocation of stand deaths to trees ####

#' Fitted tree-level annual survival, used ONLY as the Stage 3 ordering weight
#'
#' Manuscript Table 6 on the ALIVE response, a complementary log-log with an
#' ln(YIP) offset:
#'
#'   P(alive) = clip( 1 - exp(-exp(eta + ln YIP)), 0, 1 )
#'   eta = b0 + b1 HT + b2 ln(HT) + b3 rHT + b4 ln(clip(CR, 0.01, 0.99))
#'         + b5 ln(HT / DBH) + b6 ln(max(BYI, 1) / 100) + b7 (BYI / 1000)
#'
#' with HT in m, DBH in cm and HT floored at 0.1 m and DBH at 0.1 cm before use.
#' Ported line for line from the deposit's figshare_v66/koa_equations.py
#' LineageA.surv_annual(), 11 September 2026.
#'
#' THIS IS NOT surv_prob() AND IT IS NOT A SECOND PRODUCTION SURVIVAL EQUATION.
#' It carries a different coefficient vector (KOA_S3_SURV, Table 6) and the
#' opposite response sense from surv.parm/surv_prob(), and both of those facts
#' are the open divergence flagged in the block above surv.parm, which this edit
#' does not settle. It does not have to. The only use of this function is inside
#' koa_alloc_frac(mode = 'tree_eq'), where its output becomes a weight that is
#' immediately renormalized against its own expansion-factor-weighted mean. Any
#' constant scaling of the weight cancels, so the LEVEL of this equation has no
#' effect on any number this file returns; only its spread across a tree list
#' does. Deaths are ORDERED by it, not sized by it.
#'
#' @param dbh Numeric: diameter at breast height (cm).
#' @param ht Numeric: total height (m).
#' @param cr Numeric: live crown ratio (0 to 1), clipped to 0.01 to 0.99.
#' @param rht Numeric: relative height, ht divided by the stand height maximum.
#' @param byi Numeric: biomass yield index (Mg ha-1).
#' @param yip Numeric: interval length in years, the ln(YIP) offset. Default 1.
#' @param p Numeric: named coefficient vector, KOA_S3_SURV.
#' @return Numeric: annual survival probability on 0 to 1.
koa_surv_annual = function(dbh, ht, cr, rht, byi, yip = 1, p = KOA_S3_SURV) {
  ht  = pmax(as.numeric(ht),  0.1)
  dbh = pmax(as.numeric(dbh), 0.1)
  eta = p[["b0"]] + p[["b1"]] * ht + p[["b2"]] * log(ht) +
        p[["b3"]] * as.numeric(rht) +
        p[["b4"]] * log(pmin(pmax(as.numeric(cr), 0.01), 0.99)) +
        p[["b5"]] * log(ht / dbh) +
        p[["b6"]] * log(pmax(as.numeric(byi), 1) / 100) +
        p[["b7"]] * (as.numeric(byi) / 1000)
  pmin(pmax(1 - exp(-exp(eta + log(yip))), 0), 1)
}

#' Renormalize per-tree mortality to the stand rate after the cap
#'
#' THE SINGLE CARRIER OF THE R1 ALGEBRA IN THIS FILE. koa_alloc_frac() calls it
#' and does not inline a second copy; a second copy of this solve is a defect and
#' not a convenience. Carried over line for line from
#' koa.SURV.renormalize.to.stand.rate as deposited, which is itself the
#' line-for-line transcription of the Python renormalize_to_stand_rate. The four
#' things that must not drift are carried over unchanged, namely the same two
#' early returns with INFEASIBILITY TESTED FIRST, the same geometric bracketing
#' from lambda = 1, the same bisection test taken BEFORE the midpoint is formed,
#' and the same return of the UPPER bracket hi rather than the midpoint. The
#' delivered guarantee is
#'   sum(expf * m_i) / sum(expf) == m_stand
#' to rtol where the cap binds and to machine precision where it does not, which
#' is what makes sum(dexpf) equal the stand deaths.
#'
#' @param m_i Numeric: uncapped per-tree step mortality fractions, the
#'   m_stand * w_i / wbar allocation, weighted mean m_stand by construction.
#' @param expf Numeric: expansion factors (trees ha-1).
#' @param m_stand Numeric: target stand step mortality fraction.
#' @param cap Numeric: per-tree ceiling, 0.95 as deployed.
#' @param renormalize Logical: FALSE returns the clipped allocation and is the
#'   as-published path, retained for reproduction and not for production.
#' @param rtol Numeric: relative tolerance on the lambda bracket, 1e-12.
#' @param max_iter Integer: iteration ceiling on both loops.
#' @return Numeric: per-tree step mortality fractions on the interval 0 to cap.
koa_renormalize_to_stand_rate = function(m_i, expf, m_stand, cap = KOA_ALLOC_CAP,
                                         renormalize = TRUE,
                                         rtol = 1e-12, max_iter = 200L) {
  m      = as.numeric(m_i)
  capped = pmin(pmax(m, 0), cap)
  if (!isTRUE(renormalize)) return(capped)
  e    = as.numeric(expf)
  esum = sum(e)
  ms   = as.numeric(m_stand)[1]
  if (esum <= 0 || length(m) == 0L || ms <= 0) return(capped)
  if (ms >= cap) {
    warning(sprintf(paste0("koa_renormalize_to_stand_rate: stand mortality rate ",
                           "%.6g is at or above the per-tree cap %.6g, so no ",
                           "allocation can deliver it. Every tree is set to the ",
                           "cap and the stand under delivers by %.6g."),
                    ms, cap, ms - cap))
    return(rep(cap, length(m)))
  }
  if (max(m) <= cap) return(capped)          # lambda = 1 exactly, nothing to do
  wmean = function(lam) sum(e * pmin(lam * m, cap)) / esum
  lo = 1; hi = 1                    # wmean(1) <= m_stand here, the cap binds
  bracketed = FALSE
  for (i in seq_len(max_iter)) {
    if (wmean(hi) >= ms) { bracketed = TRUE; break }
    lo = hi; hi = hi * 2
  }
  if (!bracketed) {
    warning(sprintf(paste0("koa_renormalize_to_stand_rate: failed to bracket ",
                           "lambda for stand rate %.6g under cap %.6g; returning ",
                           "the capped allocation unrescaled."), ms, cap))
    return(capped)
  }
  for (i in seq_len(max_iter)) {
    if (hi - lo <= rtol * hi) break
    mid = 0.5 * (lo + hi)
    if (wmean(mid) < ms) lo = mid else hi = mid
  }
  pmin(pmax(hi * m, 0), cap)
}

#' Per-tree step mortality fraction from the stand deaths, by relative diameter
#'
#' The single carrier of the Stage 3 algebra, vector in and vector out, so that
#' calc_mortality() and koa_allocate_mortality() cannot drift apart. Within-plot
#' ordering of deaths by relative diameter alone reaches a concordance of 0.73 in
#' regular intervals and 0.78 in irregular ones, with relative height and basal
#' area in larger trees no better, so the manuscript Table 6 complementary
#' log-log is not needed as the ordering weight and is not used here. The weight
#' is the as-published size weight w = exp(-b (DBH/QMD - 1)) with b = 3, which
#' weights small trees up. The ordering, and therefore the concordance, does not
#' depend on b; b sets how steeply the stand rate is spread across the diameter
#' distribution. Per-tree fractions are m_stand * w_i / wbar, capped at 0.95 and
#' renormalized so the expansion-factor-weighted mean equals the stand step
#' mortality exactly.
#'
#' TWO WEIGHTS, ONE ALGEBRA, 11 September 2026. The deployed engine of record
#' orders deaths by the FITTED TREE-LEVEL SURVIVOR EQUATION and not by relative
#' size, so mode = 'tree_eq' is now the default and
#'
#'   w = clip( 1 - koa_surv_annual(dbh, ht, cr, rht, byi), 1e-9, 1 )
#'
#' replaces the relative-size weight above. The paragraph above is the reason
#' the as-published weight was adequate and it is retained on its merits at
#' mode = 'rel_size'; the reason the deployed engine moved is that the fitted
#' equation carries height, crown ratio and relative height as well as size, and
#' the manuscript already reports it, so using it here removes a second and
#' redundant ordering rule from the system. Everything after the weight is
#' identical in both modes: per-tree fractions are m_stand * w_i / wbar, capped,
#' and renormalized by the single carrier below. BECAUSE OF THAT
#' RENORMALIZATION THE WEIGHT'S LEVEL CANCELS IN BOTH MODES and only its spread
#' across the tree list acts.
#'
#' @param dbh Numeric: diameter at breast height (cm), live records only.
#' @param expf Numeric: expansion factor (trees ha-1).
#' @param deaths_ha Numeric: stand deaths over the step (trees ha-1).
#' @param b Numeric: steepness of the size weight, 3 as published. mode
#'   'rel_size' only.
#' @param cap Numeric: per-tree cap on the step mortality fraction.
#' @param mode Character: 'tree_eq' (default, KOA_ALLOC_MODE) orders deaths by
#'   the fitted survivor equation; 'rel_size' uses the as-published
#'   exp(-b (DBH/QMD - 1)) and reproduces the 9 September 2026 allocation.
#' @param ht,cr,rht,byi Numeric: required by mode 'tree_eq' and ignored by
#'   'rel_size'. Each must be either length 1 or the length of dbh. A missing
#'   one is an error and never a silent fallback to the other weight.
#' @param surv Numeric: named coefficient vector for the weight, KOA_S3_SURV.
#' @param w_floor Numeric: lower clip on the survivor weight, KOA_S3_W_FLOOR.
#' @return Numeric: per-tree step mortality fraction, same length as dbh.
koa_alloc_frac = function(dbh, expf, deaths_ha, b = KOA_ALLOC_B, cap = KOA_ALLOC_CAP,
                          mode = KOA_ALLOC_MODE,
                          ht = NULL, cr = NULL, rht = NULL, byi = NULL,
                          surv = KOA_S3_SURV, w_floor = KOA_S3_W_FLOOR) {
  mode = match.arg(mode, c("tree_eq", "rel_size"))
  n = length(dbh)
  if (n == 0L) return(numeric(0))
  dbh = as.numeric(dbh); expf = as.numeric(expf)
  if (any(!is.finite(dbh)) || any(!is.finite(expf)) || any(expf < 0))
    stop("koa_alloc_frac: dbh and expf must be finite and expf must be non-negative")
  N0 = sum(expf)
  if (N0 <= 0) return(rep(0, n))
  qmd = sqrt(sum(expf * dbh^2) / N0)
  m_stand = min(max(deaths_ha / N0, 0), 1)
  if (m_stand <= 0) return(rep(0, n))
  if (mode == "tree_eq") {
    miss = c("ht", "cr", "rht", "byi")[c(is.null(ht), is.null(cr), is.null(rht),
                                         is.null(byi))]
    if (length(miss))
      stop(sprintf(paste0("koa_alloc_frac(mode = 'tree_eq') needs %s. The fitted ",
                          "survivor weight is the deployed Stage 3 ordering and it ",
                          "cannot be formed from dbh and expf alone. Supply them, or ",
                          "pass mode = 'rel_size' for the as-published size weight."),
                   paste(miss, collapse = ", ")))
    rep_n = function(x, nm) {
      x = as.numeric(x)
      if (length(x) == 1L) x = rep(x, n)
      if (length(x) != n) stop(sprintf("koa_alloc_frac: %s must be length 1 or %d", nm, n))
      if (any(!is.finite(x))) stop(sprintf("koa_alloc_frac: %s must be finite", nm))
      x
    }
    w = 1 - koa_surv_annual(dbh, rep_n(ht, "ht"), rep_n(cr, "cr"),
                            rep_n(rht, "rht"), rep_n(byi, "byi"), p = surv)
    w = pmin(pmax(w, w_floor), 1)
  } else {
    w = exp(-b * (dbh / max(qmd, 0.1) - 1))
  }
  wbar = sum(w * expf) / N0
  koa_renormalize_to_stand_rate(m_stand * w / max(wbar, 1e-9), expf, m_stand, cap = cap)
}

#' Allocate stand-level deaths to trees by relative diameter
#'
#' Dataframe wrapper on koa_alloc_frac(), kept because the 4 September 2026
#' package and its self-test call this signature and because it returns the
#' diagnostic columns a reviewer wants to see. It holds no algebra of its own.
#'
#' MODE DEFAULTS TO 'rel_size' HERE AND NOT TO THE PRODUCTION DEFAULT, and that
#' is deliberate. This wrapper and koa_mortality_step() are the standalone
#' non-production entry points, and the 0.4.0 parity report undertakes that they
#' keep returning what they returned on 9 September 2026. They therefore pin
#' their own defaults the same way koa_mortality_step() already pins
#' beta = KOA_GARCIA_BETA and the floor off. Pass mode = 'tree_eq' with ht, cr,
#' rht and byi to drive the deployed Stage 3 ordering from a bare tree list.
#' calc_mortality(), the production path, defaults to 'tree_eq'.
#'
#' @param tree_df Dataframe: at least columns dbh (cm) and expf (trees ha-1),
#'   holding live koa records with dbh > 0 only. Mode 'tree_eq' additionally
#'   needs ht (m), cr and byi, and uses rht if present or forms it from the
#'   tree list's own height maximum if not.
#' @param deaths_ha Numeric: stand deaths over the step (trees ha-1), from
#'   koa_regular_survival()$deaths plus any irregular loss.
#' @param b Numeric: steepness of the size weight, 3 as published.
#' @param cap Numeric: per-tree cap on the step mortality fraction.
#' @param mode Character: 'rel_size' (default here) or 'tree_eq'.
#' @return Dataframe: tree_df with rdbh, w_alloc, mort_frac and dexpf added.
#'   w_alloc always reports the weight the chosen mode actually used.
koa_allocate_mortality = function(tree_df, deaths_ha, b = KOA_ALLOC_B, cap = KOA_ALLOC_CAP,
                                  mode = "rel_size") {
  mode = match.arg(mode, c("rel_size", "tree_eq"))
  stopifnot(is.data.frame(tree_df), all(c("dbh", "expf") %in% names(tree_df)))
  if (nrow(tree_df) == 0L) {
    tree_df$rdbh = tree_df$w_alloc = tree_df$mort_frac = tree_df$dexpf = numeric(0)
    return(tree_df)
  }
  dbh = as.numeric(tree_df$dbh); expf = as.numeric(tree_df$expf)
  qmd = sqrt(sum(expf * dbh^2) / sum(expf))
  tree_df$rdbh = dbh / max(qmd, 0.1)
  if (mode == "tree_eq") {
    need = c("ht", "cr", "byi")[!c("ht", "cr", "byi") %in% names(tree_df)]
    if (length(need))
      stop(sprintf(paste0("koa_allocate_mortality(mode = 'tree_eq') needs column(s) %s ",
                          "for the fitted survivor weight."), paste(need, collapse = ", ")))
    rht = if ("rht" %in% names(tree_df)) as.numeric(tree_df$rht) else
      as.numeric(tree_df$ht) / max(c(as.numeric(tree_df$ht), 0.1), na.rm = TRUE)
    tree_df$w_alloc = pmin(pmax(1 - koa_surv_annual(dbh, tree_df$ht, tree_df$cr,
                                                    rht, tree_df$byi),
                                KOA_S3_W_FLOOR), 1)
    tree_df$mort_frac = koa_alloc_frac(dbh, expf, deaths_ha, b = b, cap = cap,
                                       mode = "tree_eq", ht = tree_df$ht,
                                       cr = tree_df$cr, rht = rht, byi = tree_df$byi)
  } else {
    tree_df$w_alloc = exp(-b * (tree_df$rdbh - 1))
    tree_df$mort_frac = koa_alloc_frac(dbh, expf, deaths_ha, b = b, cap = cap,
                                       mode = "rel_size")
  }
  tree_df$dexpf = expf * tree_df$mort_frac
  tree_df
}

### Stage 1: irregular event (optional, OFF by default) ####

#' Optional stochastic irregular mortality event
#'
#' In the koa record 60 of 421 plot intervals (14%) are irregular, meaning cohort
#' mortality above 0.10 yr⁻¹, and they carry 66% of all deaths, as a mixture of
#' thinning removals, one FIA die-off and older plantation losses of unrecorded
#' cause. Occurrence is only weakly predictable, a logistic on ln stand density
#' index, origin and ln interval reaching an area under the curve of 0.61, so it
#' is offered as a stochastic stage on the observed occurrence rate and the
#' empirical magnitude distribution rather than as part of the deterministic
#' default. The 0.14 is a rate per observed plot interval of mean length 2.68 yr,
#' and the observed rate barely rises with interval length, 0.138 at 1 yr against
#' 0.127 at 6 to 30 yr, so converting it to a step of yip years is a convention
#' rather than a result. The default treats it as an annual hazard
#' h = 1 - (1 - rate)^(1/interval_ref), giving h = 0.055 yr⁻¹ and
#' p_step = 1 - (1 - h)^yip. Setting interval_ref to NA applies the rate once per
#' call regardless of yip. Magnitude is drawn from the 60 observed cohort-loss
#' fractions, median 0.32 and IQR 0.16 to 0.69. Stand density index and origin
#' are accepted for interface stability and to allow a future covariate model,
#' yet they do not change the draw here. Turn this on only for stochastic runs
#' and record the seed.
#'
#' @param sdi Numeric: stand density index at the start of the step, unused in
#'   the draw.
#' @param origin Character "Planted"/"Natural" or numeric 1/0, unused in the draw.
#' @param yip Numeric: step length in years.
#' @param rate Numeric: occurrence rate per observed plot interval, 0.14.
#' @param interval_ref Numeric: mean observed interval length (yr) used to
#'   annualize the rate, 2.68; NA applies the rate once per call.
#' @param loss_dist Numeric: the empirical cohort-loss fractions to sample from.
#' @param seed Numeric: optional RNG seed for reproducibility.
#' @return List: event (logical), loss_frac, p_step.
koa_irregular_event = function(sdi = NA, origin = "Natural", yip = 1,
                               rate = KOA_IRREG_RATE,
                               interval_ref = KOA_IRREG_INTERVAL,
                               loss_dist = KOA_IRREG_LOSS, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  p_step = if (is.na(interval_ref)) rate else 1 - (1 - rate)^(yip / interval_ref)
  event = runif(1) < p_step
  loss = if (event) sample(loss_dist, 1) else 0
  list(event = event, loss_frac = loss, p_step = p_step)
}

#' Three-stage koa mortality for one plot over one step
#'
#' Standalone wrapper mirroring koa_mortality_step() of the 4 September 2026
#' package, kept so a caller outside HiGYOneStand() can drive the component from
#' a bare tree list. calc_mortality() below does not call it, since it works on
#' the joined tree frame with dplyr and needs the per-tree columns in place, yet
#' the two share koa_regular_survival() and koa_alloc_frac() so they cannot
#' disagree on any number.
#'
#' @param tree_df Dataframe: dbh (cm), expf (trees ha-1) and, when H40_0 is not
#'   supplied, ht (m).
#' @param H40_0 Numeric: top height at step start (m), computed from tree_df if NA.
#' @param H40_1 Numeric: top height projected for step end (m). Required.
#' @param origin Character "Planted"/"Natural" or numeric 1/0.
#' @param yip Numeric: step length in years.
#' @param sdi Numeric: optional stand density index at step start, computed if NA.
#' @param irregular Logical: run the optional stochastic Stage 1, default FALSE.
#' @param seed Numeric: RNG seed passed to Stage 1.
#' @param alpha,beta,planted_background Passed to koa_regular_survival().
#'   beta defaults here to KOA_GARCIA_BETA (0.117, the fitted H40 arm), not
#'   the anchored default koa_regular_survival() otherwise uses, and
#'   base_nat/base_plt default to NA (floor off), so this standalone wrapper
#'   keeps reproducing the 8 September 2026 numbers exactly. It is not on the
#'   production path (see below); calc_mortality() uses the anchored H_QMD
#'   arm with the A1 floor via koa_step_deaths().
#' @param base_nat,base_plt Numeric: A1 floor, default NA (off) here to
#'   preserve the fitted-H40 arm's original unfloored behaviour.
#' @param mort_mult Numeric: FVS mortality multiplier applied to dexpf.
#' @param alloc_mode Character: Stage 3 weight, default 'rel_size' HERE so this
#'   wrapper keeps reproducing the 9 September 2026 numbers exactly, unlike
#'   calc_mortality() which defaults to the deployed 'tree_eq'. Pass 'tree_eq'
#'   with ht, cr and byi columns on tree_df to drive the deployed ordering.
#' @param gate Logical: apply the Stage 1 occurrence gate to the stand rate,
#'   default FALSE HERE for the same reason. calc_mortality() defaults to TRUE.
#'   When TRUE the sdi argument is what the gate reads.
#' @return List: tree (tree_df with rdbh, w_alloc, mort_frac, dexpf) and stand
#'   (a one-row summary).
koa_mortality_step = function(tree_df, H40_0 = NA, H40_1, origin = "Natural", yip = 1,
                              sdi = NA, irregular = FALSE, seed = NULL,
                              alpha = KOA_GARCIA_ALPHA, beta = KOA_GARCIA_BETA,
                              planted_background = NA, mort_mult = 1,
                              base_nat = NA, base_plt = NA,
                              alloc_mode = "rel_size", gate = FALSE) {
  stopifnot(is.data.frame(tree_df), all(c("dbh", "expf") %in% names(tree_df)))
  live = tree_df$expf > 0 & tree_df$dbh > 0
  td = tree_df[live, , drop = FALSE]
  N0 = sum(td$expf)
  if (is.na(H40_0)) {
    if (!"ht" %in% names(td)) stop("supply H40_0 or a ht column")
    H40_0 = koa_h40(td$dbh, td$ht, td$expf)
  }
  if (is.na(sdi)) sdi = koa_sdi(N0, sqrt(sum(td$expf * td$dbh^2) / N0))
  reg = koa_regular_survival(N0, H40_0, H40_1, origin, alpha, beta,
                             planted_background, yip, base_nat, base_plt)
  # Stage 1 gate, OFF by default in this standalone wrapper; see the argument
  # documentation above. When on it reproduces koa_step_deaths()'s production
  # path exactly, gate applied to the post-floor rate and the irregular loss
  # then taken from the gated survivors.
  N1_reg = reg$N1; d_reg = reg$deaths
  if (isTRUE(gate)) {
    m_gated = koa_gate_rate(reg$m_step, sdi = sdi, origin = origin)
    N1_reg  = N0 * (1 - m_gated)
    d_reg   = N0 - N1_reg
  }
  ev = list(event = FALSE, loss_frac = 0, p_step = 0)
  if (isTRUE(irregular)) ev = koa_irregular_event(sdi, origin, yip, seed = seed)
  d_irr = ev$loss_frac * N1_reg            # event loss taken from the regular survivors
  deaths = d_reg + d_irr
  td = koa_allocate_mortality(td, deaths, mode = alloc_mode)
  td$dexpf = td$dexpf * mort_mult
  out = tree_df
  out$rdbh = out$w_alloc = out$mort_frac = out$dexpf = 0
  out[live, c("rdbh", "w_alloc", "mort_frac", "dexpf")] =
    td[, c("rdbh", "w_alloc", "mort_frac", "dexpf")]
  list(tree = out,
       stand = data.frame(N0 = N0, N1 = N0 - deaths, H40_0 = H40_0, H40_1 = H40_1,
                          SDI0 = sdi, deaths_regular = d_reg,
                          deaths_irregular = d_irr, deaths_total = deaths,
                          m_step = deaths / N0, N_limit = reg$N_limit,
                          event = ev$event))
}

#' Stand deaths over one step, guarded, for use inside a grouped mutate
#'
#' Scalar wrapper on koa_regular_survival() and koa_irregular_event() that
#' returns 0 rather than stopping on a plot the component cannot act on, namely
#' one with no live koa records, a zero or missing top height at the step start,
#' or a missing projected top height. Every guard here returns no deaths and none
#' of them substitutes a value, since a plot whose height state is unknown is a
#' plot whose regular mortality is unknown and inventing one would be worse than
#' leaving it alone.
#'
#' @param n0 Numeric: live koa trees ha-1 at the step start.
#' @param h40_0 Numeric: top height (m) at the step start.
#' @param h40_1 Numeric: top height (m) projected for the step end.
#' @param planted Numeric: 1 planted, 0 natural.
#' @param yip Numeric: step length in years.
#' @param irregular Logical: run the stochastic Stage 1.
#' THE STAGE 1 GATE IS APPLIED HERE AND THIS IS THE ONLY PRODUCTION RATE PATH,
#' 11 September 2026. calc_mortality()'s garcia branch reaches the Garcia step
#' through this function and through no other, so gating it here gates
#' production and leaves koa_regular_survival(), koa_mortality_step() and every
#' reproduction path untouched. The gate is applied to the post-floor rate
#' koa_regular_survival() returns, matching the deployed engine, and the
#' irregular loss is then taken from the GATED survivors. With gate = FALSE the
#' returned deaths are bitwise the 9 September 2026 value, because that branch
#' returns reg$deaths itself rather than recomputing it from the rate.
#'
#' @param planted_background Numeric: TODO hook, NA and off by default.
#' @param sdi Numeric: stand density index at the step start. Read by the
#'   Stage 1 gate and by the optional stochastic irregular event. WHEN IT IS NOT
#'   FINITE THE GATE SILENTLY PASSES THE RATE THROUGH UNGATED, matching the
#'   deployed wrapper; see koa_gate_rate().
#' @param gate Logical: apply the Stage 1 occurrence gate, default TRUE. Pass
#'   FALSE to recover the ungated 0.4.0 stand rate exactly.
#' @return Numeric: total deaths over the step (trees ha-1).
koa_step_deaths = function(n0, h40_0, h40_1, planted = 0, yip = 1,
                           irregular = FALSE, planted_background = NA, sdi = NA,
                           gate = TRUE) {
  n0 = as.numeric(n0)[1]
  h0 = as.numeric(h40_0)[1]
  h1 = as.numeric(h40_1)[1]
  if (!is.finite(n0) || n0 <= 0) return(0)
  if (!is.finite(h0) || h0 <= 0) return(0)
  if (!is.finite(h1)) return(0)
  reg = koa_regular_survival(n0, h0, h1, origin = planted[1],
                             planted_background = planted_background, yip = yip)
  s = suppressWarnings(as.numeric(sdi))
  if (isTRUE(gate) && length(s) && is.finite(s[1])) {
    m  = koa_gate_rate(reg$m_step, sdi = s[1], origin = planted[1])
    n1 = n0 * (1 - m)
    d  = n0 - n1
  } else {
    n1 = reg$N1
    d  = reg$deaths
  }
  if (isTRUE(irregular)) {
    ev = koa_irregular_event(sdi = s[1], origin = planted[1], yip = yip)
    d = d + ev$loss_frac * n1
  }
  min(max(d, 0), n0)
}


# Tree survival probability  parameters
#
# RETAINED UNCHANGED AND NO LONGER ON THE PRODUCTION PATH, 8 September 2026.
# calc_mortality() runs the three-stage Garcia component by default and reaches
# surv_prob() only under mort.engine = 'cloglog'. The table and the function are
# kept because this is the published Table 6 lineage, because a reviewer must be
# able to recover any projection this file made before version 0.3.0, and
# because the deposit's gate 1 reads these eight literals out of a file of this
# name. Deleting either was considered and rejected on those three grounds.
#
# TWO DIVERGENCES AGAINST THE MANUSCRIPT DEPOSIT ARE FLAGGED HERE AND ARE NOT
# RESOLVED BY THIS EDIT. Both are coupled and neither may be applied alone.
#
#   1. THE COEFFICIENT VECTOR. This file carries (18.133, 0.199, -5.718, 7.640,
#      15.678, -3.396, 3.039, -25.102). The deposit's copy of HiGy.R was changed
#      on 15 August 2026 to manuscript Table 6, namely (14.102, 0.130, -4.516,
#      6.684, 14.218, -2.806, 2.649, -21.188), on the ground that the vector
#      below is a pre-deduplication development snapshot. That change was never
#      pushed to this branch, so the two files have differed since that date.
#
#   2. THE SENSE OF THE RETURN. This file computes surv = exp(-exp(eta)). The
#      deposit's copy was changed on 12 August 2026 to surv = 1 - exp(-exp(eta))
#      on the ground that the published fit is a complementary log-log on the
#      ALIVE response. WeiskittelKoaGy.R on this same branch states the opposite
#      convention explicitly, that the fit is a cloglog on the DEATH response
#      with P(alive) = exp(-exp(eta) YIP), and it pairs that form with the same
#      coefficient vector carried below. The two lineages are each internally
#      consistent and they contradict one another, so applying one half of the
#      deposit's pair to this file would produce a form neither lineage
#      supports.
#
# There is also a units question sitting under both. WeiskittelKoaGy.R forms the
# slenderness term as log(HT / (DBH/100)), a height to diameter ratio in m m⁻¹,
# while this file forms it as log(ht / dbh) with ht in m and dbh in cm, which
# differs by log(100) inside the linear predictor and therefore by 4.605 b5 in
# eta. That is a large constant offset and it must be settled at the same time
# as the two items above.
#
# THIS IS FOR AARON AND BEN. It is deliberately not decided inside a mortality
# edit, and until it is decided mort.engine = 'cloglog' should be treated as a
# reproduction path and not as a second production option.
surv.parm = dplyr::tribble(
  ~type,  ~species,  ~b0,     ~b1,    ~b2,     ~b3,     ~b4,     ~b5,     ~b6,    ~b7,
  'base',  'AK',     18.133,  0.199,  -5.718,   7.640,  15.678,  -3.396,   0,       0,
  'site',  'AK',     18.133,  0.199,  -5.718,   7.640,  15.678,  -3.396,  3.039,  -25.102)

#' Calculate tree survival probability
#'
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param ht Numeric: Tree height (ft)
#' @param cr Numeric: Live crown ratio (0-1)
#' @param r.ht Numeric: Relative height ht / max plot ht
#' @param byi Numeric: Biomass Yield Index (Mg per ha).
#' @param b0-b7 Numeric: Species parameters
#' @return Numeric: Tree survival probability (proportion 0-1)
surv_prob = function(dbh, ht, cr, r.ht, byi,
                     b0, b1, b2, b3, b4, b5, b6, b7) {


  # constrain input height and diameter
  ht = pmax(ht,  0.1)
  dbh = pmax(dbh, 0.1)


  surv = exp(-exp((b0 + b1*ht +
                      b2* log(ht) +
                      b3* r.ht +
                      b4* log(pmax(pmin(cr, 0.99), 0.01)) +
                      b5* log(ht / dbh ) +
                      b6* log(pmax(byi, 1) / 100) +
                      b7* (byi / 1000))))

  # constrain to between 0 and 1
  surv =  pmin(pmax(surv, 0), 1)

  surv
}


#' Calculate mortality and modifiers for tree list
#'
#' REWRITTEN 8 September 2026 to run the three-stage Garcia component. What this
#' function did through version 0.2.0 is retained byte for byte behind
#' mort.engine = 'cloglog' and is described in the block above surv.parm.
#'
#' HOW THE THREE STAGES REACH A TREE LIST. Stage 2 is a whole-stand statement, so
#' it is evaluated once per plot on the live koa records, taking the top height
#' at the start of the step from the current tree list and the top height at the
#' end of the step from the same trees carrying the diameter and height
#' increments this cycle already computed. That ordering is a genuine advantage
#' of this file over the reference Python projector, which computes its height
#' increment AFTER mortality and therefore drives the Garcia step on the previous
#' year's realised height change, a one-year lag it documents and lives with.
#' HiGYOneStand() calls calc_ddbh() and calc_dht() before calc_mortality(), so
#' the end-of-step top height is available at the moment the step is taken and no
#' lag is needed. Stage 3 then spreads the plot's deaths across that plot's trees
#' by relative diameter and renormalizes, so that the expansion-factor-weighted
#' mean per-tree mortality equals the stand rate and the summed dexpf equals the
#' stand deaths. Stage 1 is off unless asked for.
#'
#' WHY H40 AND NOT topht. koa_h40() is the expansion-factor-weighted mean height
#' of the 40 largest-DIAMETER trees ha-1, which is the manuscript Eq. 1
#' convention and the quantity the Garcia parameters were fitted against.
#' calc_topht() is the mean height of the 100 largest-HEIGHT trees ha-1 and is a
#' different quantity used by the increment equations. Neither may be substituted
#' for the other.
#'
#' STEP LENGTH. The Garcia step is exact for any step length because the state
#' variable is height rather than time, so yip carries the cycle length for the
#' planted_background hook and for Stage 1 and enters the regular rate nowhere.
#' HiGYOneStand() steps one year, so the default of 1 is correct there.
#'
#' SCOPE. The component acts on the koa records of a plot, meaning those with a
#' positive diameter and a positive expansion factor. Records carried through
#' the projection under species code OT take no modelled mortality here, exactly
#' as they took none from the tree-level equation, and make_fvs_tree() returns
#' their original values to FVS.
#'
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data
#' @param surv.parm.df Dataframe: Species parameter table for survival (default surv.parm)
#' @param byi Numeric: Biomass Yield Index (Mg per ha).
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param mort.engine Character: 'garcia' (default) runs the three-stage
#'   component; 'cloglog' runs the version 0.2.0 tree-level survivor equation and
#'   is retained for reproduction of every projection made before version 0.3.0.
#' @param yip Numeric: step length in years, 1 in this projector.
#' @param irregular Logical: run the optional stochastic Stage 1, default FALSE.
#'   Turn it on only for stochastic runs and record the seed.
#' @param seed Numeric: RNG seed set once before the per-plot Stage 1 draws.
#' @param planted.background Numeric: TODO hook passed to koa_regular_survival(),
#'   default NA and off. There is no defensible number for it yet, since the fit
#'   predicts 0.4% yr⁻¹ for planted stands against 2.2% observed.
#' @param gate Logical: apply the Stage 1 occurrence gate to the stand rate,
#'   default TRUE and the deployed engine of record. Pass FALSE to recover the
#'   ungated 0.4.0 rate exactly. See koa_gate_rate().
#' @param alloc.mode Character: Stage 3 ordering weight. 'tree_eq' (default,
#'   KOA_ALLOC_MODE) is the deployed fitted tree-level survivor weight;
#'   'rel_size' is the as-published exp(-b (DBH/QMD - 1)) and reproduces the
#'   0.4.0 allocation. 'tree_eq' needs ht, cr and byi on the tree list, which
#'   HiGYOneStand() always supplies.
#' @return Dataframe: Tree data with mortality calculations
calc_mortality = function(tree.data, plot.data,
                          surv.parm.df = surv.parm,
                          byi = stand$byi,
                          planted = stand$planted,
                          mort.engine = c('garcia', 'cloglog'),
                          yip = 1,
                          irregular = FALSE,
                          seed = NULL,
                          planted.background = NA,
                          gate = TRUE,
                          alloc.mode = KOA_ALLOC_MODE) {

  mort.engine = match.arg(mort.engine)
  alloc.mode  = match.arg(alloc.mode, c("tree_eq", "rel_size"))

  # get tree list variable names
  tree.data.names= colnames(tree.data)

  # filter survival parameter estimate to type base or BYI site
  surv.parm.type =  ifelse(byi %in% c(NA, 0),
                           'base',
                           'site')


  surv.parm = surv.parm.df %>%
    filter(type==surv.parm.type)


  if (mort.engine == 'cloglog') {

    # RETIRED PATH, retained for reproduction and not for production. This is the
    # version 0.2.0 body unchanged, so a caller can recover any projection this
    # file made before the Garcia component without editing code or checking out
    # an older revision. Read the block above surv.parm before trusting a number
    # this branch returns.
    tree = tree.data %>%
      dplyr::left_join(plot.data %>%
                         dplyr::select(plot, ba.plot, htmax),
                       by = 'plot') %>%

      # calculate tree survival probability
      dplyr::mutate(idx = match(sp,
                                surv.parm$species,
                                nomatch = match('AK', surv.parm$species)), #
                    b0 = surv.parm$b0[idx],
                    b1 = surv.parm$b1[idx],
                    b2 = surv.parm$b2[idx],
                    b3 = surv.parm$b3[idx],
                    b4 = surv.parm$b4[idx],
                    b5 = surv.parm$b5[idx],
                    b6 = surv.parm$b6[idx],
                    b7 = surv.parm$b7[idx],
                    byi = dplyr::coalesce(byi, 0),
                    r.ht = ht / htmax,
                    # r.ht = pmax(ht / htmax, 0.65),
                    surv = surv_prob(dbh, ht, cr, r.ht, byi,
                                     b0, b1, b2, b3, b4, b5, b6, b7),
                    dexpf = expf*(1-surv),
                    #apply mortality multiplier
                    dexpf = dexpf * mort.mult)

  } else {

    # THREE-STAGE GARCIA COMPONENT, the production path from version 0.3.0.
    if (!all(c('ddbh', 'dht') %in% colnames(tree.data)))
      warning(paste0("calc_mortality(mort.engine = 'garcia'): the tree list carries ",
                     "no ddbh or dht, so the projected end-of-step top height equals ",
                     "the start-of-step top height and NO regular mortality can occur. ",
                     "Call calc_ddbh() and calc_dht() first, as HiGYOneStand() does."))

    if (!is.null(seed)) set.seed(seed)

    planted.stand = dplyr::coalesce(as.numeric(planted)[1], 0)

    tree = tree.data %>%
      dplyr::left_join(plot.data %>%
                         dplyr::select(plot, ba.plot, htmax),
                       by = 'plot')

    # The two step-scoped increment columns are formed in base R before the pipe
    # rather than inside the mutate, because a tree list reaching this function
    # without ddbh or dht is a legitimate call from outside HiGYOneStand() and a
    # conditional inside a dplyr verb would resolve against the wrong frame.
    # Written to step-scoped names, never onto ddbh or dht themselves, so that a
    # coalesced NA cannot leak back into a returned column.
    tree$ddbh.step = if ('ddbh' %in% colnames(tree)) dplyr::coalesce(tree$ddbh, 0) else 0
    tree$dht.step  = if ('dht'  %in% colnames(tree)) dplyr::coalesce(tree$dht,  0) else 0

    # Relative height for the Stage 3 fitted-survivor weight, added 11 September
    # 2026. Formed on the SAME plot htmax the retired cloglog branch forms r.ht
    # on, so the two branches of this function cannot disagree about what
    # relative height means. The deployed Python projector takes its maximum
    # over a koa-only tree list, where the two coincide; on an FVS-HI plot that
    # carries OT records the plot maximum is the file's existing convention and
    # is kept. Formed in base R before the pipe for the same reason ddbh.step is.
    tree$rht.step = as.numeric(tree$ht) /
      pmax(dplyr::coalesce(as.numeric(tree$htmax), as.numeric(tree$ht)), 0.1)

    tree = tree %>%
      dplyr::mutate(byi = dplyr::coalesce(byi, 0),
                    live.koa = !is.na(expf) & expf > 0 & !is.na(dbh) & dbh > 0) %>%

      # Stage 2, once per plot on the live koa records, then Stage 3 within plot.
      dplyr::group_by(plot) %>%
      dplyr::mutate(n0.koa  = sum(expf[live.koa]),
                    qmd.koa = sqrt(sum(expf[live.koa] * dbh[live.koa]^2) /
                                     pmax(n0.koa, 1e-12)),
                    # End-of-step QMD, the projected-dbh analogue of qmd.koa,
                    # added 9 September 2026 so the anchored arm's state
                    # variable (H_QMD, via koa_h_qmd()) can be formed at both
                    # ends of the step exactly as h40.0/h40.1 were.
                    qmd.1.koa = sqrt(sum(expf[live.koa] *
                                            (dbh[live.koa] + ddbh.step[live.koa])^2) /
                                       pmax(n0.koa, 1e-12)),
                    sdi.koa = koa_sdi(n0.koa, qmd.koa),
                    h40.0   = koa_h40(dbh[live.koa],
                                      ht[live.koa],
                                      expf[live.koa]),
                    h40.1   = koa_h40(dbh[live.koa] + ddbh.step[live.koa],
                                      ht[live.koa]  + dht.step[live.koa],
                                      expf[live.koa]),
                    # h40.0/h40.1 are kept above for diagnostics and are no
                    # longer what drives the step; the production state
                    # variable is H_QMD, ported 9 September 2026.
                    h_qmd.0 = koa_h_qmd(qmd.koa),
                    h_qmd.1 = koa_h_qmd(qmd.1.koa),
                    # Stage 1 gate applied inside koa_step_deaths(), which reads
                    # sdi.koa. This is the deployed rate of record.
                    deaths.ha = koa_step_deaths(n0.koa, h_qmd.0, h_qmd.1,
                                                planted = planted.stand,
                                                yip = yip,
                                                irregular = irregular,
                                                planted_background = planted.background,
                                                sdi = sdi.koa,
                                                gate = gate),
                    # Stage 3 ordering, fitted survivor weight by default.
                    mort.frac = replace(rep(0, dplyr::n()),
                                        live.koa,
                                        koa_alloc_frac(dbh[live.koa],
                                                       expf[live.koa],
                                                       deaths.ha[1],
                                                       mode = alloc.mode,
                                                       ht  = ht[live.koa],
                                                       cr  = cr[live.koa],
                                                       rht = rht.step[live.koa],
                                                       byi = byi[live.koa])),
                    dexpf = expf * mort.frac,
                    #apply mortality multiplier
                    dexpf = dexpf * mort.mult) %>%
      dplyr::ungroup()

  }


  # Remove temporary columns
  tree = tree %>%
    dplyr::select(dplyr::all_of(tree.data.names), dexpf)

  tree
}


#### Calibration ####
# multipliers for diameter increment, height increment and mortality
# maximum tree diameter and height

  # default tree size limits from HI FIA data

    tree.size.cap=dplyr::tribble(
      ~species, ~max.dbh, ~max.height,
      'AK',	  90,	    92)	#


#' create table of height and diameter increment and mortality multipliers from FVS species attributes and tree size cap
#'
#' @param spcodes Dataframe: FVS species codes from fvsGetSpeciesCodes(). Required fields- fvs (FVS alpha species code). FVS numeric code is the vector "row" number. Note fvsGetSpeciesCodes() returns a character vector
#' @param tree.size.cap Dataframe: tree size limits, Required fields: species (FVS alpha species code), max.dbh and max.height
#' @return Dataframe: Species calibration factors (ddbh multiplier, dht multiplier, mortality multiplier, max dbh, max total height)

    make_fvs_calib=function(spcodes, tree.size.cap){

      # customary-metric conversion
      in.to.cm = 2.54
      ft.to.m = 0.3048

      # get fvs dll
      fvs.loaded=try(as.character(get(".FVSLOADEDLIBRARY",envir=.GlobalEnv)[['ldf']]),
                     silent = TRUE)

      if (inherits(fvs.loaded, "try-error") || is.na(fvs.loaded)){
        stop('FVS variant DLL not loaded')
      }

      # fetch calibration multipliers from FVS
      calib.fvs = fvsGetSpeciesAttrs(c("baimult","htgmult","mortmult","mortdia1","mortdia2",
                                       "maxdbh", "maxht", "minmort", "maxdbhcd"))


      # calibration dataframe fields
      calib.df = data.frame(sp=character(),
                            baimult=numeric(),
                            htgmult=numeric(),
                            mortmult=numeric(),
                            mortdia1=numeric(),
                            mortdia2=numeric(),
                            maxdbh=numeric(),
                            maxht=numeric(),
                            minmort=numeric(),
                            maxdbhcd=numeric())

      # create dataframe
      calib.fvs= calib.fvs %>%
        dplyr::mutate(fvs.num=as.integer(rownames(.))) %>%
        dplyr::left_join(spcodes %>%
                           as.data.frame() %>%
                           dplyr::transmute(sp=as.character(fvs),
                                            fvs.num=as.integer(rownames(.))),
                         by='fvs.num')

      # some variables in fvsGetSpeciesAttrs() are limited to the development version 2024-04-01
      # ensure that df contains all variable
      calib.fvs=calib.df %>%
        dplyr::bind_rows(calib.fvs) %>%
        dplyr::rename(ddbh.mult=baimult,
                      dht.mult=htgmult,
                      mort.mult=mortmult,
                      maxdbh.fvs=maxdbh,
                      maxht.fvs=maxht)


      # join with default max height and diameter values
      calib.fvs=calib.fvs %>%
        dplyr::left_join(tree.size.cap,
                         by=c('sp'='species')) %>%
        dplyr::mutate(dplyr::across(c(ddbh.mult, # if multipliers are 0 or 999 change to NA
                                      dht.mult,
                                      mort.mult,
                                      maxdbh.fvs,
                                      maxht.fvs),
                                    ~ifelse(.x %in% c(0, 999), NA, .x)),
                      max.dbh=dplyr::coalesce(maxdbh.fvs,
                                              max.dbh, 999) * in.to.cm, # metric conversion
                      max.height=dplyr::coalesce(maxht.fvs,
                                                 max.height, 999) * ft.to.m,
                      ddbh.mult=dplyr::coalesce(ddbh.mult, 1),
                      dht.mult=dplyr::coalesce(dht.mult, 1),
                      mort.mult=dplyr::coalesce(mort.mult, 1)) %>%
        dplyr::select(sp, ddbh.mult, dht.mult, mort.mult, max.dbh, max.height)


      calib.fvs
    }

    # Notes:
      # function will test if FVS DLL is loaded
      # tree size limits from FVS-NE and tree.size.cap values are in customary units
      # call to FVS will return multipliers via fvsGetSpeciesAttrs(c("baimult","htgmult","mortmult","mortdia1","mortdia2",
        #  "maxdbh", "maxht", "minmort", "maxdbhcd"))


#### Ingrowth ####
# Still absent, and it bounds what the mortality component above can be asked to
# do over a long projection, since a stand that loses stems and gains none runs
# down whatever the mortality equation is. Noted 8 September 2026 because the
# three-stage component makes the gap matter more than it did.

#### Prepare input tree list ####
####

## define model species
  hi.species.ht.dia=dht.parm %>%
    dplyr::inner_join(ddbh.parm, by='species',
                      relationship = "many-to-many") %>%
    dplyr::distinct(species)

## For tree list from FVS add FVS alpha species codes and identify records with species outside scope of the model
    #' Prepare tree list using FVS tree list
    #'
    #' @param tree.data Dataframe: tree list from FVS. Required tree list fields: plot, species (fvs numeric species code), tpa, dbh, ht, cratio, mgmtcd, special (used in form, Risk)
    #' @param spcodes Dataframe: FVS species codes. Required fields: fvs (FVS alpha species code). FVS numeric code is the vector "row" number. Note fvsGetSpeciesCodes() returns a character vector
    #' @param acd.species Dataframe: Acadian model species. Default species contained in the diameter and height increment parameter estimate tables (acd.species$sp)
    #' @return Dataframe: Tree list with added columns (sp: FVS alpha speies code and model.ex: indicator value to drop records when returning to FVS)
    #'
     validate_tree_spp=function(tree.data, spcodes, model.species= hi.species.ht.dia$species){

    # retain records in the projections for accurate plot values and change species to OT

    tree.list=tree.data %>%
      dplyr::rename(fvs.num= species) %>%
      dplyr::left_join(spcodes %>%
                         as.data.frame() %>%
                         transmute(sp=fvs,
                                   fvs.num=as.integer(rownames(.))),
                       by='fvs.num') %>%
        dplyr::mutate(model.ex=dplyr::case_when(!sp %in% model.species ~TRUE, # indicator value to drop records when returning to FVS
                                              TRUE ~ FALSE),
                      sp=dplyr::case_when(!sp %in% model.species ~'OT', # assign species code OT
                                          TRUE ~ sp))

      tree.list
  }


## drop invalid tree records not handled by the model (snags, dbh=0)
     #' Filter tree records with DBH=0 and snags
     #' @param tree.data Dataframe: tree list from FVS. Required tree list fields: mgmtcd, sp (FVS alpha species code), dbh
     #' @param acd.species Dataframe: Acadian model species. Default species contained in the diameter and height increment parameter estimate tables (acd.species$sp)
     #' @return Dataframe: Tree list
  validate_tree_status=function(tree.data){

    tree.list=tree.data %>%
      dplyr::filter(mgmtcd!=9, # remove snags from tree list
                    dbh>0) # remove tree records with dbh zero or NULL


    tree.list

  }


## create model input dataframe from FVS tree list
  #' Create tree list dataframe
  #'
  #' @param tree.list Dataframe: Tree list from FVS. Required tree.list fields: plot, species (fvs numeric species code), tpa, dbh, ht, cratio, mgmtcd, special (used in Form, Risk)
  #' @param num.plots Numeric: Number of plots in a stand
  #' @param calib.spp Dataframe: Data frame of species calibration and size limits. Required fields: sp (FVS alpha species code), dDBH.mult, d.ht.mult, mort.mult, max.dbh,  max.height
  #' @return Dataframe: Tree list dataframe
  # Note: FVS-NE dg; htg and mort=MORT remain in customary units

make_tree=function(tree.list, num.plots, calib.spp){

   # customary-metric conversion
  in.to.cm = 2.54
  ft.to.m = 0.3048
  ha.to.ac = 2.47105

  tree.list.vars=c('cr', 'dbh', 'ht', 'special', 'sp')

  # stop if tree list is missing required variables

  # if(all(tree.list.vars %in% names(tree.list))==FALSE){
  #   stop('Required tree list variable missing')
  #   message(setdiff(tree.list.vars, names(tree.list)))
  # }

  tree.list=tree.list %>%
    dplyr::rename_with(.fn=tolower) %>%
    dplyr::rename(cr= cratio,
                  expf= tpa) %>%
    dplyr::mutate(tree = seq.int(1:n()), # sequential tree id used to retain order of tree list from fvs
                  cr = abs(cr) * 0.01,
                  #change cr to a proportion and take abs; note that in FVS a negative cr
                  #signals that cr change has been computed by the fire or insect/disease model
                  dbh  = dbh  * in.to.cm, # metric conversion
                  ht   = ht   * ft.to.m,
                  #hcb = ht-cr*ht,
                  expf = expf * dplyr::coalesce(num.plots, 1) * ha.to.ac) %>%  # each plot as "stand"

    dplyr::left_join(calib.spp,
                     by='sp')

    tree.list
  }


#### Prepare model options (ops) ####
#' Create run options dataframe
#'
#' @param verbose Logical or character: Print verbose output. Accepts TRUE/FALSE or 'Yes'/'No'/'Y'/'N' (default FALSE)
#' @param rtn.vars Character vector: Variables to return in output (default core variables)
#' @param use.cap.dbh Logical or character: Apply maximum DBH constraint. Accepts TRUE/FALSE or 'Yes'/'No'/'Y'/'N' (default TRUE).
#' @param use.cap.ht Logical or character: Apply maximum total tree height constraint. Accepts TRUE/FALSE or 'Yes'/'No'/'Y'/'N' (default TRUE)
#' @param mort.engine Character: 'garcia' (default) runs the three-stage
#'   component of version 0.3.0; 'cloglog' runs the version 0.2.0 tree-level
#'   survivor equation and is a reproduction path only.
#' @param irregular Logical or character: run the stochastic Stage 1 irregular
#'   event, default FALSE. A deterministic run must leave this off, and a run
#'   that turns it on must record mort.seed.
#' @param mort.seed Numeric: RNG seed set once per cycle before the Stage 1
#'   draws, default NA meaning unseeded. Only Stage 1 consumes randomness.
#' @param planted.background Numeric: TODO hook, annual background mortality
#'   applied to planted stands only, default NA and off. There is no defensible
#'   number for it yet.
#' @return Dataframe: Run options dataframe
#'
make_ops = function(verbose = FALSE,
                    rtn.vars = c('year', 'plot', 'tree', 'sp', 'dbh', 'ht',
                                 'cr', 'expf',
                                 'ddbh.mult', 'dht.mult', 'mort.mult', 'max.dbh', 'max.height'),
                    use.cap.dbh = TRUE,
                    use.cap.ht = TRUE,
                    mort.engine = 'garcia',
                    irregular = FALSE,
                    mort.seed = NA,
                    planted.background = NA) {

  # Convert strings to logical-- in case someone redefines TRUE and FALSE
  char_to_logical = function(x) {

    if (is.logical(x)) return(x)
    if (is.character(x)) {
      x_upper = toupper(trimws(x))
      if (x_upper %in% c("YES", "Y", "TRUE", "T")) return(TRUE)
      if (x_upper %in% c("NO", "N", "FALSE", "F")) return(FALSE)
    }
    # Return original value if not convertible
    x
  }

  # Mortality engine, matched loosely so the interface can hand over a label
  mort.engine = tolower(trimws(as.character(mort.engine)[1]))
  if (!mort.engine %in% c('garcia', 'cloglog')) mort.engine = 'garcia'

  # Create dataframe
  ops = data.frame(verbose = char_to_logical(verbose),
                   rtn.vars = I(list(rtn.vars)), # rtn.vars as a list column
                   use.cap.dbh = char_to_logical(use.cap.dbh),
                   use.cap.ht = char_to_logical(use.cap.ht),
                   mort.engine = mort.engine,
                   irregular = char_to_logical(irregular),
                   mort.seed = as.numeric(mort.seed),
                   planted.background = as.numeric(planted.background),
                   stringsAsFactors = FALSE) %>%
    dplyr::mutate(dplyr::across(c(verbose, use.cap.dbh, use.cap.ht, irregular),
                                as.logical))


  ops
}


#### Prepare stand dataframe ####
#' Create ACD stand list
#'
#' @param stand.id character: Stand identifier
#' @param rain Numeric: Average annual rainfall (mm)
#' @param temp Numeric: Average annual temperature (C)
#' @return Dataframe: Stand dataframe
#'
  make_stand= function(stand.id,
                       elev = 0,
                       byi = 0,
                       planted = 0){

    stand=data.frame(stand.id = stand.id,
                     elev = elev,
                     byi = pmin(coalesce(byi, 0), 600), # BYI capped at 600
                     planted = coalesce(planted, 0))

    stand

  }

#### Prepare output tree list ####
#### for FVS fvsSetTreeAttrs()
#' Create FVS return tree list
#'
#' @param tree.data Dataframe: tree list output from model, fields:  year; dbh; ht; expf; cr
#' @param num.plots Numeric: number of plots in a stand
#' @param orgtree.list Dataframe: input tree list from FVS. orgtree.list fields tree; dbh; ht; expf; dg; htg; mort; cratio
#' @return Dataframe: FVS tree dataframe
#'

make_fvs_tree=function(tree.data, orgtree.list, num.plots){

  #customary-metric conversion
  cm.to.in = 0.393701
  m.to.ft = 3.28084
  ac.to.ha = 0.404686

  # remove projected values for species not in model
  tree.list=tree.data %>%
    dplyr::anti_join(orgtree.list %>%
                       dplyr::filter(model.ex==TRUE),
                     by='tree')

  # dataframe with tree records not handled by model- snags and invalid DBH; species not in model
  tree.org=orgtree.list %>%
    dplyr::select(tree,
                  dbh, # metric
                  ht, # metric
                  expf, # plot level tph
                  dg, # customary units
                  htg, # customary units
                  mort, # stand level TPA
                  cr) %>%
    dplyr::anti_join(tree.list,
                     by='tree')
  # metric to customary option
      # dg=(dbh-dbh.fvs)*cm.to.in, # diameter growth to inches
      # htg=(ht-ht.fvs)*m.to.ft,  # height growth to feet
      # mort=(expf.fvs-expf)*ac.to.ha,  # mortality TPH stand level to trees per acre

  tree=orgtree.list %>%
    dplyr::select(tree,
                  dbh.fvs=dbh,
                  ht.fvs=ht,
                  expf.fvs=expf) %>%
    dplyr::inner_join(tree.list, # inner join excludes records not handled by model
                      by='tree') %>%
    dplyr::mutate(dg=(dbh-dbh.fvs)*cm.to.in, # diameter growth to inches
                  htg=(ht-ht.fvs)*m.to.ft,  # height growth to feet
                  # set the crown ratio sign to negative so that FVS doesn't change them.
                  cratio = round(cr*-100, 1), #
                  mort=(expf.fvs-expf)*ac.to.ha,   # mortality trees per hectare
                  mort=mort/dplyr::coalesce(num.plots, 1), # calculate stand level mortality TPA
                  mort = ifelse(expf.fvs*ac.to.ha - mort < 0.01,
                                expf.fvs*ac.to.ha/dplyr::coalesce(num.plots, 1),
                                mort)) %>%  # if TPA <0.01 then 0
    dplyr::bind_rows(tree.org) %>% # append tree records not handled by model
    dplyr::arrange(tree) %>%
    dplyr::select(#dbh,
                  #sp,
                  dg,
                  htg,
                  cratio,
                  mort)

  #tibble to dataframe
  tree=as.data.frame(tree)

  tree
}

#### tree list for FVS fvsAddTrees() (if adding regen)


#### Calculated tree values ####

#' Calculate basal area in larger trees (BAL) for each tree
#'
#' @param tree.data Dataframe: Tree list
#' @return Dataframe: Tree data with added BAL column
#'
# FLAGGED 8 September 2026, NOT CHANGED. The deposit replaced this construction
# on 8 September 2026 with a single carrier that handles the plot boundary
# differently, and the correction moved 21 of 24 even-aged quadratic mean
# diameters in the deposit's own projection table by a mean of 5.0586 cm. It is
# not applied here, because it belongs in its own edit against its own control
# and it is not part of the mortality change. It does reach mortality, since the
# three-stage component takes its projected top height from the diameter and
# height increments and both read bal, so a decision on this construction moves
# mortality as well.
calc_bal = function(tree.data) {

  # Check required columns
  required.cols = c('plot', 'dbh', 'ba')
  missing.cols = setdiff(required.cols, names(tree.data))
  if (length(missing.cols) > 0) {
    stop(paste("Missing required columns:", paste(missing.cols, collapse = ", ")))
  }

  # Sort by plot and descending DBH; calculate cumulative BA
  tree=tree.data %>%
    dplyr::arrange(plot,
            desc(dbh)) %>%
    dplyr::group_by(plot) %>%
    dplyr::mutate(bal = cumsum(ba) - ba) %>%
    dplyr::ungroup()

  tree
}


#### Calculated plot values ####

#' Calculate plot summary statistics from tree list
#'
#' @param tree.data Dataframe: Tree list
#' @param plot.col Character: Column name for plot identifier (default 'plot')
#' @param tree.col Character: Column name for tree identifier (default 'tree')
#' @param sp.col Character: Column name for species code (default 'sp')
#' @param dbh.col Character: Column name for diameter at breast height (default 'dbh')
#' @param expf.col Character: Column name for expansion factor (default 'expf')
#' @param ba.col Character: Column name for basal area (default 'ba')
#' @param sg.col Character: Column name for specific gravity (default 'sg')
#' @param sp.type.col Character: Column name for species type (default 'sp.type')
#' @param shade.col Character: Column name for shade tolerance (default 'sp.type')
#' @return Dataframe: Plot-level summary statistics
#'
calc_plot_summary = function(tree.data) {

  # Check required columns
  required.cols = c('plot', 'tree', 'sp', 'dbh', 'expf', 'ba')
  missing.cols = setdiff(required.cols, names(tree.data))
  if (length(missing.cols) > 0) {
    stop(paste("Missing required columns:", paste(missing.cols, collapse = ", ")))
  }

  # Plot level summary
  plot.summary = tree.data %>%
    dplyr::group_by(plot) %>%
    dplyr::summarise(tph.plot = sum(expf, na.rm = TRUE),
                     ba.plot = sum(ba, na.rm = TRUE),
                     # max tree number for ingrowth
                     max.tree.id = max(tree, na.rm = TRUE),
                     # max plot height
                     htmax=max(ht, na.rm = TRUE),
                     .groups = 'drop') %>%
    # QMD
    dplyr::mutate(qmd = sqrt(ba.plot / (0.00007854 * tph.plot)))

  plot.summary
}

# Plot top height
#' Calculate plot top height
#'
#' @param tree.data Dataframe: Tree list
#' @param topht.tph Numeric: Number of trees per hectare to include (default 100)
#' @return Dataframe: Plot top height values with columns for plot and topht
#'
# NOTE 8 September 2026. This is the mean height of the 100 largest-HEIGHT trees
# ha-1 and it is used by the increment equations. It is NOT the H40 the Garcia
# step runs on, which is koa_h40(), the expansion-factor-weighted mean height of
# the 40 largest-DIAMETER trees ha-1. The two are different quantities and
# neither may be substituted for the other.
calc_topht = function(tree.data, topht.tph = 100) {

  plot.topht = tree.data %>%
    dplyr::arrange(plot,
                   desc(ht)) %>%
    dplyr::group_by(plot) %>%
    dplyr::mutate(cum.expf = cumsum(expf),
                  tree.inc = dplyr::case_when(cum.expf <= topht.tph ~ expf,
                                              topht.tph - (cum.expf - expf) > 0 ~ topht.tph - (cum.expf - expf),
                                              TRUE ~ 0),
                  wt.ht = tree.inc * ht) %>%
    dplyr::summarise(mean.ht = weighted.mean(ht, expf, na.rm = TRUE),
                     wt.ht.sum = sum(wt.ht, na.rm = TRUE),
                     tph.actual = sum(tree.inc, na.rm = TRUE),
                     .groups = 'drop') %>%
    dplyr::mutate(topht = ifelse(tph.actual > 0,
                                 wt.ht.sum / tph.actual,
                                 mean.ht)) %>%
    dplyr::select(plot,
                  topht)

  plot.topht
}



#### Model execution ####

### Call growth and yield model for each stand
# FLAGGED 8 September 2026, NOT CHANGED. The call below names
# AcadianGYOneStand(), which is not defined anywhere in this file, so this
# function errors if it is ever reached. Nothing reaches it today, since
# customRun_fvsRunHi.R calls HiGYOneStand() directly per stand cycle. It is left
# alone because repairing it is not part of the mortality change and because the
# intended callee should be confirmed rather than assumed.
Hi.GY = function(tree, stand, ops = NULL) {

  ans = tree %>%
    dplyr::filter(!is.na(stand.id)) %>%
    split(.$stand.id) %>%
    purrr::imap_dfr(function(tree.subset, stand.id.subset) {
      stand.subset = subset(stand, stand.id == stand.id.subset)

      AcadianGYOneStand(tree.subset,
                        stand = stand.subset,
                        ops = ops)
    })

  tree = ans %>%
    dplyr::arrange(year, stand.id, plot, tree)

  tree
}


### Growth and yield model called for one stand at time
#' Run growth and yield model for one year for one stand
#'
#' @param tree Dataframe: Tree list
#' @param stand Dataframe: Stand attributes
#' @param ops Dataframe:
#' @return Dataframe: Plot top height values with columns for plot and topht
#'
HiGYOneStand = function(tree, stand, ops)
{
  ### -----
  ## before proceeding run
  ## * make_ops()
  ## * make_stand()
  ## * make_tree()
  ## * check tree list variables
  ### ----


##### Add tree attributes ####
  tree = tree %>%
        # basal area (plot level)
    dplyr::mutate(ba = (dbh^2*0.00007854)*expf) %>%
      # Calculate BAL
    calc_bal()


##### Plot attributes ####
    # Calculate plot summary
  plot.smry = tree %>%
    calc_plot_summary()

  # SDI - height and diameter increment
    # sdi = expf *(qmd / 25)^1.6
    # [The 1.6 exponent on the commented line above must not be uncommented as
    #  written. No code reads it. The Reineke exponent of record is 1.605 and
    #  koa_sdi() in the Mortality section carries it, so every SDI this file
    #  reports is on the same scale as the rest of the koa system. Noted
    #  8 September 2026.]
  #  SDI_max = 500 (estimated from upper boundary of FIA koa SDI distribution)

##### Height and crown ratio ####
  #calculate heights of any with missing values.
  #generally, none will be missing when function is used with FVS, but some or
  #all may be missing when code us used to grow tree lists from other sources.
  tree = tree %>%
    # mutate(rain=stand.copy$rain,
    #        temp=stand.copy$temp) %>%
          #predicted height
    calc_ht(plot.data = plot.smry) %>%
    dplyr::mutate(#use predicted height if missing or > 150ft
           ht= dplyr::case_when(ht %in% c(NA, 0)| ht>50 ~pht,
                        TRUE ~ ht),
           hcb = ht-cr*ht) %>%
           #predicted height to crown base (returns phcb)
    calc_hcb(plot.data = plot.smry) %>%
           #use predicted height to crown base if hcb is missing or invalid
    dplyr::mutate(hcb= dplyr::case_when(is.na(hcb) | hcb>ht  ~phcb,
                                TRUE ~hcb),
                  cr = 1-(hcb/ht))

# Compute plot-level heights

  # Plot top height (for 100 tph)
  plot.topht = tree %>%
    calc_topht()

  # Add to plot summary
  plot.smry=plot.smry %>%
    dplyr::left_join(plot.topht,
                     by='plot')

##### Diameter increment ####

  tree = tree %>%
    calc_ddbh(plot.data = plot.smry)

##### Height increment ####

  tree = tree %>%
    calc_dht(plot.data = plot.smry)



#### Ingrowth ####


#### Mortality ####
# The three-stage component runs here and NOT earlier, because Stage 2 needs the
# end-of-cycle top height and that is only available once calc_ddbh() and
# calc_dht() above have run on this cycle's trees. Moving this call ahead of
# either of them silences regular mortality without erroring.
# Options are read defensively so that a caller passing the version 0.2.0 ops
# frame, which carries none of these four fields, still runs the default engine
# rather than failing on a missing column.

  mort.engine.run = if (!is.null(ops$mort.engine)) as.character(ops$mort.engine)[1] else 'garcia'
  irregular.run   = if (!is.null(ops$irregular)) isTRUE(as.logical(ops$irregular)[1]) else FALSE
  seed.run        = if (!is.null(ops$mort.seed) && !is.na(ops$mort.seed[1])) as.numeric(ops$mort.seed)[1] else NULL
  pbg.run         = if (!is.null(ops$planted.background)) as.numeric(ops$planted.background)[1] else NA

  tree = tree %>%
    calc_mortality(plot.data=plot.smry,
                   mort.engine = mort.engine.run,
                   yip = 1,                 # this projector steps one year
                   irregular = irregular.run,
                   seed = seed.run,
                   planted.background = pbg.run)


#### Update tree values- t+1 ####
  tree=tree %>%
    dplyr::mutate(year= year+1,
                  dbh= dbh+ dplyr::coalesce(ddbh, 0),
                  ht= ht+ dplyr::coalesce(dht, 0),
                  expf= dplyr::coalesce(expf, 0) - dplyr::coalesce(dexpf, 0),
                  expf= ifelse(expf< 0.00001, 0.00001, expf))

#### Crown recession ####
 # calculate t+1 height to crown base
  tree=tree %>%
    calc_bal()

  # Calculate plot summary
  plot.smry = tree %>%
    calc_plot_summary()

  # crown ratio change limited to 2.5% annual (FIA data median annual change -2.5%)
  tree=tree %>%
    calc_hcb(plot.data = plot.smry) %>%
    dplyr::mutate(pcr= 1-(hcb/ht),
                  cr= dplyr::case_when((cr-pcr)/cr>0.025 ~cr*0.975,
                                       (cr-pcr)/cr<(-0.025) ~cr*1.025,
                                       TRUE ~pcr))

#### Output ####
  # select return variables
  rtn.vars=intersect(ops$rtn.vars[[1]],
                     colnames(tree))
  tree=subset(tree,
              select=rtn.vars) %>%
    as.data.frame()

  tree
}

####
#### Taper ####
####

