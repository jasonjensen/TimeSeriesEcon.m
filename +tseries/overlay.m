function r = overlay(varargin)
%OVERLAY  Combine series so each observation is the first valid argument.
%
%   r = tseries.overlay(t1, t2, ...)
%   r = tseries.overlay(rng, t1, t2, ...)
%
%   The first form spans the union of input ranges.  The second
%   restricts to the explicit range.  At each observation, the first
%   argument that is not "not-a-number" (per tseries.istypenan) wins.
%
%   Also works on bare values: overlay(NaN, 5) -> 5; overlay(1,2) -> 1.

    if isempty(varargin)
        error('tseries:noMatch', 'overlay requires at least one argument.');
    end

    % Scalar/array overlay (everything that's not a TSeries)
    if ~isa(varargin{1}, 'tseries.MITRange') && ~isa(varargin{1}, 'tseries.TSeries')
        head = varargin{1};
        if tseries.istypenan(head)
            if numel(varargin) == 1
                r = head;
            else
                r = tseries.overlay(varargin{2:end});
            end
        else
            r = head;
        end
        return
    end

    % First arg is the range
    if isa(varargin{1}, 'tseries.MITRange')
        rng = varargin{1};
        tseries_args = varargin(2:end);
    else
        % Range spans all TSeries arguments
        rngs = cellfun(@tseries.rangeof, varargin, 'UniformOutput', false);
        rng = tseries.rangeof_span(rngs{:});
        tseries_args = varargin;
    end

    if isempty(tseries_args)
        error('tseries:noMatch', 'overlay requires at least one TSeries.');
    end

    % Promote element type across all arguments
    cls = class(tseries_args{1}.values);
    for k = 2:numel(tseries_args)
        cls = sumtype(cls, class(tseries_args{k}.values));
    end

    F = tseries_args{1}.firstdate.frequency;
    n = length(rng);
    out = repmat(tseries.typenan(cls), n, 1);
    out = cast(out, cls);
    filled = false(n, 1);
    rngFirst = rng.startMIT.value;

    for k = 1:numel(tseries_args)
        ts = tseries_args{k};
        if ~eq(ts.firstdate.frequency, F)
            mixed_freq_error(F, ts.firstdate.frequency);
        end
        tsFirst = ts.firstdate.value;
        nts = length(ts.values);
        for j = 1:nts
            mitVal = tsFirst + (j - 1);
            pos = double(mitVal - rngFirst) + 1;
            if pos < 1 || pos > n
                continue
            end
            if filled(pos)
                continue
            end
            v = ts.values(j);
            if tseries.istypenan(v)
                continue
            end
            out(pos) = v;
            filled(pos) = true;
        end
        if all(filled)
            break
        end
    end

    r = tseries.TSeries(rng.startMIT, out);
end

function c = sumtype(a, b)
% Pick the "wider" numeric/logical type between two classes.
    if strcmp(a, b)
        c = a; return
    end
    order = {'logical','uint8','int8','uint16','int16','uint32','int32', ...
             'uint64','int64','single','double'};
    ia = find(strcmp(order, a), 1);
    ib = find(strcmp(order, b), 1);
    if isempty(ia) || isempty(ib)
        c = 'double';
    else
        c = order{max(ia, ib)};
    end
end
