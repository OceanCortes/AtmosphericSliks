function R = Table1_Recalc(S)
%TABLE1_RECALC  Table 1 (pCO2, dpCO2, CO2 flux) computed with ONE consistent
%definition, so every flux equals k*K0*dpCO2 and every dpCO2 equals the
%difference of the pCO2 values shown in the same table.
%
%   R = Table1_Recalc()      uses BASS_pCO2_Settings()
%   R = Table1_Recalc(S)     uses a (modified) settings struct
%
%   Procedure
%     1. Raw data of each platform (no gap filling, no nearest-neighbour
%        merge). Duplicate SNIFFLE time stamps -> median.
%     2. Each level is averaged into 1.5-min bins; a bin is kept when it
%        holds >= S.minFill of the expected samples.
%     3. Near-surface: dpCO2 = NSL - NSA in every bin where both exist.
%     4. Meter-scale : dpCO2 = Sea100 - Air100. SNIFFLE measures air and
%        water alternately with the same detector, so Air100 is linearly
%        interpolated in time to each Sea100 bin; a Sea100 bin is used only
%        if an air bin lies within S.maxAirGap.
%     5. Table pCO2 = mean over exactly the bins used for that dpCO2,
%        so Sea - Air = dpCO2(MS) and NSL - NSA = dpCO2(NS).
%        (Air100 SD = SD of the measured air bins.)
%     6. F = f * dpCO2 per bin, f = k*K0 [mmol m-2 d-1 uatm-1]; daily
%        F = f * daily dpCO2 and SD(F) = f * SD(dpCO2).
%     7. SE of daily dpCO2 = SD / sqrt(n_eff), n_eff = n(1-r1)/(1+r1)
%        (lag-1 autocorrelation r1 of the binned series, Methods 2.2).
%     8. D% = |mean_slick(F_NS - F_MS)| / |mean_slick(F_NS)| * 100
%        (independent of k and K0), scaled by slick coverage.
%
%   Sign: dpCO2 = pCO2(water) - pCO2(air); positive = sea-to-air flux.

    if nargin < 1 || isempty(S), S = BASS_pCO2_Settings(); end

    K0 = S.K0;
    if isempty(K0), K0 = weissK0(S.T_C, S.Sal); end
    f = (S.k_cmh/100/3600) * K0 * 1e-6 * 86400 * 1000;   % mmol m-2 d-1 per uatm

    % ------------------------------------------------------------ data
    Ts = readtable(S.sniffleFile);  Ts.Time = datetime(Ts.Time);
    Tg = readtable(S.glaucusFile);  Tg.Time = datetime(Tg.Time);
    [tu, ~, g] = unique(Ts.Time);
    Ts = table(tu, splitapply(@(x) median(x,'omitnan'), Ts.pCO2_m100_S, g), ...
                   splitapply(@(x) median(x,'omitnan'), Ts.pCO2_p100_S, g), ...
               'VariableNames', {'Time','pCO2_m100_S','pCO2_p100_S'});
    nS = round(S.binWidth / seconds(2));   % SNIFFLE ~0.5 Hz
    nG = round(S.binWidth / seconds(1));   % GLAUCUS 1 Hz

    nD = numel(S.days);
    vars = {'Air','Air_sd','NSA','NSA_sd','NSL','NSL_sd','Sea','Sea_sd', ...
            'dMS','dMS_sd','dMS_se','nMS','neffMS','dNS','dNS_sd','dNS_se','nNS','neffNS', ...
            'FMS','FMS_sd','FNS','FNS_sd'};
    for v = vars, R.(v{1}) = nan(1, nD); end
    R.bins = struct('tMS',{},'dMS',{},'FMS',{},'tNS',{},'dNS',{},'FNS',{});

    for i = 1:nD
        d0 = dateshift(S.days(i), 'start', 'day');
        [tNSA, xNSA] = binMean(Tg.Time, Tg.pCO2_m20_G, d0, S.binWidth, S.minFill*nG);
        [tNSL, xNSL] = binMean(Tg.Time, Tg.pCO2_p20_G, d0, S.binWidth, S.minFill*nG);
        [tAir, xAir] = binMean(Ts.Time, Ts.pCO2_m100_S, d0, S.binWidth, S.minFill*nS);
        if strcmpi(S.sea100, 'sniffle')
            [tSea, xSea] = binMean(Ts.Time, Ts.pCO2_p100_S, d0, S.binWidth, S.minFill*nS);
        else
            [tSea, xSea] = binMean(Tg.Time, Tg.pCO2_p100_G, d0, S.binWidth, S.minFill*nG);
        end

        % ---- near-surface: common bins
        [tNS, ia, ib] = intersect(tNSA, tNSL);
        a = xNSA(ia);  b = xNSL(ib);  dNS = b - a;

        % ---- meter-scale: Air interpolated to Sea bins
        ta = datenum(tAir);  ts = datenum(tSea);
        if numel(ta) > 1
            aI = interp1(ta, xAir, ts, 'linear');
        else
            aI = nan(size(ts));
        end
        aI(ts <= ta(1))   = xAir(1);      % hold end values
        aI(ts >= ta(end)) = xAir(end);
        dist = min(abs(ts - ta.'), [], 2);           % days to nearest air bin
        keep = dist <= days(S.maxAirGap);
        tMS = tSea(keep);  aI = aI(keep);  s = xSea(keep);  dMS = s - aI;

        R.Air(i) = mean(aI);  R.Air_sd(i) = std(xAir);
        R.Sea(i) = mean(s);   R.Sea_sd(i) = std(s);
        R.NSA(i) = mean(a);   R.NSA_sd(i) = std(a);
        R.NSL(i) = mean(b);   R.NSL_sd(i) = std(b);
        [R.dMS(i), R.dMS_sd(i), R.dMS_se(i), R.nMS(i), R.neffMS(i)] = meanSdSe(dMS);
        [R.dNS(i), R.dNS_sd(i), R.dNS_se(i), R.nNS(i), R.neffNS(i)] = meanSdSe(dNS);
        R.FMS(i) = f*R.dMS(i); R.FMS_sd(i) = f*R.dMS_sd(i);
        R.FNS(i) = f*R.dNS(i); R.FNS_sd(i) = f*R.dNS_sd(i);
        R.bins(i).tMS = tMS;  R.bins(i).dMS = dMS;  R.bins(i).FMS = f*dMS;
        R.bins(i).tNS = tNS;  R.bins(i).dNS = dNS;  R.bins(i).FNS = f*dNS;
    end

    R.gap_dpCO2   = abs(R.dNS - R.dMS);
    R.gap_F       = abs(R.FNS - R.FMS);
    R.Dpct_day    = abs(R.FNS - R.FMS) ./ abs(R.FNS) * 100;
    R.ratio_NS_MS = R.FNS ./ R.FMS;
    sl = S.isSlick;
    R.Dpct_slick  = abs(mean(R.FNS(sl) - R.FMS(sl))) / abs(mean(R.FNS(sl))) * 100;
    R.Dpct_open   = R.Dpct_slick * S.covOpen;
    R.Dpct_coast  = R.Dpct_slick * S.covCoast;
    R.f = f;  R.K0 = K0;  R.settings = S;

    % Combined uncertainty U = 2*sqrt(u1^2 + u2^2 + sigma^2) (Methods 2.2);
    % sigma = SD of dpCO2 on non-slick days. NaN until sensor u's are filled.
    sigMS = sqrt(mean(R.dMS_sd(~sl).^2));  sigNS = sqrt(mean(R.dNS_sd(~sl).^2));
    R.U_MS = 2*sqrt(2*S.u_sniffle^2 + sigMS^2);
    R.U_NS = 2*sqrt(2*S.u_glaucus^2 + sigNS^2);

    printTable(R, S);
    if ~isempty(S.tableCsv), writeCsv(R, S); end
end

% =====================================================================
function [tc, xm] = binMean(t, x, d0, bw, minN)
    m = t >= d0 & t < d0 + days(1) & ~isnan(x);
    b = floor((t(m) - d0) / bw) + 1;
    s = accumarray(b, x(m));  n = accumarray(b, 1);
    k = find(n >= minN);
    tc = d0 + (k - 1) * bw + bw/2;
    xm = s(k) ./ n(k);
end

function [mu, sd, se, n, neff] = meanSdSe(x)
    x = x(:);  n = numel(x);  mu = mean(x);  sd = std(x);
    if n > 2
        c  = corrcoef(x(1:end-1), x(2:end));   % core MATLAB (no toolbox)
        r1 = c(1,2);
        neff = max(1, n * (1 - r1) / (1 + r1));
    else
        neff = n;
    end
    se = sd / sqrt(neff);
end

function K0 = weissK0(T_C, Sal)
% CO2 solubility, Weiss (1974), in mol m-3 atm-1 (rho ~ 1024 kg m-3)
    T = (T_C + 273.15) / 100;
    lnK = -58.0931 + 90.5069 ./ T + 22.2940 .* log(T) + ...
          Sal .* (0.027766 - 0.025888 .* T + 0.0050578 .* T.^2);
    K0 = exp(lnK) * 1024;
end

function printTable(R, S)
    lab = cellstr(datestr(S.days, 'dd mmm'));
    fprintf('\n===== TABLE 1 (recalculated) =====\n');
    fprintf('Sea100 = %s | k = %.1f cm h-1 | K0 = %.1f mol m-3 atm-1 | f = k*K0 = %.4f mmol m-2 d-1 uatm-1\n', ...
        S.sea100, S.k_cmh, R.K0, R.f);
    fprintf('%-26s%s\n', '', sprintf('%16s', lab{:}));
    pr  = @(name, m, s) fprintf('%-26s%s\n', name, sprintf('%16s', compose('%.1f ± %.1f', [m; s].')));
    pr1 = @(name, m)    fprintf('%-26s%s\n', name, sprintf('%16s', compose('%.1f', m.')));
    pr('Air 100 cm [uatm]', R.Air, R.Air_sd);   pr('NSA 20 cm [uatm]', R.NSA, R.NSA_sd);
    pr('NSL 20 cm [uatm]',  R.NSL, R.NSL_sd);   pr('Sea 100 cm [uatm]', R.Sea, R.Sea_sd);
    pr('dpCO2 meter-scale (SE)',  R.dMS, R.dMS_se);
    pr('dpCO2 near-surface (SE)', R.dNS, R.dNS_se);
    pr1('dpCO2 approach gap', R.gap_dpCO2);
    pr('F meter-scale (SD)',  R.FMS, R.FMS_sd);
    pr('F near-surface (SD)', R.FNS, R.FNS_sd);
    pr1('F approach gap', R.gap_F);
    pr1('D% per day', R.Dpct_day);
    pr1('F_NS / F_MS', R.ratio_NS_MS);
    fprintf('%-26s%s\n', 'bins MS / NS', sprintf('%16s', compose('%d / %d', [R.nMS; R.nNS].')));
    fprintf('\nD%% (slick days) = %.0f%%  -> open ocean (x%.2f) = %.0f%%, coastal (x%.2f) = %.0f%%\n', ...
        R.Dpct_slick, S.covOpen, R.Dpct_open, S.covCoast, R.Dpct_coast);
    fprintf('Consistency check: max |F - f*dpCO2| = %.2g ; max |(Sea-Air) - dpCO2_MS| = %.2g ; max |(NSL-NSA) - dpCO2_NS| = %.2g\n', ...
        max(abs([R.FMS - R.f*R.dMS, R.FNS - R.f*R.dNS])), ...
        max(abs((R.Sea - R.Air) - R.dMS)), max(abs((R.NSL - R.NSA) - R.dNS)));
end

function writeCsv(R, S)
    lab = matlab.lang.makeValidName(cellstr(datestr(S.days, 'dd_mmm'))).';
    rows = {'Air100','NSA20','NSL20','Sea100','dpCO2_MS','dpCO2_NS','dpCO2_gap', ...
            'F_MS','F_NS','F_gap','Dpct','nBins_MS','nBins_NS'};
    nD = numel(S.days);
    M  = [R.Air; R.NSA; R.NSL; R.Sea; R.dMS; R.dNS; R.gap_dpCO2; R.FMS; R.FNS; R.gap_F; R.Dpct_day; R.nMS; R.nNS];
    E  = [R.Air_sd; R.NSA_sd; R.NSL_sd; R.Sea_sd; R.dMS_se; R.dNS_se; nan(1,nD); ...
          R.FMS_sd; R.FNS_sd; nan(4,nD)];
    T = array2table([M E], 'RowNames', rows, 'VariableNames', [strcat('mean_', lab), strcat('sd_or_se_', lab)]);
    writetable(T, S.tableCsv, 'WriteRowNames', true);
    fprintf('Table written to %s (pCO2 and F: SD; dpCO2: SE with n_eff)\n', S.tableCsv);
end
