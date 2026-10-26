# -*- coding: utf-8 -*-
"""v106 text edits on koa_manuscript_v105_DRAFT.docx.
SET: whole-paragraph rewrites keyed by a unique start anchor of the v105 paragraph.
SUB: in-paragraph substitutions (anchor, old, new markup).
"""

SET = {}
SUB = []

# ---------------- Abstract ----------------
SET['Acacia koa A. Gray (koa) is Hawaii’s most valuable'] = (
"\t*Acacia koa* A. Gray (koa) is Hawaii’s most valuable endemic hardwood, yet it has no integrated growth and yield (GY) model. "
"This study developed five linked tree-level GY equations from 9,164 live-tree records across 158 installations of natural and planted stands on four islands over seven decades. "
"Site quality enters as a Biomass Yield Index (BYI), a productivity index derived from inventory biomass and top height without stand age and mapped at 30 m by a random forest trained on Hawaii Island, where it separates forest from nonforest and indicates broad productivity differences. "
"The height model explained 86.2% of variation with random intercepts and 79.8% under installation cross-validation. "
"Calibrated with origin constants that also absorb differences among data sources, the increment equations reached population-average {R2} of 0.38 for diameter and 0.26 for height, although the height increment site term was not distinguishable from zero. "
"Mortality is predicted in three stages, in which the probability that a stand records any mortality rises with stand density, a self-thinning rate sets the stand loss and a tree-level survival equation allocates that loss among trees. "
"A tree-list simulator projected 100-year trajectories with Monte Carlo intervals from joint parameter draws, with installations resampled within data sources. "
"On 17 remeasured plots that also informed fitting or calibration, projected quadratic mean diameter agreed with observation in both origins, whereas survival in natural stands and basal area in each origin did not, and on the two natural plots outside every fitting frame the system overpredicted quadratic mean diameter by 3.9 cm. "
"The GY equations, simulator code and BYI surface are a provisional foundation for management, economic and policy assessments, although projections for sites off Hawaii Island, for low-productivity sites and for planted stands older than about 18 years rely on extrapolation.")

# ---------------- Introduction ----------------
SET['Recent US Forest Service Forest Inventory and Analysis (FIA) data indicate'] = (
"The first statewide Forest Inventory and Analysis (FIA) inventory of Hawaii, measured between 2010 and 2015, ranked koa seventh among species in the number of stems at least 12.7 cm in diameter (about 9.1 million) and placed 3.8 million m^3^ of live aboveground volume in koa (Owen et al., 2022), and remeasurement of those plots now supports repeated estimates as fencing, ungulate removal and planting continue across approximately 170,000 ha of forest land that supports koa (Baker et al., 2009). "
"Sustaining koa recovery, whether in high-value timber plantations or in restoration and conservation of residual old-growth stands, requires reliable growth and yield (GY) projections over decadal time scales (Baker et al., 2009; Weiskittel et al., 2011), yet no tool provides species-specific projections across Hawaii’s environmental gradients.")

SUB.append(('The goal of this analysis was to synthesize',
 'The equations were developed for the initial Hawaii variant of the Forest Vegetation Simulator (FVS-HI), which can support further development for koa and extension to additional species.',
 'The equations were developed for the Hawaii variant of the Forest Vegetation Simulator (FVS-HI; Crookston and Dixon, 2005), which implements the height, crown and increment equations and can support further development for koa and extension to additional species.'))

# ---------------- 2.1 ----------------
SET['Two defects in the assembled tables were repaired'] = (
"Stand covariates (BAPH, {tph}, QMD and SDI) were computed for every plot-year from the live stems of all species on the deduplicated tree list, and FIA plot-years were rebuilt from the FIA tree table at the subplot expansion, replacing the stand values originally assembled with the tree list (Section S1.3). "
"The 2015 visit of each Keauhou PSP installation 101 to 108 repeated the 2014 visit tree for tree, so these eight visits (160 records) were removed and the adjacent periods merged. "
"FIA plots enter the validation as whole plots, with their four subplots pooled at the plot expansion (Section 2.6).")

# ---------------- 2.4.1 ----------------
SET['where η = b0 + b1√(HT/100)'] = (
"where η = b~0~ + b~1~√(HT/100) + b~2~ln(HT/DBH) + b~3~√(BAL×BAPH + 1) + b~4~ln(BAPH + 1) + b~5~ln(BYI/100). "
"FVS-HI and the projection simulator carry a parameter vector for this equation whose residual sum of squares on the originally assembled crown covariates was 3.4% above the least-squares optimum (Section S3.1; Table S9). "
"With the covariates of the 360 crown records recomputed from the FIA tree table under the live-list BAL, the deployed vector returns an RMSE of 2.38 m, and refitting the same form lowers it to 2.11 m but reverses the intercept and the BAL term, so the selection rule fixed before refitting, which required both a lower RMSE and every sign kept, retained the deployed vector. "
"The BYI term b~5~ is not significant (P = 0.19), and all crown records are natural FIA trees, so crown ratios in plantations are an extrapolation, and FVS-HI sets b~5~ to zero when no BYI value is supplied.")

