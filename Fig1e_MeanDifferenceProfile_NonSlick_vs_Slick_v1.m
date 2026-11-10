function Fig1e_MeanDifferenceProfile_NonSlick_vs_Slick_v1(T, nonSlickDays, slickDays)
% Scenario contrast profile of mean pCO2 by depth using bars from 0 to Δmean.
% Δmean = mean(Slick) - mean(Non-slick)
% Error bars: SD of difference, SDΔ = sqrt(SD_slick^2 + SD_non^2)
%
% Depths (cm): 100, 20, 20, 100 (ATM, NSA, NSL, OCN)
% OCN pooled from Sniffle and Glaucus.

    arguments
        T table
        nonSlickDays datetime
        slickDays datetime
    end

    % ---------------- Global font ----------------
    set(groot, 'defaultAxesFontName', 'Calibri');
    set(groot, 'defaultTextFontName', 'Calibri');

    % ---------------- Depths ----------------
    z = [-100 -20 20 100];

    % ---------------- Colours (depth-consistent) ----------------
    C.ATM = [0.5 0.5 0.5];             
    C.NSA = [0 0 0];    
    C.NSL = [0 0.75 0.75];       
    C.OCN = [0.00 0.20 0.55];    

    % ---------------- Stats ----------------
    S_non = local_groupStats_meanSD(T, nonSlickDays);
    S_slk = local_groupStats_meanSD(T, slickDays);

    % Difference (Slick − Non-slick)
    dMu = S_slk.mu - S_non.mu;

    % SD of difference
    dSD = sqrt(S_slk.sd.^2 + S_non.sd.^2);

    % Axis limits
    maxAbs = max(abs([dMu(:); dMu(:)+dSD(:); dMu(:)-dSD(:)]), [], 'omitnan');
    if ~isfinite(maxAbs) || maxAbs == 0
        maxAbs = 10;
    end
    xMax = ceil(1.2 * maxAbs / 10) * 10;

    % ---------------- Plot ----------------
    figure('Color','w'); hold on; box on;

    xline(0, '-k', 'LineWidth', 1.2);
    yline(0, '-k', 'LineWidth', 1.0);

    for k = 1:numel(z)
        if ~isfinite(dMu(k)), continue; end

        col = local_depthColour(z(k), C);

        % Bar from 0 to Δmean
        plot([0 dMu(k)], [z(k) z(k)], '-', ...
            'Color', [col 0.5], 'LineWidth', 6);

        % Error bar
        errorbar(dMu(k), z(k), dSD(k), 'horizontal', 'o', ...
            'Color', col, ...
            'MarkerFaceColor', col, ...
            'MarkerEdgeColor', col, ...
            'LineWidth', 1.2, ...
            'CapSize', 8, ...
            'MarkerSize', 7);
    end

    % ---------------- Axes formatting ----------------
    ax = gca;
    set(ax,'YDir','reverse');
    ylim([-110 110]);
    yticks(-120:20:120);

    % 🔥 Remove minus sign from Y tick labels
    yt = yticks;
    yticklabels(string(abs(yt)));

    xlim([-50 xMax]);

    title('{\it p}CO_2 differences between Scenarios');
    ylabel('Depth [cm]');
    xlabel('{\it p}CO_2 [\muatm]');

    grid off;

end

% =====================================================================
% Helpers
% =====================================================================

function S = local_groupStats_meanSD(T, daysVec)
% Pool all values across all provided days, then compute mean and SD by depth.

    pool = cell(4,1); % ATM, NSA, NSL, OCN

    for d0 = daysVec(:)'
        d   = dateshift(d0,'start','day');
        idx = T.Time >= d & T.Time < d + days(1);

        X = {
            T.pCO2_ATM(idx)
            T.pCO2_NSA(idx)
            T.pCO2_NSL(idx)
            [T.pCO2_OCN_S(idx); T.pCO2_OCN_G(idx)]
        };

        for k = 1:4
            x = X{k};
            x = x(~isnan(x));
            if isempty(x), continue; end
            pool{k} = [pool{k}; x(:)];
        end
    end

    S.mu = NaN(1,4);
    S.sd = NaN(1,4);

    for k = 1:4
        x = pool{k};
        if isempty(x), continue; end
        S.mu(k) = mean(x,'omitnan');
        S.sd(k) = std(x,'omitnan');
    end
end

function col = local_depthColour(z, C)
    if z == -100
        col = C.ATM;
    elseif z == -20
        col = C.NSA;
    elseif z == 20
        col = C.NSL;
    else
        col = C.OCN;
    end
end