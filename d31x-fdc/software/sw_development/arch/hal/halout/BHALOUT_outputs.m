function BHALOUT_outputs(varargin)
%===========$Update Time :  2025-03-18 10:31:07 $=========
disp('Loading $Id: BHALOUT_outputs.m  2025-03-18 10:31:07    foxtron $ FVT_export_businfo_v3.0 2022-09-06')
%===========$Update Time :  2025-03-18 10:31:07 $=========
% BXXX_outputs returns a cell array containing bus object information
% Optional Input: 'false' will suppress a call to Simulink.Bus.cellToObject
% when the m-file is executed.
% The order of bus element attributes is as follows:
% ElementName, Dimensions, DataType, SampleTime, Complexity, SamplingMode

suppressObject = false;
if nargin == 1 && islogical(varargin{1}) && varargin{1} == false
suppressObject = true;
elseif nargin > 1
error('Invalid input argument(s) encountered');
end

cellInfo = { ... 
           {... 
    'BHALOUT_outputs',...
       '', ...
       sprintf(''), { ... 
      } ... 
    } ...
  }'; 
if ~suppressObject
    % Create bus objects in the MATLAB base workspace
    Simulink.Bus.cellToObject(cellInfo)
end
end