# ---------------- 2.4.2 ----------------
SET['where Δ is the periodic annual increment, size is DBH or HT'] = (
"where Δ is the periodic annual increment, size is DBH or HT, b~7~ and b~9~ carry the planted size slope and level shift, and b~8~ carries site quality. "
"The consecutive-interval frames keep live-tree intervals with annual increment above zero and below 10 {cmyr} or 10 {myr}, which leaves 4,792 diameter and 3,857 height intervals, and most removed intervals are shorter than three years, where change lies inside measurement error (Section S3.2). "
"The calibration frames add the first-to-last interval of each tree, drop every interval that spans a thinning removal and keep the records with a recorded origin, which leaves 4,971 diameter and 4,033 height records, and Table S33 reconciles every frame size reported here. "
"Plot BYI on these records runs from 25 to 691, so ln(BYI) is defined on every increment record. "
"The equations were fitted in nlme with random intercepts for data source and installation within source, the height equation also with a tree intercept, and are deployed in population-average form with a marginal lognormal correction factor of 1.369 for diameter (weighted Duan (1983) smearing counterpart 1.372) and 2.420 for height, each computed from the fitted data-source and installation variances. "
"The planted size argument is bounded at 45 cm and 20 m, about the 99th percentiles of planted size in the fitting frames.")

SUB.append(('Because the KMR PSP source is entirely planted',
 'so that the total annual increment projected through the simulator’s crown and competition recursion equals the observed total',
 'so that the total annual increment projected through the simulator’s annual crown and competition update equals the observed total'))

SET['The increment equations were selected under a rule written before'] = (
"The selection rule for the increment equations was fixed before any candidate was fitted (Section S3.2). "
"For each response, five candidates crossed the competition definition, namely the percentile over every record of the plot-year, the live-list percentile and the conventional expansion-weighted BAL, with the interval frame, and a candidate was eligible if its signs matched expectation, if observed on predicted increment passed an installation-cluster equivalence test at ±25% in intercept and slope on both frames, and if no size class up to 60 cm or 30 m departed from observation by more than 25%. "
"No candidate was eligible for either response. "
"Every diameter candidate fell short of observed growth in the 30 to 60 cm classes (observed to predicted 1.29 to 1.78), three of the four conventional and live-list diameter fits returned a positive stand basal area term, and every height candidate fell short of observed growth above 15 m (1.24 to 1.40). "
"For height increment the fallback of the rule was deployed, namely the candidate whose widest equivalence region was narrowest, which is the live-list fit on the calibration frame (widest region 0.245, against 0.246 for the conventional fit). "
"For diameter increment, we retained the coefficient vector fitted to 4,790 consecutive intervals on the original covariates, which was not one of the candidates, and re-solved its origin constants on the calibration frame under the live-list BAL, a documented departure from the rule. "
"Scored that way it meets every criterion of the rule (equivalence regions of 0.21 and 0.16 on the consecutive frame and 0.21 and 0.18 on the calibration frame, largest size-class departure 0.14 at 40 to 60 cm), although it fails under conventional BAL (intercept regions 0.26 and 0.27), and its RMSE of 1.263 {cmyr} lies within 0.3% of the refitted live-list candidate (1.261 {cmyr}). "
"The diameter coefficients of Table 4 therefore come from the original covariates, and only their calibration reflects the recomputed stand variables.")

# ---------------- 2.4.3 ----------------
SUB.append(('with ηd = c0 + c1ln(DBH)',
 'so the equation was respecified on the death response of a recovered sample, now 4,223 records carrying 877 deaths after the copied visits were removed, censored at the first thinning removal on each PSP installation (Section S3.4). The deployed coefficients were fitted to a 4,911-record precursor of that sample before duplicate visits were resolved, and refitting on the repaired sample changes no sign,',
 'so the equation was respecified on the death response of a recovered sample of 4,223 records carrying 877 deaths, censored at the first thinning removal on each PSP installation (Section S3.4). The deployed coefficients were fitted to a 4,911-record precursor of that sample before duplicate visits were resolved, and refitting on the final sample changes no sign,'))

# ---------------- 2.6 ----------------
SET['Competition is BAL = (1 − BA.perc) × BAPH (Eq. 7)'] = (
"Competition is BAL = (1 − BA.perc) × BAPH (Eq. 7), stand basal area allocated by each stem’s diameter percentile among the live stems of the plot-year, and heights advance by their own increments, HT(*t* + 1) = HT(*t*) + ΔHT (Eq. 8). "
"Because the simulator keeps a record for every stem of the initial list and lets its expansion factor decay with mortality, it takes BA.perc as the expansion-weighted share of the other live stems at least as large as the subject, which equals the fitting definition wherever expansion factors are equal within a plot. "
"That condition holds for every source except the FIA microplot records (102 of the 1,071 natural diameter records), and the weighted form keeps the fraction of stand basal area carried as BAL at 0.48 to 0.50 over 100 years (Section S3.3).")

SUB.append(('Given the limitations of the tree-level equation and of the mortality record',
 'and gated by the Stage 1 probability so the expected rate over the fitting record is unchanged',
 'and scaled by the Stage 1 probability so the expected rate over the fitting record is unchanged'))

