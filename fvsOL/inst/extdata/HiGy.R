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

# version 0.5.0 (2026-11-20)
  # Equations and parameters from the koa model of record (Zenodo 1.14.1)
  # Maximum SDI predicted from BYI and origin; relative density competition
  # Height- asymptote from BYI shared with height increment 
  # Height to crown base- logistic in slenderness and koa competition, refit to crown base HT x (1 - CR) from the
      # FIA crown ratio (koa 1.14.3, E3e, 2026-11-21); the 1.14.2 fit had used crown length HT x CR
  # Diameter increment- refit parameters and modified calculation 
  # Height increment- asymptote form 
  # Mortality- tree-level annual mortality replaces the three-stage plot model

# version 0.4.0 (2026-10-14)
  # Height- refit parameters and changed relative diameter definition 
  # Height to crown base- guards added 
  # Diameter increment- refit parameters and modified calculation 
  # Height increment- refit parameters and modified calculation 
  # Mortality- replaced the single tree-level logistic survival equation with a
      # three-stage plot mortality model


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

##### Maximum stand density index ####
sdimax.parm = dplyr::tribble(
  ~species, ~s0,              ~s1,               ~s2,
  'AK',     5.64535004933422, 0.267708773204307, -0.565468519531123)


#' Predict maximum stand density index (25.4 cm index diameter)
#' 
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param s0-s2 Numeric: Parameters
#' @return Numeric: Maximum stand density index (trees per ha)
#'
pred_sdimax = function(byi, planted, s0, s1, s2){
  
  sdimax = exp(s0 + s1 * log(byi) + s2 * planted)
  
  sdimax
}


##### Total height prediction ####
ht.pred.parm = dplyr::tribble(
  ~species, ~a0,              ~a1,                ~b,                 ~c,
  'AK',     2.76907028735262, 0.0625077438977538, 0.0415284019555746, 1.05365705524209)



#' Predict total height 
#' 
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param  a0-c Numeric: Parameters (a0 and a1 give the asymptote shared with height increment)
#' @return Numeric: Predicted height (m)
#'
#
pred_ht= function(dbh, byi, a0, a1, b, c){

  ht.max = exp(a0 + a1 * log(byi))
  
  ht = 1.37 + (ht.max - 1.37) * (1 - exp(-b * dbh))^c
    
  ht
}


#' Wrapper to calculate predicted heights for tree list
#' 
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data
#' @param byi Biomass Yield Index (Mg per ha)
#' @param ht.spp.parms Dataframe: Dataframe of parameters (default ht.pred.parm)
#' @return Dataframe: Tree data with ht column added
#'
calc_ht = function(tree.data, plot.data, byi=stand$byi, 
                   ht.pred.parm.df = ht.pred.parm) {
  
  tree.data.names= colnames(tree.data)   
  
  # BYI is required to impute height, there is no base model
  if (dplyr::coalesce(as.numeric(byi), 0) <= 0 && any(tree.data$phtrow %in% TRUE)) {
    stop('BYI missing or zero: HiGy requires the Biomass Yield Index to impute height')
  }
  
  ht.parm = ht.pred.parm.df
    
  tree = tree.data %>%
    # Match parameter estimates on species, Koa is currently the default
    # when the model extends to other species, the code may need to be updated to another default species
    dplyr::mutate(idx = match(sp, ht.parm$species, nomatch = match('AK', ht.parm$species)),
                  a0 = ht.parm$a0[idx],
                  a1 = ht.parm$a1[idx],
                  b  = ht.parm$b[idx],
                  c  = ht.parm$c[idx],
                  pht = pred_ht(dbh, byi, a0, a1, b, c)) %>%
    dplyr::select(dplyr::all_of(tree.data.names), pht)
  
  
  tree
}


##### Height to crown base prediction ####  
  
# Height to crown base species parameters
  hcb.pred.parm = dplyr::tribble(
    ~species,  ~b0,                 ~b1,                 ~b2,                  ~b3,
    'AK',     -0.82892102575579,  -0.44435342092672,  -0.0396716421642529,  -0.0993967760664791)


