================================================================================
README — Near-Surface pCO2 Study | BASS Field Campaign, North Sea, July 2024
================================================================================
Authors  : Edgar Fernando Cortés-Espinoza
Institute: ICBM, Carl von Ossietzky Universität Oldenburg, Germany
Contact  : edgar.fernando.cortes.espinoza@uni-oldenburg.de
================================================================================

OVERVIEW
--------
This MATLAB code reproduces Table 1, Figures 2-4 and the flux-discrepancy
scaling (D%) of:

  Cortés-Espinoza et al., "Near-Surface Atmospheric CO2 Enrichment Above
  Sea-Surface Slicks: Implications for Air-Sea CO2 Flux Estimates",
  submitted to Geophysical Research Letters.

Two non-intrusive platforms were deployed simultaneously near Helgoland
(North Sea) during the BASS campaign (July 2024):
  SNIFFLE            : Air100 (100 cm above) and Sea100 (100 cm below)
  GLAUCUS ATLANTICUS : NSA20 (20 cm above) and NSL20 (20 cm below)

--------------------------------------------------------------------------------
WHAT CHANGED AFTER REVIEW MR2 (and why)
--------------------------------------------------------------------------------
Reviewers found that the fluxes of Table 1 could not be reproduced from the
dpCO2 values and the k and K0 stated in the text. The causes were:

 1. Wrong constant. The flux scripts used k = 1.0e-4 m s-1 (= 36 cm h-1)
    with K0 = 33, i.e. f = k*K0 = 0.285 mmol m-2 d-1 uatm-1, whereas
    Methods 2.3 states k = 15.7 cm h-1 (f = 0.124). In one later version the
    value 15.7 had been typed into K0 instead of k.
 2. dpCO2 and flux from different data. The dpCO2 rows were differences of
    daily means of ALL samples; the fluxes were means over another subset
    (only rows with an Air100 value).
 3. Wrong Sea100 sensor in the fluxes. In those rows Sea100 was in practice
    the GLAUCUS 100-cm inlet (SNIFFLE Sea100 was present in 0% of them),
    while the Sea100 row of Table 1 pooled SNIFFLE and GLAUCUS.
 4. Gap filling. The merge used interp1('nearest') WITHOUT tolerance, so
    every gap was filled with a repeated value. This produced the flat
    segments seen in Figure 2 (e.g. NSA/NSL/Sea 27 Jul 10:03-10:20 and
    16:41-17:08, GLAUCUS 29 Jul 09:53-10:22) and ~3 h per day of Air100
    values that were never measured. These values entered the means.
 5. Bias script. Fig4_Bias_Estimation_Global_v2 computed its own fluxes
    (k = 36 cm h-1) on the merged rows, so D% (144/43/16%) did not follow
    from Table 1.

Now:
 - ALL constants are in ONE file, BASS_pCO2_Settings.m
   (k = 15.7 cm h-1, K0 = 33 mol m-3 atm-1 -> f = 0.1243, as in Methods 2.3).
 - Table1_Recalc.m computes pCO2, dpCO2 and fluxes ONCE from the raw
   platform files; Figures 3 and 4 and D% use its output R. Therefore, in
   every column of Table 1:
        Sea100 - Air100 = dpCO2 (meter-scale)
        NSL20  - NSA20  = dpCO2 (near-surface)
        F = 0.1243 x dpCO2     and   SD(F) = 0.1243 x SD(dpCO2)
   The script prints a check of these identities.
 - The merge uses a 60-s tolerance and no gap filling.

