function Fig3_CO2Flux_v1(T)
% CO2Flux_TimeSeries_2Scenarios_v7
%
% CO2 flux time series with a broken x-axis (18–19 Jul vs 27–29 Jul).
%
% v7 changes vs v6:
%   - Removes ΔpCO2 panels (ax11, ax12) entirely
%   - Only plots CO2 flux panels: ax21 (Non-slick) and ax22 (Slick)
%   - Keeps broken-axis layout via two tiles and break marks between them
%   - Preserves bottom-row tick formatting (18,19,27,29 at 12:00)

    % ==============================
    % GLOBAL FONT SETTINGS
    % ==============================
    fontName = 'Calibri';
    fontSize = 11;

    availableFonts = listfonts;
    if ~any(strcmpi(fontName, availableFonts))
        fontName = 'Arial';
    end

    set(groot, 'defaultAxesFontName', fontName);
    set(groot, 'defaultTextFontName', fontName);
    set(groot, 'defaultAxesFontSize', fontSize);
    set(groot, 'defaultTextFontSize', fontSize);
    set(groot, 'defaultLegendFontName', fontName);
    set(groot, 'defaultLegendFontSize', fontSize);

    % ---------------- Constants ----------------
    k_ms = 1.0e-4;
    K0   = 33;

    % ---------------- Segments ----------------
    tNS1 = datetime(2024,7,18,0,0,0);
    tNS2 = datetime(2024,7,19,23,59,59);

    tS1  = datetime(2024,7,27,0,0,0);
    tS2  = datetime(2024,7,29,23,59,59);

    if ~isdatetime(T.Time), T.Time = datetime(T.Time); end

    keep = (T.Time>=tNS1 & T.Time<=tNS2) | (T.Time>=tS1 & T.Time<=tS2);
    T = T(keep,:);

    okATM = isfinite(T.pCO2_ATM);
    T = T(okATM,:);

    if isempty(T)
        warning('No data remaining after ATM filter in the requested periods.');
        return
    end

    % ---------------- Per-row pooled OCN, gradients, flux ----------------
    pOCN_row = mean([T.pCO2_OCN_S(:), T.pCO2_OCN_G(:)], 2, 'omitnan');

    dP_ATM_OCN_row = pOCN_row - T.pCO2_ATM;
    dP_NSA_NSL_row = T.pCO2_NSL - T.pCO2_NSA;

    F_ATM_OCN_row = flux_from_dp(dP_ATM_OCN_row, k_ms, K0);
    F_NSA_NSL_row = flux_from_dp(dP_NSA_NSL_row, k_ms, K0);

    % ---------------- 1.5 min bins ----------------
    dtBin = minutes(1.5);
    tRef  = datetime(2024,7,1,0,0,0);
    tbin  = tRef + dtBin * floor((T.Time - tRef)/dtBin);

    % ---------------- Colours ----------------
    colConv = [0.35 0.35 0.35];
    colNSI  = [0.00 0.45 0.70];

    colConv_faint = lighten_rgb(colConv, 0.60);
    colNSI_faint  = lighten_rgb(colNSI,  0.60);

    % ---------------- Layout ----------------
    fig = figure('Color','w','Name','CO2 flux time series (broken axis)');
    tiledlayout(fig, 1, 2, 'TileSpacing','compact', 'Padding','compact');

    ax21 = nexttile(1); hold(ax21,'on'); box(ax21,'on');
    ax22 = nexttile(2); hold(ax22,'on'); box(ax22,'on');

    % ---------------- Plot segments ----------------
    idxNS = (T.Time>=tNS1 & T.Time<=tNS2);
    plot_segment_flux_only(ax21, T.Time(idxNS), tbin(idxNS), ...
        F_ATM_OCN_row(idxNS), F_NSA_NSL_row(idxNS), ...
        colConv_faint, colNSI_faint, colConv, colNSI);

    idxS = (T.Time>=tS1 & T.Time<=tS2);
    plot_segment_flux_only(ax22, T.Time(idxS), tbin(idxS), ...
        F_ATM_OCN_row(idxS), F_NSA_NSL_row(idxS), ...
        colConv_faint, colNSI_faint, colConv, colNSI);

    % ---------------- Cosmetics ----------------
    yline(ax21,0,'k-','LineWidth',0.8);
    yline(ax22,0,'k-','LineWidth',0.8);

    title(ax21,'Non-slick Scenarios');
    title(ax22,'Slick Scenarios');

    ylabel(ax21,'CO_2 flux [mmol m^{-2} d^{-1}]');

    xlim(ax21,[tNS1 tNS2]);
    xlim(ax22,[tS1  tS2 ]);

    linkaxes([ax21 ax22],'y');

    ax22.YTickLabel = {};

    % ---------------- X-axis formatting ----------------
    ticksNS = datetime(2024,7,[18 19],12,0,0);
    ticksS  = datetime(2024,7,[27 29],12,0,0);

    ax21.XTick = ticksNS;
    ax21.XTickLabel = {'18','19'};

    ax22.XTick = ticksS;
    ax22.XTickLabel = {'27','29'};

    hx21 = xlabel(ax21,'July, 2024');
    hx22 = xlabel(ax22,'July, 2024');
    hx21.HorizontalAlignment = 'right';
    hx22.HorizontalAlignment = 'right';

    ax21.XTickLabelRotation = 0;
    ax22.XTickLabelRotation = 0;

    % ---------------- Legend ----------------
    hLegConv = line(ax21, NaN, NaN, ...
        'LineStyle','none', 'Marker','o', 'MarkerSize',7, ...
        'MarkerFaceColor', colConv, 'MarkerEdgeColor', colConv);

    hLegNSI  = line(ax21, NaN, NaN, ...
        'LineStyle','none', 'Marker','o', 'MarkerSize',7, ...
        'MarkerFaceColor', colNSI,  'MarkerEdgeColor', colNSI);

    legend(ax21, [hLegConv hLegNSI], {'Meter-scale','Near-surface'}, ...
        'Location','southwest');

    % ---------------- Reduce gap ----------------
    dx = 0.03;
    p22 = ax22.Position;
    p22(1) = p22(1) - dx;
    ax22.Position = p22;

    add_axis_break_marks(ax21, ax22);

