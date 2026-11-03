source(path.expand("~/jobs/koa_rdcomp_20261102/lib.R")); F <- readRDS(file.path(OB, "fit_K0.rds")); G <- list()
for (r in c("dDBH", "dHT")) { dd <- max(abs(F[[r]]$b[names(DEP[[r]])] - DEP[[r]])); G[[r]] <- data.frame(resp = r, n = F[[r]]$n, max_abs_diff = dd, pass = dd < 1e-5) }
st <- F$dDBH$strata; r46 <- st$ratio[st$strat == "size" & st$level == "40-60"]
G <- do.call(rbind, G); G$ratio_40_60 <- c(r46, NA); G$ratio_pass <- c(abs(r46 - 1.70132057172756) < 1e-4, NA); print(G); write.csv(G, file.path(OB, "gate_G1.csv"), row.names = FALSE)
