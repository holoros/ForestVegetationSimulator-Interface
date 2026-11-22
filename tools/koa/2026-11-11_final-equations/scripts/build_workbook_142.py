# build_workbook_142.py  Koa yield-curve workbook for the Forest Solutions financial model, koa v142 (22 November 2026).
# Starts from the 21 November (1.15.0) workbook and refills it from script 72_workbook_1150.R rerun on the v142 frames (Cardinal koa142, logs142/72.log).
import sys, math, openpyxl, pandas as pd
SRC = sys.argv[1]; D = sys.argv[2]; OUT = sys.argv[3]
g = pd.read_csv(f'{D}/workbook_grid_72.csv'); dg = pd.read_csv(f'{D}/workbook_diag_72.csv')
lg = pd.read_csv(f'{D}/workbook_logistic_72.csv'); xo = pd.read_csv(f'{D}/workbook_crossover_72.csv')
SITES = ['Excellent', 'Good', 'Marginal', 'Low Feasibility']; DENS = [100, 200, 300, 400]
wb = openpyxl.load_workbook(SRC)
c = g[g.sdimax == 'central']
def col(df, s, n, v): return df[(df.site == s) & (df.stems_ac == n)].sort_values('age')[v].round(2).tolist()
def fill_age_sheet(ws, df, v, combos):
    for j, (s, n, d) in enumerate(combos):
        vals = col(d, s, n, v)
        assert len(vals) == 200
        for i, x in enumerate(vals): ws.cell(3 + i, 2 + j).value = float(x)
combos = [(s, n, c) for s in SITES for n in DENS]
for sh, v in [('Basal Area', 'BA_ft2ac'), ('QMD', 'QMD_in'), ('Stems', 'TPA'), ('VBAR', 'VBAR')]:
    fill_age_sheet(wb[sh], c, v, combos)
# SDImax cases: good and marginal at the low and high multipliers
sv = {(r.sdimax, r.site): r.sdimax_value for r in g[['sdimax', 'site', 'sdimax_value']].drop_duplicates().itertuples()}
ws = wb['SDImax Cases']; cc = []
for s in ['Good', 'Marginal']:
    for k in ['low', 'high']:
        for n in DENS: cc.append((s, n, g[g.sdimax == k], k))
for j, (s, n, d, k) in enumerate(cc):
    ws.cell(2, 2 + j).value = f'{s}, SDImax {round(sv[(k, s)])}\n{n} stems ac⁻¹'
    for i, x in enumerate(col(d, s, n, 'BA_ft2ac')): ws.cell(3 + i, 2 + j).value = float(x)
mlo = sv[('low', 'Good')] / sv[('central', 'Good')]; mhi = sv[('high', 'Good')] / sv[('central', 'Good')]
ws.cell(1, 1).value = (f'Table 9. Stand basal area (ft² ac⁻¹) when the site maximum SDI is at the 10th or the 90th percentile of the planted plot estimates about the prediction '
    f'({mlo:.2f} and {mhi:.2f} times the predicted value), good and marginal sites, for comparison with the predicted value on the Basal Area sheet (good {round(sv[("central","Good")])}, marginal {round(sv[("central","Marginal")])}).')
def ba(k, s, n, a): return float(g[(g.sdimax == k) & (g.site == s) & (g.stems_ac == n) & (g.age == a)].BA_ft2ac.iloc[0])
ws.cell(204, 1).value = ('Shaded rows, ages 53 to 200, are beyond the 52 years of the longest koa record and rest on the fitted response to relative density. Once thinned plots are cut off at their first thinning, only seven plots were followed for 10 years or more. Age 1 is the starting state (QMD 2.85 in), not the planting year. '
    f'At 200 stems ac⁻¹ on a good site, basal area at age 40 is {ba("low","Good",200,40):.0f}, {ba("central","Good",200,40):.0f} and {ba("high","Good",200,40):.0f} ft² ac⁻¹ at the low, predicted and high maximum SDI, and at age 100 it is {ba("low","Good",200,100):.0f}, {ba("central","Good",200,100):.0f} and {ba("high","Good",200,100):.0f}.')