#' Predict height to crown base
#' 
#' @param ht Numeric: Total tree height (m)
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param bal Numeric: Basal area of larger koa (m^2 per ha)
#' @param ba Numeric: Plot koa basal area (m^2 per ha)
#' @param b0-b3 Numeric: Species parameters
#' @return Numeric: Predicted height to crown base (m); crown ratio is 1 - hcb/ht
#'
  pred_hcb = function(ht, dbh, bal, ba, b0, b1, b2, b3) {
    
    hcb = ht / (1 + exp(b0 + b1 * log(pmax(ht, 0.5) / pmax(dbh, 0.1)) + b2 * sqrt(bal * ba + 1) + b3 * log(ba + 1)))
    
    hcb
  }
 
   
#' Wrapper to calculate height to crown base for tree list
#' 
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data (supplies ba.plot; tree.data must carry bal)
#' @param hcb.spp.parms Dataframe: Species parameters (default hcb.pred.spp)
#' @return Dataframe: Tree data with hcb column added
#'
  calc_hcb = function(tree.data, plot.data, 
                      hcb.pred.parm.df = hcb.pred.parm) {
    
    tree.data.names= colnames(tree.data)  
    
    hcb.parm = hcb.pred.parm.df
    
    tree=tree.data %>% 
      dplyr::left_join(plot.data %>% dplyr::select(plot, ba.plot), by = 'plot') %>%
       # Match parameter estimates on species, Koa is currently the default
      dplyr::mutate(idx = match(sp, hcb.parm$species, nomatch = match('AK', hcb.parm$species)),
                    b0 = hcb.parm$b0[idx],
                    b1 = hcb.parm$b1[idx],
                    b2 = hcb.parm$b2[idx],
                    b3 = hcb.parm$b3[idx],
                    phcb = pred_hcb(ht, dbh, bal, ba.plot, b0, b1, b2, b3)) %>%
      dplyr::select(dplyr::all_of(tree.data.names), phcb)
    
    tree
  }
  

#### Diameter increment ####

# Diameter increment parameters
  ddbh.parm = dplyr::tribble(
    ~species,  ~b0,               ~b1,               ~b2,                 ~b3,               ~b4,              ~b5,
    'AK',     -3.34389382394364,  0.258944012422482, -0.0287540660054976, -2.19339616993293,  0.51703684690369, 1.30520211265738)

    
