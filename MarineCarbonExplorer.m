function MarineCarbonExplorer()
%% Marine Carbon System Explorer — BASS 2024 / Mesocosm
%
% Interactive interface implementing methods from:
%
%   MS2 – Cortés-Espinoza et al. (in prep.)
%        "Air-Sea CO2 Fluxes Are Biased by Near-surface Atmospheric Slicks"
%        § Two ΔpCO2 approaches  (Meter-scale ±100 cm | Near-surface ±20 cm)
%        § CO2 Flux Bias = F_NearSurface − F_MeterScale
%        § F = k · K0 · ΔpCO2   (Wanninkhof 2014)
%        § k = 15.7 cm h⁻¹ (constant; Methods 2.3 — same as BASS_pCO2_Settings)
%        § K0 = 33 mol m⁻³ atm⁻¹ (Weiss 1974, N.Sea summer)
%        § Bin: 1.5-minute aggregation
%
%   MS1 – Cortés-Espinoza et al. (in prep.)
%        "Organic Alkalinity covaried with pH in the SML"
%        § ΔpH = pH_SML − pH_ULW
%        § OA Enrichment Factor EF = OA_SML / OA_ULW
%        § Deffeyes diagram: NDIC vs NTA vectors

clc;

%% ════════════════════════════════════════════════════
%%  USER SETTINGS
%% ════════════════════════════════════════════════════
% ── The script searches these filenames in order (same folder as this .m file).
% ── If none is found it opens a file-browser dialog automatically.
% ── Needs ONE file holding all four levels: use the merged file written by
% ── NearSurface_pCO2_Study.m (pCO2_GlauSniff.xlsx, 60-s tolerance, no gap filling).
% ── For the published numbers use Table1_Recalc.m; this explorer is for browsing.
DATA_FILE = mce_findFile({ ...
    'pCO2_GlauSniff.xlsx'});

%  Physical constants (MS2 §2.4 — kept constant to isolate ΔpCO2 effect)
k_cmhr   = 15.7;  % gas transfer velocity [cm h⁻¹] (Methods 2.3)
K0_const = 33;    % CO2 solubility  [mol m⁻³ atm⁻¹]
BIN_SEC  = 90;    % 1.5-minute aggregation bins [s]

% Force exact column names (set true if auto-detection fails)
FORCE = false;
% Sign convention of the column names: m = above the surface (air), p = below (water)
FRC.time   = 'Time';
FRC.air100 = 'pCO2_ATM';      % Air 100 cm — Sniffle   (raw: pCO2_m100_S)
FRC.nsa20  = 'pCO2_NSA';      % NSA  20 cm — Glaucus   (raw: pCO2_m20_G)
FRC.nsl20  = 'pCO2_NSL';      % NSL  20 cm — Glaucus   (raw: pCO2_p20_G)
FRC.sea100 = 'pCO2_OCN_S';    % Sea 100 cm — Sniffle   (raw: pCO2_p100_S)
FRC.u10    = 'Wind_U10';       % Wind speed at 10 m [m s⁻¹]
FRC.phSML  = 'pH_00_G';        % pH SML
FRC.phULW  = 'pH_m20_G';       % pH ULW

%% ════════════════════════════════════════════════════
%%  LOAD DATA
%% ════════════════════════════════════════════════════
[T, t, vn] = mce_load(DATA_FILE);

if FORCE
    col = FRC;
else
    % m = above the surface (air), p = below (water) — see README
    col.air100 = mce_pick(vn,{'pCO2_ATM','pCO2_m100_S','Air100','pCO2_air100','pCO2_m100'});
    col.nsa20  = mce_pick(vn,{'pCO2_NSA','pCO2_m20_G','NSA20','pCO2_nsa20','pCO2_m20'});
    col.nsl20  = mce_pick(vn,{'pCO2_NSL','pCO2_p20_G','NSL20','pCO2_nsl20','pCO2_p20'});
    col.sea100 = mce_pick(vn,{'pCO2_OCN_S','pCO2_p100_S','Sea100','pCO2_sea100','pCO2_p100'});
    col.u10    = mce_pick(vn,{'Wind_U10','U10','wind_u10','WindSpeed','WS10'});
    col.phSML  = mce_pick(vn,{'pH_00_G','pH_00','pH_SML','pHSML'});
    col.phULW  = mce_pick(vn,{'pH_m20_G','pH_m20','pH_ULW','pHULW','pH_40cm'});
end

