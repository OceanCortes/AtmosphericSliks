function D = Fig1e_MeanDifferenceProfile_NonSlick_vs_Slick_v1(R)
%FIG1E_MEANDIFFERENCEPROFILE_NONSLICK_VS_SLICK_V1  Manuscript Figure 3c:
%mean pCO2 difference (slick - non-slick) at each level.
%
%   D = Fig1e_MeanDifferenceProfile_NonSlick_vs_Slick_v1(R)
%   R = output of Table1_Recalc (same daily means and SDs as Table 1)
%
%   How the panel is computed (the days are NOT paired):
%     scenario mean  = mean of the two daily means of that scenario
%     scenario SD    = pooled SD = sqrt( mean(SD_day^2) + var(daily means) )
%                      (within-day variability + between-day spread)
%     difference     = mean(slick) - mean(non-slick)
%     error bar      = SD_delta = sqrt(SD_slick^2 + SD_non-slick^2)

    S  = R.settings;
    sl = S.isSlick;
    z  = [100 20 -20 -100];                        % height relative to sea surface [cm]
    MU = [R.Air; R.NSA; R.NSL; R.Sea];
    SD = [R.Air_sd; R.NSA_sd; R.NSL_sd; R.Sea_sd];

    scen = @(m) deal(mean(MU(:,m),2), sqrt(mean(SD(:,m).^2,2) + var(MU(:,m),0,2)));
    [muS, sdS] = scen(sl);
    [muN, sdN] = scen(~sl);
    D.z = z;  D.delta = (muS - muN).';  D.sd = sqrt(sdS.^2 + sdN.^2).';

    col = [0.50 0.50 0.50; 0 0 0; 0 0.75 0.75; 0.10 0.30 0.65];
    names = {'Air_{100}','NSA_{20}','NSL_{20}','Sea_{100}'};

    figure('Color','w','Name','Figure 3c - slick minus non-slick'); hold on; box on;
    xline(0, '-k', 'LineWidth', 1.2);  yline(0, '-k', 'LineWidth', 1.0);
    h = gobjects(1,4);
    for k = 1:4
        plot([0 D.delta(k)], [z(k) z(k)], '-', 'Color', [col(k,:) 0.5], 'LineWidth', 6, 'HandleVisibility','off');
        h(k) = errorbar(D.delta(k), z(k), D.sd(k), 'horizontal', 'o', 'Color', col(k,:), ...
            'MarkerFaceColor', col(k,:), 'MarkerEdgeColor', col(k,:), ...
            'LineWidth', 1.2, 'CapSize', 8, 'MarkerSize', 7);
    end
    ylim([-120 120]);  yticks(-100:20:100);
    m = max(abs([D.delta + D.sd, D.delta - D.sd]));
    xlim([-1 1] * ceil(1.1*m/10)*10);
    legend(h, names, 'Location', 'southeast', 'FontSize', 8);
    title('c) Slick - non-slick');
    ylabel('Height / depth relative to sea surface [cm]');
    xlabel('\Delta{\it p}CO_2 between scenarios [\muatm]');

    fprintf('\nFigure 3c (slick - non-slick, unpaired days):\n');
    for k = 1:4
        fprintf('  %-10s %+7.1f +/- %.1f uatm\n', strrep(strrep(names{k},'_{',''),'}',''), D.delta(k), D.sd(k));
    end
end
