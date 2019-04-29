function[Amean, Avar, Ye, R, update] = dash( M, D, R, F, varargin )
%% Implements paleo data assimilation
%
% [Amean, Avar, Ye, R, update] = dash( M, D, R, F )
% Runs a data assimilation using dynamic forward models and a joint update
% scheme. Returns the updated ensemble mean, updated ensemble variance, and
% forward model estimates. 
% 
% dash( ..., 'serial', true )
% Runs a data assimilation using serial updates.
%
% dash( ..., 'serial', true, 'append', true )
% Run serial updates using the appended Ye method. Ye values are
% calculated for the initial model prior, appended to the state vector, and
% updated through the Kalman Gain. Returns the Ye estimates from the
% initial estimate (Yi), used for updating (Yu), and final estimate (Yf).
%
% dash( ... , 'inflate', inflate )
% Specifies an inflation factor. The covariance of the model ensemble will
% be multiplied by the inflation factor.
%
% dash( ..., 'localize', {w, yloc} )
% dash( ..., 'serial', true, 'localize', w )
% Specifies a covariance localization to use in data assimilation for the 
% joint or serial updating schemes. See the covLocalization.m function.
%
% dash( ..., 'meanOnly', true )
% Only calculates the updated ensemble mean for joint updates. May improve
% runtime if the ensemble mean is the only quantity of interest.
%
% ----- Inputs -----
%
% M: The model ensemble. (nState x nEns)
%
% D: The observations. (nObs x nTime)
%
% R: Observation uncertainty of each proxy measurement. Values for NaN
%    elements are generated dynamically by the PSMs. (nObs x nTime )
%
% F: A cell vector of PSM objects. {nObs x 1}
%
% inflate: A scalar inflation factor. 
%
% w: Model-estimate covariance localization weights. Applied to the Kalman
%    numerator. Required for localization in both serial and joint update
%    schemes. (nState x nObs)
%
% yloc: Estimate-estimate covariance localization weights. Applied to the
%       Kalman denominator. Only required for localization with a joint
%       update scheme. (nObs x nObs)
%
% ----- Outputs -----
%
% Amean: Update analysis mean. (nState x nTime).
%
% Avar: Update analysis variance (nState x nTime).
%
% Ye: Model estimates.
%       serial DA: (nObs x nEns x nTime)
%       joint DA: (nObs x nEns)
% 
% Yi: The initial model estimate for the appended Ye method. (nObs x nEns)
%
% Yu: The model estimate used to update each time step for the appended Ye
%     method. (nObs x nEns x nTime)
%
% Yf: The final model estimate for each time step. (nObs x nEns x nTime)

% ----- Written By -----
% Jonathan King, University of Arizona, 2019

%% Setup 

% Parse inputs
[serial, append, inflate, localize, meanOnly] = parseInputs( varargin, {'serial','append','inflate','localize','meanOnly'}, ...
                                                           {false, false, 1, [], []}, {[],[],[],[],[]} );
                                        
% Error check. Get w and yloc if unspecified.
[w, yloc] = setup( M, D, R, F, inflate, localize, serial, append, meanOnly );

% Apply the inflation factor
M = inflateEnsemble( inflate, M );

% Setup for the appended Ye method
if append
    [M, F] = appendSetup( M, F );
end

% Run a serial or jointly updating data assimilation
if serial
    [Amean, Avar, Ye, R, update] = serialENSRF( M, D, R, F, w );
else
    [Amean, Avar, Ye, R, update] =  jointENSRF( M, D, R, F, w, yloc, meanOnly );
end

% Finish for the appened Ye method
if append
    [Amean, Avar] = unappendEnsemble( Amean, Avar, numel(F) );
end

end

function[w, yloc] = setup( M, D, R, F, inflate, localize, serial, append, meanOnly )

% Check that M is a matrix of real, numeric value without NaN or Inf
if ~ismatrix(M) || ~isreal(M) || ~isnumeric(M) || any(isinf(M(:))) || any(isnan(M(:)))
    error('M must be a matrix of real, numeric, finite values and may not contain NaN.');
end
    
% Check that observations are a matrix of real, numeric values
if ~ismatrix(D) || ~isreal(D) || ~isnumeric(D) || any(isinf(D(:)))
    error('D must be a matrix of real, numeric, finite values.');
end

% Get the number of state elements
nState = size(M,1);
[nObs] = size(D,1);

% Check R is real, numeric, finite, and non-negative
if ~ismatrix(R) || ~isreal(R) || ~isnumeric(R) || any(isinf(R(:)))
    error('R must be a matrix of real, numeric, finite values.');
elseif any( R(:) < 0 )
    error('R cannot contain negative values.');
elseif size(R,1)~=size(D,1) || size(R,2)~=size(D,2)
    error('The number of rows and columns in R do not match the number in D.');
end

% Check F
if ~isvector( F )
    error('F must be a vector of PSM objects.');
elseif numel(F) ~= size(D,1)
    error('The number of PSMs does not match the number of observations.');
end
for k = 1:nObs
    
    % Check that each element is a PSM
    if ~isa( F{k}, 'PSM' )
        error('Element %.f of F is not a PSM', k);
    end
    
    % Have the PSM do an internal error check
    F{k}.reviewPSM;
end

%% Flags

% Check that the true/false flags are scalar logicals
flag = {serial, append, meanOnly};
flagStr = {'serial','append','meanOnly'};
for f = 1:3
    if ~isscalar( flag{f} ) || ~islogical( flag{f} )
        error('The value following the %s flag must be a scalar logical.', flagStr{f} );
    end 
end

if ~serial && append
    error('Cannot use the appended method with joint updates.')
elseif serial && meanOnly
    error('The serial update scheme cannot only update the ensemble mean. It must also update the deviations.');
end


%% Inflation

% Inflation factor
if ~isscalar(inflate) || inflate<=0 || isinf(inflate) || isnan(inflate) || ~isnumeric(inflate)
    error('The inflation factor must be a scalar greater than 0. It must be real, numeric, finite and not NaN.');
end


%% Covariance localization

% Do a default of no localization if unspecified
if isempty( localize )
    w = ones(nState, nObs);
    yloc = ones(nObs, nObs);

% Otherwise, check everything...
elseif serial
    w = localize;
    yloc = ones(nObs, nObs);

% If not serial, must be a 2 element cell
else
    if ~iscell(localize) || numel(localize)~=2
        error('The input following the "localize" flag must be a cell with 2 elements for joint updates.');
    end
    w = localize{1};
    yloc = localize{2};
end

% Check that w and yloc are good
if ~ismatrix(w) || ~isnumeric(w) || ~isreal(w)
    error('w must be a real, numeric matrix.');
elseif size(w,1) ~= nState
    error('The number of rows in w does not match the number of state elements (i.e. rows of M).');
elseif size(w,2)~=size(D,1)
    error('The number of columns in w must match the number of rows in D.');
end
if ~ismatrix(yloc) || ~isnumeric(yloc) || ~isreal(yloc)
    error('yloc must be a real, numeric matrix.');
elseif size(yloc,1) ~= nObs
    error('The number of rows in yloc does not match the number of observations (rows of D).');
elseif size(yloc,2) ~= nObs
    error('The number of columns in yloc does not match the number of observations (rows of D).');
end

end