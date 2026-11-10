% NearSurface_pCO2_Study.m
% MAIN SCRIPT - Near-surface pCO2 study (BASS 2024, North Sea).
% Reproduces Table 1, Figures 2-4 and the D% scaling of the manuscript.
%
% All constants and processing choices are in BASS_pCO2_Settings.m.
% Table 1, Figure 3 and Figure 4 are computed ONCE by Table1_Recalc.m from
% the raw platform files, so the table and the figures cannot disagree.
%
% Changes after review MR2 (see README):
%   - k = 15.7 cm h-1 and K0 = 33 mol m-3 atm-1, as stated in Methods 2.3
%     (previously k = 1e-4 m s-1 = 36 cm h-1 in the flux scripts).
%   - Merge with 60-s tolerance: no nearest-neighbour gap filling, so the
%     flat segments (e.g. NSA 27 Jul 10:03-10:20) are gone.
%   - dpCO2 and fluxes computed from the same 1.5-min bins; Sea100 from
%     SNIFFLE (Methods 2.2), Air100 interpolated between SNIFFLE air periods.
close all
clear all
clc

S = BASS_pCO2_Settings();

% ---------------------------------------------------------
% 1) Read raw data
% ---------------------------------------------------------
Ts = readtable(S.sniffleFile);
Tg = readtable(S.glaucusFile);
Ts.Time = datetime(Ts.Time);
Tg.Time = datetime(Tg.Time);

% SNIFFLE has duplicate time stamps -> median per time stamp
[Tu, ~, g] = unique(Ts.Time);
Ts = table(Tu, ...
    splitapply(@(x) median(x,'omitnan'), Ts.pCO2_m100_S, g), ...
    splitapply(@(x) median(x,'omitnan'), Ts.pCO2_p100_S, g), ...
    'VariableNames', {'Time','pCO2_m100_S','pCO2_p100_S'});
Tg = sortrows(Tg, 'Time');

% ---------------------------------------------------------
% 2) Merge onto a common time vector, 60-s tolerance, NO gap filling
%    (used only for the time-series figure and the exported file)
% ---------------------------------------------------------
Tmaster = union(Ts.Time, Tg.Time);
T = table(Tmaster, 'VariableNames', {'Time'});
T.pCO2_ATM   = nearestWithinTol(Ts.Time, Ts.pCO2_m100_S, Tmaster, S.mergeTol);
T.pCO2_OCN_S = nearestWithinTol(Ts.Time, Ts.pCO2_p100_S, Tmaster, S.mergeTol);
T.pCO2_NSA   = nearestWithinTol(Tg.Time, Tg.pCO2_m20_G,  Tmaster, S.mergeTol);
T.pCO2_NSL   = nearestWithinTol(Tg.Time, Tg.pCO2_p20_G,  Tmaster, S.mergeTol);
T.pCO2_OCN_G = nearestWithinTol(Tg.Time, Tg.pCO2_p100_G, Tmaster, S.mergeTol);
writetable(T, S.mergedFile, 'Sheet', 'pCO2_merged');

% ---------------------------------------------------------
% 3) Table 1 (pCO2, dpCO2, fluxes) - single consistent calculation
% ---------------------------------------------------------
R = Table1_Recalc(S);

% ---------------------------------------------------------
% 4) Figures
% ---------------------------------------------------------
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
set(groot, 'defaultLegendFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 12);
set(groot, 'defaultTextFontSize', 12);
set(groot, 'defaultLegendFontSize', 11);

Fig1abcd_TimeSeries_v1(T, S);                       % Figure 2 a-d
Fig2_DailyProfiles_v1(R);                           % Figure 3 a-b
Fig1e_MeanDifferenceProfile_NonSlick_vs_Slick_v1(R);% Figure 3 c
Fig3_CO2Flux_v1(R);                                 % Figure 4
B = Fig4_Bias_Estimation_Global_v2(R);              % Section 3.4 (D%)

% =====================================================================
function y = nearestWithinTol(tSrc, xSrc, tDst, tol)
% Value of the nearest source sample, only if it lies within tol;
% otherwise NaN (no gap filling).
    xs = datenum(tSrc);  xd = datenum(tDst);
    iN = interp1(xs, (1:numel(xs)).', xd, 'nearest', NaN);
    y  = NaN(numel(xd), 1);
    ok = ~isnan(iN);
    ok(ok) = abs(xd(ok) - xs(iN(ok))) <= days(tol);
    y(ok) = xSrc(iN(ok));
end
