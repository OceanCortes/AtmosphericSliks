================================================================================
README — Near-Surface pCO2 Study | BASS Field Campaign, North Sea, July 2024
================================================================================
Authors : Edgar Fernando Cortés-Espinoza
Institute: ICBM, Carl von Ossietzky Universität Oldenburg, Germany
Contact  : edgar.fernando.cortes.espinoza@uni-oldenburg.de
================================================================================

OVERVIEW
--------
This MATLAB code reproduces the analysis and figures presented in:

  Cortés-Espinoza et al. (2025), "Near-Surface pCO2 Gradients Reveal
  Atmospheric Slick Formation", submitted in Geophysical Research Letters.

The code merges near-surface pCO2 measurements from two non-intrusive
platforms — GLAUCUS ATLANTICUS and SNIFFLE — deployed simultaneously in the
North Sea near Helgoland, Germany, during July 2024 as part of the
Biogeochemical Processes and Air-Sea Exchange in the Sea-Surface Microlayer
(BASS) field campaign. It then produces all figures reported in the manuscript.

--------------------------------------------------------------------------------
REQUIREMENTS
--------------------------------------------------------------------------------
Software : MATLAB R2021a or later (tested on R2023b)
Toolboxes: No additional toolboxes required beyond core MATLAB
           (Statistics and Machine Learning Toolbox recommended but not required)

--------------------------------------------------------------------------------
FILE STRUCTURE
--------------------------------------------------------------------------------

  NearSurface_pCO2_Study/
  │
  ├── NearSurface_pCO2_Study.m                      ← MAIN SCRIPT (run this)
  │
  ├── Functions/
  │   ├── Fig1abcd_TimeSeries_v1.m                  ← Figure 2a-d
  │   ├── Fig1e_MeanDifferenceProfile_NonSlick_      ← Figure 2e
  │   │       vs_Slick_v1.m
  │   ├── Fig2_DailyProfiles_v1.m                   ← Figure 3
  │   └── Fig3_CO2Flux_v1.m                         ← Figure 4
  │
  ├── Data/
      ├── Glaucus_pCO2_DataBase_v2.xlsx             ← GLAUCUS ATLANTICUS data
      └── Sniffle_pCO2_DataBase_v2.xlsx             ← SNIFFLE buoy data
  


--------------------------------------------------------------------------------
INPUT DATA FILES
--------------------------------------------------------------------------------

1. Glaucus_pCO2_DataBase_v2.xlsx
   Platform : GLAUCUS ATLANTICUS
   Variables:
     Time        — datetime of measurement
     pCO2_m20_G  — pCO2 at Near-Surface Atmosphere, NSA (−20 cm above surface)
     pCO2_p20_G  — pCO2 at Near-Surface Layer, NSL (+20 cm below surface)
     pCO2_p100_G — pCO2 at Ocean reference depth (+100 cm below surface)
   Units: µatm

2. Sniffle_pCO2_DataBase_v2.xlsx
   Platform : SNIFFLE
   Variables:
     Time         — datetime of measurement
     pCO2_m100_S  — pCO2 at Atmosphere reference height (−100 cm above surface)
     pCO2_p100_S  — pCO2 at Ocean reference depth (+100 cm below surface)
   Units: µatm
   Note: Sniffle data may contain duplicate timestamps, which are resolved
         by median aggregation in the main script before merging.

   Sign oceanographic convention: negative values = above sea surface (atmosphere side)
                    positive values = below sea surface (ocean side)

--------------------------------------------------------------------------------
HOW THE CODE WORKS — STEP BY STEP
--------------------------------------------------------------------------------

STEP 1 — Run NearSurface_pCO2_Study.m
   This is the only file you need to run. All functions are called
   automatically from within this script.

STEP 2 — Data loading and cleaning
   - Reads both Excel files into MATLAB tables (Ts for Sniffle, Tg for Glaucus)
   - Converts Time columns to MATLAB datetime format
   - Resolves duplicate Sniffle timestamps using median aggregation
     (required for interpolation to work correctly)

STEP 3 — Merging onto a common time vector
   - Builds a master time vector as the union of both platforms' timestamps
   - Maps each platform's pCO2 variables onto the master time vector using
     nearest-neighbour interpolation (tolerance: 60 seconds)
   - Produces a single merged table T with five pCO2 columns:

       T.pCO2_ATM   — Atmosphere at 100 cm   (from Sniffle)
       T.pCO2_OCN_S — Ocean at 100 cm        (from Sniffle)
       T.pCO2_NSA   — Near-Surface Atm 20 cm (from Glaucus)
       T.pCO2_NSL   — Near-Surface Layer 20cm(from Glaucus)
       T.pCO2_OCN_G — Ocean at 100 cm        (from Glaucus)

   - Saves merged data to: pCO2_GlauSniff.xlsx (Sheet: pCO2_merged)

