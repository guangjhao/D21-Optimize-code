%===========$Update Time :  2025-05-08 18:47:06 $=========
disp('Loading $Id: inp_can2_var.m  2025-05-08 18:47:06    foxtron $      FVT_export_businfo_v3.0 2022-09-06')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KINP_CANMsgInvalidIVIC1000_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_CANMsgInvalidIVIC1000_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_IVIACFanSpdReqCmd_enum_defval', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KINP_IVIACFanSpdReqCmd_enum_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_IVIACFanSpdReqCmd_enum_ovrdval', 	'enum',    0,    3,    'uint8',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VINP_CANMsgValidIVIC1000_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VINP_IVIACFanSpdReqCmd_enum', 	'enum',    0,    3,    'uint8',    '');