% Guard: at least pCO2 columns must exist
req = {col.air100, col.nsa20, col.nsl20, col.sea100};
miss = req(cellfun(@isempty, req));
if ~isempty(miss)
    error(['Required pCO2 columns not found.\nMissing: %s\n' ...
        'Set FORCE=true and fill FRC.* names, or check column headers.'], ...
        strjoin(miss,', '));
end

% Day list and scenario classification
dayList   = unique(dateshift(t,'start','day'));
nDays     = numel(dayList);
dayLabels = cellstr(datestr(dayList,'dd mmm yyyy'));
scenVec   = mce_scenario(T, t, dayList, col.u10);

%% ════════════════════════════════════════════════════
%%  COLOUR PALETTE
%% ════════════════════════════════════════════════════
C.bg     = [0.10 0.12 0.17];
C.panel  = [0.15 0.18 0.24];
C.text   = [0.92 0.93 0.95];
C.grid   = [0.28 0.32 0.40];
C.air100 = [0.60 0.62 0.65];   % grey
C.nsa20  = [0.95 0.50 0.10];   % orange — Atmospheric Slick
C.nsl20  = [0.20 0.65 0.85];   % sky blue
C.sea100 = [0.10 0.35 0.70];   % deep blue
C.Fms    = [0.65 0.67 0.70];   % meter-scale flux
C.Fns    = [0.20 0.65 0.85];   % near-surface flux
C.bias   = [0.90 0.25 0.25];   % bias / error
C.slick  = [0.95 0.78 0.20];   % amber
C.nosl   = [0.50 0.80 0.50];   % green

%% ════════════════════════════════════════════════════
%%  BUILD UI FIGURE
%% ════════════════════════════════════════════════════
fig = uifigure(...
    'Name',  'Marine Carbon System Explorer  |  BASS 2024', ...
    'Position', [30 30 1440 880], ...
    'Color', C.bg, ...
    'Resize','on');

% ─── Title bar ───────────────────────────────────────────────────────
tt = uitextarea(fig,'Position',[6 848 1428 28], ...
    'Value',{'Marine Carbon System Explorer  |  BASS Field Campaign & Mesocosm  |  North Sea – Helgoland, July 2024'}, ...
    'FontSize',12,'FontWeight','bold','FontColor',C.text, ...
    'BackgroundColor',C.bg,'Editable','off','HorizontalAlignment','center');  %#ok<NASGU>

% ─── Left sidebar ───────────────────────────────────────────────────
LP = uipanel(fig,'Position',[6 6 192 840],'BackgroundColor',C.panel,'BorderType','none');

% Section: Day selector
mce_label(LP,'SELECT DAY',10,806,172,18,11,C.slick,true);
dayLbx = uilistbox(LP,'Items',dayLabels,'Position',[8 580 174 222], ...
    'BackgroundColor',C.bg,'FontColor',C.text,'FontSize',10);
if nDays > 0
    dayLbx.Value = dayLabels{1};
end

% Scenario badge
scenLbl = uitextarea(LP,'Value',{'Scenario: —'},'Position',[8 545 174 32], ...
    'BackgroundColor',C.bg,'FontColor',C.slick,'FontSize',10,'Editable','off');

% Section: Visibility toggles
mce_label(LP,'DISPLAY',10,518,172,18,9,C.text,true);
chk_air = uicheckbox(LP,'Text','Air₁₀₀ (Sniffle)',  'Value',1,'Position',[8 496 174 20],'FontColor',C.air100,'FontSize',9);
chk_nsa = uicheckbox(LP,'Text','NSA₂₀ (Atm.Slick)', 'Value',1,'Position',[8 474 174 20],'FontColor',C.nsa20,'FontSize',9);
chk_nsl = uicheckbox(LP,'Text','NSL₂₀ (NearSurf.)', 'Value',1,'Position',[8 452 174 20],'FontColor',C.nsl20,'FontSize',9);
chk_sea = uicheckbox(LP,'Text','Sea₁₀₀ (Sniffle)',  'Value',1,'Position',[8 430 174 20],'FontColor',C.sea100,'FontSize',9);
chk_Fms = uicheckbox(LP,'Text','Flux Meter-scale',   'Value',1,'Position',[8 406 174 20],'FontColor',C.Fms,'FontSize',9);
chk_Fns = uicheckbox(LP,'Text','Flux Near-surface',  'Value',1,'Position',[8 384 174 20],'FontColor',C.Fns,'FontSize',9);
chk_bia = uicheckbox(LP,'Text','Flux Bias (error)',  'Value',1,'Position',[8 362 174 20],'FontColor',C.bias,'FontSize',9);