STEP 4 — Global figure formatting
   - Sets Times New Roman font (size 12) and consistent style for all figures
     to match journal requirements (Geophysical Research Letters, AGU)

STEP 5 — Figure generation (four functions called sequentially)
   See Functions section below for details.

--------------------------------------------------------------------------------
FUNCTIONS
--------------------------------------------------------------------------------

1. Fig1abcd_TimeSeries_v1.m
   Produces : Figure 2, panels (a), (b), (c), (d) of the manuscript
   Input    : Merged table T; four sampling dates
                Non-slick: 18 July 2024, 19 July 2024
                Slick    : 27 July 2024, 29 July 2024
   Output   : Time series of pCO2 at all four depths for each day,
              illustrating the persistent NSA pCO2 elevation during
              Slick Scenarios (Atmospheric Slick)

2. Fig1e_MeanDifferenceProfile_NonSlick_vs_Slick_v1.m
   Produces : Figure 2, panel (e) of the manuscript
   Input    : Merged table T; arrays of Non-slick and Slick dates
   Output   : Mean pCO2 difference between Slick and Non-slick Scenarios
              at each depth, with propagated standard deviation error bars
              (SD∆ = sqrt(SD²_Slick + SD²_NonSlick))

3. Fig2_DailyProfiles_v1.m
   Produces : Figure 3 of the manuscript
   Input    : Merged table T; four sampling dates
   Output   : Vertical pCO2 profiles (mean ± 1 SD) for Non-slick and
              Slick Scenarios, showing the near-surface atmospheric
              stratification under Slick Scenarios

4. Fig3_CO2Flux_v1.m
   Produces : Figure 4 of the manuscript
   Input    : Merged table T (all dates used)
   Output   : CO2 flux time series comparing the Meter-scale (Air-Sea)
              and Near-surface (NSA-NSL) approaches under both scenarios.
              Fluxes computed as F = k · K0 · ΔpCO2 following
              Wanninkhof (2014), with k = 1.0×10⁻⁴ m s⁻¹ and
              K0 = 33 mol m⁻³ atm⁻¹ (Weiss, 1974)

--------------------------------------------------------------------------------
HOW TO RUN
--------------------------------------------------------------------------------

1. Place all files in the same folder (or add Functions/ to MATLAB path)
2. Open MATLAB and navigate to the folder
3. Run the main script:

     >> NearSurface_pCO2_Study

4. Output figures will appear in MATLAB figure windows
5. Merged data will be saved as: pCO2_GlauSniff.xlsx


--------------------------------------------------------------------------------
OUTPUT FILES GENERATED
--------------------------------------------------------------------------------

  pCO2_GlauSniff.xlsx   — Merged pCO2 dataset (both platforms, common time
                           vector), Sheet: pCO2_merged. This file is the
                           basis for all figures and Table I in the manuscript.

--------------------------------------------------------------------------------
SAMPLING DATES AND SCENARIOS
--------------------------------------------------------------------------------

  Date          Scenario    Wind conditions
  ----------    ----------  ------------------------------------------
  18 July 2024  Non-slick   Higher winds, capillary waves, well-mixed
  19 July 2024  Non-slick   Higher winds, capillary waves, well-mixed
  27 July 2024  Slick       Calm (U10 < 4 m s⁻¹), mirror-like surface
  29 July 2024  Slick       Calm (U10 < 4 m s⁻¹), mirror-like surface

--------------------------------------------------------------------------------
REFERENCES
--------------------------------------------------------------------------------

Wanninkhof, R. (2014), Relationship between wind speed and gas exchange
  over the ocean revisited. Limnology and Oceanography: Methods, 12(6),
  351–362. doi:10.4319/lom.2014.12.351

Weiss, R. F. (1974), Carbon dioxide in water and seawater: The solubility
  of a non-ideal gas. Marine Chemistry, 2(3), 203–215.
  doi:10.1016/0304-4203(74)90015-2

Wurl, O., et al. (2024), HALOBATES: An Autonomous Surface Vehicle for
  High-Resolution Mapping of the Sea Surface Microlayer. Journal of
  Atmospheric and Oceanic Technology, 41(12), 1197–1211.
  doi:10.1175/JTECH-D-24-0021.1

Ribas-Ribas, M., Kilcher, L. F., & Wurl, O. (2018), Sniffle: A step
  forward to measure in situ CO2 fluxes with the floating chamber
  technique. Elementa: Science of the Anthropocene, 6, 14.
  doi:10.1525/elementa.275

--------------------------------------------------------------------------------
LICENSE
--------------------------------------------------------------------------------

This code is shared for reproducibility purposes in support of the
associated manuscript. For reuse or adaptation, please contact the
corresponding author and cite the associated publication.

================================================================================
END OF README
================================================================================