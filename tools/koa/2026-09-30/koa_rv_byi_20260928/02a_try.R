suppressMessages(library(nlme))
a <- read.csv("in/AGB.FIA.csv")
n1 <- nls(AGB ~ A * (1 - exp(-k * H40.m))^p, data = a, start = list(A = 500, k = 0.05, p = 2.5), control = nls.control(maxiter = 500))
lower_bounds <- c(A = 10, k = 0.01, p = 0.5); upper_bounds <- c(A = 1000, k = 0.20, p = 5.0)
t0 <- Sys.time()
m <- try(nlme(AGB ~ A * (1 - exp(-k * H40.m))^p, data = a, fixed = A + k + p ~ 1, random = A ~ 1 | COUNTYCD/PLOT,
  start = coef(n1), weights = varPower(0.2, form = ~H40.m), na.action = na.omit,
  control = nlmeControl(returnObject = TRUE, maxIter = 5000, minScale = 1e-6, msMaxIter = 5000, opt = "nlminb",
                        lower = lower_bounds, upper = upper_bounds, niterEM = 5000)))
print(Sys.time() - t0)
if (!inherits(m, "try-error")) { print(fixef(m)); cf <- coef(m); s <- read.csv("in/Schmoldt_Index_by_plot.csv"); cf$id <- rownames(cf); s$id <- paste(s$COUNTYCD, s$PLOT, sep = "/"); z <- merge(cf, s, by = "id"); cat("n", nrow(z), "r", cor(z$A, z$Schmoldt_Index), "maxdiff", max(abs(z$A - z$Schmoldt_Index)), "\n") }