% Section: Parameters
mce_label(LP,'FLUX PARAMETERS  (MS2 §2.4)',10,336,172,18,9,C.text,true);
paramBox = uitextarea(LP,'Position',[8 206 174 126],'BackgroundColor',C.bg, ...
    'FontColor',[0.65 0.85 0.65],'FontSize',9,'Editable','off','Value',{ ...
    sprintf('k  = %g cm h⁻¹',   k_cmhr), ...
    sprintf('K₀ = %g mol m⁻³ atm⁻¹', K0_const), ...
    'Bin = 1.5 min  (90 s)', ...
    '', ...
    'F = k · K₀ · ΔpCO₂', ...
    'ΔpCO₂(i)  = Sea₁₀₀ − Air₁₀₀', ...
    'ΔpCO₂(ii) = NSL₂₀  − NSA₂₀', ...
    '', ...
    'BIAS = F_NS − F_MS'});  %#ok<NASGU>

% Export button
uibutton(LP,'Text','Export 1.5-min table (xlsx)', ...
    'Position',[8 172 174 30],'FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',[0.20 0.35 0.30],'FontColor',C.text, ...
    'ButtonPushedFcn',@(~,~) doExport());

% Section: Cursor values
mce_label(LP,'CURSOR  (drag over plot)',10,148,172,18,9,C.text,true);
crsBox = uitextarea(LP,'Position',[8 6 174 138],'BackgroundColor',C.bg, ...
    'FontColor',[0.80 0.88 0.95],'FontSize',8.5,'Editable','off', ...
    'Value',{'← drag cursor over any plot'});

%% ── Four axes (right side) ──────────────────────────────────────────
axX  = 206; axW = 1228;
% [bottom, height] for each panel
AP = [695 140;  % ax1: pCO2
      542 142;  % ax2: CO2 flux
      355 172;  % ax3: CO2 flux bias
      175 168]; % ax4: wind / U10

ax = gobjects(4,1);
for ai = 1:4
    ax(ai) = uiaxes(fig,'Position',[axX AP(ai,1) axW AP(ai,2)]);
    mce_styleax(ax(ai), C);
end
ylabel(ax(1),'pCO₂  (µatm)',         'Color',C.text,'FontSize',10);
ylabel(ax(2),'CO₂ Flux  (mmol m⁻² d⁻¹)', 'Color',C.text,'FontSize',10);
ylabel(ax(3),'Flux Bias  (mmol m⁻² d⁻¹)','Color',C.bias,'FontSize',10);
ylabel(ax(4),'U₁₀  (m s⁻¹)',         'Color',C.text,'FontSize',10);
xlabel(ax(4),'Time  (UTC)','Color',C.text,'FontSize',10);

% Cursor vertical lines (one per axes)
CL = gobjects(4,1);
for ai = 1:4
    hold(ax(ai),'on');
    CL(ai) = plot(ax(ai),[NaT NaT],[0 0],'--', ...
        'Color',[1 1 1 0.55],'LineWidth',1.3,'HitTest','off','PickableParts','none');
    hold(ax(ai),'off');
end

%% ════════════════════════════════════════════════════
%%  APP STATE
%% ════════════════════════════════════════════════════
S.T=T; S.t=t; S.col=col; S.C=C;
S.dayList=dayList; S.dayLabels=dayLabels; S.scenVec=scenVec;
S.binSec=BIN_SEC;
S.k_ms  = k_cmhr / 100 / 3600;    % m s⁻¹
S.K0    = K0_const;
S.dayIdx = 1;
% Computed per-day (filled on first draw)
S.tb=[]; S.pAir=[]; S.pNSA=[]; S.pNSL=[]; S.pSea=[];
S.u10=[]; S.F_ms=[]; S.F_ns=[]; S.bias=[];
S.dpms=[]; S.dpns=[];

%% ════════════════════════════════════════════════════
%%  INITIAL DRAW
%% ════════════════════════════════════════════════════
doDay(1);

%% ════════════════════════════════════════════════════
%%  CALLBACKS
%% ════════════════════════════════════════════════════
dayLbx.ValueChangedFcn = @(src,~) onDayChange(src);
for ch = {chk_air,chk_nsa,chk_nsl,chk_sea,chk_Fms,chk_Fns,chk_bia}
    ch{1}.ValueChangedFcn = @(~,~) redraw();
end
fig.WindowButtonMotionFcn = @onMotion;

