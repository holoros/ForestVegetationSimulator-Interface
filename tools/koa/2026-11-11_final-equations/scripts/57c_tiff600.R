# 57c_tiff600.R  Upload copies of Figs. 3 to 5 of manuscript v137 at 600 dpi: runs scripts 57a and 57b unchanged except for the output folder and the resolution.
setwd("~/jobs/koa_final_eq_20261110"); dir.create("ms_v137/dpi600", showWarnings = FALSE)
for (f in c("scripts/57a_fig3_figS4_v137.R", "scripts/57b_fig4_fig5_v137.R")) { L <- readLines(f); L <- gsub("ms_v137/(Fig[0-9S]+_[a-z_]+\\.png)", "ms_v137/dpi600/\\1", L); L <- gsub("dpi = 300", "dpi = 600", L, fixed = TRUE); L <- gsub("fwrite(hs, \"ms_v137/", "fwrite(hs, \"ms_v137/dpi600/", L, fixed = TRUE); eval(parse(text = L)) }
cat("600 dpi figures written\n")
