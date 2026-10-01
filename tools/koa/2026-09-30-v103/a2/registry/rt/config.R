## config.R: every path, column name and published constant the job needs, in one place.
## Edit the PATHS block after running 00_discover.R; the rest is taken from manuscript v92,
## supplement v91 and the September 16, 2026 red team review.

## ---------------- PATHS ----------------
DEPOSIT_DIR   <- Sys.getenv("KOA_DEPOSIT", "deposit")      # unpacked Zenodo 1.7.1 release
OUT_DIR       <- Sys.getenv("KOA_OUT", "output")
F_TREE        <- Sys.getenv("KOA_TREE", "AK_TREE.csv")   # 2026-09-16: set to derived/tree_join.csv (AK_TREE + BYI and origin from AK_PLT_GEO)
F_PLT         <- "AK_PLT.csv"
F_PLT_GEO     <- "AK_PLT_GEO.csv"
F_HCB         <- "AK_HCB.csv"
F_INC_DDBH    <- Sys.getenv("KOA_INC_DDBH", "")   # legacy increment fitting frames on firebreather
F_INC_DHT     <- Sys.getenv("KOA_INC_DHT", "")
F_SURV        <- Sys.getenv("KOA_SURV", "AK_SURV.csv")   # 2026-09-16: derived/surv_baseline_rebuilt (reproduces AK_SURV.csv, 5,969 / 79)
## recovered survival sample (variant ii of Supplemental Table S11); leave "" if not in the deposit
F_SURV_RECOVERED <- Sys.getenv("KOA_SURV_RECOVERED", "")
## engine trajectory output: one row per scenario x site x age (x replicate), written by the
## deposited projection driver; leave "" until 04_engine_patch.R has produced it
F_TRAJ        <- Sys.getenv("KOA_TRAJ", "")
F_TRAJ_REF    <- Sys.getenv("KOA_TRAJ_REF", "")     # same output under the engine vector of record, for the before/after table
## per-plot 23-plot validation output (projected and observed at the remeasurement)
F_VALID       <- Sys.getenv("KOA_VALID", "")
## command that runs the deposited projection driver inside the patched engine copy
DRIVER_CMD    <- Sys.getenv("KOA_DRIVER_CMD", "")

## ---------------- COLUMN MAP ----------------
## left side is the name the scripts use; right side is the name in the deposit files.
## 00_discover.R reports every mismatch; fix the right-hand side only.
COL <- list(
  source = "SOURCE", inst = "INSTALLATION", plot = "PLOT", year = "MEASYEAR", tree = "TREE",
  dbh = "DBH", ht = "HT", expf = "EXPF", status = "STATUS", baph = "BAPH", bal = "BAL",
  baperc = "BA.perc", byi = "BYI", planted = "Planted", yip = "YIP", cr = "CR",
  ddbh = "dDBH", dht = "dHT", hcb = "HCB", alive = "alive", rht = "rHT"
)
VCOL <- list(plot = "PLOT", obs_surv = "obs_surv", pred_surv = "pred_surv",
             obs_ba = "obs_ba", pred_ba = "pred_ba", obs_qmd = "obs_qmd", pred_qmd = "pred_qmd",
             origin = "origin", interval = "interval")
TCOL <- list(scenario = "scenario", site = "site", age = "age", rep = "rep", qmd = "QMD",
             ht = "HT", baph = "BAPH", tph = "TPH", vol = "VOL", mort_vol = "MORT_VOL", sdi = "SDI")

## ---------------- PUBLISHED CONSTANTS (for gates, never refit here) ----------------
HT_ENGINE <- c(a0 = 19.832, a1 = 0.106, b = 0.044, c = 0.863, g1 = -0.198, g2 = 0.479)   # rDBH = DBH/QMD
HT_REFIT_PRINTED <- c(a0 = 25.37, a1 = 1.042, b = 0.0220, c = 0.814, g1 = 0.0556, g2 = -0.282) # rDBH = DBH/DBH.max
HT_FIT_STATS <- c(n = 10706, r2_cond = 0.866, r2_pa = 0.783, rmse_pa = 2.476)
INC_S8 <- list(
  ddbh = c(b0 = -2.4705, b1 = 0.2072, b2 = -0.0160, b3 = -0.00169, b4 = -0.2973, b5 = -0.4470, b6 = -0.0158, b7 = 0.0189, b8 = 0.4530),
  dht  = c(b0 = -3.3822, b1 = 0.2725, b2 = -0.1053, b3 = -0.000829, b4 = -0.0717, b5 = -1.4839, b6 = 0.0330, b7 = 0.0179, b8 = 0.4332))
INC_S8_SE <- list(
  ddbh = c(0.4346, 0.0299, 0.00288, 0.000402, 0.0209, 0.2327, 0.00281, 0.00472, 0.0401),
  dht  = c(0.5623, 0.0715, 0.01108, 0.000212, 0.0235, 0.2439, 0.00362, 0.01191, 0.0490))
SURV_S9 <- c(b0 = 14.102, b1 = 0.130, b2 = -4.516, b3 = 6.684, b4 = 14.218, b5 = -2.806, b6 = 2.649, b7 = -21.188)
SURV_N <- c(records = 5969, events = 79, installations = 62)
SITE_BYI <- c(Low = 100, Medium = 264, High = 450)
CAP_DBH  <- c(natural = 90, planted = as.numeric(Sys.getenv("KOA_CAP_PLANTED", "60")))
OBS_MAX_QMD <- 69.7
FORM_FACTOR <- 0.40
WOOD_BASIC_DENSITY <- 510      # kg m-3, specific gravity 0.51 (Wilton et al. 2015)
CARBON_FRACTION    <- 0.47     # IPCC (2006) Table 4.3 default
CALIB_AGE_MAX <- 52

## ---------------- RUN CONTROL ----------------
SEED     <- 20260916L
NBOOT    <- as.integer(Sys.getenv("KOA_NBOOT", "5000"))                # cluster bootstrap resamples for equivalence tests
NDRAW    <- 2000L                # coefficient draws for figure bands
NCORES   <- min(8L, parallel::detectCores())
EQ_REGION <- c(b0 = 0.25, b1 = 0.25)  # regions of equivalence, fixed a priori (25% convention)
RUN_LOIO <- as.logical(Sys.getenv("KOA_LOIO", "TRUE"))