%% ════════════════════════════════════════════════════
%%  NESTED: compute & draw a day
%% ════════════════════════════════════════════════════
    function doDay(idx)
        S.dayIdx = idx;
        d    = S.dayList(idx);
        scen = S.scenVec{idx};

        % Scenario badge colour
        if strcmpi(scen,'Slick')
            scenLbl.FontColor = S.C.slick;
        else
            scenLbl.FontColor = S.C.nosl;
        end
        scenLbl.Value = {sprintf('Scenario: %s', scen), ...
            ternary(strcmpi(scen,'Slick'), 'U₁₀ < 4 m s⁻¹  (calm)', 'U₁₀ ≥ 4 m s⁻¹')};

        % Extract raw data for this day
        mask = S.t >= d & S.t < d + days(1);
        if sum(mask) < 5, return; end
        td   = S.t(mask);

        pA = mce_getcol(S.T, S.col.air100, mask);
        pN = mce_getcol(S.T, S.col.nsa20,  mask);
        pL = mce_getcol(S.T, S.col.nsl20,  mask);
        pS = mce_getcol(S.T, S.col.sea100, mask);
        u  = mce_getcol(S.T, S.col.u10,    mask);

        % 1.5-min bins
        [tb,pAb,pNb,pLb,pSb,ub] = mce_bin(td, S.binSec, pA,pN,pL,pS,u);

        % ΔpCO2 & flux (MS2 §2.4)
        dpms = pSb - pAb;   % µatm  Meter-scale
        dpns = pLb - pNb;   % µatm  Near-surface
        conv = 1e-6 * 1000 * 86400;   % µatm→atm, mol→mmol, s→d
        Fms  = S.k_ms .* S.K0 .* dpms .* conv;
        Fns  = S.k_ms .* S.K0 .* dpns .* conv;
        bias = Fns - Fms;

        % Store in state
        S.tb=tb; S.pAir=pAb; S.pNSA=pNb; S.pNSL=pLb; S.pSea=pSb;
        S.u10=ub; S.F_ms=Fms; S.F_ns=Fns; S.bias=bias;
        S.dpms=dpms; S.dpns=dpns;

        drawAllAxes(d, scen);
    end