SET['Projected over the 24 natural plot intervals, the gated rate'] = (
"Projected over the 24 natural plot intervals, the scaled rate underpredicts observed deaths, so the natural rate carries a level factor solved on those intervals, whereas the planted rate is left unscaled (Section S4.3). "
"Diameter growth of each tree stops at a ceiling of 90 cm (natural) or 69.7 cm (planted), the latter the largest QMD observed on a natural plot-year with at least five live stems, since no planted tree in the record exceeds 57 cm. "
"Both ceilings lie below diameters observed in koa, which reach 230 cm, so natural projections beyond about 60 years are conditional on them (Section S7.2). "
"Stem volume is V = BAPH × H~Q~ × 0.40 (Eq. 10), where H~Q~ is Eq. 2 evaluated at the QMD of the list.")

SUB.append(('The linked GY system was evaluated from first to last measurement',
 'Trajectories were rerun with the level factor solved without each plot’s installation, stand-level calibration from the first remeasurement interval was tested under the earlier system (Section S6.2), and general behavior',
 'Trajectories were rerun with the level factor solved without each plot’s installation, stand-level calibration from the first remeasurement interval was tested (Section S6.2), and general behavior'))

# ---------------- 3.1 ----------------
SUB.append(('The increment samples span rainfall',
 'Planted stands grew faster in diameter than natural stands, at a mean of 2.04 against 0.57 {cmyr} on the deposited frame.',
 'Planted stands grew faster in diameter than natural stands, at a mean of 2.02 against 0.58 {cmyr} on the calibration frame.'))

# ---------------- 3.2 ----------------
SUB.append(('Eq. 1 returned a conditional asymptote for all 339 plots',
 'and the 320 growth-model plots carry values of 0 to 813 (median 204).',
 'and the 320 mapped growth-model plots carry values of 0 to 813 (median 204), one of them at zero.'))
SUB.append(('The Kona random forest reached an out-of-bag R2 of 0.300',
 'With a local out-of-bag error of about 150 to 220 index units, the three BYI levels',
 'With a local out-of-bag error that runs from 78 to 419 index units across the mapped cells (median 159 on Hawaii Island; Fig. 2), the three BYI levels'))

# ---------------- 3.3.1 ----------------
SET['The height equation explains 86.2% of height variation'] = (
"The height equation explains 86.2% of height variation with random intercepts, 78.8% in the population-average form deployed in projection (n = 8,914, RMSE 2.39 m) and 79.8% under leave-one-installation-out cross-validation. "
"Its population-average predictions are equivalent to observed heights in mean bias, at −0.39 m predicted minus observed (90% installation-cluster interval −0.68 to −0.10), and in slope, at 0.93 (0.89 to 0.98) (Fig. 3f; Table S8). "
"Under the fitted coefficients a high site (BYI 450) carries an asymptotic height 11.3% (3.4 m) above a low site (BYI 100), although an installation-cluster bootstrap on the original covariates placed the BYI modifier a~1~ between −1.31 and 2.39, so the site effect on height is uncertain (Section S3.1). "
"With the crown-record covariates recomputed, the deployed crown vector explains 24.4% of HCB variation (n = 360), against 39.2% on the original covariates, where the mixed-effects crown fit had explained 61.1% and 40.7% at the conditional and population-average levels and 30.9% under cross-validation (Table S9).")

# ---------------- 3.3.2 ----------------
SET['The deployed increment equations (Table 4) explain 46.3%'] = (
"The deployed increment equations (Table 4) explain 46.3% of periodic diameter increment variation at the conditional level on the original frame and 75.6% of height increment variation with tree, installation and data-source intercepts. "
"Calibrated by origin on the calibration frames, the population-average forms reach {R2} of 0.381 for diameter (RMSE 1.26 {cmyr}) and 0.264 for height (RMSE 1.08 {myr}) on annual increment. "
"The site terms are weakly identified, since the ln(BYI) coefficient of height increment is 0.091, with a 95% installation-cluster bootstrap interval of −0.147 to 0.834 that spans zero, whereas the diameter coefficient of 0.305 (0.007 to 0.837 in a bootstrap on the original covariates) carries almost all of the site response of the system, and a live-list diameter refit halved it to 0.140 (−0.167 to 0.417) (Section S3.2). "
"At equal covariates the planted terms raise log increment in small trees and lower it above about 23 cm and 6 m (level shifts +0.410, P = 0.086, and +0.757, bootstrap interval 0.032 to 3.887), a crossover that the origin constants remove in the calibrated forms, where planted increment exceeds natural increment at every size (Fig. 3a, b). "
"The calibrated diameter form returns observed to predicted ratios of 0.99 in natural and 1.03 in planted records, but 0.88 on DOFAW, 1.27 on FIA and 1.38 on KMR PSP records, and under the calibrated height form trees above 15 m grow 1.24 to 1.36 times the prediction (Table S12; Section S3.2). "
"The calibrated planted height increment reaches the 2 {myr} cap on 15.9% of the planted records of the calibration frame and on no natural record, whereas 35.9% of planted records grew faster than 2 {myr}.")

