classdef Array
    %ARRAY  An array with one tse.daec.Axis per dimension.
    %
    %   a = tse.daec.Array(axes, values)
    %       axes is a 1-by-N tse.daec.Axis array (N <= 5), in any order;
    %       size(values, k) must equal axes(k).length.
    %   a = tse.daec.Array(x)
    %       from a tse.TSeries (one range axis) or a tse.MVTSeries (a range
    %       axis, then a names axis).
    %
    %   readdb and the load_* functions return an Array for stored data
    %   that is not a plain array, a TSeries or an MVTSeries, for example a
    %   names-by-dates table or a 3-d array with a range axis.  Writing an
    %   Array stores its axes as they are.
    %
    %   s = toseries(a) converts back to a TSeries or MVTSeries when the
    %   axes allow it.
    %
    %   See also tse.daec.Axis, tse.daec.readdb, tse.daec.writedb.

    properties (SetAccess = private)
        axes = tse.daec.Axis.empty(1, 0)
        values = []
    end

    methods
        function a = Array(axes, values)
            if nargin == 0
                return
            end
            if nargin == 1
                [axes, values] = fromSeries(axes);
            end
            if ~isa(axes, 'tse.daec.Axis') || isempty(axes)
                error('tseries:noMatch', 'Array(axes, values) needs at least one tse.daec.Axis.');
            end
            axes = reshape(axes, 1, []);
            if numel(axes) > 5
                error('tseries:noMatch', 'A .daec array has at most 5 axes.');
            end
            lens = [axes.length];
            if numel(lens) == 1
                if ~isvector(values) && ~isempty(values)
                    error('tseries:noMatch', 'A one-axis Array needs vector values.');
                end
                if numel(values) ~= lens
                    error('tseries:noMatch', ...
                        'Axis length %d does not match %d values.', lens, numel(values));
                end
                values = reshape(values, [], 1);
            else
                sz = size(values);
                sz(end+1:numel(lens)) = 1;
                if numel(sz) > numel(lens) || ~isequal(sz, lens)
                    error('tseries:noMatch', 'Axis lengths [%s] do not match values of size [%s].', ...
                        num2str(lens), num2str(size(values)));
                end
            end
            a.axes = axes;
            a.values = values;
        end

        function s = toseries(a)
            %TOSERIES  Convert to tse.TSeries or tse.MVTSeries.
            %
            %   One range axis gives a TSeries, a range axis followed by a
            %   names axis gives an MVTSeries; other layouts are an error.
            kinds = [a.axes.kind];
            if isequal(kinds, "range") && (isnumeric(a.values) || islogical(a.values))
                s = tse.TSeries(a.axes(1).firstdate(), a.values);
            elseif isequal(kinds, ["range" "names"]) && (isnumeric(a.values) || islogical(a.values))
                s = tse.MVTSeries(a.axes(1).firstdate(), a.axes(2).names, a.values);
            else
                error('tseries:noMatch', ...
                    'Only a range axis, or a range then a names axis, converts to a series.');
            end
        end

        function tf = isequal(a, b)
            tf = isa(b, 'tse.daec.Array') && isequal(a.axes, b.axes) ...
                && isequal(class(a.values), class(b.values)) ...
                && isequaln(a.values, b.values);
        end
    end
end

function [axes, values] = fromSeries(x)
    if isa(x, 'tse.TSeries')
        axes = tse.daec.Axis(x.firstdate, size(x.values, 1));
        values = x.values;
    elseif isa(x, 'tse.MVTSeries')
        axes = [tse.daec.Axis(x.firstdate, size(x.values, 1)), tse.daec.Axis(x.colnames)];
        values = x.values;
    else
        error('tseries:noMatch', 'Array(x) needs a tse.TSeries or tse.MVTSeries.');
    end
end
