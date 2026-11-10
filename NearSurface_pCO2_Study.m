% NearSurface_pCO2_Study.m
% Merge Sniffle + Glaucus pCO2 into one Excel with a single Time column
% Fix: aggregate duplicate Sniffle timestamps (required for interp1)
close all
clear all
clc

% Paths
sniffleFile = 'Sniffle_pCO2_DataBase_v2.xlsx';
glaucusFile = 'Glaucus_pCO2_DataBase_v2.xlsx';

% Read
Ts = readtable(sniffleFile);
Tg = readtable(glaucusFile);

% Ensure datetime
Ts.Time = datetime(Ts.Time);
Tg.Time = datetime(Tg.Time);

% ---------------------------------------------------------
% FIX: Sniffle has duplicate timestamps -> must aggregate
% Use median (robust) for each duplicated timestamp
% ---------------------------------------------------------
[Tu, ~, g] = unique(Ts.Time, 'stable');

Ts_clean = table(Tu, 'VariableNames', {'Time'});

% Only aggregate if the variables exist (prevents hard crashes)
if ismember('pCO2_m100_S', Ts.Properties.VariableNames)
    Ts_clean.pCO2_m100_S = splitapply(@(x) median(x,'omitnan'), Ts.pCO2_m100_S, g);
else
    Ts_clean.pCO2_m100_S = NaN(size(Tu));
    warning('Sniffle column pCO2_m100_S not found. Filled with NaN.');
end

if ismember('pCO2_p100_S', Ts.Properties.VariableNames)
    Ts_clean.pCO2_p100_S = splitapply(@(x) median(x,'omitnan'), Ts.pCO2_p100_S, g);
else
    Ts_clean.pCO2_p100_S = NaN(size(Tu));
    warning('Sniffle column pCO2_p100_S not found. Filled with NaN.');
end

Ts = Ts_clean;  % overwrite with de-duplicated Sniffle table

% ---------------------------------------------------------
% Master time vector
% ---------------------------------------------------------
Tmaster = union(Ts.Time, Tg.Time);

% Initialise merged table
T = table(Tmaster, 'VariableNames', {'Time'});

% Matching tolerance (kept for documentation; nearest neighbour used)
tol = seconds(60); 

% Helper function (nearest neighbour mapping)
matchToMaster = @(tSrc, xSrc) ...
    interp1(datenum(tSrc), xSrc, datenum(Tmaster), 'nearest', NaN);

% Assign columns
T.pCO2_ATM    = matchToMaster(Ts.Time, Ts.pCO2_m100_S);
T.pCO2_OCN_S  = matchToMaster(Ts.Time, Ts.pCO2_p100_S);

T.pCO2_NSA    = matchToMaster(Tg.Time, Tg.pCO2_m20_G);
T.pCO2_NSL    = matchToMaster(Tg.Time, Tg.pCO2_p20_G);
T.pCO2_OCN_G  = matchToMaster(Tg.Time, Tg.pCO2_p100_G);

% Write to Excel
writetable(T, 'pCO2_GlauSniff.xlsx', 'Sheet', 'pCO2_merged');


%%
%% === Global graphics defaults ===
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
set(groot, 'defaultLegendFontName', 'Times New Roman');
set(groot, 'defaultColorbarFontName', 'Times New Roman');

% Optional but common for papers
set(groot, 'defaultAxesFontSize', 12);
set(groot, 'defaultTextFontSize', 12);
set(groot, 'defaultLegendFontSize', 11);


%Results 1
Fig1abcd_TimeSeries_v1(T, ...
    datetime(2024,7,18), datetime(2024,7,19), ...
    datetime(2024,7,27), datetime(2024,7,29));

Fig1e_MeanDifferenceProfile_NonSlick_vs_Slick_v1(T, ...
    [datetime(2024,7,18) datetime(2024,7,19)], ...
    [datetime(2024,7,27) datetime(2024,7,29)]);

%Results 2
Fig2_DailyProfiles_v1(T, ...
    datetime(2024,7,18), datetime(2024,7,19), ...
    datetime(2024,7,27), datetime(2024,7,29));

%Results 3
Fig3_CO2Flux_v1(T)

Fig4_Bias_Estimation_Global_v2(T)