function[design] = restrictMeta( design, cv, ensDim )
%% Gets the most restrictive metadata for a set of coupled variables.
%
% design: stateDesign
%
% cv: Variable indices of coupled variables
%
% ensDim: Name of ensemble dimensions
%
% ----- Written By -----
% Jonathan King, University of Arizona, 2019

% Initialize a cell to hold allowed metadata for each ensemble dimension
allowMeta = cell( numel(ensDim), 1 );

% Get the intial variable
X = design.var(cv(1));

% For each ensemble dimension
for dim = 1:numel(ensDim)
    
    % Initialize the matching metadata indices with the indices from the
    % first variable
    xd = checkVarDim( X, ensDim{dim} );
    allowMeta{dim} = X.meta.(X.dimID{xd})(X.indices{xd});
    
    % For each remaining variable
    for k = 2:numel(cv)
        Y = design.var(cv(k));
        
        % Get the dimensional metadata
        yd = checkVarDim( Y, ensDim{dim} );
        currMeta = Y.meta.(Y.dimID{yd})(Y.indices{yd});
        
        % Restrict allowed metadata to the union with the current set
        allowMeta{dim} = union( allowMeta{dim}, currMeta );
    end
    
    % Ensure there is some metadata remaining
    if isempty( allowMeta{dim} )
        error(['There are no indices with overlapping metadata for the %s dimension\n]',...
            'of variables: ', sprintf('%s, ',design.varName{cv}), '\b\b'], ensDim{dim} );
    end
    
    % Now assign the overlap indices to each variable
    for k = 1:numel(cv)
        Y = design.var(cv(k));
        yd = checkVarDim(Y, ensDim{dim});
        
        % Assign the indices
        design.var(cv(k)).indices{yd} = getMatchingMetaDex( Y, ensDim{dim}, allowMeta{dim} );
    end
end

end
