suppressMessages(library(nlme))
a <- read.csv("in/AGB.FIA.csv"); a$PID <- factor(paste(a$COUNTYCD, a$PLOT, sep = "/")); a$CTY <- factor(a$COUNTYCD)
s <- read.csv("in/Schmoldt_Index_by_plot.csv"); s$id <- paste(s$COUNTYCD, s$PLOT, sep = "/")
chk <- function(m, lab, sc = 1) { if (inherits(m, "try-error")) { cat(lab, "FAIL", substr(as.character(m), 1, 90), "\n"); return() }
  cf <- coef(m); cf$A <- cf$A * sc; cf$id <- sub("^[^/]*/", "", rownames(cf)); if (!grepl("/", cf$id[1])) cf$id <- rownames(cf); z <- merge(cf, s, by = "id")
  cat(lab, "fixef", round(fixef(m), 4), " n", nrow(z), " r", round(cor(z$A, z$Schmoldt_Index), 5), " maxdiff", round(max(abs(z$A - z$Schmoldt_Index)), 2), " medA", round(median(cf$A), 1), "\n") }
ctl <- nlmeControl(returnObject = TRUE, maxIter = 500, msMaxIter = 500, opt = "nlminb", pnlsTol = 0.01)
t0 <- Sys.time()
m1 <- try(nlme(AGB ~ 100 * A * (1 - exp(-k * H40.m))^p, data = a, fixed = A + k + p ~ 1, random = A ~ 1 | CTY/PID,
  start = c(A = 4.379, k = 0.0377, p = 2.78), weights = varPower(0.2, form = ~H40.m), control = ctl), silent = TRUE); chk(m1, "scaledA nested", 100)
cat(" s", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "\n")
m2 <- try(nlme(AGB ~ A * (1 - exp(-k * H40.m))^p, data = a, fixed = A + k + p ~ 1, random = A ~ 1 | PID,
  start = c(A = 437.9, k = 0.0377, p = 2.78), weights = varPower(0.2, form = ~H40.m), control = ctl), silent = TRUE); chk(m2, "plot only")
m3 <- try(nlme(AGB ~ A * (1 - exp(-k * H40.m))^p, data = a, fixed = A + k + p ~ 1, random = A ~ 1 | CTY/PID,
  start = c(A = 437.9, k = 0.0377, p = 2.78), control = ctl), silent = TRUE); chk(m3, "no weights")
cat(" s", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "\n"); cat(as.character(packageVersion("nlme")), "\n")
