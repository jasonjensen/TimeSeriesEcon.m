function s = impose_line_length(s, limit, delve)
%IMPOSE_LINE_LENGTH  Wrap spec lines to the X13-ARIMA-SEATS length limit.
%
%   X13 imposes a strict line-length limit on the .spc file it reads.  This
%   splits any over-long line in the cellstr S at spaces (or " + " separators),
%   continuing it on the next line indented by 8 spaces.  Lines containing
%   embedded newlines are processed sub-line by sub-line.  A tab counts as 8.
%
%   The default limit is 132-8 = 124, reserving 8 columns for the indent that
%   each spec block adds.  This is a direct port of the Julia impose_line_length!.
    if nargin < 2 || isempty(limit), limit = 132 - 8; end
    if nargin < 3, delve = true; end

    counter = 1;
    while counter <= numel(s)
        line = s{counter};
        if delve && contains(line, newline)
            sub = strsplit(line, newline, 'CollapseDelimiters', false);
            sub = tse.x13.impose_line_length(sub, limit, false);
            s{counter} = strjoin(sub, newline);
            counter = counter + 1;
            continue
        end
        if local_len(line) > limit
            splitchar = ' ';
            if contains(line, ' + ')
                splitchar = ' + ';
            end
            parts = strsplit(line, splitchar, 'CollapseDelimiters', false);
            best = 2;
            cum = 0;
            for i = 1:numel(parts)
                cum = cum + local_len(parts{i}) + local_len(splitchar);
                if cum > limit
                    best = i - 1;
                    break
                end
            end
            s1 = [strjoin(parts(1:best), splitchar) splitchar];
            s2 = ['        ' strjoin(parts(best+1:end), splitchar)];
            if numel(s1) == 8 && isempty(strtrim(s1)) && local_len(s2) > limit
                error('tseries:noMatch', ...
                    ['Could not split the following line into components shorter than %d. ', ...
                     'Please shorten the argument length:\n%s'], limit, s2);
            end
            s{counter} = s1;
            s = [s(1:counter), {s2}, s(counter+1:end)];
        end
        counter = counter + 1;
    end
end

function n = local_len(str)
    n = numel(str) + 7 * numel(strfind(str, sprintf('\t')));
end
