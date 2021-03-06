function[] = reconstructVars( obj, vars, ensMeta )
% Specifies to only reconstruct certain variables.
%
% obj.reconstructVars( vars, ensMeta )
% Reconstructs specific variables given the ensemble metadata for the
% prior.
%
% obj.reconstructVars
% Reset to the default of reconstructing all variables.
%
% ----- Inputs -----
%
% vars: The names of the variables to reconstruct. String, cellstring, or
%       character row vector.
%
% ensMeta: The ensemble metadata for the prior.

% Reset to default if no inputs
if (~exist('vars','var') || isempty(vars)) && (~exist('ensMeta','var') || isempty(ensMeta))
    obj.reconstruct = [];
    obj.reconH = [];
    return;
end
    
% Error check
if ~isscalar(ensMeta) || ~isa(ensMeta, 'ensembleMetadata')
    error('ensMeta must be a scalar ensembleMetadata object.');
end
ensMeta.varCheck( vars );
vars = string(vars);

% Check that this ensemble metadata matches the size of M
if isa(obj.M, 'ensemble')
    Mmeta = obj.M.loadMetadata;
    nState = Mmeta.ensSize(1);
else
    nState = size(obj.M,1);
end
if ensMeta.ensSize(1)~=nState
    error('The ensemble metadata does not match the number of state elements (%.f) in the prior.', nState );
end

% Get the indices to reconstruct
nVars = numel(vars);
indices = cell( nVars, 1 );
for v = 1:nVars
    indices{v} = ensMeta.varIndices( vars(v) );
end
indices = cell2mat( indices );

% Convert to logical
reconstruct = false( nState, 1 );
reconstruct( indices ) = true;

% Check if PSM H indices are reconstructed. Throw error for serial
reconH = dash.checkReconH( reconstruct, obj.F );
if ~reconH && strcmpi(obj.type,'serial') && ~obj.append
    error('When using serial updates without appended Ye, you must reconstruct all state elements used to run the PSMs.');
end

% Check if localization exists. Require reset
if ~isempty(obj.localize)
    if iscell(obj.localize)
        w = obj.localize{1};
    else
        w = obj.localize;
    end
    if size(w,1)~=sum(reconstruct)
        error('The previously specified localization weights would no longer match the size of the reconstructed prior. You can reset them with the command:\n\t>> obj.settings(''localize'',[])%s','');
    end
end 

% Set the values
obj.reconstruct = reconstruct;
obj.reconH = reconH;

end