function span = effective_span(s)
%EFFECTIVE_SPAN  The data span an X13 series spec effectively analyses.
%
%   Starts from the series range, then narrows it by the span or modelspan
%   argument (a range or a tse.x13.Span).  Port of the Julia effective_span.
    span = tse.rangeof(s.data);
    if isa(s.span, 'tse.MITRange')
        span = s.span;
    elseif isa(s.span, 'tse.x13.Span')
        if isa(s.span.b, 'tse.MIT'), span = s.span.b:last(span); end
        if isa(s.span.e, 'tse.MIT'), span = first(span):s.span.e; end
    elseif isa(s.modelspan, 'tse.MITRange')
        span = s.span;
    elseif isa(s.modelspan, 'tse.x13.Span')
        if isa(s.modelspan.b, 'tse.MIT'), span = s.modelspan.b:last(span); end
        if isa(s.modelspan.e, 'tse.MIT'), span = first(span):s.modelspan.e; end
    end
end
