# 84_table1_byi.R  koa v142 Table 1: record-weighted mean BYI by source over the live records of the inventory database (in/koa.sqlite),
# with plot BYI of koa 1.15.0 (frames) and of v142 (script 80); Kualoa plots (not in the frames) predicted by the statewide C2 forest
# with and without the 474 duplicate Eq. 1 rows, as script 80 builds it. Server side; no coordinate printed or written.
suppressMessages({library(data.table); library(ranger); library(DBI); library(RSQLite)})
L <- readLines("~/jobs/koa_byi2_20261101/v2/01_index.R"); iq <- grep("quit(status = 1)", L, fixed = TRUE); L[iq] <- "if (!G2) logm(\"G2 below 0.975 (expected without duplicates)\")"
kua <- list()
for (mode in c("orig", "dedup")) { env <- new.env(); eval(parse(text = L[1:6]), envir = env); env$O <- file.path(tempdir(), mode); dir.create(env$O, showWarnings = FALSE)
  eval(parse(text = L[7]), envir = env); if (mode == "dedup") env$a <- env$a[!duplicated(env$a), ]; eval(parse(text = L[8:79]), envir = env)
  with(env, { Dw <- mkD(fr$w, wv, "C2"); fw <- ranger(y ~ ., data = Dw, num.trees = 500, mtry = 3, min.node.size = 5, seed = 42, num.threads = NT) })
  g <- env$g; k <- which(g$Data == "Kualoa"); nw <- g[k, env$wv]; ok <- complete.cases(nw)
  kua[[mode]] <- data.table(Plot = as.character(g$Plot[k]), byi = ifelse(ok, predict(env$fw, nw[ok, , drop = FALSE])$predictions[cumsum(ok)], NA_real_)) }
K <- merge(kua$orig, kua$dedup, by = "Plot", suffixes = c("_1150", "_v142")); cat("Kualoa plots:", nrow(K), "\n"); print(K)
con <- dbConnect(SQLite(), "~/jobs/koa_1150_20261121/in/koa.sqlite"); tr <- as.data.table(dbGetQuery(con, "select Data, Install, Plot, Status from tree")); dbDisconnect(con)
l <- tr[Status == "live"]; l[, `:=`(Install = as.character(Install), Plot = as.character(Plot))]
B <- fread("~/jobs/koa_bendb_20261121/v142/out/byi_oob_80.csv", colClasses = list(character = c("Install", "Plot")))
m <- merge(l, B[, .(Data, Install, Plot, b0 = BYI_frames, b1 = BYI_v142)], by = c("Data", "Install", "Plot"), all.x = TRUE)
m[Data == "Kualoa", `:=`(b0 = K$byi_1150[match(Plot, K$Plot)], b1 = K$byi_v142[match(Plot, K$Plot)])]
R <- m[, .(records = .N, with_byi = sum(!is.na(b1)), mean_1150 = round(mean(b0, na.rm = TRUE), 1), mean_v142 = round(mean(b1, na.rm = TRUE), 1)), by = Data][order(Data)]
R <- rbind(R, m[, .(Data = "Total", records = .N, with_byi = sum(!is.na(b1)), mean_1150 = round(mean(b0, na.rm = TRUE), 1), mean_v142 = round(mean(b1, na.rm = TRUE), 1))])
print(R); fwrite(R, "~/jobs/koa_1150_20261121/out/table1_byi_84.csv"); cat("84 done\n")
