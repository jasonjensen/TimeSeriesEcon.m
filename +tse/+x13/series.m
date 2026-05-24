function out = series(varargin)
%SERIES  Build (or set on a spec) the X13 series spec from a TSeries.
%
%   xts = tse.x13.series(ts, 'name', "GDP", 'title', "Quarterly GDP")
%   tse.x13.series(spec, ts, ...)      sets spec.series in place
%
%   Symbol-valued options are given as char (e.g. 'comptype','add'); String
%   options (name, title, file, format) as double-quoted strings.
%
%   See also: tse.x13.newspec, tse.x13.arima.
    [spec, args] = tse.x13.specsplit(varargin{:});
    if isempty(args) || ~isa(args{1}, 'tse.TSeries')
        error('tseries:noMatch', 'series requires a TSeries as its first argument.');
    end
    t = args{1};
    args(1) = [];

    D = tse.x13.X13default();
    d = struct('appendbcst',D,'appendfcst',D,'comptype',D,'compwt',D,'decimals',D, ...
        'file',D,'format',D,'modelspan',D,'name',D,'period',D,'precision',D, ...
        'print',D,'save',D,'span',D,'start',D,'title',D,'type',D,'divpower',D, ...
        'missingcode',D,'missingval',D,'saveprecision',D,'trimzero',D);
    o = tse.x13.getopts(d, args);

    data = t;
    if isa(o.start, 'tse.MIT')
        data = t(o.start:tse.lastdate(t));
    else
        o.start = tse.firstdate(data);
    end

    if (ischar(o.name) || isstring(o.name)) && strlength(string(o.name)) > 64
        warning('Series name truncated to 64 characters. Full name: %s', char(o.name));
        nm = char(o.name); o.name = nm(1:64);
    end
    if (ischar(o.title) || isstring(o.title)) && strlength(string(o.title)) > 79
        warning('Series title truncated to 79 characters. Full title: %s', char(o.title));
        tt = char(o.title); o.title = tt(1:79);
    end

    if ~tse.ismonthly(t) && ~tse.isyearly(t)
        o.period = double(tse.ppy(t));
    end

    if isa(o.span, 'tse.MITRange')
        if first(o.span) < tse.firstdate(t) || last(o.span) > tse.lastdate(t)
            error('tseries:noMatch', ...
                'span must be contained within the range of the provided series.');
        end
    elseif isa(o.span, 'tse.x13.Span')
        if isa(o.span.b, 'tse.MIT') && o.span.b < tse.firstdate(t)
            error('tseries:noMatch', ...
                'The start of the specified span must be on or after the start of the series.');
        end
        if isa(o.span.e, 'tse.MIT') && o.span.e > tse.lastdate(t)
            error('tseries:noMatch', ...
                'The end of the specified span must be on or before the end of the series.');
        end
    end

    if ~tse.x13.isdefault(o.divpower)
        if o.divpower < -9 || o.divpower > 9
            error('tseries:noMatch', ...
                'divpower values must be between -9 and 9 (inclusive). Received: %d.', o.divpower);
        end
    end

    if isa(o.span, 'tse.x13.Span') && o.span.hasFuzzyEnd()
        error('tseries:noMatch', ...
            'Spans with a fuzzy ending time are not allowed in the span argument of the series spec.');
    end

    dv = data.values;
    if any(isnan(dv))
        if tse.x13.isdefault(o.missingcode)
            error('tseries:noMatch', ...
                ['The provided TSeries has NaN values but no missingcode was specified. ', ...
                 'Please specify a missingcode, e.g. missingcode = -99999.0.']);
        else
            dv(isnan(dv)) = o.missingcode;
            data = tse.TSeries(tse.firstdate(data), dv);
        end
    end

    o.print = tse.x13.expandall(o.print, ...
        {'default','adjoriginal','adjorigplot','calendaradjorig','outlieradjorig','seriesplot'});
    o.save = tse.x13.expandall(o.save, ...
        {'span','specfile','adjoriginal','calendaradjorig','outlieradjorig','seriesmvadj'});

    obj = tse.x13.X13series();
    obj.appendbcst = o.appendbcst; obj.appendfcst = o.appendfcst;
    obj.comptype = o.comptype; obj.compwt = o.compwt; obj.data = data;
    obj.decimals = o.decimals; obj.file = o.file; obj.format = o.format;
    obj.modelspan = o.modelspan; obj.name = o.name; obj.period = o.period;
    obj.precision = o.precision; obj.print = o.print; obj.save = o.save;
    obj.span = o.span; obj.start = o.start; obj.title = o.title; obj.type = o.type;
    obj.divpower = o.divpower; obj.missingcode = o.missingcode;
    obj.missingval = o.missingval; obj.saveprecision = o.saveprecision;
    obj.trimzero = o.trimzero;

    out = tse.x13.specfinish(spec, 'series', obj);
end
