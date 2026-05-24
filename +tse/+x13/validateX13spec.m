function validateX13spec(spec)
%VALIDATEX13SPEC  Check cross-spec consistency of an X13 specification.
%
%   Raises an error (id 'tseries:noMatch') for incompatible combinations and
%   warns about ineffective ones.  Called by tse.x13.x13write.  Direct port of
%   the Julia validateX13spec.
    isd = @(v) tse.x13.isdefault(v);

    if ~isd(spec.arima)
        if ~isd(spec.automdl)
            error('tseries:noMatch', 'The arima spec cannot be used in the same spec file as the pickmdl or automdl specs.');
        end
        if ~isd(spec.pickmdl)
            error('tseries:noMatch', 'The arima spec cannot be used in the same spec file as the pickmdl or automdl specs.');
        end
        if ~isd(spec.estimate) && ~isd(spec.estimate.file) && ...
                (~isd(spec.arima.ar) || ~isd(spec.arima.model))
            error('tseries:noMatch', 'The model, ma, and ar arguments of the arima spec cannot be used when the file argument is specified in the estimate spec.');
        end
    end

    if ~isd(spec.automdl)
        if ~isd(spec.pickmdl)
            error('tseries:noMatch', 'The automdl spec cannot be used in the same spec file as the pickmdl or arima specs.');
        end
        if ~isd(spec.estimate) && ~isd(spec.estimate.file)
            error('tseries:noMatch', 'The automdl spec cannot be used with an estimate spec employing the file argument.');
        end
    end

    if ~isd(spec.estimate) && ~isd(spec.estimate.file)
        if ~isd(spec.regression)
            if ~isd(spec.regression.variables) || ~isd(spec.regression.user) || ~isd(spec.regression.b)
                error('tseries:noMatch', 'The variables, user, and b arguments of the regression spec cannot be used when the estimate spec contains the file argument.');
            end
        end
    end

    if ~isd(spec.forecast)
        if ~isd(spec.forecast.maxlead) && ~isd(spec.history) && ~isd(spec.history.fstep)
            fstep = spec.history.fstep;
            if any(fstep > spec.forecast.maxlead)
                error('tseries:noMatch', 'history fstep values cannot exceed the forecast maxlead (%d).', spec.forecast.maxlead);
            end
        end
    end

    if ~isd(spec.history)
        if ~isd(spec.history.outlier) && isd(spec.outlier)
            warning('The outlier argument of the history spec has no effect when no outlier spec is specified.');
        end
    end

    if ~isd(spec.regression) && ~isd(spec.regression.variables)
        vars = local_varcell(spec.regression.variables);
        sdata = spec.series.data;
        stype = spec.series.type;
        mq = tse.ismonthly(sdata) || tse.isquarterly(sdata);

        if ~isd(spec.transform) && ~isd(spec.transform.adjust) && strcmp(char(spec.transform.adjust), 'lom')
            for i = 1:numel(vars)
                v = vars{i};
                if isequal_sym(v, 'td') || isequal_sym(v, 'lom') || isa(v, 'tse.x13.td') || isa(v, 'tse.x13.lom')
                    error('tseries:noMatch', 'When adjust=lom is specified in transform, td or lom variables in regression conflict.');
                end
            end
        end

        typesUsed = cellfun(@tse.x13.regvartype, vars, 'UniformOutput', false);
        seriesRange = tse.rangeof(sdata);
        spanRange = tse.x13.effective_span(spec.series);

        for i = 1:numel(vars)
            v = vars{i};
            vt = tse.x13.regvartype(v);

            if ~isd(stype)
                if ~strcmp(char(stype), 'flow')
                    if ismember(vt, {'td','tdnolpyear','td1coef','td1nolpyear','lpyear','easter','labor','thank','sceaster'})
                        error('tseries:noMatch', '%s regressors can only be used with flow-type data.', vt);
                    end
                elseif ~strcmp(char(stype), 'stock')
                    if ismember(vt, {'tdstock','td1stock','easterstock'})
                        error('tseries:noMatch', '%s regressors can only be used with stock-type data.', vt);
                    end
                end
            end

            switch vt
                case 'td'
                    local_needMQ(mq, 'td');
                    local_conflict(typesUsed, {'tdnolpyear','td1coef','td1nolpyear','lpyear','lom','loq','tdstock','tdstock1coef'}, 'td');
                    if ~isd(spec.transform) && ~isd(spec.transform.adjust)
                        error('tseries:noMatch', 'The adjust argument of transform cannot be used when td or td1coef is in regression.');
                    end
                case 'tdnolpyear'
                    local_needMQ(mq, 'tdnolpyear');
                    local_conflict(typesUsed, {'td','td1coef','td1nolpyear','tdstock','tdstock1coef'}, 'tdnolpyear');
                case 'td1coef'
                    local_needMQ(mq, 'td1coef');
                    local_conflict(typesUsed, {'td','tdnolpyear','td1nolpyear','lpyear','lom','loq','tdstock','tdstock1coef'}, 'td1coef');
                    if ~isd(spec.transform) && ~isd(spec.transform.adjust)
                        error('tseries:noMatch', 'The adjust argument of transform cannot be used when td or td1coef is in regression.');
                    end
                case 'td1nolpyear'
                    local_needMQ(mq, 'td1nolpyear');
                    local_conflict(typesUsed, {'td','tdnolpyear','td1coef','tdstock','tdstock1coef'}, 'td1nolpyear');
                case 'lpyear'
                    local_needMQ(mq, 'lpyear');
                    local_conflict(typesUsed, {'td','td1coef','tdstock','tdstock1coef'}, 'lpyear');
                case 'lom'
                    local_needMQ(mq, 'lom');
                    local_conflict(typesUsed, {'td','td1coef','tdstock','tdstock1coef'}, 'lom');
                case 'loq'
                    local_needMQ(mq, 'loq');
                    local_conflict(typesUsed, {'td','td1coef','tdstock','tdstock1coef'}, 'loq');
                case 'tdstock'
                    local_needM(tse.ismonthly(sdata), 'tdstock');
                    local_conflict(typesUsed, {'tdstock1coef','td','tdnolpyear','td1coef','td1nolpyear','lom','loq'}, 'tdstock');
                case 'tdstock1coef'
                    local_needM(tse.ismonthly(sdata), 'tdstock1coef');
                    local_conflict(typesUsed, {'tdstock','td','tdnolpyear','td1coef','td1nolpyear','lom','loq'}, 'tdstock1coef');
                case 'labor'
                    local_needM(tse.ismonthly(sdata), 'labor');
                case 'sceaster'
                    local_needMQ(mq, 'sceaster');
            end

            local_daterange(v, seriesRange, spanRange);
        end

        if ~isd(spec.regression.aictest)
            aics = local_cellify(spec.regression.aictest);
            for a = 1:numel(aics)
                aic = aics{a};
                if ~isd(stype)
                    if ~strcmp(char(stype), 'flow')
                        if ismember(aic, {'tdnolpyear','td1coef','td1nolpyear','lpyear','easter','labor','thank','sceaster'})
                            error('tseries:noMatch', 'aictest: %s can only be tested with flow-type data.', aic);
                        end
                    elseif ~strcmp(char(stype), 'stock')
                        if ismember(aic, {'tdstock','td1stock','easterstock'})
                            error('tseries:noMatch', 'aictest: %s can only be tested with stock-type data.', aic);
                        end
                    end
                end
                switch aic
                    case 'td'
                        local_needMQ(mq, 'aictest: td');
                        local_conflict(typesUsed, {'lpyear','lom','loq'}, 'aictest: td');
                    case 'tdnolpyear'
                        local_needMQ(mq, 'aictest: tdnolpyear');
                        local_conflict(typesUsed, {'td','td1coef','td1nolpyear','tdstock','tdstock1coef'}, 'aictest: tdnolpyear');
                    case 'td1coef'
                        local_needMQ(mq, 'aictest: td1coef');
                        local_conflict(typesUsed, {'td','tdnolpyear','td1nolpyear','lpyear','lom','loq','tdstock','tdstock1coef'}, 'aictest: td1coef');
                    case 'td1nolpyear'
                        local_needMQ(mq, 'aictest: td1nolpyear');
                        local_conflict(typesUsed, {'td','tdnolpyear','td1coef','tdstock','tdstock1coef'}, 'aictest: td1nolpyear');
                    case 'lpyear'
                        local_needMQ(mq, 'aictest: lpyear');
                        local_conflict(typesUsed, {'td','td1coef','tdstock','tdstock1coef'}, 'aictest: lpyear');
                    case 'lom'
                        local_needM(tse.ismonthly(sdata), 'aictest: lom');
                        local_conflict(typesUsed, {'td','td1coef','tdstock','tdstock1coef'}, 'aictest: lom');
                    case 'loq'
                        local_needM(tse.isquarterly(sdata), 'aictest: loq');
                        local_conflict(typesUsed, {'td','td1coef','tdstock','tdstock1coef'}, 'aictest: loq');
                    case 'tdstock'
                        local_needM(tse.ismonthly(sdata), 'aictest: tdstock');
                        local_conflict(typesUsed, {'tdstock1coef','td','tdnolpyear','td1coef','td1nolpyear','lom','loq'}, 'aictest: tdstock');
                    case 'tdstock1coef'
                        local_needM(tse.ismonthly(sdata), 'aictest: tdstock1coef');
                        local_conflict(typesUsed, {'tdstock','td','tdnolpyear','td1coef','td1nolpyear','lom','loq'}, 'aictest: tdstock1coef');
                    case 'labor'
                        local_needM(tse.ismonthly(sdata), 'aictest: labor');
                    case 'sceaster'
                        local_needMQ(mq, 'aictest: sceaster');
                end
            end
        end
    end

    if ~isd(spec.regression) && ~isd(spec.regression.data)
        required = local_required(spec);
        if ~isequal(intersect(required, tse.rangeof(spec.regression.data)), required)
            error('tseries:noMatch', 'The data in the regression spec must cover the required range.');
        end
    end

    if ~isd(spec.seats)
        if ~isd(spec.seats.hpcycle) && isd(spec.seats.hplan) && isequal(spec.seats.hpcycle, true)
            n = numel(spec.series.data.values);
            if tse.ismonthly(spec.series.data) && n < 120
                warning('Hodrick-Prescott filters will not be used as the default hplan requires at least 120 monthly observations. The provided series has %d observations.', n);
            elseif tse.isquarterly(spec.series.data) && n < 48
                warning('Hodrick-Prescott filters will not be used as the default hplan requires at least 48 quarterly observations. The provided series has %d observations.', n);
            end
        end
    end

    if ~isd(spec.series.modelspan) && ~isd(spec.forecast) && ~isd(spec.forecast.maxback)
        if ~isd(spec.series.span) && ~isequal(first(spec.series.modelspan), first(spec.series.span))
            warning('Backcasts will not be generated as the start of the modelspan does not coincide with the start of the series span.');
        end
    end

    if ~isd(spec.slidingspans)
        if ~isd(spec.slidingspans.length)
            L = spec.slidingspans.length;
            if tse.isquarterly(spec.series.data) && L < 12
                error('tseries:noMatch', 'The slidingspans length must cover at least 3 years.');
            end
            if tse.isquarterly(spec.series.data) && L > 4*19
                error('tseries:noMatch', 'The slidingspans length can cover at most 19 years.');
            end
            if tse.ismonthly(spec.series.data) && L < 36
                error('tseries:noMatch', 'The slidingspans length must cover at least 3 years.');
            end
            if tse.ismonthly(spec.series.data) && L > 12*19
                error('tseries:noMatch', 'The slidingspans length can cover at most 19 years.');
            end
        end
        if ~isd(spec.slidingspans.outlier) && isd(spec.outlier)
            warning('The outlier argument of the slidingspans spec will be ignored as there is no outlier spec specified.');
        end
    end

    if ~isd(spec.spectrum)
        if ~isd(spec.spectrum.qcheck) && isequal(spec.spectrum.qcheck, true) && ~tse.ismonthly(spec.series.data)
            warning('The qcheck argument of the spectrum spec only produces output for a monthly TSeries.');
        end
    end

    if ~isd(spec.transform)
        if ~isd(spec.transform.adjust) && ~isd(spec.x11) && ~isd(spec.x11.mode)
            if any(strcmp(char(spec.x11.mode), {'add','pseudoadd'}))
                error('tseries:noMatch', 'The adjust argument of transform cannot be used when x11 mode is add or pseudoadd.');
            end
        end
        if ~isd(spec.x11)
            if isd(spec.x11.mode) && isd(spec.transform.power) && isd(spec.transform.func)
                error('tseries:noMatch', 'The default x11 mode (multiplicative) conflicts with the default transform function/power (no transformation).');
            end
        end
    end

    if ~isd(spec.x11regression)
        if ~isd(spec.x11regression.data)
            required = local_required(spec);
            if ~isequal(intersect(required, tse.rangeof(spec.x11regression.data)), required)
                error('tseries:noMatch', 'The data in the x11regression spec must cover the required range.');
            end
        end
        if ~isd(spec.x11regression.umdata)
            required = local_required(spec);
            if ~isequal(intersect(required, tse.rangeof(spec.x11regression.umdata)), required)
                error('tseries:noMatch', 'The umdata in the x11regression spec must cover the required range.');
            end
        end
        if ~isd(spec.x11regression.outlierspan)
            os = spec.x11regression.outlierspan;
            if isa(os, 'tse.MITRange')
                if ~isequal(intersect(os, tse.rangeof(spec.series.data)), os)
                    error('tseries:noMatch', 'The outlierspan of x11regression must lie within the series range.');
                end
            end
        end
        if ~isd(spec.x11regression.span)
            required = tse.x13.effective_span(spec.series);
            sp = spec.x11regression.span;
            if isa(sp, 'tse.MITRange')
                regrange = sp;
            elseif isa(sp, 'tse.x13.Span')
                regrange = required;
                if isa(sp.b, 'tse.MIT'), regrange = sp.b:last(required); end
                if isa(sp.e, 'tse.MIT'), regrange = first(regrange):sp.e; end
            else
                regrange = required;
            end
            if ~isequal(intersect(regrange, required), regrange)
                error('tseries:noMatch', 'The span argument of x11regression must lie within the series range.');
            end
        end
        if ~isd(spec.x11regression.variables)
            vars = local_varcell(spec.x11regression.variables);
            typesUsed = cellfun(@tse.x13.regvartype, vars, 'UniformOutput', false);
            if ~isd(spec.x11regression.usertype)
                typesUsed = [typesUsed, local_cellify(spec.x11regression.usertype)];
            end
            if ~isd(spec.x11regression.forcecal)
                hasTD = any(ismember({'td','td1coef','tdstock','tdstock1coef'}, typesUsed));
                hasHol = any(ismember({'easter','labor','thank','sceaster'}, typesUsed));
                if ~(hasTD && hasHol)
                    warning('The forcecal argument of the x11regression will not have any effect as the variables argument does not contain both td and holiday regressors.');
                end
            end
        end
    end
