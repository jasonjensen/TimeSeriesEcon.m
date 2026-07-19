function write_object(dbkey, name, t)
%WRITE_OBJECT  Write a tse.TSeries as a named series into an open FAME db.
%
%   tse.fame.write_object(dbkey, name, t)
%
%   Mirrors FAME.jl: create the object with cfmnwob, build the date range
%   with fame_year_period_to_index, and write with a typed range writer.
%   The FAME type follows the tse value class: double -> precision, single
%   -> numeric, logical -> boolean.  Requires an open, writable database key.
%
%   See also: tse.fame.write, tse.fame.read_object.
    if ~isa(t, 'tse.TSeries')
        error('tseries:fame', 'write_object supports tse.TSeries in this version (got %s).', class(t));
    end
    K    = fame_constants();
    F    = tse.frequencyof(t);
    freq = tse.fame.freq_to_fame(F);
    v    = t.values;

    % type + observed: observed = summed for a float series (FAME rejects
    % undefined there), undefined otherwise -- matching FAME.jl.
    if islogical(v)
        type = K.HBOOLN;  observed = K.HOBUND;
    elseif isa(v, 'single')
        type = K.HNUMRC;  observed = K.HOBSUM;
    else
        type = K.HPRECN;  observed = K.HOBSUM;   % double (others promote)
    end
    tse.fame.CHLI.newobj(dbkey, name, K.HSERIE, freq, type, K.HBSDAY, observed);

    % Build the date range from the endpoints' (year, period).
    first  = t.firstdate;
    last   = first + (numel(v) - 1);
    fyp    = tse.mit2yp(first);
    lyp    = tse.mit2yp(last);
    findex = tse.fame.CHLI.yp_to_index(freq, fyp(1), fyp(2));
    lindex = tse.fame.CHLI.yp_to_index(freq, lyp(1), lyp(2));
    r      = tse.fame.CHLI.make_range(freq, findex, lindex);

    if islogical(v)
        tse.fame.CHLI.write_booleans(dbkey, name, r, v);
    elseif isa(v, 'single')
        tse.fame.CHLI.write_numerics(dbkey, name, r, v);
    else
        tse.fame.CHLI.write_precisions(dbkey, name, r, v);
    end
end
