# $Id: HiGy.R 3968 2026-02-10 10:36:05Z benrice $
################################################################################
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

VersionTag = "HiGyV0.4.1"   # 0.4.1, 25 September 2026: BAL construction of record (percentile), matching the deployed v102 engine that KOA_S3_RESPEC assumes

##############################
#### major update summary ####
####


# version 0.3.1
  # constants refit on the v102 fitting frames (2026-09-18)
  # frames rebuilt under the data owner's revised deduplication ruling
  # height, diameter increment, height increment and survival vectors replaced
  # Duan correction factor for diameter increment and origin calibration multipliers updated
  # no change to any equation form or code path
  # details in CHANGELOG_HiGy.md

# version 0.3.0
  # refit height, diameter increment, height increment and survival equations (2026-09-17)
  # height: relative diameter is dbh / plot maximum dbh (was dbh / qmd)
  # increment: planted level shift (b9), updated Duan correction factors, origin calibration multipliers
  # height increment: plot basal area (ba.plot) replaces tree basal area in calc_dht()
  # details in CHANGELOG_HiGy.md

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
  'base',  'AK',      32.198224,  0,         0.016579,  0.804891,  0.062077,  -0.373262,
  'site',  'AK',      32.198224,  1.208508,  0.016579,  0.804891,  0.062077,  -0.373262)


