function d = descriptions(res)
%DESCRIPTIONS  Grouped listing of the outputs available in an X13 result.
%
%   d = tse.x13.descriptions(res) returns a struct with fields 'series',
%   'tables' and 'other', each a cellstr of the table codes present.
%
%   Note: the long per-table English descriptions in the Julia
%   _output_descriptions table are not transcribed in this port; consult the
%   X13-ARIMA-SEATS manual for the meaning of each code.
    d = struct();
    d.series = fieldnames(res.series);
    d.tables = fieldnames(res.tables);
    d.other = fieldnames(res.other);
end
