function Fig2_DailyProfiles_v1(R)
%FIG2_DAILYPROFILES_V1  Manuscript Figure 3 (a, b): daily vertical pCO2
%profiles (mean +/- SD) for non-slick and slick scenarios.
%
%   Fig2_DailyProfiles_v1(R)   R = output of Table1_Recalc
%
%   Means and SDs are exactly those of Table 1. The vertical axis is height
%   relative to the sea surface (+ above, - below): Air +100, NSA +20,
%   NSL -20, Sea -100 cm.

    S = R.settings;
    C = levelColours();
    z = [100 20 -20 -100];                     % height relative to sea surface [cm]
    mk = {'o','s'};

    figure('Color','w','Name','Figure 3ab - daily pCO2 profiles');
    tl = tiledlayout(1, 2, 'TileSpacing','compact', 'Padding','compact');
    groups = {find(~S.isSlick), find(S.isSlick)};
    titles = {'a) Non-slick', 'b) Slick'};
    allX = [R.Air - R.Air_sd, R.Sea - R.Sea_sd, R.NSA - R.NSA_sd, R.NSL - R.NSL_sd, ...
            R.Air + R.Air_sd, R.Sea + R.Sea_sd, R.NSA + R.NSA_sd, R.NSL + R.NSL_sd];
    xl = [floor(min(allX)/10)*10 - 10, ceil(max(allX)/10)*10 + 10];

    for p = 1:2
        ax = nexttile(tl, p); hold(ax,'on'); box(ax,'on');
        idx = groups{p};  hDay = gobjects(1, numel(idx));
        for j = 1:numel(idx)
            i  = idx(j);
            mu = [R.Air(i) R.NSA(i) R.NSL(i) R.Sea(i)];
            sd = [R.Air_sd(i) R.NSA_sd(i) R.NSL_sd(i) R.Sea_sd(i)];
            plot(ax, mu, z, '-', 'Color', C.line, 'LineWidth', 1.0, 'HandleVisibility','off');
            for k = 1:4
                errorbar(ax, mu(k), z(k), sd(k), 'horizontal', mk{j}, 'Color', C.lev(k,:), ...
                    'MarkerFaceColor', C.lev(k,:), 'MarkerEdgeColor', C.lev(k,:), ...
                    'LineWidth', 1.0, 'CapSize', 8, 'MarkerSize', 7, 'HandleVisibility','off');
            end
            hDay(j) = plot(ax, nan, nan, mk{j}, 'Color', 'k', 'MarkerFaceColor', 'w');
        end
        yline(ax, 0, '-', 'Color', [0 0 0], 'LineWidth', 1.0, 'HandleVisibility','off');
        ylim(ax, [-120 120]);  yticks(ax, -100:20:100);  xlim(ax, xl);
        xlabel(ax, '{\it p}CO_2 [\muatm]');
        title(ax, titles{p});
        hLev = gobjects(1,4);
        for k = 1:4
            hLev(k) = plot(ax, nan, nan, 's', 'MarkerFaceColor', C.lev(k,:), 'MarkerEdgeColor', C.lev(k,:));
        end
        legend(ax, [hDay hLev], [cellstr(datestr(S.days(idx), 'dd mmmm')).', C.names], ...
            'Location', 'northeast', 'FontSize', 8);
        if p == 1
            ylabel(ax, 'Height / depth relative to sea surface [cm]');
        end
    end
end

function C = levelColours()
    C.lev   = [0.50 0.50 0.50;     % Air100
               0.00 0.00 0.00;     % NSA20
               0.00 0.75 0.75;     % NSL20
               0.10 0.30 0.65];    % Sea100
    C.names = {'Air_{100}','NSA_{20}','NSL_{20}','Sea_{100}'};
    C.line  = [0.55 0.55 0.55];
end