SET['Within the Kulani installation, the only one holding both origins'] = (
"Within the Kulani installation, the only one holding both origins, the covariate-adjusted planted to natural ratio on the original frame was 1.36 (95% interval 0.98 to 1.76) for diameter and 0.77 (0.60 to 0.99) for height increment, and entering data source as a fixed effect reduced the diameter level shift to 0.26 (P = 0.31) (Table S11; Section S3.2). "
"On the calibration frame the calibrated diameter increment is close to observation on intervals of one to two years (observed to predicted 1.04) and three to five years (0.93), but it overpredicts the 32 intervals of 11 to 20 years about threefold (0.30) (Section S3.2).")

# ---------------- 3.3.3 ----------------
SUB.append(('The tree-level survival equation ordered deaths within plot intervals but could not',
 'In the earlier fit on the unrepaired intervals the response persisted',
 'In sensitivity fits on the original intervals the response persisted'))
SUB.append(('Magnitude given occurrence showed no detectable density response',
 'On the repaired recovered sample, Eq. 5 refitted expects',
 'On the recovered sample, Eq. 5 refitted expects'))

# ---------------- 3.3.4 ----------------
SUB.append(('The ingrowth expectation (Eq. 6) has d0 = 3.3838',
 ', within 0.06 standard errors of the earlier fit, and is truncated',
 ', and is truncated'))
SUB.append(('The ingrowth expectation (Eq. 6) has d0 = 3.3838',
 '(47.1 {tph} yr^−1^ on the deposited frame)',
 '(47.1 {tph} yr^−1^ on the original frame)'))

# ---------------- 3.4 ----------------
SET['On the 17 remeasured plots (Table S25; Fig. S5), projected cohort survival'] = (
"On the 17 remeasured plots (Table S25; Fig. S5), projected cohort survival exceeds observed by 0.040 (RMSE 0.167, r = 0.87), projected QMD falls 0.70 cm below observed (RMSE 2.09 cm) and projected basal area 0.96 {m2ha} below observed (RMSE 11.9 {m2ha}). "
"With 90% plot bootstrap intervals (5,000 resamples) and equivalence regions of ±25% of the observed mean fixed in advance, mean survival (+0.040, −0.023 to +0.109, against ±0.155) and mean QMD (−0.70 cm, −1.51 to +0.08, against ±6.09 cm) are equivalent across the 17 plots, as are their slopes (0.94 and 0.90). "
"Basal area is equivalent in the mean only when both origins are pooled (−0.96 {m2ha}, −5.46 to +3.93, against ±6.77), because the natural and planted errors offset, and its slope is not equivalent (0.88, 0.11 to 2.04).")

SET['Split by origin, mean QMD is equivalent in both'] = (
"Split by origin, mean QMD is equivalent in both (−0.28 cm natural, −0.93 cm planted), mean planted survival is equivalent (+0.030) whereas mean natural survival is not (+0.060 against a region of ±0.083), and basal area is equivalent in neither origin (+0.60 {m2ha} natural, −1.80 {m2ha} planted). "
"The natural basal area errors are large and offsetting, since Kulani 23 is projected at 28.0 against 41.5 {m2ha} observed and Waiakea 24 at 24.4 against 13.6 {m2ha}. "
"FIA plot 15-1-1-2628 burned in a ground fire recorded in 2018, and 81 of its 82 koa deaths carry the FIA fire cause code (Section S6.1). "
"There the system projects survival of 0.103 against 0.215 observed and a QMD 9.8 cm above observed while matching basal area (−0.11 {m2ha}). "
"With a minimum of 15 instead of 20 live koa records, two further FIA plots enter, which are the only natural units outside every fitting and calibration frame, and on them the system projects QMD 3.85 cm above and survival 0.181 below observation. "
"Monte Carlo coverage was not recomputed for these plots, and on a previous 23-unit validation set the 95% intervals contained the observed value on 21 of 23 units for QMD but on only 15 of 23 for cohort survival and basal area (Table S26), so the intervals understate predictive uncertainty for density and basal area, as expected from the error sources they omit.")

SET['Along trajectories (Fig. 5; Table S27), projected minus observed survival'] = (
"Along trajectories (Fig. 5; Table S27), projected minus observed survival on the four long natural plots runs from −0.09 to +0.09 across horizons, against +0.13 to +0.27 without the natural level factor, and QMD errors run from −1.6 to +1.2 cm, against −4.8 to −0.1 cm without it. "
"The level factor solved without each natural installation ranges from 2.36 to 3.03 against 2.54 pooled (Section S4.3). "
"The 52-year Kulani plantation, whose BYI of 25 is the lowest in the data, diverges with each remeasurement, and averaged over its three measurements at 36 to 52 years it is projected to hold more stems (survival error +0.30) and 25.2 {m2ha} more basal area than observed.")

# ---------------- 3.5 ----------------
SET['Table 5 and Fig. 4 give the 100-year projections'] = (
"Table 5 and Fig. 4 give the 100-year projections, with the full grid in Table S30. "
"Standing volume at age 40 runs from 106 to 197 {m3ha} in natural even-aged stands from the low to the high BYI level, QMD rises in all nine trajectories, and in the even-aged scenarios volume is ordered by BYI at every age to 100 years, whereas basal area ordering holds only to age 92 (natural) and 80 (planted). "
"Net MAI culminates at 37, 25 and 20 years on the low, medium and high natural levels and at 7 to 12 years in planted stands (Table S32). "
"Natural even-aged stands never exceed a stand density index of about 430 or a basal area of about 29 {m2ha}, whereas the three long natural DOFAW plots reached plot-year maxima of 760 to 880 in stand density index and DOFAW basal area reached 47.0 {m2ha} (Section S7.1).")

