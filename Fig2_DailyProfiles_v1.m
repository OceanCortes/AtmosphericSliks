function Fig2_DailyProfiles_v1(T, day18, day19, day27, day29)
% plot_pCO2_dailyProfiles_2panels
% Daily vertical pCO2 profiles (mean ± SD) in two panels

    arguments
        T table
        day18 datetime
        day19 datetime
        day27 datetime
        day29 datetime
    end

    % ==============================
    % GLOBAL FONT SETTINGS
    % ==============================
    fontName = 'Calibri';   % change here if needed
    fontSize = 11;

    % Fallback if Calibri is not available
    availableFonts = listfonts;
    if ~any(strcmpi(fontName, availableFonts))
        fontName = 'Arial';
    end

    % Apply globally (professional approach)
    set(groot, 'defaultAxesFontName', fontName);
    set(groot, 'defaultTextFontName', fontName);
    set(groot, 'defaultAxesFontSize', fontSize);
    set(groot, 'defaultTextFontSize', fontSize);
    set(groot, 'defaultLegendFontName', fontName);
    set(groot, 'defaultLegendFontSize', fontSize);

    % --- Colours (RGB) ---
    C.ATM = [0.5 0.5 0.5];   
    C.NSA = [0 0 0];         
    C.NSL = [0 0.75 0.75];   
    C.OCN = [0.10 0.30 0.65];
    C.line = [0.55 0.55 0.55];
    C.zero = [0.70 0.70 0.70];

    % --- Depth vector (cm) ---
    z = [-100 -20 20 100];

    % --- Compute stats ---
    S18 = local_dayStats(T, day18);
    S19 = local_dayStats(T, day19);
    S27 = local_dayStats(T, day27);
    S29 = local_dayStats(T, day29);

    % ==============================
    % FIGURE
    % ==============================
    figure('Color','w');
    tiledlayout(1,2, 'TileSpacing','compact', 'Padding','compact');

    % ---------------- Panel 1 ----------------
    nexttile(1); hold on; box on;
    title('Non-slick Scenarios');

    h18 = local_plotOneDay(z, S18, 'o', C);
    h19 = local_plotOneDay(z, S19, 's', C);

    yline(0, '-', 'Color', C.NSA, 'LineWidth', 1.0);
    set(gca,'YDir','reverse');
yticks = get(gca,'YTick');          % get current tick positions
yticklabels(abs(yticks));           % set tick labels as absolute values

    ylabel('Depth [cm]');
    ylim([-110 110]);

    xlabel('{\it p}CO_2 [\muatm]');
    xlim([390 550]);

    grid off;

    legend([h18 h19], ...
        {datestr(day18,'dd mmmm, yyyy'), datestr(day19,'dd mmmm, yyyy')}, ...
        'Location','northeast');

    % ---------------- Panel 2 ----------------
    nexttile(2); hold on; box on;
    title('Slick Scenarios');

    h27 = local_plotOneDay(z, S27, 'o', C);
    h29 = local_plotOneDay(z, S29, 's', C);

    yline(0, '-', 'Color', C.NSA, 'LineWidth', 1.0);
    set(gca,'YDir','reverse');
    yticks = get(gca,'YTick');          % get current tick positions
yticklabels(abs(yticks));           % set tick labels as absolute values

    ylabel('');
    ylim([-110 110]);

    xlabel('{\it p}CO_2 [\muatm]');
    xlim([390 550]);

    grid off;

    legend([h27 h29], ...
        {datestr(day27,'dd mmmm, yyyy'), datestr(day29,'dd mmmm, yyyy')}, ...
        'Location','northeast');

end

% =====================================================================
% Local helpers
% =====================================================================

function S = local_dayStats(T, day0)

    d = dateshift(day0, 'start', 'day');
    idx = T.Time >= d & T.Time < d + days(1);

    xATM = T.pCO2_ATM(idx);
    xNSA = T.pCO2_NSA(idx);
    xNSL = T.pCO2_NSL(idx);
    xOCN = [T.pCO2_OCN_S(idx); T.pCO2_OCN_G(idx)];

    S.mu = [mean(xATM,'omitnan'), mean(xNSA,'omitnan'), ...
            mean(xNSL,'omitnan'), mean(xOCN,'omitnan')];

    S.sd = [ std(xATM,'omitnan'), std(xNSA,'omitnan'), ...
             std(xNSL,'omitnan'), std(xOCN,'omitnan')];
end

function hLegend = local_plotOneDay(z, S, mk, C)

    mu = S.mu;
    sd = S.sd;

    % Connect means
    plot(mu, z, '-', 'Color', C.line, 'LineWidth', 1.0);

    % ATM
    errorbar(mu(1), z(1), sd(1), 'horizontal', mk, ...
        'Color', C.ATM, 'MarkerFaceColor', C.ATM, ...
        'MarkerEdgeColor', C.ATM, ...
        'LineWidth', 1.0, 'CapSize', 8, 'MarkerSize', 7);

    % NSA (legend handle)
    hLegend = errorbar(mu(2), z(2), sd(2), 'horizontal', mk, ...
        'Color', C.NSA, 'MarkerFaceColor', C.NSA, ...
        'MarkerEdgeColor', C.NSA, ...
        'LineWidth', 1.0, 'CapSize', 8, 'MarkerSize', 7);

    % NSL
    errorbar(mu(3), z(3), sd(3), 'horizontal', mk, ...
        'Color', C.NSL, 'MarkerFaceColor', C.NSL, ...
        'MarkerEdgeColor', C.NSL, ...
        'LineWidth', 1.0, 'CapSize', 8, 'MarkerSize', 7);

    % OCN
    errorbar(mu(4), z(4), sd(4), 'horizontal', mk, ...
        'Color', C.OCN, 'MarkerFaceColor', C.OCN, ...
        'MarkerEdgeColor', C.OCN, ...
        'LineWidth', 1.0, 'CapSize', 8, 'MarkerSize', 7);
end