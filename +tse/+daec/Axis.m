classdef Axis
    %AXIS  One dimension of an array stored in a .daec file.
    %
    %   An axis is one of three kinds:
    %     plain   a length only                  tse.daec.Axis(n)
    %     range   a tse.MITRange of dates        tse.daec.Axis(rng)
    %                                            tse.daec.Axis(firstdate, n)
    %     names   variable names                 tse.daec.Axis(["a" "b"])
    %                                            tse.daec.Axis({'a', 'b'})
    %
    %   Properties: kind ("plain", "range" or "names"), length, range (a
    %   tse.MITRange, range axes only) and names (a string row, names axes
    %   only).
    %
    %   A tse.daec.Array holds one Axis per dimension, in any order.  See
    %   also tse.daec.Array.

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

        function tf = isequal(a, b)
            tf = isa(b, 'tse.daec.Axis') && numel(a) == numel(b);
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
