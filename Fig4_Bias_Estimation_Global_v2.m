function B = Fig4_Bias_Estimation_Global_v2(R)
%FIG4_BIAS_ESTIMATION_GLOBAL_V2  Section 2.4 / 3.4: discrepancy between the
%near-surface and meter-scale fluxes, scaled by slick coverage.
%
%   B = Fig4_Bias_Estimation_Global_v2(R)   R = output of Table1_Recalc
%
%   Uses the daily fluxes of Table 1 (no separate flux calculation here):
%       D%_day   = |F_NS - F_MS| / |F_NS| * 100
%       D%_slick = |mean_slick(F_NS - F_MS)| / |mean_slick(F_NS)| * 100
%       weighted = D%_slick * coverage (open ocean 11%, coastal 30%; Romano 1996)
%   Because k and K0 are identical in both fluxes, D% does not depend on them.
%   Units: F = k[m s-1] * K0[mol m-3 atm-1] * dpCO2[atm] = mol m-2 s-1,
%   converted to mmol m-2 d-1.

    S  = R.settings;
    sl = S.isSlick;

    B.days        = S.days;
    B.F_MS        = R.FMS;
    B.F_NS        = R.FNS;
    B.diff        = R.FNS - R.FMS;
    B.Dpct_day    = R.Dpct_day;
    B.ratio_NS_MS = R.ratio_NS_MS;
    B.Dpct_slick  = R.Dpct_slick;
    B.Dpct_open   = R.Dpct_open;
    B.Dpct_coast  = R.Dpct_coast;

    fprintf('\n===== Section 3.4: flux discrepancy =====\n');
    for i = 1:numel(S.days)
        fprintf('  %s (%s): F_MS = %+6.1f | F_NS = %+6.1f | F_NS - F_MS = %+6.1f | D%% = %5.0f%% | F_NS/F_MS = %6.1f\n', ...
            datestr(S.days(i),'dd mmm'), ternary(sl(i),'slick','non-slick'), ...
            R.FMS(i), R.FNS(i), B.diff(i), R.Dpct_day(i), R.ratio_NS_MS(i));
    end
    fprintf('  Slick days: mean F_MS = %+.1f, mean F_NS = %+.1f, mean (F_NS - F_MS) = %+.1f mmol m-2 d-1\n', ...
        mean(R.FMS(sl)), mean(R.FNS(sl)), mean(B.diff(sl)));
    fprintf('  D%% (slick) = %.0f%%  ->  open ocean (x%.2f) = %.0f%%,  coastal (x%.2f) = %.0f%%\n', ...
        R.Dpct_slick, S.covOpen, R.Dpct_open, S.covCoast, R.Dpct_coast);
    fprintf('  NOTE: n = %d slick days; these are illustrative values, not a correction.\n', sum(sl));
end

function out = ternary(c, a, b)
    if c, out = a; else, out = b; end
end
