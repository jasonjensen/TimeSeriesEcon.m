classdef Axis
    %AXIS  One dimension of a tse.NDTSeries (or of a tse.daec.Array).
    %
    %   An axis is one of three kinds:
    %     plain   a length only                  tse.Axis(n)
    %     range   a tse.MITRange of dates        tse.Axis(rng)
    %                                            tse.Axis(firstdate, n)
    %     names   variable names                 tse.Axis(["a" "b"])
    %                                            tse.Axis({'a', 'b'})
    %
    %   Properties: kind ("plain", "range" or "names"), length, range (a
    %   tse.MITRange, range axes only) and names (a string row, names axes
    %   only).
    %
    %   A tse.NDTSeries holds one Axis per dimension, in any order, and so
    %   does a tse.daec.Array.  tse.daec.Axis(...) is an alias that returns
    %   a tse.Axis.
    %
    %   See also tse.NDTSeries, tse.daec.Array.

    properties (SetAccess = private)
        kind = "plain"
        length = 0
        range = []
        names = strings(1, 0)
    end

    methods
        function ax = Axis(arg, n)
            if nargin == 0
                return
            end
            if nargin == 2
                if ~isa(arg, 'tse.MIT')
                    error('tseries:noMatch', ...
                        'Axis(firstdate, n) needs a tse.MIT first date.');
                end
                n = int64(n);
                arg = tse.MITRange(arg, tse.MIT(arg.frequency, arg.value + n - 1));
            end
            if isa(arg, 'tse.MITRange')
                if arg.stepSize ~= 1
                    error('tseries:noMatch', 'A range axis needs a range with step 1.');
                end
                ax.kind = "range";
                ax.range = arg;
                ax.length = double(length(arg));
            elseif isnumeric(arg) && isscalar(arg) && arg >= 0 && arg == fix(arg)
                ax.kind = "plain";
                ax.length = double(arg);
            elseif isstring(arg) || iscellstr(arg) || ischar(arg)
                names = string(arg);
                if ischar(arg)
                    names = string(cellstr(arg));
                end
                if any(contains(names, newline))
                    error('tseries:noMatch', 'Axis names cannot contain newlines.');
                end
                ax.kind = "names";
                ax.names = reshape(names, 1, []);
                ax.length = numel(names);
            else
                error('tseries:noMatch', ['Axis takes a length, a tse.MITRange, ' ...
                    'a first date and a length, or a list of names.']);
            end
        end

        function m = firstdate(ax)
            %FIRSTDATE  First date of a range axis.
            if ax.kind ~= "range"
                error('tseries:noMatch', 'Only a range axis has dates.');
            end
            m = ax.range.startMIT;
        end

        function L = labels(ax)
            %LABELS  A string label for each position along the axis:
            %   dates for a range axis, the names for a names axis and
            %   "1".."n" for a plain axis.
            switch ax.kind
                case "range"
                    L = strings(1, ax.length);
                    m = ax.range.startMIT;
                    for k = 1:ax.length
                        L(k) = string(char(m + (k - 1)));
                    end
                case "names"
                    L = ax.names;
                otherwise
                    L = string(1:ax.length);
            end
        end

        function s = describe(ax)
            %DESCRIBE  One-line description, e.g. "2020Q1:2020Q4".
            switch ax.kind
                case "range"
                    if ax.length == 0
                        s = sprintf('empty range from %s', char(ax.range.startMIT));
                    else
                        s = sprintf('%s:%s', char(ax.range.startMIT), ...
                            char(ax.range.startMIT + (ax.length - 1)));
                    end
                case "names"
                    if ax.length <= 5
                        s = char(strjoin(ax.names, ', '));
                    else
                        s = sprintf('%s, ... (%d names)', ...
                            char(strjoin(ax.names(1:3), ', ')), ax.length);
                    end
                otherwise
                    s = sprintf('1:%d', ax.length);
            end
        end

        function tf = isequal(a, b)
            tf = isa(b, 'tse.Axis') && numel(a) == numel(b);
            for k = 1:numel(a)
                if ~tf, return, end
                tf = a(k).kind == b(k).kind && a(k).length == b(k).length ...
                    && isequal(a(k).names, b(k).names);
                if tf && a(k).kind == "range"
                    tf = a(k).range.startMIT == b(k).range.startMIT;
                end
            end
        end
    end
end