SET['Planted volume peaks at age 72, 87 and 98'] = (
"Planted projections beyond about age 18 lie outside the plantation record (Section 3.1), and beyond about age 40 planted volume is set by the 69.7 cm diameter ceiling rather than by the equations, since the largest planted tree approaches it by that age at every initial density (68.9 to 69.4 cm at BYI 264), so the later planted peak is not interpreted (Section S7.2). "
"The Monte Carlo intervals sit asymmetrically around the point projections, because re-solving the multipliers under each drawn vector removes most coefficient level uncertainty, and the natural QMD point lies at 0.31 to 0.42 of its interval (Section S5).")

# ---------------- 4.1 ----------------
SET['This study delivers the first linked individual-tree GY equations'] = (
"This study delivers the first linked individual-tree GY equations and stand projection system for *A. koa*, with an age-independent productivity index, BYI, that is mapped at 30 m and enters the height, crown and increment equations, with installation-level support that is moderate for diameter increment and weak for height growth and crown base. "
"The mapped surface separates forest from nonforest and indicates only coarse productivity differences, with demonstrated skill on Hawaii Island alone, and it can likely be refined with layers that represent the high microsite variation across the islands.")

SET['Koa mortality occurrence rose with stand density, whereas its magnitude'] = (
"Koa mortality occurrence rose with stand density, whereas its magnitude showed no detectable density response, which is why a three-stage structure is deployed, with a level calibrated for natural stands that remains open for plantations. "
"Volume is ordered by site at every age to 100 years, and stem numbers converge across initial densities. "
"Over years 11 to 100 the realized self-thinning slopes fall within the −1.2 to −2.2 band in seven of nine stand types, and the two exceptions are the low natural sites, at −1.02 in even-aged and −1.18 in uneven-aged stands. "
"Natural stands never exceed a stand density index of about 430, well below the 760 to 880 reached on the three long natural plots, and mean tree size does not fall with initial density (Leary, 1997), so the long-term projections are a provisional basis for planning until plantations are remeasured over longer intervals.")

# ---------------- 4.3 ----------------
SUB.append(('The conditional fit statistics sit at or above',
 'and the one within-installation comparison gives a planted diameter advantage of 1.36 against the implied 3.8, the constants are best read as network corrections that happen to align with origin. Under the earlier system, carrying their interval through the projection widened planted culmination to 7 to 32 years, and stand-level calibration from remeasurements of about five years or more is the principled remedy (Section 3.4).',
 'and the one within-installation comparison gives a planted diameter advantage of only 1.36 (Section 3.3.2), the constants are best read as network corrections that happen to align with origin. Stand-level calibration from remeasurements of about five years or more is the principled remedy (Section S6.2).'))
SUB.append(('Faster planted growth at small sizes is consistent',
 'and in the refitted height equation its term is positive but not distinguishable from zero where the earlier fit carried a negative sign.',
 'and in the height equation its term is positive but not distinguishable from zero.'))
SUB.append(('Faster planted growth at small sizes is consistent',
 'and none of the refits on that definition met the preregistered size criterion (Section S3.3).',
 'and none of the refits on that definition met the size criterion of the selection rule (Section S3.3).'))

SET['Three properties of the increment calibration limit'] = (
"Three properties of the increment calibration limit how far it can be pushed. "
"First, the site response is weakly identified, since the height increment site term has a bootstrap interval spanning zero, the diameter term of 0.30 carries nearly all of the site effect in the system, and below BYI 150 the natural increment records come from a single plot (Waiakea 24, BYI 93), so natural growth projected at the low BYI level rests on one installation. "
"Second, the simulator carries only koa, whereas the equations were fitted with all-species BAPH and BAL, which is immaterial for the single-species sources but lowers the natural diameter constant by 2.9% when koa-only covariates are imposed on the mixed DOFAW and FIA records. "
"Third, no increment candidate met every criterion of the selection rule, so the deployed height vector is the fallback of that rule and the diameter vector was retained by decision (Section 2.4.2). "
"The calibrated diameter increment also overpredicts the few intervals of 11 to 20 years about threefold, so growth over long projection steps is less certain than the short-interval fit suggests. "
"Consequently, a refit that removes the large-tree shortfall of both increments, scored against the recalibrated diameter vector on identical covariates, is the first task for the next release.")

# ---------------- 4.4 ----------------
SUB.append(('Mortality was the component furthest from observation',
 'Size-independent agents of this kind interrupt self-thinning, which offers one explanation for the shallow realized slope on the low natural site (−1.02 over years 11 to 100) compared with long-term European plots (Pretzsch and Biber, 2005; Pretzsch, 2006) and for the absence of an identifiable maximum stand density index (Section S7.2).',
 'The shallow realized slope on the low natural site (−1.02 over years 11 to 100), against the steeper slopes of long-term European plots (Pretzsch and Biber, 2005; Pretzsch, 2006), most likely reflects the mortality level, since the deployed rate realizes one fifth to one third of the observed natural rate and holds natural stands near half of the observed stand density index (Section 3.3.3). Episodic agents such as fire and frost also interrupt self-thinning in real stands, but the deterministic simulator does not carry them, and no maximum stand density index is identifiable from these data (Section S7.2).'))
