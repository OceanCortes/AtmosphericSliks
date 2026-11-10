function Fig1abcd_TimeSeries_v1(T, day18, day19, day27, day29)
% Fig1_TimeSeries_v1
% Same as v2, but:
%   - uniform font (Calibri or fallback)
%   - custom legend with sea surface divider

    arguments
        T table
        day18 datetime
        day19 datetime
        day27 datetime
        day29 datetime
    end

    % ---------------- Global font ----------------
    if any(strcmp(listfonts, 'Calibri'))
        set(groot, 'defaultAxesFontName', 'Calibri');
        set(groot, 'defaultTextFontName', 'Calibri');
    else
        set(groot, 'defaultAxesFontName', 'Arial');
        set(groot, 'defaultTextFontName', 'Arial');
    end

    % Colours (RGB)
    C.ATM = [0.5 0.5 0.5];        
    C.NSA = [0 0 0];              
    C.NSL = [0 0.75 0.75];        
    C.OCN = [0.10 0.30 0.65];     

    figure('Color','w');

    % --- Panel 1: 18 (Non-slick) ---
    ax1 = subplot(2,2,1); hold on; box on;
    local_plotOneDayTimeseries(ax1, T, day18, C);
    title('Non-slick Scenarios');
    ylabel('{\it p}CO_2 [\muatm]');
    ylim([385 565]);
    grid off

    % --- Panel 3: 19 (Non-slick) ---
    ax3 = subplot(2,2,3); hold on; box on;
    local_plotOneDayTimeseries(ax3, T, day19, C);
    ylabel('{\it p}CO_2 [\muatm]');
    ylim([385 565]);
    grid off

    % --- Panel 2: 27 (Slick) ---
    ax2 = subplot(2,2,2); hold on; box on;
    local_plotOneDayTimeseries(ax2, T, day27, C);
    title('Slick Scenarios');
    ylim([385 565]);
    grid off

    % --- Panel 4: 29 (Slick) ---
    ax4 = subplot(2,2,4); hold on; box on;
    local_plotOneDayTimeseries(ax4, T, day29, C);
    ylim([385 565]);
    grid off

% Legend only once
    legend(ax3, {'Air_{ 100 cm}', 'NSA_{ 20 cm}', 'NSL_{ 20 cm}', 'Sea_{ 100 cm}'}, ...
        'Location','northeast','FontSize', 8);
end

% =====================================================================
% Local helper: plot one day
% =====================================================================
function local_plotOneDayTimeseries(ax, T, day0, C)

    d = dateshift(day0,'start','day');
    idx = T.Time >= d & T.Time < d + days(1);

    tt = T.Time(idx);

    xNSA = T.pCO2_NSA(idx);
    xATM = T.pCO2_ATM(idx);
    xNSL = T.pCO2_NSL(idx);
    xOCN = T.pCO2_OCN_G(idx);

    validAny = ~isnan(xNSA) | ~isnan(xATM) | ~isnan(xNSL) | ~isnan(xOCN);
    if ~any(validAny)
        warning('No data found for %s', datestr(day0,'dd mmm yyyy'));
        return
    end

    tFirst = min(tt(validAny));
    tLast  = max(tt(validAny));

    plot(ax, tt, xATM, '-', 'Color', C.ATM, 'LineWidth', 1.0);
    plot(ax, tt, xNSA, '-', 'Color', C.NSA, 'LineWidth', 1.0);
    plot(ax, tt, xNSL, '-', 'Color', C.NSL, 'LineWidth', 1.0);
    plot(ax, tt, xOCN, '-', 'Color', C.OCN, 'LineWidth', 1.0);

    xlim(ax, [tFirst - minutes(30), tLast + minutes(30)]);
    grid(ax, 'on');

    % ---- X-axis formatting ----
    ax.XAxis.TickLabelFormat = 'HH:mm';
    xlabel(ax, datestr(day0,'dd mmmm, yyyy'));

    % Remove MATLAB secondary date label
    try
        ax.XAxis.SecondaryLabel.Visible = 'off';
    catch
        try
            ax.XAxis.SecondaryLabel.String = '';
        catch
        end
    end
end