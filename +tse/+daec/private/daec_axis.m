function ax = daec_axis(s)
%DAEC_AXIS  tse.daec.Axis from an axis_t struct returned by libdaec.
    e = daec_enums();
    len = double(s.length);
    switch daec_code('axis_type_t', s.ax_type)
        case e.axis_type_t.axis_plain
            ax = tse.daec.Axis(len);
        case e.axis_type_t.axis_range
            f = daec_code('frequency_t', s.frequency);
            ax = tse.daec.Axis(tse.MIT(f, int64(s.first)), len);
        case e.axis_type_t.axis_names
            if len == 0 || isempty(s.names)
                names = strings(1, 0);
            else
                names = split(string(s.names), newline);
            end
            if numel(names) ~= len
                error('tseries:daec', 'A names axis of length %d holds %d names.', ...
                    len, numel(names));
            end
            ax = tse.daec.Axis(names);
        otherwise
            error('tseries:daec', 'Unknown axis type %s.', string(s.ax_type));
    end
end
