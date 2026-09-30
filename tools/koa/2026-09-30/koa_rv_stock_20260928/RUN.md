# koa_rv_stock_20260928

Date 2026-09-28; RUN.md written 2026-09-29. Host ifm-kershaw (firebreather).
Purpose: stocking of projected stands against the A-line of Baker and Scowcroft (2005).
Input: ~/jobs/koa_rv_mort_20260928/deliver/a5_tph_qmd_trajectories.csv (anonymized).
Method (stock.py): N_A = 10000 / (pi/4 * CW^2) * 0.9069, CW = a + b * QMD (m), lines
Keauhou 1992 windward (0.78, 15.34), Hakalau 2000 windward (0.70, 16.44), Honomalino 2002 leeward (-0.23, 24.59).
Stocking percent = TPH / N_A * 100 by source, scenario, site and line: age 1, age 40, maximum and its age,
first age at 80 and at 100 percent.
Output: stocking_summary.csv. Run: cd ~/jobs/koa_rv_stock_20260928 && python3 stock.py
