%===========$Update Time :  2024-03-05 14:38:33 $=========
disp('Loading $Id: hal_imu_var.m  2024-03-05 14:38:33    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KHAL_IMUSta_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KHAL_IMUSta_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VHAL_IMUOffsetValSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_IMUSixAxisValSta_flg', 	'flg',    0,    1,    'boolean',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VHAL_MemOffsetGyroX_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_MemOffsetGyroY_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_MemOffsetGyroZ_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_MemOffsetAccX_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_MemOffsetAccY_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_MemOffsetAccZ_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_SensingGyroX_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_SensingGyroY_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_SensingGyroZ_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_SensingAccX_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_SensingAccY_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
a2l_mon('VHAL_SensingAccZ_raw16', 	'raw16',    -32768,    32767,    'int16',    '');
