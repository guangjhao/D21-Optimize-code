function a2l_mon( VariableName, Units, Min, Max, DataType, Description )
% A2L_MON
%	To create ASAP2.Signal variables.
%	$Id: a2l_mon.m 370 2012-06-18 03:43:15Z jchen $

created = 0;
try %#ok<TRYNC>
    val = Simulink.Signal;
	created = 1;
end

if created
	val.Min = double(Min);
	val.Max = double(Max);
	val.DataType = DataType;
	val.DocUnits = Units;
	val.Dimensions = 1;
	val.Description = Description;
	val.RTWInfo.StorageClass = 'exportedGlobal';
    val.Complexity = 'real';
    val.SamplingMode = 'Sample based';
	assignin('base', VariableName, val);
end

% ASAP2.Signal (handle)
%            RTWInfo: [1x1 Simulink.SignalRTWInfo]
%        Description: ''
%           DataType: 'auto'
%                Min: -Inf
%                Max: Inf
%           DocUnits: ''
%         Dimensions: -1
%     DimensionsMode: 'auto'
%         Complexity: 'auto'
%         SampleTime: -1
%       SamplingMode: 'auto'
%       InitialValue: ''


end

