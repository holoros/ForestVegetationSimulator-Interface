# Build the koa FVS-Hi input database from the model frames of record (koa v142: BYI recomputed; trees unchanged from 1.15.0).
# One stand per plot measurement: FVS_StandInit (with BYI and STDORGCD columns) and FVS_TreeInit
# (live koa with DBH > 0). Units: DIAMETER in, HT ft, TREE_COUNT trees/ac. No coordinates.
suppressMessages({library(data.table); library(DBI); library(RSQLite)})
f <- readRDS("~/jobs/koa_bendb_20261121/v142/frames/frames.rds"); tr <- as.data.table(f$tr)
tr[, base := paste(gsub(" ", "", Data), Install, Plot, sep = "_")]
tr[, STAND_ID := paste(base, Measure, sep = "_")]
lv <- tr[Status == "live" & DBH > 0 & EXPF > 0]
st <- unique(tr[, .(STAND_ID, base, pid, Data, Install, Plot, INV_YEAR = Measure, BYI = round(BYI, 6), STDORGCD = planted)])
st <- st[STAND_ID %in% lv$STAND_ID]
stopifnot(!anyDuplicated(st$STAND_ID), all(is.finite(st$BYI)), all(st$BYI > 0))
SI <- st[, .(STAND_ID, VARIANT = "HI", INV_YEAR, BASAL_AREA_FACTOR = -1, INV_PLOT_SIZE = 1, BRK_DBH = 999,
             NUM_PLOTS = 1L, STDORGCD = as.integer(STDORGCD), BYI, SOURCE = Data, INSTALLATION = Install, PLOT = Plot,
             FIRST_MEAS = as.integer(INV_YEAR == min(INV_YEAR))), by = base][, base := NULL]
SI[, FIRST_MEAS := as.integer(INV_YEAR == min(INV_YEAR)), by = .(SOURCE, INSTALLATION, PLOT)]
TI <- lv[order(STAND_ID, Tree), .(STAND_ID, PLOT_ID = 1L, TREE_ID = as.integer(Tree), TREE_COUNT = EXPF / 2.4710538147,
          HISTORY = 1L, SPECIES = SPP, DIAMETER = DBH / 2.54, HT = fifelse(HT > 0, HT / 0.3048, NA_real_), CRRATIO = NA_character_)]
stopifnot(!anyDuplicated(TI[, .(STAND_ID, TREE_ID)]))
out <- "2026-11-22_koa-fvshi-input_DATA.db"; unlink(out); con <- dbConnect(SQLite(), out)
dbWriteTable(con, "FVS_StandInit", as.data.frame(SI)); dbWriteTable(con, "FVS_TreeInit", as.data.frame(TI))
rd <- data.frame(item = c("FVS_StandInit", "FVS_TreeInit", "BYI", "STDORGCD", "STAND_ID", "source of records", "not included"),
  description = c("One row per plot measurement with live koa (stand = plot at that inventory year). FIRST_MEAS = 1 marks each plot's first measurement.",
    "Live koa with DBH > 0 at that measurement: DIAMETER in, HT ft (NULL when not measured), TREE_COUNT trees per acre from the plot expansion factor.",
    "Biomass yield index (Mg/ha), modeled, not measured (koa v142): the statewide or Kona C2 spatial random forest at each plot, retrained without the 474 duplicate Eq. 1 rows; FIA training plots carry out-of-bag predictions. The 53 Kapapala (Kap) plots carry BYI predicted from their own climate and soils (statewide forest).",
    "0 natural, 1 planted, as assigned in the model frames. HiByi.kcp passes BYI and STDORGCD to the Event Monitor when its keywords are part of each stand (as when the kcp is attached in FVS-Online, or pasted into a keyfile); an AddFile record pointing to it did not load in our test.",
    "SOURCE_INSTALLATION_PLOT_YEAR, spaces removed from SOURCE.",
    "Model frames of record of the koa v142 build (repaired, deduplicated koa trees, identical to 1.15.0 apart from BYI); the recorded inventory is in the separate inventory SQLite.",
    "No coordinates, no other species, no dead or zero-DBH records."))
dbWriteTable(con, "readme", rd); dbDisconnect(con)
cat("stands", nrow(SI), "plots", uniqueN(SI[, .(SOURCE, INSTALLATION, PLOT)]), "trees", nrow(TI), "\n"); print(SI[, .N, by = SOURCE])
fwrite(SI[, .(SOURCE, INSTALLATION, PLOT, STAND_ID, INV_YEAR, FIRST_MEAS, STDORGCD, BYI)], "stand_byi_142.csv")
# site-level BYI (one row per plot), same layout as site_byi_1150.csv
s1 <- fread("site_byi_1150.csv", colClasses = list(character = "Plot"))
site <- unique(tr[, .(Data, Install, Plot = as.character(Plot), pid, Origin, planted, BYI)])
stopifnot(!anyDuplicated(site$pid), setequal(site$pid, s1$pid))
fwrite(site[match(s1$pid, pid)], "site_byi_142.csv")
# BYI summary by data source and by forest / out-of-bag status (stand rows)
o <- fread("v142/out/byi_oob_80.csv", colClasses = list(character = "Plot"))
cat("BYI by SOURCE (stands)\n"); print(SI[, .(stands = .N, plots = uniqueN(paste(INSTALLATION, PLOT)), min = min(BYI), median = median(BYI), mean = mean(BYI), max = max(BYI)), by = SOURCE], digits = 4)
sp <- merge(site, o[, .(Data, Install, Plot, forest_dedup, oob = !is.na(oob_dedup))], by = c("Data", "Install", "Plot"))
stopifnot(nrow(sp) == nrow(site))
cat("BYI by forest and out-of-bag (plots)\n"); print(sp[, .(plots = .N, min = min(BYI), median = median(BYI), max = max(BYI)), by = .(forest_dedup, oob)], digits = 4)
