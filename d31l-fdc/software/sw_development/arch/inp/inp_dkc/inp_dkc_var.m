%===========$Update Time :  2023-11-15 09:47:45 $=========
disp('Loading $Id: inp_dkc_var.m  2023-11-15 09:47:45    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment

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
