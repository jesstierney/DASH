function[] = getStateIndices( obj, ensMeta, sstName, varargin ) 
    obj.H = ensMeta.closestLatLonIndices( obj.coord, sstName);
end