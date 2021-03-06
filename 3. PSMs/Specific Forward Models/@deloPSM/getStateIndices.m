function[] = getStateIndices( obj, ensMeta, sstName, deloName, monthMeta, varargin ) 
% Gets state indices for a deloPSM
%
% obj.getStateIndices( ensMeta, sstName, deloName, monthMeta, varargin )

    % Concatenate the variable names
    % varNames = [string(sstName), string(deloName)];
    % Get the time dimension
    [~,~,~,~,~,~,timeID] = getDimIDs;
    obj.H = ensMeta.closestLatLonIndices( obj.coord, sstName, timeID, monthMeta, varargin{:} );
    obj.H(13) = ensMeta.closestLatLonIndices( obj.coord, deloName);
end