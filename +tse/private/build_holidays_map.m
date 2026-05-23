function ts = build_holidays_map(col)
%BUILD_HOLIDAYS_MAP  Construct the BDaily boolean holidays TSeries for a column.
%
%   Reads the packed-bit holidays.bin (rows = business days 1970-01-01 ..
%   2049-12-31, one bit per day per country/subdivision, little bit order)
%   and returns a TSeries{BDaily} of logicals where true = a business day
%   that is NOT a holiday.

    here = fileparts(mfilename('fullpath'));
    J = read_holidays_json();
    oh = double(J.output_height);

    fid = fopen(fullfile(here, 'holidays.bin'), 'r');
    if fid < 0
        error('tseries:noMatch', 'Could not open holidays.bin.');
    end
    cleaner = onCleanup(@() fclose(fid));
    bytes = fread(fid, Inf, 'uint8=>uint8');

    perCol = numel(bytes) / oh;
    if perCol ~= floor(perCol)
        error('tseries:noMatch', 'holidays.bin size is not a multiple of output_height.');
    end
    M = reshape(bytes, perCol, oh);
    cb = double(M(:, col)).';            % 1 x perCol
    bitmat = false(8, perCol);           % little bit order
    for k = 1:8
        bitmat(k, :) = logical(bitget(cb, k));
    end
    bits = bitmat(:);

    startMIT = tse.bdaily('1970-01-01');
    ts = tse.TSeries(startMIT, bits);
end