SUB.append(('The tree-level survival equation was restricted to allocating',
 'and the only natural units outside the calibration, two FIA plots admitted at a 15-record minimum, are projected worse by the repaired system than by the earlier one.',
 'and on the only natural units outside the calibration, two FIA plots admitted at a 15-record minimum, the system overpredicts QMD by 3.9 cm.'))

# ---------------- 4.5 ----------------
SET['BYI is a conditional asymptote far beyond observed biomass'] = (
"BYI is a conditional asymptote far beyond observed biomass, so it indexes productivity and does not bound accumulated biomass. "
"Planted rows beyond about age 18 or below BYI 158 describe the implications of the calibrated equations and remain untested against plantation observations, since the only older planting, Kulani 12 at BYI 25, is projected at 43.8 against 13.6 {m2ha} of basal area, and because planted mortality is uncalibrated, planted volume and carbon are more likely overstated than understated. "
"The simulated thinning response is modest and temporary because the equations carry no release response beyond reduced competition, and since release thinning increased koa crop tree growth in dense young stands (Idol et al., 2017) but not in a phosphorus-limited forest (Scowcroft et al., 2007), it is likely conservative on productive sites.")

SUB.append(('For management, net MAI culminates early in planted stands',
 'On sites with BYI above 250, projected stemwood carbon at age 40 is roughly 38 to 118 {MgCha} at a basic density',
 'On sites with BYI above 250, projected stemwood carbon in natural even-aged stands at age 40 is roughly 38 to 47 {MgCha} at a basic density'))

# ---------------- 5 ----------------
SUB.append(('This study developed five individual-tree GY equations for A. koa',
 'no preregistered increment candidate met every selection criterion',
 'no increment candidate met every criterion of a selection rule fixed before fitting'))
SUB.append(('Net MAI culminates at 7 to 12 years in planted stands and at 37, 25 and 20 years',
 'Net MAI culminates at 7 to 12 years in planted stands and at 37, 25 and 20 years on the low, medium and high natural levels, and at age 40 projected even-aged volumes on the medium and high levels span 160 to 490 {m3ha}, approximately 38 to 118 {MgCha} of stemwood carbon.',
 'Net MAI culminates at 37, 25 and 20 years on the low, medium and high natural levels. At age 40, projected volume in natural even-aged stands on the medium and high levels is 160 to 197 {m3ha}, or about 38 to 47 {MgCha} of stemwood carbon, whereas planted yields at that age lie beyond the plantation record.'))

# ---------------- Data availability ----------------
SET['The assembled tree-level dataset (AK_TREE.csv'] = (
"The assembled tree-level dataset (AK_TREE.csv, AK_PLT.csv, AK_PLT_GEO.csv), crown subset (AK_HCB.csv), survival table (AK_SURV.csv), plot-level origin and thinning table, BYI raster (BYI_all.tif), R and Python prediction and projection code (HiGy.R, koa_projector.py), deployed constants (v103_constants.json), number registry (numbers_v103.json) and the scripts that produced every table and figure (v103_rebuild_20260930.zip, engine_v103.zip) are archived in the data and code deposit for this study (Weiskittel et al., 2026), concept DOI https://doi.org/10.5281/zenodo.21081014. "
"Version 1.9.5 of the deposit (https://doi.org/10.5281/zenodo.22997704), whose tree, plot, crown and survival tables carry the recomputed stand covariates used here, is the version of record for the results reported here.")

SUB.append(('[dataset] Weiskittel, A.R., Sprecher, I.', 'Version 1.9.3.', 'Version 1.9.5.'))

# ---------------- Figure captions ----------------
SUB.append(('Fig. 1. Koa (Acacia koa) permanent plot network',
 'with the number of mapped plot locations in parentheses (320 in all)',
 'with the number of mapped plot locations in parentheses (320 in all, FIA plots counted by subplot)'))
SUB.append(('Fig. 1. Koa (Acacia koa) permanent plot network',
 'The two Kualoa plots on Oʻahu have no recorded coordinates and are not shown.',
 'The six Kualoa plots (two installations) on Oʻahu have no recorded coordinates and are not shown.'))
SUB.append(('Fig. 2. Biomass Yield Index (BYI, index units',
 'Fig. 2. Biomass Yield Index (BYI, index units, where one unit corresponds to 4 {Mgha} of aboveground biomass) predicted',
 '**Fig. 2.** Biomass Yield Index (BYI, index units; Section S2.1) predicted'))
SUB.append(('Fig. 2. Biomass Yield Index (BYI, index units',
 'and runs from 78 on the least productive substrates to 419 on the most productive sites,',
 'and runs from 78 on the least productive substrates to 419 on the most productive sites (median 159 on Hawaii Island),'))
SUB.append(('Fig. 4. Projected koa stand development',
 'and dashed lines the largest QMD (69.7 cm) observed on a natural plot-year with at least five live stems and the largest deposited plot-year basal area (76.06 {m2ha}), a doubled Kulani 23 record that rebuilds to 38.2 {m2ha} (Section S1.3).',
 'and dashed lines the largest QMD (69.7 cm) observed on a natural plot-year with at least five live stems and the largest basal area on a natural DOFAW plot-year (47.0 {m2ha}, Laupahoehoe 41 in 2001). Single FIA subplots reach higher basal area at the per-subplot expansion (Section S1.3).'))