%% ════════════════════════════════════════════════════
%%  NESTED: draw all 4 axes
%% ════════════════════════════════════════════════════
    function drawAllAxes(d, scen)
        tb   = S.tb;
        pAir = S.pAir; pNSA = S.pNSA; pNSL = S.pNSL; pSea = S.pSea;
        Fms  = S.F_ms; Fns  = S.F_ns; bias = S.bias;
        u10  = S.u10;

        Fms_mn = mean(Fms,'omitnan');
        Fns_mn = mean(Fns,'omitnan');
        bias_mn= mean(bias,'omitnan');
        bias_sd= std(bias,'omitnan');

        %% — AX1: pCO2 time series ——
        cla(ax(1),'reset'); mce_styleax(ax(1),S.C); hold(ax(1),'on');
        if chk_air.Value
            plot(ax(1),tb,pAir,'Color',C.air100,'LineWidth',1.5,'DisplayName','Air₁₀₀  (Sniffle)');
        end
        if chk_nsa.Value
            plot(ax(1),tb,pNSA,'Color',C.nsa20,'LineWidth',2.5,'DisplayName','NSA₂₀  (Atm.Slick – Glaucus)');
        end
        if chk_nsl.Value
            plot(ax(1),tb,pNSL,'Color',C.nsl20,'LineWidth',2.0,'DisplayName','NSL₂₀  (NearSurf. – Glaucus)');
        end
        if chk_sea.Value
            plot(ax(1),tb,pSea,'Color',C.sea100,'LineWidth',1.5,'DisplayName','Sea₁₀₀  (Sniffle)');
        end
        ylabel(ax(1),'pCO₂  (µatm)','Color',C.text,'FontSize',10);
        leg1 = legend(ax(1),'Location','northwest','Orientation','horizontal', ...
            'FontSize',9,'TextColor',C.text,'Color',C.panel);
        leg1.EdgeColor = C.grid;
        ttl = sprintf('pCO₂  |  %s  [%s]', datestr(d,'dd mmm yyyy'), scen);
        title(ax(1),ttl,'Color',C.text,'FontSize',11,'FontWeight','bold');
        ax(1).XTickLabel = {};
        hold(ax(1),'off');

        %% — AX2: CO2 flux ——
        cla(ax(2),'reset'); mce_styleax(ax(2),S.C); hold(ax(2),'on');
        if chk_Fms.Value
            plot(ax(2),tb,Fms,'Color',C.Fms,'LineWidth',2.2, ...
                'DisplayName',sprintf('F Meter-scale (±100 cm)  mean=%.1f',Fms_mn));
        end
        if chk_Fns.Value
            plot(ax(2),tb,Fns,'Color',C.Fns,'LineWidth',2.2, ...
                'DisplayName',sprintf('F Near-surface (±20 cm)  mean=%.1f',Fns_mn));
        end
        yline(ax(2),0,'--','Color',[1 1 1 0.35],'LineWidth',0.9,'HandleVisibility','off');
        ylabel(ax(2),'CO₂ Flux  (mmol m⁻² d⁻¹)','Color',C.text,'FontSize',10);
        leg2 = legend(ax(2),'Location','northwest','Orientation','horizontal', ...
            'FontSize',9,'TextColor',C.text,'Color',C.panel);
        leg2.EdgeColor = C.grid;
        title(ax(2), ...
            sprintf('CO₂ Flux Comparison  |  F_{MS}=%.1f  F_{NS}=%.1f  mmol m⁻² d⁻¹', ...
            Fms_mn, Fns_mn), 'Color',C.text,'FontSize',10);
        ax(2).XTickLabel = {};
        hold(ax(2),'off');

        %% — AX3: CO2 flux BIAS (the "error") ——
        cla(ax(3),'reset'); mce_styleax(ax(3),S.C); hold(ax(3),'on');
        if chk_bia.Value
            % Shaded area: outgassing bias (red) / uptake bias (blue)
            posB = bias; posB(bias < 0) = 0;
            negB = bias; negB(bias > 0) = 0;
            area(ax(3),tb,posB,'FaceColor',[0.85 0.30 0.10],'FaceAlpha',0.30,'EdgeColor','none');
            area(ax(3),tb,negB,'FaceColor',[0.20 0.50 0.80],'FaceAlpha',0.30,'EdgeColor','none');
            plot(ax(3),tb,bias,'Color',C.bias,'LineWidth',2.5, ...
                'DisplayName',sprintf('CO₂ Flux Bias  (mean=%.1f ± %.1f)', bias_mn, bias_sd));
        end
        yline(ax(3),0,'--','Color',[1 1 1 0.35],'LineWidth',0.9,'HandleVisibility','off');
        ylabel(ax(3),'Flux Bias  (mmol m⁻² d⁻¹)','Color',C.bias,'FontSize',10);
        legend(ax(3),'Location','northwest','FontSize',9,'TextColor',C.text,'Color',C.panel, ...
            'EdgeColor',C.grid);

        biasTitle = sprintf('CO₂ Flux Bias = F_{NS} − F_{MS}  |  mean = %.1f ± %.1f mmol m⁻² d⁻¹  |  (~%.0f%% of F_NS)', ...
            bias_mn, bias_sd, abs(bias_mn / nanmean_safe(Fns)) * 100);
        title(ax(3), biasTitle,'Color',C.bias,'FontSize',10);
        ax(3).XTickLabel = {};
        hold(ax(3),'off');

        %% — AX4: Wind speed + Slick threshold ——
        cla(ax(4),'reset'); mce_styleax(ax(4),S.C); hold(ax(4),'on');
        if ~isempty(u10) && any(~isnan(u10))
            area(ax(4),tb,u10,'FaceColor',[0.30 0.55 0.42],'FaceAlpha',0.55, ...
                'EdgeColor',[0.50 0.75 0.60],'LineWidth',1.0,'DisplayName','U₁₀');
        end
        yline(ax(4),4,'--','Color',C.slick,'LineWidth',1.8, ...
            'Label','Slick threshold  4 m s⁻¹', ...
            'LabelHorizontalAlignment','right','LabelVerticalAlignment','top', ...
            'FontSize',8,'HandleVisibility','off');
        ylabel(ax(4),'U₁₀  (m s⁻¹)','Color',C.text,'FontSize',10);
        xlabel(ax(4),'Time  (UTC)','Color',C.text,'FontSize',10);
        ax(4).XAxis.TickLabelFormat = 'HH:mm';
        hold(ax(4),'off');

        %% ── Restore cursor lines on top ──
        for ai = 1:4
            hold(ax(ai),'on');
            delete(CL(ai));
            CL(ai) = plot(ax(ai),[NaT NaT],[0 0],'--', ...
                'Color',[1 1 1 0.55],'LineWidth',1.3, ...
                'HitTest','off','PickableParts','none');
            hold(ax(ai),'off');
        end

        %% ── Link x-axes ──
        linkaxes(ax,'x');
        if ~isempty(tb)
            xlim(ax(1),[tb(1) tb(end)]);
        end
    end

