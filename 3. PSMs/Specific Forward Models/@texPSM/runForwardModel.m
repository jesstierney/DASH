% TEX86 forward model
function[tex,R] = runForwardModel( obj, M, ~, ~ )
    tex = TEX_forward(obj.coord(1),obj.coord(2),M,obj.Runname,obj.Type,obj.Stol);

    % Estimate R from the variance of the model for each ensemble
    % member. (scalar)
    R = mean( var(tex,[],2), 1);

    % Take the mean of the 1500 possible values for each ensemble
    % member as the final estimate. (1 x nEns)
    tex = mean(tex,2);
    % transpose for Ye
    tex = tex';
end