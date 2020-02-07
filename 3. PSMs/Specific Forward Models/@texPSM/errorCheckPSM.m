function[] = errorCheckPSM( obj )
    if ~isscalar( obj.H )
        error('H is not the right size.');
    end
end