%% ════════════════════════════════════════════════════
%%  NESTED: redraw (toggle visibility changed)
%% ════════════════════════════════════════════════════
    function redraw()
        if isempty(S.tb), return; end
        drawAllAxes(S.dayList(S.dayIdx), S.scenVec{S.dayIdx});
    end

%% ════════════════════════════════════════════════════
%%  NESTED: day list callback
%% ════════════════════════════════════════════════════
    function onDayChange(src)
        sel = src.Value;
        idx = find(strcmpi(S.dayLabels, sel), 1);
        if isempty(idx), return; end
        doDay(idx);
    end

%% ════════════════════════════════════════════════════
%%  NESTED: mouse motion → cursor & status update
%% ════════════════════════════════════════════════════
    function onMotion(~,~)
        if isempty(S.tb), return; end

        % Try each axes to find which one the mouse is over
        cursorT = NaT;
        figPt = fig.CurrentPoint;  % [x y] pixels from bottom-left of figure

        for ai = 1:4
            % Get axes position in pixels (within figure)
            axPx = getAxPixPos(ax(ai), fig);
            if isempty(axPx), continue; end

            inX = figPt(1) >= axPx(1) && figPt(1) <= axPx(1)+axPx(3);
            inY = figPt(2) >= axPx(2) && figPt(2) <= axPx(2)+axPx(4);
            if inX && inY
                % Fraction of axis width
                frac = (figPt(1) - axPx(1)) / axPx(3);
                xl   = ax(ai).XLim;   % MATLAB datenum units
                tnum = xl(1) + frac*(xl(2)-xl(1));
                cursorT = datetime(tnum,'ConvertFrom','datenum');
                break;
            end
        end

        if isnat(cursorT), return; end
        if isempty(S.tb), return; end
        if cursorT < S.tb(1) || cursorT > S.tb(end), return; end

        % Move cursor lines
        tnum = datenum(cursorT);
        for ai = 1:4
            try
                yl = ax(ai).YLim;
                CL(ai).XData = [cursorT cursorT];
                CL(ai).YData = [yl(1)-1e4 yl(2)+1e4];
            catch
            end
        end

        % Interpolate values at cursor
        tSec = seconds(S.tb - S.tb(1));
        cSec = seconds(cursorT - S.tb(1));
        pA_c  = interp1(tSec, S.pAir,  cSec,'linear',NaN);
        pN_c  = interp1(tSec, S.pNSA,  cSec,'linear',NaN);
        pL_c  = interp1(tSec, S.pNSL,  cSec,'linear',NaN);
        pS_c  = interp1(tSec, S.pSea,  cSec,'linear',NaN);
        Fms_c = interp1(tSec, S.F_ms,  cSec,'linear',NaN);
        Fns_c = interp1(tSec, S.F_ns,  cSec,'linear',NaN);
        b_c   = interp1(tSec, S.bias,  cSec,'linear',NaN);
        dm_c  = interp1(tSec, S.dpms,  cSec,'linear',NaN);
        dn_c  = interp1(tSec, S.dpns,  cSec,'linear',NaN);

        crsBox.Value = { ...
            sprintf('Time:        %s', datestr(cursorT,'HH:MM:SS')), ...
            '─────────────────', ...
            sprintf('Air₁₀₀:   %6.1f µatm', pA_c), ...
            sprintf('NSA₂₀:    %6.1f µatm', pN_c), ...
            sprintf('NSL₂₀:    %6.1f µatm', pL_c), ...
            sprintf('Sea₁₀₀:   %6.1f µatm', pS_c), ...
            '─────────────────', ...
            sprintf('ΔpCO₂ MS:  %+6.1f µatm', dm_c), ...
            sprintf('ΔpCO₂ NS:  %+6.1f µatm', dn_c), ...
            '─────────────────', ...
            sprintf('F_MS:  %+6.2f mmol/m²d', Fms_c), ...
            sprintf('F_NS:  %+6.2f mmol/m²d', Fns_c), ...
            '─────────────────', ...
            sprintf('BIAS:  %+6.2f mmol/m²d', b_c), ...
            sprintf('   (~%.0f%% of F_NS)', abs(b_c/Fns_c)*100)};
    end

