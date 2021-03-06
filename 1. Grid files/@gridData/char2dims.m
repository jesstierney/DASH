function[dims] = char2dims( dimChar )
% Converts a comma delimited character array of dimension names to string
dims = "";
if ~isempty(dimChar)
    comma = strfind(dimChar, ',');
    nDims = numel(comma) + 1;
    dims = cell(1, nDims);

    start = [1, comma+1];
    stop = [comma-1, numel(dimChar)];

    for d = 1:nDims
        dims{d} = dimChar( start(d):stop(d) );
    end

    dims = string( dims );
end

end