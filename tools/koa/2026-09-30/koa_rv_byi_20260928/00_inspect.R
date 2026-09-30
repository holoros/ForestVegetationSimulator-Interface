## Structure-only inspection of the two BYI spatialRF fit objects. Prints names, dims and classes, never coordinate values.
for (f in c("in/BYI_srf_fit.RDS","in/BYI_srf_fit_HI.RDS")) {
  m <- readRDS(f); cat("\n==", f, paste(class(m), collapse=","), "\n")
  cat("top names:", paste(names(m), collapse=" "), "\n")
  a <- m$ranger.arguments
  cat("ranger.arguments names:", paste(names(a), collapse=" "), "\n")
  for (nm in names(a)) { v <- a[[nm]]; cat(sprintf("  %s: class=%s dim=%s len=%s\n", nm, paste(class(v),collapse=","), paste(dim(v),collapse="x"), length(v))) }
  cat("data cols:", paste(names(a$data), collapse=" "), "\n")
  y <- a$data[[m$dependent.variable.name]]; cat("dep:", m$dependent.variable.name, " n=", length(y), " zeros=", sum(y==0), " mean=", mean(y), " median nonzero=", median(y[y>0]), "\n")
  if (!is.null(a$xy)) cat("xy present: cols", paste(names(a$xy), collapse=" "), " nrow", nrow(a$xy), "\n")
  for (nm in c("performance","residuals","spatial","evaluation","importance","variable.importance")) if (!is.null(m[[nm]])) { cat("--", nm, "names:", paste(names(m[[nm]]), collapse=" "), "\n") }
  if (!is.null(m$performance)) print(m$performance[sapply(m$performance, function(z) is.numeric(z) && length(z) < 5)])
  if (!is.null(m$residuals$autocorrelation)) print(m$residuals$autocorrelation$per.distance)
}
o <- readRDS("in/BYI_OOB_per_plot.rds"); cat("\nOOB rds class", class(o), " names:", paste(names(o), collapse=" "), "\n")