end

% ======================================================================
function plot_segment_flux_only(axF, tRaw, tbin, Fconv_row, Fnsi_row, ...
                               colConv_faint, colNSI_faint, colConv, colNSI)

    G = findgroups(tbin);

    tMin = splitapply(@min, tRaw, G);
    tMax = splitapply(@max, tRaw, G);
    tCen = splitapply(@meanTime, tRaw, G);

    Fconv_mu  = splitapply(@(x) mean(x,'omitnan'), Fconv_row, G);
    Fconv_sd  = splitapply(@(x) std(x,'omitnan'),  Fconv_row, G);

    Fnsi_mu   = splitapply(@(x) mean(x,'omitnan'), Fnsi_row,  G);
    Fnsi_sd   = splitapply(@(x) std(x,'omitnan'),  Fnsi_row,  G);

    local_plotBinnedWhiskers(axF, tMin, tMax, tCen, Fconv_mu, Fconv_sd, colConv_faint, 4.5);
    local_plotBinnedWhiskers(axF, tMin, tMax, tCen, Fnsi_mu,  Fnsi_sd,  colNSI_faint,  4.5);

    day0 = dateshift(tRaw,'start','day');
    GD = findgroups(day0);

    dMin = splitapply(@min, tRaw, GD);
    dMax = splitapply(@max, tRaw, GD);
    dCen = splitapply(@meanTime, tRaw, GD);

    FconvD_mu  = splitapply(@(x) mean(x,'omitnan'), Fconv_row, GD);
    FconvD_sd  = splitapply(@(x) std(x,'omitnan'),  Fconv_row, GD);

    FnsiD_mu   = splitapply(@(x) mean(x,'omitnan'), Fnsi_row,  GD);
    FnsiD_sd   = splitapply(@(x) std(x,'omitnan'),  Fnsi_row,  GD);

    local_plotBinnedWhiskers(axF, dMin, dMax, dCen, FconvD_mu, FconvD_sd, colConv, 8.0);
    local_plotBinnedWhiskers(axF, dMin, dMax, dCen, FnsiD_mu,  FnsiD_sd,  colNSI,  8.0);

end

function local_plotBinnedWhiskers(ax, tMin, tMax, tCen, yMu, ySd, rgb, markerSize)

    for i = 1:numel(tCen)
        if ~isfinite(yMu(i)), continue; end

        plot(ax, [tMin(i) tMax(i)], [yMu(i) yMu(i)], '-', ...
            'Color', rgb, 'LineWidth', 1.0, 'HandleVisibility','off');

        if isfinite(ySd(i))
            plot(ax, [tCen(i) tCen(i)], [yMu(i)-ySd(i) yMu(i)+ySd(i)], '-', ...
                'Color', rgb, 'LineWidth', 1.0, 'HandleVisibility','off');
        end

        plot(ax, tCen(i), yMu(i), 'o', ...
            'MarkerSize', markerSize, ...
            'MarkerFaceColor', rgb, ...
            'MarkerEdgeColor', rgb, ...
            'LineStyle','none', ...
            'HandleVisibility','off');
    end
end

function add_axis_break_marks(axL, axR)
    fig = ancestor(axL,'figure');
    pL = get(axL,'Position');
    pR = get(axR,'Position');

    x1 = pL(1) + pL(3);
    x2 = pR(1);

    yTop = pL(2) + pL(4);
    yBot = pL(2);

    dx = 0.006; dy = 0.010;

    annotation(fig,'line', [x1-dx x1+dx], [yTop-dy yTop+dy], 'Color',[0.3 0.3 0.3]);
    annotation(fig,'line', [x1-dx x1+dx], [yBot-dy yBot+dy], 'Color',[0.3 0.3 0.3]);

    annotation(fig,'line', [x2-dx x2+dx], [yTop-dy yTop+dy], 'Color',[0.3 0.3 0.3]);
    annotation(fig,'line', [x2-dx x2+dx], [yBot-dy yBot+dy], 'Color',[0.3 0.3 0.3]);
end

function F = flux_from_dp(dp_uatm, k_ms, K0)
    dp_atm = dp_uatm * 1e-6;
    F = k_ms .* K0 .* dp_atm;
    F = F * 1000 * 86400;
end

function t = meanTime(tt)
    t = datetime(mean(datenum(tt),'omitnan'), 'ConvertFrom','datenum');
end

function rgb2 = lighten_rgb(rgb, fracToWhite)
    fracToWhite = max(0,min(1,fracToWhite));
    rgb2 = rgb + fracToWhite*(1 - rgb);
end
