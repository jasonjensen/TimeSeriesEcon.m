function idx = to_date(m)
%TO_DATE  Convert a tse.MIT into a FAME date index.
%
%   idx = tse.fame.to_date(tse.qq(2020, 1))
%
%   Uses the constant per-frequency offset between the tse MIT value and the
%   FAME date index (see the private fame_offset helper).  Requires the CHLI
%   to be loaded (tse.fame.startup) except for Unit frequency, whose index
%   equals the raw value.
%
%   See also: tse.fame.from_date, tse.fame.to_range.
    if ~isa(m, 'tse.MIT')
        error('tseries:noMatch', 'to_date expects a tse.MIT.');
    end
    F = tse.frequencyof(m);
    if isa(F, 'tse.Unit')
        idx = double(m.value);
        return
    end
    tse.fame.CHLI.ensure_loaded();
    idx = double(int64(m.value) + fame_offset(F));
end
