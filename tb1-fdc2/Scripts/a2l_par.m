function a2l_par( VariableName, Units, Min, Max, DataType, Description )
% A2L_PAR
%	To create ASAP2.Parameter variables.
%	$Id: a2l_par.m 281 2012-05-31 16:15:42Z wxia $

created = 0;

try                                     %Error handling without RTW
    val = AUTOSAR4.Parameter;
%     val = Simulink.Parameter;
	created = 1;
catch                                   %#ok<CTCH>
    v = num2str(Min);
    s = [DataType, '([', v, '])'];
    x = eval(s);
    assignin('base', VariableName, x);
end

if created
	val.DataType = DataType;
	val.Min = double(Min);
	val.Max = double(Max);
	val.DocUnits = Units;
	val.Description = Description;
%     val.StorageClass = 'Model default';
 	val.StorageClass = 'Global';
    val.CoderInfo.CustomAttributes.MemorySection = 'CAL';
	% val.Value = DefValue;

	assignin('base', VariableName, val);
end

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

end