# logistic parameters
ws = wb['Logistic Parameters']; L = lg[lg.sdimax == 'central']
for i, (s, n) in enumerate([(s, n) for s in SITES for n in DENS]):
    r = L[(L.site == s) & (L.stems_ac == n)].iloc[0]; row = 3 + i
    vals = [s, int(r.byi), n, round(n / 0.8), n, round(r.A, 2), round(r.B, 3), round(r.C, 3), round(r.rmse, 3), round(r.rmse_pct, 2), round(-r.e40, 2), round(-r.e52, 2), round(r.A100, 2), round(r.B100, 3), round(r.C100, 3), round(r.rmse_pct100, 2)]
    for j, v in enumerate(vals): ws.cell(row, 1 + j).value = v
# max gap between logistic (1 to 60) and the simulated curve, ages 10 to 60
gap = 0
for r in L.itertuples():
    d = c[(c.site == r.site) & (c.stems_ac == r.stems_ac) & (c.age >= 10) & (c.age <= 60)]
    f = r.A / (1 + (-(d.age - r.B) / r.C).apply(math.exp)); gap = max(gap, (f - d.BA_ft2ac).abs().max())
# VBAR summary
ws = wb['VBAR Summary']
def at(s, n, v, a): return float(c[(c.site == s) & (c.stems_ac == n) & (c.age == a)][v].iloc[0])
for i, (s, n) in enumerate([(s, n) for s in SITES for n in DENS]):
    vals = [s, n, round(at(s, n, 'VBAR', 45), 1)] + [round(at(s, n, 'VBAR', a), 1) for a in (20, 40, 45, 52, 60, 100)] + [round(at(s, n, 'QMD_in', a), 2) for a in (20, 45, 100)]
    for j, v in enumerate(vals): ws.cell(3 + i, 1 + j).value = v
vb = c[c.age >= 20].VBAR
# diagnostics
ws = wb['Diagnostics']; G = dg[dg.sdimax == 'central']
for i, (s, n) in enumerate([(s, n) for s in SITES for n in DENS]):
    r = G[(G.site == s) & (G.stems_ac == n)].iloc[0]
    vals = [s, n, round(r.BA20, 2), round(r.BA40, 2), round(r.BA52, 2), round(r.BA100, 2), round(r.BA200, 2), round(r.peakBA, 2), int(r.peak_age), round(r.decline_pct, 1), round(r.stems52, 1), round(r.qmd52, 2), round(r.reineke, 3), 'pass' if r.rises_to_peak else 'fail']
    for j, v in enumerate(vals): ws.cell(3 + i, 1 + j).value = v
for i, r in enumerate(xo.itertuples()):
    ws.cell(25 + i, 1).value = int(r.stems_ac); ws.cell(25 + i, 2).value = (int(r.first_inversion) if not pd.isna(r.first_inversion) else 'none by 200')
    ws.cell(25 + i, 3).value = round(r.exc_minus_low_100, 1); ws.cell(25 + i, 4).value = round(r.low_minus_exc_200, 1)
rd100 = c[c.age == 100].RD; rd200 = c[c.age == 200].RD
inv = xo.first_inversion.dropna().astype(int).tolist()
ws.cell(20, 1).value = (f'Site ordering between adjacent classes holds to age {min(inv) - 1} at every density; the first inversions come at ages {min(inv)} to {max(inv)} (Table 8). ' if len(inv) == 4 else (f'Site ordering holds to age {min(inv) - 1} where an inversion occurs (Table 8). ' if inv else 'Site ordering holds to age 200 at every density (Table 8). ')) + \
    (f'Basal area rises monotonically to its peak in all sixteen. ' if G.rises_to_peak.all() else '') + \
    f'Realized Reineke slopes run {G.reineke.min():.2f} to {G.reineke.max():.2f}. Stands rise to a maximum relative density of {G.rd_max.min():.2f} to {G.rd_max.max():.2f} under the fitted mortality response and thin out afterwards (relative density {rd100.min():.2f} to {rd100.max():.2f} at age 100 and {rd200.min():.2f} to {rd200.max():.2f} at age 200); no thinning rule, diameter cap or floor is applied.'