#' Calculate annual diameter increment 
#' 
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param bal Numeric: Plot basal area larger trees (m^2 per ha)
#' @param ba Numeric: Plot basal area (m^2 per ha)
#' @param rd Numeric: Plot relative density
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param b0-b5 Numeric: Species parameters
#' @return Numeric: Diameter increment (cm)
ddbh = function(dbh, bal, ba, rd, byi, planted,
                b0, b1, b2, b3, b4, b5) {

  # diameter increment
  ddbh = exp(b0 + b1*log(dbh+1) +
               b2 * dbh +
               b3 * bal / pmax(ba, 1e-6) * rd +
               b4 * log(byi) +
               b5 * planted)

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
  
  ddbh.parm = ddbh.parm.df

  # Calculate diameter increment
  tree = tree.data %>%
    dplyr::left_join(plot.data %>%
                       dplyr::select(plot, 
                                     ba.plot,
                                     rd),
                     by = 'plot') %>%
    # Match parameter estimates on species, Koa is currently the default
    dplyr::mutate(idx = match(sp, ddbh.parm$species, nomatch = match('AK', ddbh.parm$species)),
                  b0 = ddbh.parm$b0[idx],
                  b1 = ddbh.parm$b1[idx],
                  b2 = ddbh.parm$b2[idx],
                  b3 = ddbh.parm$b3[idx],
                  b4 = ddbh.parm$b4[idx],
                  b5 = ddbh.parm$b5[idx],
                  planted = dplyr::coalesce(planted, 0),
                  ddbh = dplyr::case_when(ht<1.3716 ~0,
                                          TRUE ~ddbh(dbh, bal, ba=ba.plot, rd,
                                                     byi, planted,
                                                     b0, b1, b2, b3, b4, b5)),
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

# Height increment parameters (asymptote from ht.pred.parm)
dht.parm = dplyr::tribble(
  ~species,  ~b0,               ~b1,                ~b2,                ~b3,
  'AK',     -3.58396035295639,  0.0776483889881895, -0.809943486352306, 1.35008130619277)


#' Calculate height increment
#' 
#' @param ht Numeric: Tree height (m)
#' @param bal Numeric: Plot basal area larger (m^2 per ha)
#' @param ba Numeric: Plot basal area (m^2 per ha)
#' @param rd Numeric: Plot relative density
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param a0-a1 Numeric: Height asymptote parameters (ht.pred.parm)
#' @param b0-b3 Numeric: Species parameters
#' @return Numeric: Height increment (m)
dht = function(ht, bal, ba, rd, byi, planted,
               a0, a1, b0, b1, b2, b3) {

  ht.max = exp(a0 + a1 * log(byi))
  ht = pmax(ht, 0.5)
  m = exp(b1)

  dht = pmax(m * exp(b0 + b3 * planted) * ht * ((ht.max / ht)^(1 / m) - 1), 0) *
    exp(b2 * bal / pmax(ba, 1e-6) * rd)

  dht
}


#' Wrapper function to calculate height increment with modifiers and constraints
#' 
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data  
#' @param use.cap.ht Logical: Apply maximum total tree height constraint (default ops$use.cap.ht)
#' @param dht.parm.df Dataframe: Species parameter table for height increment (dht.parm)
#' @param ht.pred.parm.df Dataframe: Species parameter table for total height (ht.pred.parm)
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @return Dataframe: Tree data with height increment calculations
calc_dht = function(tree.data, 
                    plot.data,  
                    use.cap.ht = ops$use.cap.ht, 
                    dht.parm.df = dht.parm,
                    ht.pred.parm.df = ht.pred.parm,
                    byi= stand$byi, 
                    planted= stand$planted ) {
  
  # get tree list variable names
  tree.data.names= colnames(tree.data)   
  
  dht.parm = dht.parm.df
  
  ht.parm = ht.pred.parm.df
  
  # Calculate height increment
  tree = tree.data %>%
    dplyr::left_join(plot.data %>% 
                       dplyr::select(plot, 
                                     ba.plot,
                                     rd), 
                     by = 'plot') %>%
    # Species parameters
    dplyr::mutate(idx = match(sp,  
                              dht.parm$species,
                                 nomatch = match('AK', dht.parm$species)), # 
                  ht.idx = match(sp,  
                                 ht.parm$species,
                                 nomatch = match('AK', ht.parm$species)),
                  a0 = ht.parm$a0[ht.idx],
                  a1 = ht.parm$a1[ht.idx],
                  b0 = dht.parm$b0[idx],
                  b1 = dht.parm$b1[idx],
                  b2 = dht.parm$b2[idx], 
                  b3 = dht.parm$b3[idx],
                  planted = dplyr::coalesce(planted, 0),
     dht = dht(ht, bal, ba.plot, rd, byi, planted, 
               a0, a1, b0, b1, b2, b3),
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

# Tree-level annual mortality parameters
mort.parm = dplyr::tribble(
  ~species, ~b0,               ~b1,                ~b2,                  ~b3,                  ~b4,                ~b5,               ~b6,                ~b7,
  'AK',     0.340426001075269, -0.869658145840034, -0.0236697637666886,  0.000275459669220663, 0.0340721198355973, 0.744946139770556, -0.116539979564868, -1.04977227058111)

#' Calculate annual probability of mortality
#'
#' @param dbh Numeric: Diameter at breast height (cm)
#' @param bal Numeric: Plot basal area larger trees (m^2 per ha)
#' @param rd Numeric: Plot relative density
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @param b0-b7 Numeric: Species parameters
#' @return Numeric: Annual probability of mortality (0-1)
pred_mort = function(dbh, bal, rd, byi, planted,
                     b0, b1, b2, b3, b4, b5, b6, b7) {

  eta = b0 +
    b1 * log(dbh + 1) +
    b2 * dbh +
    b3 * dbh^2 +
    b4 * bal +
    b5 * log(pmax(rd, 0.001)) +
    b6 * log(byi) +
    b7 * planted

  mort.prob = 1 - exp(-exp(eta))

  mort.prob
}

#' Calculate mortality and modifiers for tree list
#'
#' @param tree.data Dataframe: Tree list
#' @param plot.data Dataframe: Plot summary data
#' @param mort.parm.df Dataframe: Species parameter table (default mort.parm)
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @return Dataframe: Tree data with mortality calculations
calc_mortality = function(tree.data, plot.data, mort.parm.df = mort.parm, 
                          byi = stand$byi,
                          planted = stand$planted) {

  tree.data.names = colnames(tree.data)

  tree = tree.data %>%
    dplyr::left_join(plot.data %>% 
                       dplyr::select(plot, 
                                     rd), 
                     by = 'plot') %>%
    # Match parameter estimates on species, Koa is currently the default
    dplyr::mutate(idx = match(sp, mort.parm.df$species, nomatch = match('AK', mort.parm.df$species)),
                  b0 = mort.parm.df$b0[idx],
                  b1 = mort.parm.df$b1[idx],
                  b2 = mort.parm.df$b2[idx],
                  b3 = mort.parm.df$b3[idx],
                  b4 = mort.parm.df$b4[idx],
                  b5 = mort.parm.df$b5[idx],
                  b6 = mort.parm.df$b6[idx],
                  b7 = mort.parm.df$b7[idx],
                  planted = dplyr::coalesce(planted, 0),
                  dexpf = expf * pred_mort(dbh, bal, rd, byi, planted,
                                           b0, b1, b2, b3, b4, b5, b6, b7),
                  dexpf = dexpf * mort.mult)

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
#' @return Dataframe: Run options dataframe
#'
make_ops = function(verbose = FALSE,
                    rtn.vars = c('year', 'plot', 'tree', 'sp', 'dbh', 'ht', 
                                 'cr', 'expf', 'pht',  
                                 'ddbh.mult', 'dht.mult', 'mort.mult', 'max.dbh', 'max.height'),
                    use.cap.dbh = TRUE,
                    use.cap.ht = TRUE) {
  
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
  
  
  # Create dataframe
  ops = data.frame(verbose = char_to_logical(verbose),
                   rtn.vars = I(list(rtn.vars)), # rtn.vars as a list column 
                   use.cap.dbh = char_to_logical(use.cap.dbh),
                   use.cap.ht = char_to_logical(use.cap.ht)) %>%
    dplyr::mutate(dplyr::across(c(verbose, use.cap.dbh, use.cap.ht), 
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
    
    # BYI is NA at the imputation stop point, before the Event Monitor computes it
    stand=data.frame(stand.id = stand.id,
                     elev = elev,
                     byi = pmin(as.numeric(byi), 600), # BYI capped at 600 
                     planted = dplyr::coalesce(as.numeric(planted), 0))
    
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
    dplyr::mutate(dg=(dbh-dbh.fvs)*cm.to.in*0.9, # diameter growth to inches inside bark (FVS-HI bark ratio 0.9)
                  htg=(ht-ht.fvs)*m.to.ft,  # height growth to feet
                  # set the crown ratio sign to negative so that FVS doesn't change them. 
                  cratio = round(cr*-100, 1), # 
                  mort=(expf.fvs-expf)*ac.to.ha,   # mortality trees per hectare
                  mort=mort/dplyr::coalesce(num.plots, 1)) %>%  # calculate stand level mortality TPA
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
    dplyr::mutate(bal = (cumsum(ba) - ba)[match(dbh, dbh)]) %>% # trees with equal DBH share BAL
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
#' @param sdimax.parm.df Dataframe: Maximum SDI parameters (default sdimax.parm)
#' @param byi Numeric: Biomass Yield Index (Mg per ha)
#' @param planted Boolean: Origin indicator (1 = planted, 0 = natural)
#' @return Dataframe: Plot-level summary statistics
#'
calc_plot_summary = function(tree.data, 
                             sdimax.parm.df = sdimax.parm,
                             byi = stand$byi, 
                             planted = stand$planted) {
  
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
                     # max plot diameter, used by the height equation's relative diameter term
                     max.plot.dbh = max(dbh, na.rm = TRUE),
                     # max plot height, used by the mortality allocation's relative height term
                     max.plot.ht = max(ht, na.rm = TRUE), .groups = 'drop') %>%
    # QMD
    dplyr::mutate(qmd = dplyr::coalesce(sqrt(ba.plot / (0.00007854 * tph.plot)), 0),
                  # stand density index, Reineke exponent 1.605
                  sdi = tph.plot * (pmax(qmd, 0.1) / 25.4)^1.605,
                  # relative density, maximum SDI for koa
                  sdimax = pred_sdimax(byi, dplyr::coalesce(planted, 0),
                                       sdimax.parm.df$s0[1], sdimax.parm.df$s1[1], sdimax.parm.df$s2[1]),
                  rd = sdi / sdimax)
  
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
  
  # BYI is required, there is no base model
  if (any(dplyr::coalesce(as.numeric(stand$byi), 0) <= 0)) {
    stop('BYI missing or zero: HiGy requires the Biomass Yield Index')
  }
  
  ans = tree %>%
    dplyr::filter(!is.na(stand.id)) %>%
    split(.$stand.id) %>%
    purrr::imap_dfr(function(tree.subset, stand.id.subset) {
      stand.subset = subset(stand, stand.id == stand.id.subset)
      
      HiGYOneStand(tree.subset, 
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
  ## * make.ops()
  ## * make_stand() 
  ## * make_acd_tree()
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

##### Height and crown ratio ####
  #calculate heights of any with missing values.
  #generally, none will be missing when function is used with FVS, but some or
  #all may be missing when code us used to grow tree lists from other sources. 
  tree = tree %>% 
    # mutate(rain=stand.copy$rain, 
    #        temp=stand.copy$temp) %>% 
          #predicted height
    calc_ht(plot.data = plot.smry) %>% 
    dplyr::mutate(#use predicted height if missing or > 150ft (45.72m)
           ht= dplyr::case_when(ht %in% c(NA, 0)| ht>45.72 ~pht,
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
  # calc_ddbh = function(tree.data, plot.data, 
  #                      use.cap.dbh = ops$use.cap.dbh, 
  #                      ddbh.parm.df=ddbh.parm,
  #                      rain=stand$rain, temp=stand$temp, )
  
  tree = tree %>%
    calc_ddbh(plot.data = plot.smry)
 
##### Height increment ####  
  # calc_ht = function(tree.data, plot.data, rain=stand$rain, temp=stand$temp, 
  #                    ht.pred.parm.df = ht.pred.parm)
  
  tree = tree %>%
    calc_dht(plot.data = plot.smry)



#### Ingrowth ####
  
  
#### Mortality ####
  # calc_mortality = function(tree.data, plot.data, planted = stand$planted)

  tree = tree %>%
    calc_mortality(plot.data=plot.smry)
  

#### Update tree values- t+1 ####
  tree=tree %>% 
    dplyr::mutate(year= year+1,
                  dbh= dbh+ dplyr::coalesce(ddbh, 0),
                  ht= ht+ dplyr::coalesce(dht, 0),
                 # hcb= hcb + dplyr::coalesce(dhcb, 0),
                  expf= dplyr::coalesce(expf, 0) - dplyr::coalesce(dexpf, 0),
                  expf= ifelse(expf< 0.00001, 0.00001, expf)) 

#### Crown recession ####
 # calculate t+1 height to crown base  
  tree = tree %>% 
    dplyr::mutate(ba = (dbh^2*0.00007854)*expf) %>% 
    calc_bal()
  
  # Calculate plot summary
  plot.smry = tree %>% 
    calc_plot_summary()
  
  # crown ratio change limited to 1% annually   
  tree=tree %>% 
    calc_hcb(plot.data = plot.smry) %>% 
    dplyr::mutate(pcr= 1-(phcb/ht), 
                  cr= dplyr::case_when((pcr-cr)/cr>0.01 ~cr*1.01,
                                       (pcr-cr)/cr< -0.01 ~cr*0.99,
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
       
