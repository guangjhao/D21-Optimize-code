%===========$Update Time :  2024-08-22 14:56:52 $=========
disp('Loading $Id: inp_can7_var.m  2024-08-22 14:56:52    foxtron $      FVT_export_businfo_v3.0 2022-09-06')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KINP_CANMsgInvalidDoorFr1_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_CANMsgInvalidDoorFr1_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_DoorFrDoorEmergencysta_enum_defval', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KINP_DoorFrDoorEmergencysta_enum_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_DoorFrDoorEmergencysta_enum_ovrdval', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KINP_DoorFrDooroperationsta_enum_defval', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KINP_DoorFrDooroperationsta_enum_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_DoorFrDooroperationsta_enum_ovrdval', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KINP_DoorFrDoorpositionsta_enum_defval', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KINP_DoorFrDoorpositionsta_enum_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_DoorFrDoorpositionsta_enum_ovrdval', 	'enum',    0,    3,    'uint8',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VINP_CANMsgValidDoorFr1_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VINP_DoorFrDoorEmergencysta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VINP_DoorFrDooroperationsta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VINP_DoorFrDoorpositionsta_enum', 	'enum',    0,    3,    'uint8',    '');