ws.cell(30, 1).value = ('Low feasibility minus excellent is negative at age 200 at every density, so the order of the extreme classes holds; the inversions late in the run are between adjacent classes. ' if (xo.low_minus_exc_200 < 0).all() else 'Low feasibility exceeds excellent at age 200 at some densities, so the site order of basal area fails late in the run. ') + 'Do not read standing stock past age 100 off these curves without the SDImax Cases sheet beside it.'
# basal area footnote
wb['Basal Area'].cell(204, 1).value = ('Shaded rows, ages 53 to 200, are beyond the 52 years of the longest koa record and rest on the fitted response to relative density. Once thinned plots are cut off at their first thinning, only seven plots were followed for 10 years or more. Age 1 is the starting state (QMD 2.85 in), not the planting year. '
    f'Basal area peaks between ages {G.peak_age.min()} and {G.peak_age.max()} and declines thereafter, which no logistic reproduces. The level of every curve depends on the site maximum SDI, here predicted from BYI (excellent {round(sv[("central","Excellent")])}; good {round(sv[("central","Good")])}; marginal {round(sv[("central","Marginal")])}; low feasibility {round(sv[("central","Low Feasibility")])}); see the SDImax Cases sheet.')
# README
R = wb['README']
R.cell(2, 1).value = ('DRAFT prepared 22 November 2026 by Aaron Weiskittel, University of Maine, for Aviva Gottesman and Irene Sprecher. Supersedes the 21 November 2026 file. Every curve, parameter and table is rebuilt from koa version 1.15.1 (Koa 1.15.1, 22 November 2026, below). The curves are point projections; intervals are summarised under What is modeled and what is not. The dated notes further down record earlier files and keep their own numbers.')
R.cell(5, 1).value = R.cell(5, 1).value.replace('one set of koa equations of 11 November 2026: height from height equations fitted jointly (15 November 2026)', 'one set of koa equations, version 1.15.1 of 22 November 2026: height from height equations fitted jointly').replace('version 1.15.0 of 21 November 2026', 'version 1.15.1 of 22 November 2026')
R.cell(8, 1).value = f'Two routes are provided. Between ages 10 and 60 the fitted logistic is within {math.ceil(gap)} ft² ac⁻¹ of the simulated curve; it fits the first few years poorly.'
e = pd.concat([L.e40.abs(), L.e52.abs()])
R.cell(9, 1).value = ('Route 1, parameters. The Logistic Parameters sheet gives A, B and C for each of the sixteen scenarios, fitted to the simulated curve over ages 1 to 60. Drop the triplet into Model Inputs D63, D64 and D65 (Plant & Done), D70 to D72 and D75 to D77 (Clear Cut) or the Group Selection block, and the workbook needs no structural change. '
    f'Root mean square error against the simulated curve is {L.rmse_pct.min():.1f} to {L.rmse_pct.max():.1f}% of mean basal area, and the error at ages 40 and 52 is within {math.ceil(e.max())} ft² ac⁻¹.')
d200 = G.BA200; diff = []
for r in L.itertuples():
    f201 = r.A / (1 + math.exp(-(201 - r.B) / r.C)); diff.append(f201 - float(G[(G.site == r.site) & (G.stems_ac == r.stems_ac)].BA200.iloc[0]))
R.cell(19, 1).value = ('The equations are fitted on remeasured koa plots and tested by projecting each plot forward from its first measurement. Most planted plots were thinned, and a plot is used only up to its first thinning, so only seven plots were followed for 10 years or more (one planted plot for 52 years, natural plots for up to 33 years). Every value past age 52 is extrapolation and is shaded on each sheet, and values past about age 10 rest on few plots. '
    f'Past the record, the curves rest on the fitted response of mortality to relative density and tree size. Basal area peaks between ages {G.peak_age.min()} and {G.peak_age.max()} and then declines by {G.decline_pct.min():.0f} to {G.decline_pct.max():.0f}% by age 200; the planted curves carry no ingrowth. '
    f'A Plant & Done run taken to year 201 on a fitted logistic can therefore overstate standing basal area by as much as {max(diff):.0f} ft² ac⁻¹ (the difference across the sixteen scenarios runs from {min(diff):.0f} to {max(diff):.0f}). '
    f'The site maximum SDI is a large source of uncertainty. These sheets predict it from the site class (BYI) for planted stands (excellent {round(sv[("central","Excellent")])}; good {round(sv[("central","Good")])}; marginal {round(sv[("central","Marginal")])}; low feasibility {round(sv[("central","Low Feasibility")])} trees ha⁻¹). '
    'That prediction explains 15% of the plot to plot variation for plots left out of its fitting (11% for origin alone; the BYI coefficient is 0.217 with a 95% interval of -0.015 to 0.447, so the rise with site is weak), and the excellent and good classes lie above the 90th percentile of BYI in the planted plots (308), so their values are extrapolated. '
    f'The SDImax Cases sheet shows what the 10th to 90th percentile of planted plots about the prediction ({mlo:.2f} to {mhi:.2f} times) does to basal area. '
    'Tested against remeasured plots, with the maximum SDI predicted for plots left out of its fitting, the equations predict basal area with a root mean square error of 6.71 m² ha⁻¹ (29 ft² ac⁻¹), and 5.63 m² ha⁻¹ (25 ft² ac⁻¹) for planted plots, almost all at horizons under 10 years; with the maximum SDI, diameter growth and mortality equations all refitted without each plot’s installation it is 7.13 m² ha⁻¹ (31 ft² ac⁻¹). '
    'For a planted stand projected from a measured tree list at a median site (BYI 159), the 90% interval at 100 years is 24.3 to 63.8 m² ha⁻¹ (106 to 278 ft² ac⁻¹) around a point value of 42.2 (184). '
    'At each remeasured plot’s longest horizon this interval contained the observed basal area of 89% of plots where 90% was intended, and 91% when the stand’s own maximum SDI was allowed to differ from the prediction; with the equations refitted without each plot’s installation the figures are 85% and 89%. Survival was covered less well (74% and 76%, or 68% and 76% with refitted equations). '
    'Establishment losses in the first 5 to 10 years and mortality from koa wilt, Fusarium oxysporum f. sp. koae, are outside the system and must be carried as separate adjustments.')
