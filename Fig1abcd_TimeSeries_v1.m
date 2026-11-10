function Fig1abcd_TimeSeries_v1(T, S)
%FIG1ABCD_TIMESERIES_V1  Manuscript Figure 2 (a-d): pCO2 time series at the
%four levels on each day.
%
%   Fig1abcd_TimeSeries_v1(T, S)
%     T : merged table from NearSurface_pCO2_Study (60-s tolerance, NO gap
%         filling, so no flat segments)
%     S : BASS_pCO2_Settings()
%
%   GLAUCUS levels (NSA20, NSL20) are continuous lines (1 Hz). SNIFFLE
%   measures air and water ALTERNATELY with one detector (~2.5-min air
%   periods between ~7-17-min water periods), so Air100 (and Sea100 when
%   taken from SNIFFLE) are drawn as points: the gaps are real, not
%   missing data.

    C.ATM = [0.5 0.5 0.5];
    C.NSA = [0 0 0];
    C.NSL = [0 0.75 0.75];
    C.OCN = [0.10 0.30 0.65];

    if strcmpi(S.sea100, 'sniffle'), seaCol = 'pCO2_OCN_S'; else, seaCol = 'pCO2_OCN_G'; end

    figure('Color','w','Name','Figure 2 - pCO2 time series');
    tl = tiledlayout(2, 2, 'TileSpacing','compact', 'Padding','compact');
    order = [find(~S.isSlick), find(S.isSlick)];     % columns: non-slick | slick
    tileOf = [1 3 2 4];
    letters = 'acbd';
    yAll = [T.pCO2_ATM; T.pCO2_NSA; T.pCO2_NSL; T.(seaCol)];
    yl = [floor(min(yAll(isfinite(yAll)))/10)*10, ceil(max(yAll(isfinite(yAll)))/10)*10];

    for j = 1:numel(order)
        i  = order(j);
        ax = nexttile(tl, tileOf(j)); hold(ax,'on'); box(ax,'on');
        d0 = dateshift(S.days(i),'start','day');
        m  = T.Time >= d0 & T.Time < d0 + days(1);
        tt = T.Time(m);

        h1 = plot(ax, tt, T.pCO2_ATM(m), '.', 'Color', C.ATM, 'MarkerSize', 4);
        h2 = plot(ax, tt, T.pCO2_NSA(m), '-', 'Color', C.NSA, 'LineWidth', 1.0);
        h3 = plot(ax, tt, T.pCO2_NSL(m), '-', 'Color', C.NSL, 'LineWidth', 1.0);
        if strcmpi(S.sea100, 'sniffle')
            h4 = plot(ax, tt, T.(seaCol)(m), '.', 'Color', C.OCN, 'MarkerSize', 4);
        else
            h4 = plot(ax, tt, T.(seaCol)(m), '-', 'Color', C.OCN, 'LineWidth', 1.0);
        end

        v = any(isfinite([T.pCO2_ATM(m) T.pCO2_NSA(m) T.pCO2_NSL(m) T.(seaCol)(m)]), 2);
        if any(v), xlim(ax, [min(tt(v)) - minutes(20), max(tt(v)) + minutes(20)]); end
        ylim(ax, yl);
        ax.XAxis.TickLabelFormat = 'HH:mm';
        try, ax.XAxis.SecondaryLabel.Visible = 'off'; catch, end
        xlabel(ax, sprintf('%s (%s)', datestr(d0,'dd mmmm yyyy'), S.timeZone));
        if S.isSlick(i), sc = 'Slick'; else, sc = 'Non-slick'; end
        title(ax, sprintf('%s) %s', letters(j), sc));
        if tileOf(j) == 1 || tileOf(j) == 3, ylabel(ax, '{\it p}CO_2 [\muatm]'); end
        if j == 1
            legend(ax, [h1 h2 h3 h4], {'Air_{100}','NSA_{20}','NSL_{20}','Sea_{100}'}, ...
                'Location','northeast','FontSize', 8);
        end
    end
end