SUB.append(('Fig. 5. Long-term trajectory validation',
 'for the repaired system (filled) and the earlier system (open), natural green and planted red, with horizon means and 95% plot bootstrap intervals (diamonds).',
 'natural green and planted red, with horizon means and 95% plot bootstrap intervals (diamonds).'))
SUB.append(('Fig. 5. Long-term trajectory validation',
 'and the points near +0.99 in (d) are PSP 105 to 108 visits of 2009 that the source data code as entirely dead.',
 'and the crosses are the PSP 105 to 108 visits of 2009 that the source data code as entirely dead, which are excluded from the horizon means.'))

# ---------------- Table captions and notes ----------------
SET['Table 1. Data sources in the koa permanent plot network'] = (
"**Table 1.** Data sources in the koa permanent plot network, with installations, live-tree records, measurement period, stand origin, island, record-weighted mean Biomass Yield Index (BYI, index units) and median remeasurement interval (Med. int.) of each source. "
"DOFAW is the Hawaii Division of Forestry and Wildlife, PSP the plantation permanent sample plots, FIA the Forest Inventory and Analysis program, KMR the Keauhou–Mauna Loa Restoration program, whose CAR and PSP rows are separate installations under one landowner, and Kap the Kapāpala Forest Reserve. "
"Installations are counted within source, and the 158 installations hold 343 plots. "
"Mean BYI is taken over the 8,941 live records with a BYI value, so the total row is the record-weighted mean (record median 387, plot median 203 over 311 plots), and Kualoa and 112 FIA records carry no value. "
"Median intervals are taken over the consecutive diameter increment intervals, and n/a marks a source whose plots were each measured once. Per-source statistics are in Table S2.")

SET['Table 2. Summary statistics for tree and stand variables'] = (
"**Table 2.** Summary statistics for tree and stand variables in the koa live-tree modeling sample, namely diameter at breast height (DBH), height, crown ratio, stand basal area (BAPH, computed from the live stems of all species), basal area in larger trees (BAL, the live-list percentile competition index of Eq. 7) and annual diameter (ΔDBH) and height (ΔHT) increment. "
"The sample holds live stems with DBH > 0, so the DBH minimum of 0.0 reflects rounding. "
"BAPH and BAL exclude the 111 Kualoa records, whose live stems carry no expansion factor, and stand basal area above 100 {m2ha} occurs only on five single FIA subplots at the per-subplot expansion. "
"Increments are annualized over each remeasurement interval of the calibration frames (Section 2.4.2; Table S33), which keep annual increments above zero and below 10 {cmyr} or 10 {myr} and exclude intervals spanning a thinning removal, so the ΔDBH minimum of 0.00 is a single increment below 0.005 {cmyr}.")

SUB.append(('Notes. All estimates differ from zero at P < 0.001',
 'An installation-cluster bootstrap of the earlier fit on the deposited covariates, in which 1,205 of 2,000 resamples converged,',
 'An installation-cluster bootstrap on the original covariates, in which 1,205 of 2,000 resamples converged,'))
SUB.append(('Notes. All estimates differ from zero at P < 0.001',
 'and it was not repeated on the repaired frame (Section S3.1).',
 'and it was not repeated on the recomputed covariates (Section S3.1).'))
SUB.append(('Table 3. Parameter estimates for the Chapman–Richards height model',
 'with the repaired stand covariates.',
 'with the recomputed stand covariates.'))
SUB.append(('Table 4. Parameter estimates for the log-linear diameter',
 'The ΔDBH vector is the published fit to 4,790 consecutive intervals on the deposited covariates, deployed unchanged, and the ΔHT vector is the live-list fit to 4,033 consecutive and first-to-last intervals on the repaired covariates with a tree intercept.',
 'The ΔDBH vector is the fit to 4,790 consecutive intervals on the original covariates, deployed unchanged (Section 2.4.2), and the ΔHT vector is the live-list fit to 4,033 consecutive and first-to-last intervals on the recomputed covariates with a tree intercept.'))
SUB.append(('Table 4. Parameter estimates for the log-linear diameter',
 'and those of the earlier ΔDBH bootstrap 2.1 to 4.5 times (Table S13).',
 'and those of the ΔDBH bootstrap on the original covariates 2.1 to 4.5 times (Table S13).'))

SET['Table 5. Projected koa stand development for even-aged natural'] = (
"**Table 5.** Projected koa stand development for even-aged natural, even-aged planted and uneven-aged natural stands with annual ingrowth at three Biomass Yield Index (BYI, index units) levels at ages 40 and 100 yr, from the tree-list simulator, with 95% Monte Carlo intervals (installations resampled within data sources) in parentheses for quadratic mean diameter (QMD) and standing stem volume. "
"Even-aged lists start with 500 natural or 1,200 planted {sph}, at a QMD of 9.6 and 7.2 cm at projection year 1. "
"Every planted row lies beyond the plantation record, which holds stands younger than about 18 years on BYI 158 to 561, so the planted rows describe the calibrated equations rather than observed plantation growth, and their origin constants come almost entirely from the plantation permanent sample plot and Keauhou–Mauna Loa Restoration networks. "
"The intervals carry parameter and sampling uncertainty only, and their coverage was not recomputed for this system. The full grid at ages 20, 40, 60 and 100 yr is in Table S30.")

