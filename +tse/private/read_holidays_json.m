function J = read_holidays_json()
%READ_HOLIDAYS_JSON  Load the holidays index (country/subdivision -> column).
    here = fileparts(mfilename('fullpath'));
    J = jsondecode(fileread(fullfile(here, 'holidays.json')));
end
