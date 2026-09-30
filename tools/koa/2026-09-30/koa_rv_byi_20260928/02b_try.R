suppressMessages(library(nlme))
a <- read.csv("in/AGB.FIA.csv"); s <- read.csv("in/Schmoldt_Index_by_plot.csv"); s$id <- paste(s$COUNTYCD, s$PLOT, sep = "/")
st <- c(A = 437.9, k = 0.0377, p = 2.78)
chk <- function(m, lab) { if (inherits(m, "try-error")) { cat(lab, "FAIL", substr(as.character(m), 1, 90), "\n"); return() }
  cf <- coef(m); cf$id <- rownames(cf); z <- merge(cf, s, by = "id")
  cat(lab, "fixef", round(fixef(m), 4), " n", nrow(z), " r", round(cor(z$A, z$Schmoldt_Index), 5), " maxdiff", round(max(abs(z$A - z$Schmoldt_Index)), 2), " median A", round(median(cf$A), 1), "\n") }
v <- list(
 pnls = nlmeControl(returnObject = TRUE, maxIter = 5000, msMaxIter = 5000, opt = "nlminb", niterEM = 5000, pnlsTol = 0.01, minScale = 1e-6),
 nlm  = nlmeControl(returnObject = TRUE, maxIter = 500, msMaxIter = 500, opt = "nlm", pnlsTol = 0.01),
 def  = nlmeControl(returnObject = TRUE, pnlsTol = 0.1))
for (nm in names(v)) { t0 <- Sys.time()
  m <- try(nlme(AGB ~ A * (1 - exp(-k * H40.m))^p, data = a, fixed = A + k + p ~ 1, random = A ~ 1 | COUNTYCD/PLOT, start = st,
                weights = varPower(0.2, form = ~H40.m), control = v[[nm]]), silent = TRUE)
  chk(m, nm); cat("  secs", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), "\n") }
cat("done\n")