SUB.append(('Notes. Intervals are the 2.5th and 97.5th percentiles of 500 replicates',
 'No point estimate exceeds 56.5 {m2ha} of basal area,',
 'No tabulated point estimate exceeds 56.5 {m2ha} of basal area,'))

# ---------------- round 2 (red team 5 and stress test 2), applied after SET and SUB ----------------
POST = [
 ('The linked GY system was evaluated from first to last measurement',
  'Trajectories were rerun with the level factor solved without each plot’s installation, stand-level calibration from the first remeasurement interval was tested (Section S6.2), and general behavior',
  'The natural level factor was also solved with each natural installation held out (Section S4.3), stand-level calibration from the first remeasurement interval was tested on the original covariates (Section S6.2), and general behavior'),
 ('Table 5. Projected koa stand development', 'and their coverage was not recomputed for this system.', 'and their coverage was not checked on the 17 benchmark plots.'),
 ('Notes. Intervals are the 2.5th and 97.5th percentiles of 500 replicates',
  'Their coverage was not recomputed (earlier system, 15 of 23 validation units for survival and basal area).',
  'On a 23-unit set scored before the stand covariates were recomputed, the intervals contained 15 of 23 observed values for survival and basal area (Table S26).'),
 ('Split by origin, mean QMD is equivalent in both',
  'Monte Carlo coverage was not recomputed for these plots, and on a previous 23-unit validation set the 95% intervals contained',
  'Monte Carlo coverage was not checked on these plots, and on a 23-unit set scored before the stand covariates were recomputed, the 95% intervals contained'),
 ('The FVS-HI variant (HiGy.R,', 'and still carries an earlier survival equation as a rate', 'and still carries a single-stage survival equation as a rate'),
 ('Table 5 and Fig. 4 give the 100-year projections',
  'whereas the three long natural DOFAW plots reached plot-year maxima of 760 to 880 in stand density index and DOFAW basal area reached 47.0 {m2ha} (Section S7.1).',
  'whereas three of the four long natural DOFAW plots (Kulani 23, Laupahoehoe 41 and Waikamoi 25) reached plot-year maxima of 762 to 880 in stand density index and DOFAW basal area reached 47.0 {m2ha} (Section S7.1). Uneven-aged natural stands, which carry ingrowth, reach 50.4 {m2ha} by age 100.'),
 ('Koa mortality occurrence rose with stand density, whereas its magnitude',
  'well below the 760 to 880 reached on the three long natural plots',
  'well below the 762 to 880 reached on three of the four long natural plots'),
 ('The deployed increment equations (Table 4) explain 46.3%',
  'whereas 35.9% of planted records grew faster than 2 {myr}.',
  'whereas 35.9% of planted records grew at least 2 {myr}.'),
 ('The goal of this analysis was to synthesize',
  '(1) derive and map a spatially explicit productivity index (BYI); (2) develop and cross-validate five individual-tree component equations (static height, height to crown base, diameter increment, height increment, and survival); (3) link',
  '(1) derive and map a spatially explicit productivity index (BYI), (2) develop and cross-validate five individual-tree component equations (static height, height to crown base, diameter increment, height increment and survival), (3) link'),
 ('The goal of this analysis was to synthesize', 'against remeasured plots; and (4)', 'against remeasured plots, and (4)'),
 ('Table 1. Data sources in the koa permanent plot network', 'plot median 203 over 311 plots', 'plot median 203 over the 311 plots with live records and a BYI value'),
 ('Fig. 6. Behavior of the koa system', 'mark the largest trees reaching the 69.7 cm', 'mark the largest trees approaching the 69.7 cm'),
 ('Acacia koa A. Gray (koa) is Hawaii’s most valuable', 'and on the two natural plots outside every fitting frame', 'and on the only two natural plots outside every fitting frame'),
 ('Fig. 4. Projected koa stand development', 'The gray field marks ages beyond the 52-yr longest record,',
  'The gray field marks ages beyond the longest record, 52 yr in natural stands and about 18 yr in planted stands, where only the Kulani plantation is older,'),
 ('Fig. 1. Koa (Acacia koa) permanent plot network',
  'Positions are offset at random within 500 m, and exact coordinates are deposited only for the Kahikinui plots, whose identifiers encode them.',
  'Positions are offset at random within 500 m, and no plot coordinates are deposited.'),
 ('Pinheiro, J., Bates, D., R Core Team, 2023.', 'Pinheiro, J., Bates, D., R Core Team, 2023. nlme: Linear and Nonlinear Mixed Effects Models. R package version 3.1-163.', 'Pinheiro, J., Bates, D., R Core Team, 2026. nlme: Linear and Nonlinear Mixed Effects Models. R package version 3.1-170.'),
 ('The height and crown equations were cross-validated', 'nlme (Pinheiro et al., 2023)', 'nlme v3.1-170 (Pinheiro et al., 2026)'),
]
