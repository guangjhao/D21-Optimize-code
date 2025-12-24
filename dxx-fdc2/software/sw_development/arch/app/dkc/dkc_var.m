%===========$Update Time :  2024-03-25 17:22:00 $=========
disp('Loading $Id: dkc_var.m  2024-03-25 17:22:00    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KDKC_TimeSNAllowDiff_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_par('KDKC_InitialTimeErrorAllow_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_par('KDKC_DKCDecryptionErrorAllow_s', 	's',    0,    1,    'single',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VDKC_DKCTimeSNCorrect_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDKC_DKCDecryptionError_flg', 	'flg',    0,    1,    'boolean',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VDKC_DKCTimeSN_cnt', 	'cnt',    0,    4294967295,    'uint32',    '');
a2l_mon('VDKC_DKCAuthSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecReVehData_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecRemotePW_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecPCommandToBCM_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecPCommandToPTG_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecPDKeyAreaLockUnlock_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecPDKeyAreaPS_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecPDKeyAreaPTG_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecPDKeyWelcome_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecPDkeyShowIVI_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecPKeyMiss_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDKC_DKCDecPKeyMode_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VDKC_DKCDecPUIDLowPower_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDKC_TimeSNDKCFbk_cnt', 	'cnt',    0,    4294967295,    'uint32',    '');
