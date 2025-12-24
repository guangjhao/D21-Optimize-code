function a2l_cal( VariableName, DefValue )

% ASAP2.Parameter (handle)
%           Value: []
%         RTWInfo: [1x1 Simulink.ParamRTWInfo]
%     Description: ''
%        DataType: 'auto'
%             Min: -Inf
%             Max: Inf
%        DocUnits: ''
%      Complexity: 'real'
%      Dimensions: [0 0]

try 
    v = evalin('base', VariableName);
catch %#ok<CTCH>
    error([VariableName ' is not defined, stopped.']); 
end

c = class(v);

if	strcmp(c, 'ASAP2.Parameter') ||...
	strcmp(c, 'AUTOSAR4.Parameter') ||...
    strcmp(c, 'Simulink.Parameter') ||...
	strcmp(c, 'mpt.Parameter')

	v.Value = DefValue;
	assignin('base', VariableName, v);
	return;
	
else
%	warning('ASAP2:INVALIDVAR', [VariableName ' is set but not a valid ASAP2 variable.']); %#ok<WNTAG>

	DataType = class(v);

	v = num2str(DefValue);
	[r,c]=size(v); vs='';               %#ok<NASGU>
	for i=1:r
		vs = [vs v(i,:) ';'];           %#ok<AGROW>
	end
	s = [DataType, '([', vs, '])'];
	x = eval(s);
	assignin('base', VariableName, x);
	return;

end

