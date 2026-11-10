function S = BASS_pCO2_Settings()
%BASS_PCO2_SETTINGS  Single source of every constant and processing choice
%used by NearSurface_pCO2_Study.m and its functions. Change values HERE
%only, so Table 1, Figures 2-4 and the D% scaling always stay consistent.

    % ---------------- Input files ----------------
    S.sniffleFile = 'Sniffle_pCO2_DataBase_v2.xlsx';
    S.glaucusFile = 'Glaucus_pCO2_DataBase_v2.xlsx';
    S.mergedFile  = 'pCO2_GlauSniff.xlsx';          % written by the main script

    % ---------------- Days and scenarios ----------------
    S.days    = datetime(2024,7,[18 19 27 29]);
    S.isSlick = [false false true true];
    S.timeZone = 'UTC';                               % time stamps of both platforms (confirm)

    % ---------------- Flux constants (Methods 2.3) ----------------
    % F = k * K0 * dpCO2   (Wanninkhof, 2014)
    S.k_cmh = 15.7;      % gas transfer velocity [cm h-1] (mean SNIFFLE k, Methods 2.3)
    S.K0    = 33;        % CO2 solubility [mol m-3 atm-1] (Weiss, 1974; Methods 2.3)
    % To compute K0 from measured T and S instead, set S.K0 = [] and fill:
    S.T_C   = NaN;       % mean water temperature [degC]
    S.Sal   = NaN;       % mean salinity
    % f = k*K0 in mmol m-2 d-1 per uatm  (15.7 cm/h, 33 -> 0.1243)

    % ---------------- Which sensor is "Sea 100 cm" ----------------
    % 'sniffle' : SNIFFLE Sea100 (as described in Methods 2.2 / Figure 1);
    %             Air100 and Sea100 then come from the same detector.
    % 'glaucus' : GLAUCUS ATLANTICUS 100 cm inlet (sensitivity test).
    S.sea100 = 'sniffle';

    % ---------------- Time base ----------------
    S.binWidth  = minutes(1.5);   % aggregation bins (Methods 2.2)
    S.minFill   = 0.5;            % keep a bin only if >= 50% of expected samples
    S.mergeTol  = seconds(60);    % merge tolerance for the time-series table (no gap filling)
    S.maxAirGap = minutes(30);    % max distance from a SNIFFLE air bin when pairing Air with Sea

    % ---------------- Uncertainty (Methods 2.2) ----------------
    S.u_sniffle = NaN;            % sensor uncertainty SNIFFLE [uatm]   <-- fill
    S.u_glaucus = NaN;            % sensor uncertainty GLAUCUS [uatm]   <-- fill

    % ---------------- Scaling (Section 2.4) ----------------
    S.covOpen  = 0.11;            % Romano (1996)
    S.covCoast = 0.30;

    % ---------------- Output ----------------
    S.tableXlsx = 'Table1_recalculated.xlsx';   % Table 1 (Excel); '' = do not write
end