--------------------------------------------------------------------------------
METHOD IMPLEMENTED (Table1_Recalc.m)
--------------------------------------------------------------------------------
 1. Raw data only. Duplicate SNIFFLE time stamps -> median.
 2. Each level is averaged into 1.5-min bins (Methods 2.2); a bin is kept
    if it holds >= 50% of the expected samples (GLAUCUS 1 Hz, SNIFFLE 0.5 Hz).
 3. Near-surface : dpCO2 = NSL20 - NSA20 in every bin where both exist.
 4. Meter-scale  : dpCO2 = Sea100 - Air100. SNIFFLE measures air and water
    ALTERNATELY with the same detector (~2.5 min air every ~7-17 min of
    water), which is why Air100 looks intermittent in Figure 2. Air100 is
    linearly interpolated in time to each Sea100 bin; a bin is used only if
    an air measurement lies within 30 min. Because both values come from
    one detector, its calibration offset cancels in dpCO2.
 5. Table pCO2 means are taken over exactly the bins used for dpCO2
    (Air100 SD = SD of the measured air bins).
 6. F = k * K0 * dpCO2 per bin (Wanninkhof, 2014); daily F = mean of bins.
    Units: k [m s-1] * K0 [mol m-3 atm-1] * dpCO2 [atm] = mol m-2 s-1,
    converted to mmol m-2 d-1.
 7. SE of daily dpCO2 = SD / sqrt(n_eff), n_eff = n(1 - r1)/(1 + r1)
    (lag-1 autocorrelation of the binned series; Methods 2.2).
 8. D% = |mean_slick(F_NS - F_MS)| / |mean_slick(F_NS)| x 100, scaled by
    slick coverage 11% (open ocean) and 30% (coastal) (Romano, 1996).
    D% does not depend on k or K0.

Sign convention: dpCO2 = pCO2(water) - pCO2(air); positive = sea-to-air.
Column names: m = above the sea surface (air), p = below (water),
e.g. pCO2_m20_G = NSA20, pCO2_p20_G = NSL20, pCO2_m100_S = Air100,
pCO2_p100_S = Sea100 (SNIFFLE), pCO2_p100_G = 100 cm below (GLAUCUS).

--------------------------------------------------------------------------------
RESULT (default settings: Sea100 = SNIFFLE, k = 15.7 cm h-1, K0 = 33)
--------------------------------------------------------------------------------
                       18 Jul        19 Jul        27 Jul        29 Jul
 pCO2 [uatm] (mean ± SD)
  Air 100 cm       411.5 ± 2.9   419.1 ± 3.3   411.7 ± 1.4   408.0 ± 0.3
  NSA 20 cm        413.4 ± 3.9   420.5 ± 5.0   524.8 ± 17.8  518.3 ± 19.7
  NSL 20 cm        441.5 ± 6.8   403.9 ± 4.6   446.5 ± 17.8  420.7 ± 15.6
  Sea 100 cm       471.0 ± 14.1  400.3 ± 5.2   424.3 ± 16.4  407.2 ± 7.3
 dpCO2 [uatm] (mean ± SE, n_eff)
  Meter-scale       59.6 ± 8.6   -18.8 ± 4.5    12.5 ± 14.9   -0.8 ± 4.3
  Near-surface      28.1 ± 1.3   -16.6 ± 0.5   -78.3 ± 0.7   -97.6 ± 7.2
  Approach gap      31.5           2.2           90.8          96.8
 CO2 flux [mmol m-2 d-1] (mean ± SD)
  Meter-scale        7.4 ± 1.8    -2.3 ± 0.9     1.6 ± 1.9    -0.1 ± 0.9
  Near-surface       3.5 ± 0.5    -2.1 ± 0.3    -9.7 ± 0.5   -12.1 ± 1.7
  Approach gap       3.9           0.3          11.3          12.0
 D% slick days = 107%  -> open ocean 12%, coastal 32%

 Sensitivity (BASS_pCO2_Settings: S.sea100 = 'glaucus', GLAUCUS 100 cm):
  Sea 100 cm       422.3 ± 3.4   410.5 ± 4.7   456.1 ± 10.7  441.2 ± 7.9
  dpCO2 meter-scale 11.2          -8.3          44.2          33.2
  F meter-scale      1.4 ± 0.4    -1.0 ± 0.7     5.5 ± 1.2     4.1 ± 1.0
  D% slick days = 144%  -> open ocean 16%, coastal 43%

 NOTE: SNIFFLE and GLAUCUS disagree at 100 cm by -38 to +48 uatm when
 measuring simultaneously (day-specific offsets), so the meter-scale result
 depends on the sensor chosen for Sea100. With SNIFFLE, meter-scale dpCO2
 on 29 Jul (-0.8 ± 4.3 uatm) is not different from zero. A side-by-side
 intercalibration of both platforms is needed (Methods 2.2, Section 4.4).
 (Values computed with an identical Python implementation; rerun the
 MATLAB code to confirm before publication.)

