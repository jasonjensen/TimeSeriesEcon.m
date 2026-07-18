function write_object(dbkey, name, t)
%WRITE_OBJECT  Write a tse.TSeries as a named series into an open FAME db.
%
%   tse.fame.write_object(dbkey, name, t)
%
%   Mirrors FAME.jl: create the object with cfmnwob, build the date range
%   with fame_year_period_to_index, and write with a typed range writer
%   (fame_write_precisions for a double series, fame_write_numerics for a
%   single series).  Requires an open, writable database key.
%
%   See also: tse.fame.write, tse.fame.read_object.
    if ~isa(t, 'tse.TSeries')
        error('tseries:fame', 'write_object supports tse.TSeries in this version (got %s).', class(t));
    end
    K    = fame_constants();
    F    = tse.frequencyof(t);
    freq = tse.fame.freq_to_fame(F);
    isNumeric = isa(t.values, 'single');
    if isNumeric
        type = K.HNUMRC;
    else
        type = K.HPRECN;
    end

    % Create the object (basis = daily, observed = summed for a float series,
    % matching FAME.jl; FAME rejects observed = undefined here).
    tse.fame.CHLI.newobj(dbkey, name, K.HSERIE, freq, type, K.HBSDAY, K.HOBSUM);

    % Build the date range from the endpoints' (year, period).
    first  = t.firstdate;
    last   = first + (numel(t.values) - 1);
    fyp    = tse.mit2yp(first);
    lyp    = tse.mit2yp(last);
    findex = tse.fame.CHLI.yp_to_index(freq, fyp(1), fyp(2));
    lindex = tse.fame.CHLI.yp_to_index(freq, lyp(1), lyp(2));
    r      = tse.fame.CHLI.make_range(freq, findex, lindex);

    if isNumeric
        tse.fame.CHLI.write_numerics(dbkey, name, r, t.values);
    else
        tse.fame.CHLI.write_precisions(dbkey, name, r, t.values);
    end
end