#' Predict total height 
#' 
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param bal Numeric: Plot basal area larger trees (m^2 per ha)
#' @param ba Numeric: Plot basal area (m^2 per ha)
#' @param dbhmax Numeric: Plot maximum diameter at breast height (cm)
#' @param byi Boolean: Biomass Yield Index (Mg per ha). If NULL or 0, uses basic model
#' @param  a0-g2 Numeric: Parameters
#' @return Numeric: Predicted height (m)
#'
#
pred_ht= function(dbh,  ba, bal, dbhmax, byi, 
                  a0, a1, b, c, g1, g2){
  
  rdbh = pmin(dbh/dbhmax, 1)
  
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
                       dplyr::select(plot, ba.plot, dbhmax), 
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
                  pht = pred_ht(dbh, ba=ba.plot, bal, dbhmax, byi, 
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
    ~type,    ~species,  ~b0,        ~b1,         ~b2,         ~b3,         ~b4,        ~b5,         ~b6,        ~b7,        ~b8,        ~b9,
    'base',    'AK',   -1.1509411,  0.3371168,  -0.0143456,  -0.0017722,  -0.4306515,   1.2809352,  -0.0176013,  -0.0176238,        0,   0.4103534,
    'site',    'AK',   -1.1509411,  0.3371168,  -0.0143456,  -0.0017722,  -0.4306515,   1.2809352,  -0.0176013,  -0.0176238,  0.3045245,   0.4103534)

# Origin calibration multipliers for diameter and height increment
  origin.calib.parm = dplyr::tribble(
    ~species,  ~ddbh.natural,  ~ddbh.planted,  ~dht.natural,  ~dht.planted,
    'AK',      0.40548,        1.43606,        0.51917,       2.64739)

    
#' Calculate annual diameter increment 
#' 
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param bal Numeric: Plot basal area larger trees (m^2 per ha)
#' @param ba Numeric: Plot basal area (m^2 per ha)
#' @param cr Numeric: Live crown ratio (0-1)
#' @param byi Numeric: Biomass Yield Index (Mg per ha). If NULL or 0, uses base model parameters
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param b0-b9 Numeric: Species parameters
#' @param cal Numeric: Origin calibration multiplier (default 1)
#' @return Numeric: Diameter increment (cm)
ddbh = function(dbh, bal, ba, cr, byi, planted, 
                b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, cal = 1) {
  
  cf = 1.36869   # Duan (1983) smearing correction factor
  
  # diameter increment
  ddbh = exp(b0 + b1*log(dbh+1) + 
               b2 * dbh + 
               b3 * bal^2 / log(dbh + 5) + 
               b4 * log(bal + 1) +
               b5 * log(pmax(cr, 0.01)) + 
               b6 * sqrt(pmax(ba * dbh, 0)) +
               b7 * planted * pmin(dbh, 45) + 
               b8 * log(pmax(byi, 1)) +
               b9 * planted) *cf *cal
  
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
                  b9 = ddbh.parm$b9[idx],
                  byi = dplyr::coalesce(byi, 0),
                  planted = dplyr::coalesce(planted, 0),
                  # origin calibration multiplier
                  oidx = match(sp, origin.calib.parm$species, nomatch = match('AK', origin.calib.parm$species)),
                  cal = ifelse(planted > 0, 
                               origin.calib.parm$ddbh.planted[oidx], 
                               origin.calib.parm$ddbh.natural[oidx]),
                  # 
                  ddbh = dplyr::case_when(ht<1.3716 ~0,
                                          TRUE ~ddbh(dbh, bal, ba=ba.plot, cr, 
                                                     byi, planted, 
                                                     b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, cal)),
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
  ~type,   ~species,  ~b0,        ~b1,        ~b2,        ~b3,        ~b4,        ~b5,        ~b6,       ~b7,        ~b8,       ~b9,
  'base',  'AK',    -3.6114059,  1.1203441,  -0.1154809,  -0.0009067, -0.1332027,  -0.5250905,  0.0379597, -0.1240880,  0,         1.0681935,
  'site',  'AK',    -3.6114059,  1.1203441,  -0.1154809,  -0.0009067, -0.1332027,  -0.5250905,  0.0379597, -0.1240880,  0.2232825, 1.0681935)


#' Calculate height increment
#' 
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param ht Numeric: Tree height (m)
#' @param bal Numeric: Plot basal area larger (m^2 per ha)
#' @param ba Numeric: Plot basal area (m^2 per ha)
#' @param cr Numeric: Live crown ratio (0-1)
#' @param byi Numeric: Biomass Yield Index (Mg per ha). If NULL or 0, uses base model parameters
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param b0-b9 Numeric: Species parameters
#' @param cal Numeric: Origin calibration multiplier (default 1)
#' @return Numeric: Height increment (m)
dht = function(dbh, ht, bal, ba, cr, byi, planted,
               b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, cal = 1) {
  
  
  cf = 1.030   # Duan (1983) smearing correction factor
  
  
  dht = exp(b0 + b1 * log(ht+1) + 
              b2 * ht + 
              b3 * bal^2 / log(ht + 5) + 
              b4 * log(bal + 1) +
              b5 * log(pmax(cr, 0.01)) + 
              b6 * sqrt(pmax(ba * ht, 0)) +
              b7 * planted * pmin(ht, 20) + 
              b8 * log(pmax(byi, 1)) +
              b9 * planted) *cf *cal
  
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
                  b9 = dht.parm$b9[idx],
                  byi = dplyr::coalesce(byi, 0),
                  planted = dplyr::coalesce(planted, 0),
                  # origin calibration multiplier
                  oidx = match(sp, origin.calib.parm$species, nomatch = match('AK', origin.calib.parm$species)),
                  cal = ifelse(planted > 0, 
                               origin.calib.parm$dht.planted[oidx], 
                               origin.calib.parm$dht.natural[oidx]),
                  # 
                  dht = dht(dbh, ht, bal, ba=ba.plot, cr, byi,
                               planted, b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, cal),
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
# THREE STAGE Acacia koa A.Gray MORTALITY COMPONENT (version 0.4.0)
# Stage 1 occurrence gate, Stage 2 Garcia (2009) stand survival on H_QMD,
# origin level factor, Stage 3 allocation by the respecified Table S12 weight.
# Structure after Chen et al. (2023). Details and sources in CHANGELOG_HiGy.md;
# checked against the Python engine of record by HiGy_tests/.
# =============================================================================

# ---- Constants of record ----------------------------------------------------
KOA_GARCIA_ALPHA   = 2.96    # alpha = gamma, the ratio gamma/alpha fixed at 1
KOA_GARCIA_BETA    = 0.117   # m-1, limiting line S = beta * H40
KOA_REINEKE_EXP    = 1.605   # stand density index exponent, 1.605 and never 1.6
KOA_ALLOC_CAP      = 0.95    # per-tree mortality fraction cap, as deployed
KOA_IRREG_RATE     = 0.14    # irregular events per observed plot interval
KOA_IRREG_INTERVAL = 2.68    # mean observed interval length (yr) behind that rate
KOA_ALLOC_B        = 3       # steepness of the as-published size weight

KOA_GARCIA_BETA_ANCHORED = 0.16019053617304435  # m-1, deployed arm of record
KOA_GARCIA_ALLOM_A       = -0.16863070512157105 # H_QMD allometry intercept
KOA_GARCIA_ALLOM_K_HD    = 1.1719473700506686   # H_QMD allometry slope
KOA_BASE_NAT             = 0.003    # yr-1, A1 background mortality floor, natural
KOA_BASE_PLT             = 0.006    # yr-1, A1 background mortality floor, planted

KOA_S1_INTERCEPT = -1.67856483466631  # cloglog intercept
KOA_S1_LNSDI     =  0.161863756638461   # coefficient on ln(max(SDI, 1))
KOA_S1_PLANTED   = -0.19099361188623   # planted origin offset
KOA_S1_PBAR      =  0.313065206550519   # mean fitted ANNUAL occurrence, p_bar
KOA_S1_SDI_FLOOR = 1.0                  # ln argument floor, as deployed
KOA_S1_ETA_CLIP  = c(-30, 5)            # linear-predictor clip, as deployed
KOA_RATE_CAP     = 0.95                 # cap on the gated stand rate, as deployed

KOA_MORT_CAL     = c(natural = 2.64629, planted = 1.0)

KOA_S3_RESPEC = c(b0 = -2.13468022306448, b1 = -0.818899541466801, b2 = -0.813105157217597,
                  b3 =  0.382953931412773, b4 =  0.346317281270796)
KOA_S3_SURV = c(b0 = 14.132,  b1 =  0.132, b2 = -4.571, b3 =   6.721,
                b4 = 14.302,  b5 = -2.914, b6 =  2.588, b7 = -20.968)
KOA_S3_W_FLOOR = 1e-9      # lower clip on the survivor weight, as deployed
KOA_ALLOC_MODE = "tree_eq" # Stage 3 default: 'tree_eq' the respecified weight of
                           # record, 'surv_eq5' the Eq. 5 weight, 'rel_size' the
                           # as-published exp(-b (DBH/QMD - 1))

KOA_IRREG_LOSS = c(0.1111, 0.1111, 0.1111, 0.1200, 0.1250, 0.1250, 0.1250, 0.1250,
                   0.1333, 0.1429, 0.1429, 0.1500, 0.1538, 0.1538, 0.1538, 0.1667,
                   0.1667, 0.1667, 0.1667, 0.1765, 0.2000, 0.2000, 0.2000, 0.2308,
                   0.2353, 0.2500, 0.2500, 0.2745, 0.3000, 0.3171, 0.3182, 0.3333,
                   0.3333, 0.4091, 0.4118, 0.4444, 0.4815, 0.5556, 0.5870, 0.6129,
                   0.6545, 0.6579, 0.6818, 0.6842, 0.6897, 0.7105, 0.7407, 0.7500,
                   0.8182, 0.8276, 0.8310, 0.8333, 0.8710, 0.9091, 0.9273, 1.0000,
                   1.0000, 1.0000, 1.0000, 1.0000)

#' Coerce stand origin to the planted indicator
#' @param origin Character "Planted" or "Natural" (case-insensitive), or 0/1, or
#'   TRUE/FALSE, the same origin coding the rest of this file uses.
#' @return Integer: 1 for planted, 0 for natural.
koa_planted = function(origin) {
  if (is.character(origin)) return(as.integer(tolower(origin) == "planted"))
  as.integer(as.logical(origin))
}

#' Stand density index on the Reineke exponent of record
#' @param tph Numeric: live trees ha-1.
#' @param qmd Numeric: quadratic mean diameter (cm).
#' @return Numeric: stand density index, tph * (qmd / 25)^1.605.
koa_sdi = function(tph, qmd) tph * (pmax(qmd, 0.1) / 25)^KOA_REINEKE_EXP

#' Top height H40 from a tree list
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

#' Origin mortality level factor
#' @param origin Character "Planted"/"Natural", 0/1 or TRUE/FALSE.
#' @return Numeric: KOA_MORT_CAL for that origin.
koa_mort_cal = function(origin) {
  if (koa_planted(origin)[1] == 1L) KOA_MORT_CAL[["planted"]] else KOA_MORT_CAL[["natural"]]
}

### Stage 2: regular stand-level survival (Garcia 2009) ####

#' Regular stand-level survival, Garcia (2009) form with gamma/alpha = 1
#' @param N0 Numeric: live koa trees ha-1 at the start of the step (dbh > 0).
#' @param H40_0 Numeric: top height (m) at the start of the step.
#' @param H40_1 Numeric: top height (m) FVS-HI projects for the end of the step.
#' @param origin Character "Planted"/"Natural" or numeric 1/0.
#' @param alpha,beta Numeric: Garcia parameters of record. alpha is 2.96.
#'   beta defaults to the anchored H_QMD arm, 0.16019053617304435; pass
#'   beta = KOA_GARCIA_BETA (0.117) for the fitted H40 arm.
#' @param planted_background Numeric: TODO, annual background mortality for
#'   planted stands, default NA and OFF. Not fitted.
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
  if (H1 <= H40_0) {
    N1 = N0; m_step = 0; S1 = S0
  } else {
    inner = S0^alpha - (beta * H40_0)^alpha + (beta * H1)^alpha
    S1 = max(inner, 1e-9)^(1 / alpha)
    N1 = 10000 / S1^2
    N1 = min(N1, N0)                      # numerical guard; cannot exceed N0 analytically
    m_step = (N0 - N1) / N0
  }
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

#' Per-tree step mortality fraction from the stand deaths (Stage 3)
#' @param dbh Numeric: diameter at breast height (cm), live records only.
#' @param expf Numeric: expansion factor (trees ha-1).
#' @param deaths_ha Numeric: stand deaths over the step (trees ha-1).
#' @param b Numeric: steepness of the size weight, 3 as published. mode
#'   'rel_size' only.
#' @param cap Numeric: per-tree cap on the step mortality fraction.
#' @param mode Character: 'tree_eq' (default, KOA_ALLOC_MODE) the respecified
#'   Table S12 weight; 'surv_eq5' the Eq. 5 survivor weight; 'rel_size' the
#'   as-published exp(-b (DBH/QMD - 1)).
#' @param ht,cr,rht,byi Numeric: required by 'surv_eq5' (rht also by 'tree_eq').
#'   Each must be length 1 or the length of dbh.
#' @param ba,bal Numeric: plot basal area and basal area in larger trees
#'   (m2 ha-1), required by 'tree_eq'.
#' @param surv Numeric: named coefficient vector for 'surv_eq5', KOA_S3_SURV.
#' @param respec Numeric: named coefficient vector for 'tree_eq', KOA_S3_RESPEC.
#' @param w_floor Numeric: lower clip on the survivor weight, KOA_S3_W_FLOOR.
#' @return Numeric: per-tree step mortality fraction, same length as dbh.
koa_alloc_frac = function(dbh, expf, deaths_ha, b = KOA_ALLOC_B, cap = KOA_ALLOC_CAP,
                          mode = KOA_ALLOC_MODE,
                          ht = NULL, cr = NULL, rht = NULL, byi = NULL,
                          ba = NULL, bal = NULL,
                          surv = KOA_S3_SURV, respec = KOA_S3_RESPEC,
                          w_floor = KOA_S3_W_FLOOR) {
  mode = match.arg(mode, c("tree_eq", "surv_eq5", "rel_size"))
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
  rep_n = function(x, nm) {
    x = as.numeric(x)
    if (length(x) == 1L) x = rep(x, n)
    if (length(x) != n) stop(sprintf("koa_alloc_frac: %s must be length 1 or %d", nm, n))
    if (any(!is.finite(x))) stop(sprintf("koa_alloc_frac: %s must be finite", nm))
    x
  }
  need = function(nms, vals) {
    miss = nms[vapply(vals, is.null, logical(1))]
    if (length(miss))
      stop(sprintf(paste0("koa_alloc_frac(mode = '%s') needs %s. Supply them, or ",
                          "pass mode = 'rel_size' for the as-published size weight."),
                   mode, paste(miss, collapse = ", ")))
  }
  if (mode == "tree_eq") {
    need(c("rht", "ba", "bal"), list(rht, ba, bal))
    eta = respec[["b0"]] + respec[["b1"]] * log(pmax(dbh, 0.1)) +
          respec[["b2"]] * rep_n(rht, "rht") +
          respec[["b3"]] * log(rep_n(ba, "ba") + 1) +
          respec[["b4"]] * log(pmax(rep_n(bal, "bal"), 0) + 1)
    w = pmin(pmax(1 - exp(-exp(eta)), w_floor), 1)
  } else if (mode == "surv_eq5") {
    need(c("ht", "cr", "rht", "byi"), list(ht, cr, rht, byi))
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
#' @param tree_df Dataframe: at least columns dbh (cm) and expf (trees ha-1),
#'   holding live koa records with dbh > 0 only. Mode 'tree_eq' additionally
#'   needs ht (m), cr and byi, and uses rht if present or forms it from the
#'   tree list's own height maximum if not.
#' @param deaths_ha Numeric: stand deaths over the step (trees ha-1), from
#'   koa_regular_survival()$deaths plus any irregular loss.
#' @param b Numeric: steepness of the size weight, 3 as published.
#' @param cap Numeric: per-tree cap on the step mortality fraction.
#' @param mode Character: 'rel_size' (default here) or 'surv_eq5' ('tree_eq' is
#'   read as 'surv_eq5' in this standalone wrapper).
#' @return Dataframe: tree_df with rdbh, w_alloc, mort_frac and dexpf added.
#'   w_alloc always reports the weight the chosen mode actually used.
koa_allocate_mortality = function(tree_df, deaths_ha, b = KOA_ALLOC_B, cap = KOA_ALLOC_CAP,
                                  mode = "rel_size") {
  mode = match.arg(mode, c("rel_size", "tree_eq", "surv_eq5"))
  stopifnot(is.data.frame(tree_df), all(c("dbh", "expf") %in% names(tree_df)))
  if (nrow(tree_df) == 0L) {
    tree_df$rdbh = tree_df$w_alloc = tree_df$mort_frac = tree_df$dexpf = numeric(0)
    return(tree_df)
  }
  dbh = as.numeric(tree_df$dbh); expf = as.numeric(tree_df$expf)
  qmd = sqrt(sum(expf * dbh^2) / sum(expf))
  tree_df$rdbh = dbh / max(qmd, 0.1)
  if (mode == "tree_eq") mode = "surv_eq5"   # this standalone wrapper keeps its 9 September weight
  if (mode == "surv_eq5") {
    need = c("ht", "cr", "byi")[!c("ht", "cr", "byi") %in% names(tree_df)]
    if (length(need))
      stop(sprintf(paste0("koa_allocate_mortality(mode = 'surv_eq5') needs column(s) %s ",
                          "for the fitted survivor weight."), paste(need, collapse = ", ")))
    rht = if ("rht" %in% names(tree_df)) as.numeric(tree_df$rht) else
      as.numeric(tree_df$ht) / max(c(as.numeric(tree_df$ht), 0.1), na.rm = TRUE)
    tree_df$w_alloc = pmin(pmax(1 - koa_surv_annual(dbh, tree_df$ht, tree_df$cr,
                                                    rht, tree_df$byi),
                                KOA_S3_W_FLOOR), 1)
    tree_df$mort_frac = koa_alloc_frac(dbh, expf, deaths_ha, b = b, cap = cap,
                                       mode = "surv_eq5", ht = tree_df$ht,
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
#'   production path; calc_mortality() uses the anchored H_QMD
#'   arm with the A1 floor via koa_step_deaths().
#' @param base_nat,base_plt Numeric: A1 floor, default NA (off) here to
#'   preserve the fitted-H40 arm's original unfloored behaviour.
#' @param mort_mult Numeric: FVS mortality multiplier applied to dexpf.
#' @param alloc_mode Character: Stage 3 weight, default 'rel_size' HERE so this
#'   wrapper keeps reproducing the 9 September 2026 numbers exactly, unlike
#'   calc_mortality() which defaults to the deployed 'tree_eq'.
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
#' @param n0 Numeric: live koa trees ha-1 at the step start.
#' @param h40_0 Numeric: top height (m) at the step start.
#' @param h40_1 Numeric: top height (m) projected for the step end.
#' @param planted Numeric: 1 planted, 0 natural.
#' @param yip Numeric: step length in years.
#' @param irregular Logical: run the stochastic Stage 1.
#' @param planted_background Numeric: TODO hook, NA and off by default.
#' @param sdi Numeric: stand density index at the step start. Read by the
#'   Stage 1 gate and by the optional stochastic irregular event. WHEN IT IS NOT
#'   FINITE THE GATE SILENTLY PASSES THE RATE THROUGH UNGATED, matching the
#'   deployed wrapper; see koa_gate_rate().
#' @param gate Logical: apply the Stage 1 occurrence gate and the origin level
#'   factor, default TRUE and the production path. Pass FALSE to recover the
#'   ungated, uncalibrated stand rate of koa_regular_survival() exactly.
#' @param mort.cal Numeric or NULL: origin mortality level factor k. NULL, the
#'   default, takes KOA_MORT_CAL by origin (natural 2.64629, planted 1). Applied
#'   after the gate and capped at KOA_RATE_CAP, as in the engine of record; also
#'   applied when SDI is not finite and the gate passes the rate through.
#' @return Numeric: total deaths over the step (trees ha-1).
koa_step_deaths = function(n0, h40_0, h40_1, planted = 0, yip = 1,
                           irregular = FALSE, planted_background = NA, sdi = NA,
                           gate = TRUE, mort.cal = NULL) {
  n0 = as.numeric(n0)[1]
  h0 = as.numeric(h40_0)[1]
  h1 = as.numeric(h40_1)[1]
  if (!is.finite(n0) || n0 <= 0) return(0)
  if (!is.finite(h0) || h0 <= 0) return(0)
  if (!is.finite(h1)) return(0)
  reg = koa_regular_survival(n0, h0, h1, origin = planted[1],
                             planted_background = planted_background, yip = yip)
  s = suppressWarnings(as.numeric(sdi))
  if (isTRUE(gate)) {
    k  = if (is.null(mort.cal)) koa_mort_cal(planted[1]) else as.numeric(mort.cal)[1]
    m  = if (length(s) && is.finite(s[1]))
           koa_gate_rate(reg$m_step, sdi = s[1], origin = planted[1]) else reg$m_step
    m  = min(max(m * k, 0), KOA_RATE_CAP)
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
surv.parm = dplyr::tribble(
  ~type,  ~species,  ~b0,     ~b1,    ~b2,     ~b3,     ~b4,     ~b5,     ~b6,    ~b7,
  'base',  'AK',     14.132,  0.132,  -4.571,   6.721,  14.302,  -2.914,   0,       0,
  'site',  'AK',     14.132,  0.132,  -4.571,   6.721,  14.302,  -2.914,  2.588,  -20.968)

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
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data
#' @param surv.parm.df Dataframe: Species parameter table for survival (default surv.parm)
#' @param byi Numeric: Biomass Yield Index (Mg per ha).
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param mort.engine Character: 'garcia' (default) runs the three-stage
#'   component; 'cloglog' runs the version 0.3.1 tree-level survivor equation and
#'   is retained for reproduction of every projection made before version 0.4.0.
#' @param yip Numeric: step length in years, 1 in this projector.
#' @param irregular Logical: run the optional stochastic Stage 1, default FALSE.
#'   Turn it on only for stochastic runs and record the seed.
#' @param seed Numeric: RNG seed set once before the per-plot Stage 1 draws.
#' @param planted.background Numeric: TODO hook passed to koa_regular_survival(),
#'   default NA and off. There is no defensible number for it yet, since the fit
#'   predicts 0.4% yr⁻¹ for planted stands against 2.2% observed.
#' @param gate Logical: apply the Stage 1 occurrence gate to the stand rate,
#'   and the origin level factor, default TRUE and the deployed engine of record.
#'   Pass FALSE to recover the ungated, uncalibrated Garcia rate. See
#'   koa_gate_rate() and koa_step_deaths().
#' @param alloc.mode Character: Stage 3 ordering weight. 'tree_eq' (default,
#'   KOA_ALLOC_MODE) is the respecified weight of the engine of record and needs
#'   ht, ba.plot and bal; 'surv_eq5' is the Eq. 5 survivor weight; 'rel_size' is
#'   the as-published exp(-b (DBH/QMD - 1)). HiGYOneStand() supplies all inputs.
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
  alloc.mode  = match.arg(alloc.mode, c("tree_eq", "surv_eq5", "rel_size"))

  # get tree list variable names
  tree.data.names= colnames(tree.data)

  # filter survival parameter estimate to type base or BYI site
  surv.parm.type =  ifelse(byi %in% c(NA, 0),
                           'base',
                           'site')


  surv.parm = surv.parm.df %>%
    filter(type==surv.parm.type)


  if (mort.engine == 'cloglog') {

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

    # THREE STAGE COMPONENT, the production path from version 0.4.0.
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
    if (!'bal' %in% colnames(tree)) tree$bal = NA_real_

    tree$ddbh.step = if ('ddbh' %in% colnames(tree)) dplyr::coalesce(tree$ddbh, 0) else 0
    tree$dht.step  = if ('dht'  %in% colnames(tree)) dplyr::coalesce(tree$dht,  0) else 0

    tree$rht.step = as.numeric(tree$ht) /
      pmax(dplyr::coalesce(as.numeric(tree$htmax), as.numeric(tree$ht)), 0.1)

    tree = tree %>%
      dplyr::mutate(byi = dplyr::coalesce(byi, 0),
                    live.koa = dplyr::coalesce(sp != 'OT', TRUE) &
                               !is.na(expf) & expf > 0 & !is.na(dbh) & dbh > 0) %>%

      # Stage 2, once per plot on the live koa records, then Stage 3 within plot.
      dplyr::group_by(plot) %>%
      dplyr::mutate(n0.koa  = sum(expf[live.koa]),
                    qmd.koa = sqrt(sum(expf[live.koa] * dbh[live.koa]^2) /
                                     pmax(n0.koa, 1e-12)),
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
                    # Stage 3 ordering, respecified Table S12 weight by default.
                    mort.frac = replace(rep(0, dplyr::n()),
                                        live.koa,
                                        koa_alloc_frac(dbh[live.koa],
                                                       expf[live.koa],
                                                       deaths.ha[1],
                                                       mode = alloc.mode,
                                                       ht  = ht[live.koa],
                                                       cr  = cr[live.koa],
                                                       rht = rht.step[live.koa],
                                                       byi = byi[live.koa],
                                                       ba  = ba.plot[live.koa],
                                                       bal = dplyr::coalesce(bal[live.koa], 0))),
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
#'   component of version 0.4.0; 'cloglog' runs the version 0.3.1 tree-level
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
# BAL helpers, ported from the deposit carrier HiGyV0.5.3, 25 September 2026.
# koa_equations.bal_percentile_fraction and koa_equations.stand_bal of the deployed
# v102 engine, transcribed exactly.
KOA_BAL_MODE = "percentile"

koa_bal_percentile_fraction = function(dbh) {
  d = as.numeric(dbh)
  n = length(d)
  if (n < 2L) return(rep(0, n))
  r = rank(d, ties.method = "min")          # minimum tie rule, as deployed
  1 - (r - 1) / (n - 1)
}

koa_stand_bal = function(baph, dbh) {
  as.numeric(baph) * koa_bal_percentile_fraction(dbh)
}

# CHANGED 25 September 2026, 0.4.1. This file already carried the deployed Stage 3
# ordering weight KOA_S3_RESPEC, which reads BAL, while computing BAL as the
# descending cumulative sum. The deployed engine feeds that weight the PERCENTILE
# construction, BAL = BAPH * (1 - BA.perc). Evaluating a deployed weight on a
# covariate the deployed engine does not compute moves the per-tree allocation by
# up to 0.2172 and by 0.0095 on average over 40 tree lists and 630 stems. The level
# of the weight cancels under renormalization; its SPREAD across the tree list does
# not, and the spread is what this changes. mode = "cumsum" reproduces every
# pre-0.4.1 projection exactly.
calc_bal = function(tree.data, mode = KOA_BAL_MODE) {

  mode = match.arg(mode, c("percentile", "cumsum"))

  # Check required columns
  required.cols = c('plot', 'dbh', 'ba')
  missing.cols = setdiff(required.cols, names(tree.data))
  if (length(missing.cols) > 0) {
    stop(paste("Missing required columns:", paste(missing.cols, collapse = ", ")))
  }

  tree = tree.data %>%
    dplyr::arrange(plot, desc(dbh)) %>%
    dplyr::group_by(plot)

  tree = if (mode == "percentile") {
    tree %>% dplyr::mutate(bal = sum(ba) * koa_bal_percentile_fraction(dbh))
  } else {
    tree %>% dplyr::mutate(bal = cumsum(ba) - ba)
  }

  tree = dplyr::ungroup(tree)

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
                     # max plot dbh
                     dbhmax=max(dbh, na.rm = TRUE),
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

  mort.engine.run = if (!is.null(ops$mort.engine)) as.character(ops$mort.engine)[1] else 'garcia'
  irregular.run   = if (!is.null(ops$irregular)) isTRUE(as.logical(ops$irregular)[1]) else FALSE
  pbg.run         = if (!is.null(ops$planted.background)) as.numeric(ops$planted.background)[1] else NA

  tree = tree %>% 
    calc_mortality(plot.data=plot.smry,
                   mort.engine = mort.engine.run,
                   yip = 1,                 # this projector steps one year
                   irregular = irregular.run,
                   seed = NULL,             # seeded once per cycle by customRun_fvsRunHi.R
                   planted.background = pbg.run,
                   byi = stand$byi[1],
                   planted = stand$planted[1])
  

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
       
