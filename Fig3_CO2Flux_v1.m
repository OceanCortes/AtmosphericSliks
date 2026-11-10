function Fig3_CO2Flux_v1(R)
%FIG3_CO2FLUX_V1  Manuscript Figure 4: CO2 fluxes of the (i) meter-scale and
%(ii) near-surface approaches, (a) non-slick and (b) slick scenarios.
%
%   Fig3_CO2Flux_v1(R)   R = output of Table1_Recalc
%
%   Light points : 1.5-min bin fluxes, F = k*K0*dpCO2 (the bins of Table 1)
%   Large points : daily mean +/- 1 SD (identical to the Table 1 fluxes)
%   Positive values = sea-to-air flux.
%   The constants are NOT defined here: they come from BASS_pCO2_Settings
%   through R, so this figure can never disagree with Table 1.

    S = R.settings;
    colMS = [0.35 0.35 0.35];
    colNS = [0.00 0.45 0.70];
    light = @(c) c + 0.60*(1 - c);

    fig = figure('Color','w','Name','Figure 4 - CO2 flux (meter-scale vs near-surface)');
    tl  = tiledlayout(fig, 1, 2, 'TileSpacing','compact', 'Padding','compact');
    groups = {find(~S.isSlick), find(S.isSlick)};
    titles = {'a) Non-slick', 'b) Slick'};
    ax = gobjects(1,2);

    for p = 1:2
        ax(p) = nexttile(tl, p); hold(ax(p),'on'); box(ax(p),'on');
        idx = groups{p};
        for j = 1:numel(idx)
            i = idx(j);
            B = R.bins(i);
            % position each day on its own slot, time-of-day within the slot
            xMS = j - 0.45 + 0.9*mod(datenum(B.tMS), 1);
            xNS = j - 0.45 + 0.9*mod(datenum(B.tNS), 1);
            plot(ax(p), xMS, B.FMS, 'o', 'MarkerSize', 3, 'MarkerFaceColor', light(colMS), ...
                'MarkerEdgeColor', 'none', 'HandleVisibility', 'off');
            plot(ax(p), xNS, B.FNS, 'o', 'MarkerSize', 3, 'MarkerFaceColor', light(colNS), ...
                'MarkerEdgeColor', 'none', 'HandleVisibility', 'off');
            errorbar(ax(p), j - 0.06, R.FMS(i), R.FMS_sd(i), 'o', 'Color', colMS, ...
                'MarkerFaceColor', colMS, 'MarkerSize', 8, 'LineWidth', 1.2, 'HandleVisibility', 'off');
            errorbar(ax(p), j + 0.06, R.FNS(i), R.FNS_sd(i), 'o', 'Color', colNS, ...
                'MarkerFaceColor', colNS, 'MarkerSize', 8, 'LineWidth', 1.2, 'HandleVisibility', 'off');
        end
        yline(ax(p), 0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
        ax(p).XTick = 1:numel(idx);
        ax(p).XTickLabel = cellstr(datestr(S.days(idx), 'dd mmm'));
        xlim(ax(p), [0.5 numel(idx) + 0.5]);
        title(ax(p), titles{p});
    end
    linkaxes(ax, 'y');
    ax(2).YTickLabel = {};
    ylabel(ax(1), 'CO_2 flux [mmol m^{-2} d^{-1}]');
    xlabel(tl, 'July 2024');

    hMS = plot(ax(1), nan, nan, 'o', 'Color', colMS, 'MarkerFaceColor', colMS);
    hNS = plot(ax(1), nan, nan, 'o', 'Color', colNS, 'MarkerFaceColor', colNS);
    legend(ax(1), [hMS hNS], {'(i) Meter-scale','(ii) Near-surface'}, 'Location', 'southwest');

    annotation(fig, 'textbox', [0.01 0.0 0.9 0.04], 'EdgeColor', 'none', 'FontSize', 8, ...
        'String', sprintf('k = %.1f cm h^{-1}, K_0 = %.1f mol m^{-3} atm^{-1}; Sea_{100}: %s', ...
        S.k_cmh, R.K0, S.sea100));
end