%% ════════════════════════════════════════════════════
%%  NESTED: export current day table
%% ════════════════════════════════════════════════════
    function doExport()
        if isempty(S.tb)
            uialert(fig,'No data loaded yet.','Export','Icon','warning');
            return;
        end
        d    = S.dayList(S.dayIdx);
        scen = S.scenVec{S.dayIdx};
        out  = table(S.tb, S.pAir, S.pNSA, S.pNSL, S.pSea, S.u10, ...
                     S.dpms, S.dpns, S.F_ms, S.F_ns, S.bias, ...
                     'VariableNames',{ ...
                     'Time_1p5min', ...
                     'pCO2_Air100_uatm','pCO2_NSA20_uatm','pCO2_NSL20_uatm','pCO2_Sea100_uatm', ...
                     'U10_m_s','dpCO2_MeterScale_uatm','dpCO2_NearSurface_uatm', ...
                     'CO2flux_MeterScale_mmol_m2_d','CO2flux_NearSurface_mmol_m2_d', ...
                     'CO2flux_Bias_mmol_m2_d'});
        fname = sprintf('BASS_%s_%s_1p5min.xlsx', ...
            datestr(d,'yyyymmdd'), scen);
        try
            writetable(out, fname);
            uialert(fig, sprintf('Saved:\n%s\n\n%d rows × 11 columns', fname, height(out)), ...
                'Export Done','Icon','success');
        catch ME
            uialert(fig, ME.message,'Export Error','Icon','error');
        end
    end

end  %% ── END MarineCarbonExplorer ──────────────────────────────────────

%% ════════════════════════════════════════════════════
%%  STANDALONE HELPER FUNCTIONS
%% ════════════════════════════════════════════════════

function [T, t, vn] = mce_load(fpath)
    % ── 1. Try the given path ──────────────────────────────────────────
    if ~isfile(fpath)
        % ── 2. Try common relative locations ─────────────────────────
        candidates = { ...
            fpath, ...
            fullfile(fileparts(mfilename('fullpath')), fpath), ...
            fullfile(fileparts(mfilename('fullpath')), '..', fpath), ...
            fullfile(fileparts(mfilename('fullpath')), 'data', fpath), ...
            fullfile(fileparts(mfilename('fullpath')), 'Data', fpath)};
        found = '';
        for k = 1:numel(candidates)
            if isfile(candidates{k})
                found = candidates{k};
                break;
            end
        end

        if isempty(found)
            % ── 3. File browser fallback ──────────────────────────────
            fprintf('\n[MarineCarbonExplorer] File not found: %s\n', fpath);
            fprintf('Opening file browser — please locate your data file.\n');
            [fname, fdir] = uigetfile( ...
                {'*.xlsx;*.xls','Excel files (*.xlsx, *.xls)'; ...
                 '*.csv',       'CSV files (*.csv)'; ...
                 '*.*',         'All files (*.*)'}, ...
                'Select Master Time-Series data file', ...
                fpath);
            if isequal(fname, 0)
                error('No file selected. Please re-run and select a data file.');
            end
            found = fullfile(fdir, fname);
        end
        fpath = found;
    end

    fprintf('[MCE] Loading: %s\n', fpath);
    try
        opts = detectImportOptions(fpath,'VariableNamingRule','preserve');
    catch
        opts = detectImportOptions(fpath);
    end
    T  = readtable(fpath, opts);
    vn = string(T.Properties.VariableNames);

    tvar = mce_pick(vn, {'Date_Time','DateTime','Datetime','Time','TIME','timestamp'});
    if isempty(tvar)
        error(['No time column found in: %s\n' ...
               'Expected column named: Date_Time, DateTime, Time, etc.\n' ...
               'Available columns:\n%s'], fpath, strjoin(cellstr(vn),', '));
    end
    t = mce_parsetime(T.(tvar));
    [~,ix] = sort(t); T=T(ix,:); t=t(ix);
    bad = isnat(t); T(bad,:)=[]; t(bad)=[];
    fprintf('[MCE] %d rows loaded  [%s  →  %s]\n', numel(t), ...
            datestr(t(1),'dd mmm yyyy HH:MM:SS'), datestr(t(end),'dd mmm yyyy HH:MM:SS'));
end

function nm = mce_pick(varNames, patterns)
    nm = '';
    vl = lower(string(varNames));
    for k = 1:numel(patterns)
        ix = find(contains(vl, lower(string(patterns{k}))), 1,'first');
        if ~isempty(ix), nm = char(varNames(ix)); return; end
    end
