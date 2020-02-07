function[uk, R] = runForwardModel( obj, M, ~, ~ )
% Runs the UK forward model. Searches coordinate polygons for seasonal
% areas

% Get the appropriate season for the region
ind = obj.seasonalPolygon;
SST = mean( M(ind,:), 1 );

% Run the forward model, estimate R from the variance of the estimate
uk = UK_forward( SST, obj.bayesFile );
% Estimate R from the variance of the model for each ensemble
    % member. (scalar)
    R = mean( var(uk,[],2), 1);

    % Take the mean of the 1500 possible values for each ensemble
    % member as the final estimate. (1 x nEns)
    uk = mean(uk,2);
    % transpose for Ye
    uk = uk';
end