end

% ---------------------------------------------------------------- helpers ----
function local_needMQ(mq, name)
    if ~mq
        error('tseries:noMatch', '%s regressors can only be used with Monthly or Quarterly data.', name);
    end
end

function local_needM(ok, name)
    if ~ok
        error('tseries:noMatch', '%s regressors can only be used with the required frequency.', name);
    end
end

function local_conflict(typesUsed, set, name)
    if any(ismember(set, typesUsed))
        error('tseries:noMatch', '%s cannot be used with a conflicting regressor.', name);
    end
end

function local_daterange(v, seriesRange, spanRange)
    if isa(v, 'tse.x13.ao') && ~ismember(seriesRange, v.mit)
        error('tseries:noMatch', 'ao regressors must have a date within the series range.');
    elseif isa(v, 'tse.x13.tc') && ~ismember(seriesRange, v.mit)
        error('tseries:noMatch', 'tc regressors must have a date within the series range.');
    elseif isa(v, 'tse.x13.ls')
        if ~ismember(seriesRange, v.mit)
            error('tseries:noMatch', 'ls regressors must have a date within the series range.');
        elseif v.mit == first(spanRange)
            error('tseries:noMatch', 'ls regressors cannot be at the start of the series or span range.');
        end
    elseif isa(v, 'tse.x13.so')
        if ~ismember(seriesRange, v.mit)
            error('tseries:noMatch', 'so regressors must have a date within the series range.');
        elseif v.mit == first(spanRange)
            error('tseries:noMatch', 'so regressors cannot be at the start of the series or span range.');
        end
    elseif isa(v, 'tse.x13.aos') && (~ismember(seriesRange, v.mit1) || ~ismember(seriesRange, v.mit2))
        error('tseries:noMatch', 'aos regressors must have dates within the series range.');
    elseif isa(v, 'tse.x13.lss') && (~ismember(seriesRange, v.mit1) || ~ismember(seriesRange, v.mit2))
        error('tseries:noMatch', 'lss regressors must have dates within the series range.');
    elseif isa(v, 'tse.x13.rp') && (~ismember(seriesRange, v.mit1) || ~ismember(seriesRange, v.mit2))
        error('tseries:noMatch', 'rp regressors must have dates within the series range.');
    elseif isa(v, 'tse.x13.qd') && (~ismember(seriesRange, v.mit1) || ~ismember(seriesRange, v.mit2))
        error('tseries:noMatch', 'qd regressors must have dates within the series range.');
    elseif isa(v, 'tse.x13.qi') && (~ismember(seriesRange, v.mit1) || ~ismember(seriesRange, v.mit2))
        error('tseries:noMatch', 'qi regressors must have dates within the series range.');
    elseif isa(v, 'tse.x13.tl') && (~ismember(seriesRange, v.mit1) || ~ismember(seriesRange, v.mit2))
        error('tseries:noMatch', 'tl regressors must have dates within the series range.');
    end
end

function required = local_required(spec)
    required = tse.x13.effective_span(spec.series);
    if ~tse.x13.isdefault(spec.forecast)
        if ~tse.x13.isdefault(spec.forecast.maxback)
            required = (first(required) - spec.forecast.maxback):last(required);
        end
        if ~tse.x13.isdefault(spec.forecast.maxlead)
            required = first(required):(last(required) + spec.forecast.maxlead);
        end
    end
end

function c = local_varcell(v)
    if tse.x13.isdefault(v)
        c = {};
    elseif iscell(v)
        c = v;
    else
        c = {v};
    end
end

function c = local_cellify(v)
    if iscell(v)
        c = v;
    elseif ischar(v) || isstring(v)
        c = {char(v)};
    else
        c = {v};
    end
end

function tf = isequal_sym(v, s)
    tf = (ischar(v) || isstring(v)) && strcmp(char(v), s);
end
