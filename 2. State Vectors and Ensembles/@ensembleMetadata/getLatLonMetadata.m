function[latlon] = getLatLonMetadata( obj, varName )
%% Gets the set of lat-lon coordinates for one sequence element of a
% variable in an ensemble.
%
% latlon = obj.getLatLonMetadata( varName )
%
% ----- Inputs -----
%
% varName: The name of the variable

% Get the dimension names
[~,~,~,lon,lat,~,~,~,tri] = getDimIDs;
dims = [lon;lat;tri];

% Get the variable index
v = obj.varCheck(varName);
varName = string(varName);

% Check whether there is any metadata in each dimension
hasmeta = true(3,1);
for d = 1:numel(dims)
    if isscalar( obj.stateMeta.(varName).(dims(d)) ) && isnan( obj.stateMeta.(varName).(dims(d)) )
        hasmeta(d) = false;
    end
end

% Ensure that only one of lat-lon, and tri have metadata
if all(hasmeta)
    error('Variable %s has both tripolar and lat-lon metadata.', varName );
elseif all( ~hasmeta )
    error('Variable %s has neither tripolar nor lat-lon metadata.', varName );
elseif ~all( hasmeta(1:2) ) && ~all( ~hasmeta(1:2) )
    error('Only one of the lat and lon dimensions of variable %s has metadata.', varName );
end

% Get the state indices for the variable
H = obj.varIndices( varName );

% If tripolar
if hasmeta(3)
    
    % Restrict size
    H = H(1:obj.varSize(v,3));
    
    % Get the metadata
    latlon = obj.lookup( tri, H );
    
    % Error check the metadata
    if ~ismatrix( latlon )
        error('The %s data is a spatial mean.', dims(3) );
    elseif size(latlon,2)~=2 || ~isnumeric(latlon)
        error('%s metadata for variable %s must be a 2 column matrix of numeric values.', dims(3), varName);
    end
    
% Otherwise, if lat and lon
else
    
    % Restrict H
    nEls = prod( obj.varSize(v,[1 2]) );
    H = H(1:nEls);
    
    % Get the metadata
    lat = obj.lookup(lat, H);
    lon = obj.lookup(lon, H);
    
    % Error check
    if ~ismatrix(lat)
        error('Variable %s is a spatial mean along the %s dimension.', varName, dims(2) );
    elseif ~isvector(lat) || ~isnumeric(lat)
        error('%s metadata for variable %s must be a vector of numeric values.', dims(2), varName)
    elseif ~ismatrix(lon)
        error('Variable %s is a spatial mean along the %s dimension.', varName, dims(1) );
    elseif ~isvector(lon) || ~isnumeric(lon)
        error('%s metadata for variable %s must be a vector of numeric values.', dims(1), varName);
    end
    
    % Concatenate, give useful error message if failure
    try
        latlon = cat(2, lat, lon);
    catch
        error('The lat and lon metadata cannot be concatenated.');
    end
end
    
end