function write_object(dbkey, name, t)
%WRITE_OBJECT  Write a tse.TSeries as a named series into an open FAME db.
%
%   tse.fame.write_object(dbkey, name, t)
%
%   dbkey is an open, writable database key.  A double TSeries is stored as a
%   FAME precision series, a single TSeries as a numeric series.  NaN in the
%   values is stored as FAME missing.  Other tse types are added in a later
%   step.
%
%   See also: tse.fame.write, tse.fame.read_object.
    if ~isa(t, 'tse.TSeries')
        error('tseries:fame', 'write_object supports tse.TSeries in this version (got %s).', class(t));
    end
    K = fame_constants();
    F    = tse.frequencyof(t);
    freq = tse.fame.freq_to_fame(F);
    if isa(t.values, 'single')
        type = K.HNUMRC;
    else
        type = K.HPRECN;
    end
    % Match FAME.jl's create-object defaults: basis = daily, observed =
    % summed for a floating-point series (FAME rejects observed=undefined
    % here, status HBOBSV/27).  observed is metadata only and does not affect
    % the stored values.
    tse.fame.CHLI.newobj(dbkey, name, K.HSERIE, freq, type, K.HBSDAY, K.HOBSUM);

    first = t.firstdate;
    last  = first + (numel(t.values) - 1);
    range = int32([freq, tse.fame.to_date(first), tse.fame.to_date(last)]);
    tse.fame.CHLI.writerange(dbkey, name, range, t.values);
end