end

function dt = mce_parsetime(x)
    if isdatetime(x), dt=x(:); return; end
    if isnumeric(x)
        try, dt=datetime(x,'ConvertFrom','excel'); dt=dt(:); return; catch, end
    end
    if iscell(x), x=string(x); end
    if ischar(x),  x=string(x); end
    fmts={'yyyy-MM-dd HH:mm:ss','yyyy/MM/dd HH:mm:ss','dd.MM.yyyy HH:mm:ss', ...
          'MM/dd/yyyy HH:mm:ss','dd-MM-yyyy HH:mm:ss','yyyy-MM-dd''T''HH:mm:ss', ...
          'dd-MMM-yyyy HH:mm:ss','yyyy-MM-dd HH:mm','dd.MM.yyyy HH:mm'};
    for k=1:numel(fmts)
        try
            dt=datetime(x(:),'InputFormat',fmts{k});
            if sum(isnat(dt))<0.1*numel(dt), dt=dt(:); return; end
        catch, end
    end
    dt=datetime(x(:)); dt=dt(:);
end

function v = mce_getcol(T, name, mask)
    if isempty(name), v=nan(sum(mask),1); return; end
    v = double(T.(name)(mask));
end

function scens = mce_scenario(T, t, dayList, u10col)
    scens = cell(numel(dayList),1);
    for i=1:numel(dayList)
        d  = dayList(i);
        mk = t >= d & t < d+days(1);
        if ~isempty(u10col) && sum(mk)>0
            u = double(T.(u10col)(mk));
            mu10 = median(u,'omitnan');
            if mu10 < 4, scens{i}='Slick'; else, scens{i}='Non-slick'; end
        else
            scens{i}='Unknown';
        end
    end
end

function [tb, varargout] = mce_bin(t, binSec, varargin)
    t0   = t(1);
    t0   = datetime(year(t0),month(t0),day(t0), ...
                    hour(t0),minute(t0),floor(second(t0)/binSec)*binSec);
    dtS  = seconds(t - t0);
    binID = floor(dtS/binSec);
    [bk,~,G] = unique(binID);
    tb = t0 + seconds(bk * binSec);
    varargout = cell(1, numel(varargin));
    for vi=1:numel(varargin)
        x = double(varargin{vi});
        varargout{vi} = accumarray(G, x, [], @(v) mean(v,'omitnan'));
    end
end

function mce_styleax(ax, C)
    ax.Color         = C.bg;
    ax.XColor        = C.grid;
    ax.YColor        = C.text;
    ax.GridColor     = C.grid;
    ax.GridAlpha     = 0.28;
    ax.Box           = 'on';
    ax.XGrid         = 'on';
    ax.YGrid         = 'on';
    ax.FontSize      = 9;
    hold(ax,'off');
end

function mce_label(parent, txt, x, y, w, h, fs, col, bold)
    lbl = uilabel(parent,'Text',txt,'Position',[x y w h], ...
        'FontSize',fs,'FontColor',col,'HorizontalAlignment','center');
    if bold, lbl.FontWeight = 'bold'; end
end

function px = getAxPixPos(ax, fig)
    % Return [left bottom width height] of axes inner area in figure pixels.
    try
        % ax.Position is in pixels for uiaxes in uifigure
        old = ax.Units;
        ax.Units = 'pixels';
        pos = ax.Position;
        ax.Units = old;
        % Add the figure's pixel offset if needed
        px = pos;  % already relative to figure for uifigure
    catch
        px = [];
    end
end

function v = ternary(cond, a, b)
    if cond, v=a; else, v=b; end
end

function m = nanmean_safe(x)
    m = mean(x(~isnan(x)));
    if isempty(m), m = NaN; end
end

function fpath = mce_findFile(candidates)
% Search for the first candidate that exists in the same folder as this script.
% Returns the filename string (found or first candidate as fallback for browser).
    scriptDir = fileparts(mfilename('fullpath'));
    for k = 1:numel(candidates)
        p = candidates{k};
        if isfile(p), fpath = p; return; end
        p2 = fullfile(scriptDir, candidates{k});
        if isfile(p2), fpath = p2; return; end
        % Also search one level up and in data/ subfolder
        for sub = {'..',fullfile('..','data'),'data','Data'}
            p3 = fullfile(scriptDir, sub{1}, candidates{k});
            if isfile(p3), fpath = p3; return; end
        end
    end
    % None found – return first candidate; mce_load will open the browser
    fpath = candidates{1};
end
