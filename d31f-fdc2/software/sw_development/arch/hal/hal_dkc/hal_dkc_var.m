%===========$Update Time :  2025-05-14 14:05:26 $=========
disp('Loading $Id: hal_dkc_var.m  2025-05-14 14:05:26    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KHAL_DKCDecryptEnable_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KHAL_DKCDecryptEnable_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KHAL_RandomNumberY1_enum', 	'enum',    0,    4294967295,    'uint32',    '');
a2l_par('KHAL_RandomNumberY2_enum', 	'enum',    0,    4294967295,    'uint32',    '');
a2l_par('KHAL_RandomNumberY_ovrdflg', 	'flg',    0,    1,    'boolean',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VHAL_DKCResultData_raw1', 	'raw1',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw2', 	'raw2',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw3', 	'raw3',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw4', 	'raw4',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw5', 	'raw5',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw6', 	'raw6',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw7', 	'raw7',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw9', 	'raw9',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw10', 	'raw10',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw11', 	'raw11',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw12', 	'raw12',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw13', 	'raw13',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw14', 	'raw14',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw15', 	'raw15',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCResultData_raw16', 	'raw16',    0,    255,    'uint8',    '');
a2l_mon('VHAL_EncryptionDATA0631_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_EncryptionDATA0632_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_EncryptionDATA0633_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_EncryptionDATA0634_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_EncryptionDATA0635_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_EncryptionDATA0636_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_EncryptionDATA0637_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_EncryptionDATA0638_enum', 	'enum',    0,    255,    'uint8',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VHAL_DKCDecReVehData_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecRemotePW_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecPCommandToBCM_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecPCommandToPTG_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecPDKeyAreaLockUnlock_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecPDKeyAreaPS_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecPDKeyAreaPTG_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecPDKeyWelcome_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecPDkeyShowIVI_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecPKeyMiss_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_DKCDecPKeyMode_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_DKCDecPUIDLowPower_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_TimeSNDKCFbk_cnt', 	'cnt',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_DKCDecryptionFail_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_NFCDoorSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_NFCLidASta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_KeyFobAreaU16_enum', 	'enum',    0,    65535,    'uint16',    '');
a2l_mon('VHAL_UIDButtonCmd_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_BTConnectSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_UIDBatVoltx1000_V', 	'V',    0,    65535,    'uint16',    '');
a2l_mon('VHAL_DKCBTRSSI_dB', 	'dB',    -128,    127,    'int8',    '');
a2l_mon('VHAL_UWB1Distance_cm', 	'cm',    0,    65535,    'uint16',    '');
a2l_mon('VHAL_UWB2Distance_cm', 	'cm',    0,    65535,    'uint16',    '');
a2l_mon('VHAL_UWB3Distance_cm', 	'cm',    0,    65535,    'uint16',    '');
a2l_mon('VHAL_UWB4Distance_cm', 	'cm',    0,    65535,    'uint16',    '');
a2l_mon('VHAL_UWB5Distance_cm', 	'cm',    0,    65535,    'uint16',    '');
a2l_mon('VHAL_UWB1Power_dB', 	'dB',    -128,    127,    'int8',    '');
a2l_mon('VHAL_UWB2Power_dB', 	'dB',    -128,    127,    'int8',    '');
a2l_mon('VHAL_UWB3Power_dB', 	'dB',    -128,    127,    'int8',    '');
a2l_mon('VHAL_UWB4Power_dB', 	'dB',    -128,    127,    'int8',    '');
a2l_mon('VHAL_UWB5Power_dB', 	'dB',    -128,    127,    'int8',    '');
a2l_mon('VHAL_UWBpositionX_cm', 	'cm',    -32728,    32767,    'int16',    '');
a2l_mon('VHAL_UWBpositionY_cm', 	'cm',    -32728,    32767,    'int16',    '');
a2l_mon('VHAL_UWB1RangingSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_UWB2RangingSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_UWB3RangingSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_UWB4RangingSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_UWB5RangingSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_UWBRangingON_flg', 	'flg',    0,    1,    'boolean',    '');
