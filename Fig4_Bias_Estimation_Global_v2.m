function R = Fig4_Bias_Estimation_Global(T)
%BIAS_ESTIMATION_GLOBAL  Section 2.5 - Bias from Near-surface dpCO2 to regional/global scale.
%
%   Quantifies the air-sea CO2 flux error introduced when the Near-surface
%   (NSA-NSL) pCO2 gradient is ignored and only the Meter-scale (Air-Ocean)
%   gradient is used, then scales that error to regional (coastal) and global
%   (open-ocean) estimates by weighting with the slick spatial-coverage
%   frequencies of Romano (1996), following Mustaffa et al. (2020).
%
%   FLUX CONVENTION:
%       F = k * K0 * dpCO2 ,   dpCO2 = pCO2(water) - pCO2(air)   [outgassing +]
%       Meter-scale  : dpCO2 = OCN - ATM        (OCN pooled, as in Fig3_CO2Flux)
%       Near-surface : dpCO2 = NSL - NSA
%       F in mmol m-2 d-1.
%
%   BIAS DEFINITION (manuscript Eq. 2.5):
%       fluxBias = F_NearSurface - F_MeterScale
%       Bias%    = |fluxBias| / |F_NearSurface| * 100
%       weighted : Bias% * coverage      (open ocean 11%, coastal 30%)
%
%   References: Weiss (1974); Wanninkhof (2014); Romano (1996); Mustaffa et al. (2020).

    % ================================================================
    % CONSTANTS
    % ================================================================
    k_ms      = 1.0e-4;                                  % [m s-1]  = 36 cm/h
    K0        = 33;                                      % [mol m-3 atm-1]
    slickDays = [datetime(2024,7,27) datetime(2024,7,29)];
    covOpen   = 0.11;                                    % open-ocean slick coverage (Romano 1996)
    covCoast  = 0.30;                                    % coastal    slick coverage (Romano 1996)
    ocnMode   = 'pooled';                                % 'pooled' (mean OCN_S,OCN_G) or 'sniffle' (OCN_S only)

    % ---------------------------------------------- k consistency check
    k_cmh = k_ms * 3600 * 100;                           % m/s -> cm/h
    fprintf('k = %.3g m s-1  (= %.1f cm h-1) ;  K0 = %g mol m-3 atm-1\n', k_ms, k_cmh, K0);

    if abs(k_cmh - 15.7) > 1
        warning(['k here is %.1f cm h-1, but the Methods text states 15.7 cm h-1. ' ...
                 'ABSOLUTE fluxes scale with k (Bias%% does not). Reconcile text and code.'], k_cmh);
    end

    if ~isdatetime(T.Time), T.Time = datetime(T.Time); end

    % ---------------------------------------------- gradients & fluxes
    if strcmpi(ocnMode,'sniffle')
        pOCN = T.pCO2_OCN_S(:);
    else
        % Use nanmean for robust pooling when OCN_S and OCN_G have different valid counts
        pOCN = nanmean([T.pCO2_OCN_S(:), T.pCO2_OCN_G(:)], 2);
    end

    dP_MS = pOCN       - T.pCO2_ATM;                     % Meter-scale gradient [uatm]
    dP_NS = T.pCO2_NSL - T.pCO2_NSA;                     % Near-surface gradient [uatm]

    F_MS = flux_from_dp(dP_MS, k_ms, K0);                % mmol m-2 d-1
    F_NS = flux_from_dp(dP_NS, k_ms, K0);

    % ---------------------------------------------- per-day means (slick days)
    dayTag = dateshift(T.Time,'start','day');
    nD = numel(slickDays);
    [FMS_day, FNS_day, FMS_sd, FNS_sd] = deal(nan(nD,1));
    [bias_day, biasPct_day, biasPct_sd_day] = deal(nan(nD,1));

    for i = 1:nD
        m = dayTag == dateshift(slickDays(i),'start','day') & isfinite(F_MS) & isfinite(F_NS);
        
        FMS_day(i) = mean(F_MS(m),'omitnan');  
        FMS_sd(i) = std(F_MS(m),'omitnan');
        FNS_day(i) = mean(F_NS(m),'omitnan');  
        FNS_sd(i) = std(F_NS(m),'omitnan');
        
        bias_day(i)    = FNS_day(i) - FMS_day(i);                    % Near - Meter [mmol m-2 d-1]
        biasPct_day(i) = abs(bias_day(i)) / abs(FNS_day(i)) * 100;   % per-day Bias% [%]
        
        % Propagate uncertainty in Bias% from flux uncertainties
        if abs(FNS_day(i)) > 1e-6  % avoid division by near-zero
            biasPct_sd_day(i) = sqrt((FMS_sd(i)/abs(FNS_day(i)))^2 + (FNS_sd(i)/abs(FNS_day(i)))^2) * 100;
        else
            biasPct_sd_day(i) = nan;
        end
    end

    % ---------------------------------------------- aggregate + weighting
    R.k_ms=k_ms; R.k_cmh=k_cmh; R.K0=K0; R.ocnMode=ocnMode;
    R.slickDays          = slickDays(:);
    R.F_MeterScale_day   = FMS_day;   R.F_MeterScale_sd_day  = FMS_sd;
    R.F_NearSurface_day  = FNS_day;   R.F_NearSurface_sd_day = FNS_sd;
    R.fluxBias_day       = bias_day;      % mmol m-2 d-1
    R.biasPct_day        = biasPct_day;   % %

    R.F_MeterScale_mean  = mean(FMS_day,'omitnan');
    R.F_NearSurface_mean = mean(FNS_day,'omitnan');
    R.fluxBias_mean      = mean(bias_day,'omitnan');
    R.fluxBias_sd        = std(bias_day,'omitnan');
    
    % Bias% from mean fluxes (primary result)
    if abs(R.F_NearSurface_mean) > 1e-6
        R.biasPct = abs(R.fluxBias_mean) / abs(R.F_NearSurface_mean) * 100;
        % Propagate uncertainty
        R.biasPct_sd = sqrt((R.F_MeterScale_sd_day(1)/abs(R.F_NearSurface_mean))^2 + ...
                            (R.F_NearSurface_sd_day(1)/abs(R.F_NearSurface_mean))^2) * 100;
    else
        R.biasPct = nan;
        R.biasPct_sd = nan;
    end

    R.covOpen  = covOpen;   R.covCoast = covCoast;
    R.bias_global_openocean    = R.biasPct    * covOpen;
    R.bias_global_openocean_sd = R.biasPct_sd * covOpen;
    R.bias_regional_coastal    = R.biasPct    * covCoast;
    R.bias_regional_coastal_sd = R.biasPct_sd * covCoast;

    % ---------------------------------------------- report
    fprintf('\n--- Section 2.5  Bias estimation (Slick Scenarios, ocnMode=%s) ---\n', ocnMode);
    for i = 1:nD
        fprintf('  %s : F_Meter = %+6.1f | F_Near = %+6.1f | bias = %+6.1f | Bias%% = %5.1f +/- %.1f %%\n', ...
            datestr(slickDays(i),'dd mmm'), FMS_day(i), FNS_day(i), bias_day(i), biasPct_day(i), biasPct_sd_day(i));
    end
    fprintf('  --------------------------------------------------------------\n');
    fprintf('  mean Meter-scale  flux : %+.1f +/- %.1f mmol m-2 d-1\n', R.F_MeterScale_mean, mean(FMS_sd,'omitnan'));
    fprintf('  mean Near-surface flux : %+.1f +/- %.1f mmol m-2 d-1\n', R.F_NearSurface_mean, mean(FNS_sd,'omitnan'));
    fprintf('  flux bias (mean+/-SD)  : %+.1f +/- %.1f mmol m-2 d-1\n', R.fluxBias_mean, R.fluxBias_sd);
    fprintf('  Bias%% (from mean flux) : %.0f +/- %.0f %%\n', R.biasPct, R.biasPct_sd);
    fprintf('  weighted -> open ocean (global)  : %.0f +/- %.0f %%  (coverage %.0f%%)\n', ...
        R.bias_global_openocean, R.bias_global_openocean_sd, 100*covOpen);
    fprintf('  weighted -> coastal   (regional) : %.0f +/- %.0f %%  (coverage %.0f%%)\n', ...
        R.bias_regional_coastal, R.bias_regional_coastal_sd, 100*covCoast);
    if nD < 3
        fprintf('  NOTE: n = %d slick days; SD is a spread, not a robust uncertainty.\n', nD);
    end
end

% ======================================================================
% helper: flux conversion (uatm -> mmol m-2 d-1)
% ======================================================================
function F = flux_from_dp(dp_uatm, k_ms, K0)
    % F = k * K0 * dpCO2
    % k    : transfer velocity [m s-1]
    % K0   : solubility [mol m-3 atm-1]
    % dpCO2: pCO2 gradient [uatm]
    
    dp_atm = dp_uatm * 1e-6;      % uatm -> atm
    F = k_ms .* K0 .* dp_atm;     % [m s-1] * [mol m-3 atm-1] * [atm] = [mol m-3 s-1]
    F = F * 1000 * 86400;         % -> [mmol m-3 d-1]
    
    % NOTE: This gives mmol m-3 d-1, not mmol m-2 d-1. 
    % If you need m-2, multiply by a boundary layer thickness [m].
end