R.cell(22, 1).value = R.cell(22, 1).value.replace('The spread from age 20 on runs from 79 to 98.', f'The spread from age 20 on runs from {vb.min():.0f} to {vb.max():.0f}.')
R.cell(25, 1).value = ('Equations: koa version 1.15.1 of 22 November 2026 (release file koa_rdbyi_equations.csv; scripts 80 to 84 with the rerun chain in tools/koa/2026-11-11_final-equations on the ClaudeDevelopment branch of https://github.com/holoros/ForestVegetationSimulator-Interface), deterministic point path, planted origin, unthinned. '
    'Maximum SDI = exp(5.9368 + 0.2167 ln(BYI) - 0.5728 planted); diameter growth, mortality, the height curve and height increment were refitted with it, and thinning removals on the permanent sample plots are excluded from the mortality data. '
    'Site classes map to the biomass yield index at BYI = 450, 340, 230 and 120 Mg ha⁻¹ for excellent, good, marginal and low feasibility; that mapping is a modeling judgment, not a measured relationship. '
    'The starting tree list is the planted plot visit with at least 30 trees closest to the median quadratic mean diameter and stems of such visits (a permanent sample plot measured in 2015, 37 trees), with diameters rescaled to a QMD of 7.24 cm (2.85 in); the 15 November file used an 11-tree list. '
    'Grid from script 72_workbook_1150.R rerun on the v142 frames (Cardinal job koa142, log logs142/72.log); workbook builder build_workbook_142.py. Version 1.15.0 is https://doi.org/10.5281/zenodo.24425094; the 1.15.1 deposit is drafted and not yet published.')
n = R.max_row + 2
R.cell(n, 1).value = 'Koa 1.15.1, 22 November 2026'; R.cell(n, 1).font = openpyxl.styles.Font(bold=True)
R.cell(n + 1, 1).value = ('The site index (BYI) was recomputed: the 36 inventory plots that also trained the BYI forests now carry out-of-bag predictions (a median 10% lower), and 474 duplicated rows of the biomass frame were removed before refitting. Every equation was refitted with forms unchanged. '
    f'The maximum SDI now rises only weakly with site (excellent {round(sv[("central","Excellent")])}, good {round(sv[("central","Good")])}, marginal {round(sv[("central","Marginal")])}, low feasibility {round(sv[("central","Low Feasibility")])} trees ha⁻¹, against 959, 824, 667 and 469 in the 21 November file), so the spread between site classes in basal area is narrower, while diameter growth responds more strongly to site. '
    'Details are in manuscript v142 and supplement v134.')
R.cell(n + 1, 1).alignment = R.cell(19, 1).alignment.copy()
# the 1.15.0 note is already in the 21 November source workbook and is kept as is

wb.save(OUT); print('saved', OUT, 'gap', round(gap, 1), 'vbar', round(vb.min(), 1), round(vb.max(), 1), 'diff', round(min(diff)), round(max(diff)))
