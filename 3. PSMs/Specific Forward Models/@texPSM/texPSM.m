classdef texPSM < PSM
    % The properties are the variables availabe to every instance of a
    % ukPSM object. The actual values of the properties can be different
    % for every ukPSM object.
    properties
        coord;
        % These are the lat-lon coordinates of a particular proxy site.
        % Longitude can be in either 0-360 or -180-180, either is fine.
        Runname = 'SST';
        Type = "standard";
        Stol = 5;  
    end
    
    methods
    % Constructor. This creates an instance of a PSM
        function obj = texPSM( lat, lon, varargin )
        % Get optional inputs
        [runname, type, stol] = parseInputs(varargin, {'Runname','Type','Stol'}, {[],[],[]}, {[],[],[]});
        % Set the coordinates
        obj.coord = [lat lon];
            % Set optional arguments
            if ~isempty(runname)
                obj.Runname = runname;
            end
            if ~isempty(type)
                obj.Type = type;
            end
            if ~isempty(stol)
                obj.Stol = stol;
            end
        end
    end
      % PSM methods
    methods
        
        % State indices
        getStateIndices( obj, ensMeta, sstName, varargin );
        
        % Error checking
        errorCheckPSM( obj );
        
        % Run the forward model
        [tex,R] = runForwardModel( obj, M, ~, ~ );
        
    end      
end