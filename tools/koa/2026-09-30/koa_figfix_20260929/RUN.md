# koa_figfix_20260929

Regenerates main Figs 1 to 6 and supplement Figs S3, S4, S6, S7, S8 for manuscript v104 / supplement s102.
  fig1/fig1.R        Fig 1 (tags only, no in-image note, legend "Data source (plots)"); plot positions fuzzed, true coordinates never read
  fig2/fig2.R        Fig 2 (BYI index units, no note)
  main/fig_main.R    Figs 3 to 6 (engine track2/engine_v102)
  figS34/figS3S4.R   Figs S3, S4 ("Published equation" labels)
  figS67/figS67.R    Figs S6, S7 (nine panels from track3 trajectories.csv)
  figS8/figS8.R      Fig S8 (ggplot, legend, log ticks)
Outputs in deliver/ with md5 list. TIFF 600 dpi for submission, PNG embeds for docx.
Push set: the six R scripts and RUN.md. No data, no rasters, no coordinates.
