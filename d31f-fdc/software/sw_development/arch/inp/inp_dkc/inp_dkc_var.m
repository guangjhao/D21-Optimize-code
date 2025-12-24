%===========$Update Time :  2024-11-21 19:02:57 $=========
disp('Loading $Id: inp_dkc_var.m  2024-11-21 19:02:57    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KINP_NFCDoorSta_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_NFCDoorSta_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_NFCLidASta_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_NFCLidASta_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_KeyFobAreaU16_enum_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_KeyFobAreaU16_enum_ovrdval', 	'enum',    0,    65535,    'uint16',    '');
a2l_par('KINP_UIDButtonCmd_enum_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_UIDButtonCmd_enum_ovrdval', 	'enum',    0,    255,    'uint8',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VINP_DKCDecReVehData_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecRemotePW_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecPCommandToBCM_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecPCommandToPTG_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecPDKeyAreaLockUnlock_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecPDKeyAreaPS_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecPDKeyAreaPTG_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecPDKeyWelcome_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecPDkeyShowIVI_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecPKeyMiss_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VINP_DKCDecPKeyMode_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VINP_DKCDecPUIDLowPower_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VINP_TimeSNDKCFbk_cnt', 	'cnt',    0,    4294967295,    'uint32',    '');
a2l_mon('VINP_DKCDecryptionFail_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VINP_NFCDoorSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VINP_NFCLidASta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VINP_KeyFobAreaU16_enum', 	'enum',    0,    65535,    'uint16',    '');
a2l_mon('VINP_UIDButtonCmd_enum', 	'enum',    0,    255,    'uint8',    '');