--------------------------------------------------------------------------------
FILES
--------------------------------------------------------------------------------
  NearSurface_pCO2_Study.m      MAIN SCRIPT (run this)
  BASS_pCO2_Settings.m          all constants and processing choices
  Table1_Recalc.m               Table 1 + consistency checks -> Table1_recalculated.csv
  Fig1abcd_TimeSeries_v1.m      Figure 2 a-d   (time series, times in UTC)
  Fig2_DailyProfiles_v1.m       Figure 3 a-b   (daily profiles = Table 1 values)
  Fig1e_MeanDifferenceProfile_NonSlick_vs_Slick_v1.m
                                Figure 3 c     (slick - non-slick, unpaired days)
  Fig3_CO2Flux_v1.m             Figure 4       (fluxes = Table 1 bins)
  Fig4_Bias_Estimation_Global_v2.m
                                Section 3.4    (D% and coverage scaling)
  MarineCarbonExplorer.m        interactive browser of pCO2_GlauSniff.xlsx
                                (not used for published numbers)

  Glaucus_pCO2_DataBase_v2.xlsx GLAUCUS ATLANTICUS data (Time, pCO2_m20_G,
                                pCO2_p20_G, pCO2_p50_G, pCO2_p80_G, pCO2_p100_G; uatm)
  Sniffle_pCO2_DataBase_v2.xlsx SNIFFLE data (Time, pCO2_p100_S, pCO2_m100_S; uatm)
  pCO2_GlauSniff.xlsx           merged table written by the main script
                                (60-s tolerance, no gap filling); used only
                                for Figure 2 and the explorer
  BASS2024_MarineCarbon_DATA.xlsx
                                TEMPLATE WITH SIMULATED EXAMPLE VALUES
                                ("Example simulated data"). NOT measured data;
                                not used by any script of this study.

--------------------------------------------------------------------------------
REQUIREMENTS AND HOW TO RUN
--------------------------------------------------------------------------------
MATLAB R2021a or later, core MATLAB only (no toolboxes).
Put all files in one folder and run:

     >> NearSurface_pCO2_Study

To change a constant (e.g. k from the SNIFFLE chamber, or K0 from measured
T and S), edit BASS_pCO2_Settings.m only:
     S.k_cmh = <value>;                 % cm h-1
     S.K0 = []; S.T_C = <T>; S.Sal = <S>;   % K0 from Weiss (1974)
Absolute fluxes scale linearly with k*K0; dpCO2, signs, flux ratios and D%
do not change.

--------------------------------------------------------------------------------
OPEN ITEMS (cannot be resolved from these files)
--------------------------------------------------------------------------------
 - k = 15.7 cm h-1 is high for U10 < 4 m s-1; confirm with the SNIFFLE
   floating-chamber data (~4 cm h-1 expected).
 - K0 = 33 corresponds to ~22 degC; with T ~ 17 degC and S ~ 32,
   Weiss (1974) gives ~37.6. Use the measured T and S.
 - Sensor uncertainties (S.u_sniffle, S.u_glaucus) for U = 2*sqrt(u1^2+u2^2+s^2).
 - Confirm that both platforms log in UTC.

--------------------------------------------------------------------------------
REFERENCES
--------------------------------------------------------------------------------
Romano, J.-C. (1996), Deep-Sea Res. I, 43(4), 411-423.
Wanninkhof, R. (2014), Limnol. Oceanogr. Methods, 12(6), 351-362.
Weiss, R. F. (1974), Mar. Chem., 2(3), 203-215.
Ribas-Ribas, M., Kilcher, L. F., & Wurl, O. (2018), Elementa, 6, 14.
Wurl, O., et al. (2024), J. Atmos. Oceanic Technol., 41(12), 1197-1211.
================================================================================
