function[] = sensorSettings( obj, varargin )
% Specifies settings for an optimal sensor analysis
%
% sensorSettings( ..., 'replace', tf )
% Specifies whether to select sensors with or without replacement. Default
% is with replacement.
%
% sensorSettings( ..., 'nSensor', N )
% Set the number of sensors to locate. Default is 1.
%
% sensorSettings( ..., 'sites', H )
% Limit the possible sensor sites to specific locations. You may include a
% site in H more than once to allow multiple selections in an optimal
% sensor analysis without replacement.
%
% sensorSettings( ..., 'radius', R )
% Limits the selection of new sensors outside of a distance radius of
% selected sensors.
%
% ----- Inputs -----
%
% tf: Scalar logical. True: select sensors with replacement.
%
% N: The number of sensors. A scalar, positive integer.
%
% H: The state vector indices of sensors sites under consideration. Either
%    a logical vector with nState elements, or a vector of linear indices.
%
% R: The radius used to limit sensor placement. Units are km.

% Parse the inputs
curr = obj.settings.optimalSensor;
[replace, N, H, R] = parseInputs( varargin, {'replace', 'nSensor', 'sites', 'radius'},...
    {curr.replace, curr.nSensor, curr.sites, curr.radius}, {[],[],[],[]} );

% Error check
if ~isscalar(replace) || ~islogical(replace)
    error('tf must be a scalar logical.');
elseif ~isnumeric(N) || ~isscalar(N) || N<=0 || mod(N,1)~=0
    error('N must be a positive scalar integer.');
elseif ~isnumeric(R) || ~isscalar(R) || R<0
    error('R must be a scalar, non-negative number.');
end
if islogical(H)
    if ~isvector(H) || length(H)~=obj.nState
        error('logical H indices must be a vector with nState elements (%.f)', obj.nState );
    end
elseif ~isnumeric(H) || ~isvector(H) || any(H<0) || any(H>obj.nState) || any(mod(H,1)~=0)
    error('H is not a vector of linear indices on the interval [1, %.f]', obj.nState );
end

% Save the settings
obj.settings.optimalSensor = struct('replace', tf, 'nSensor', N, 'sites', H, 'radius', R );

end