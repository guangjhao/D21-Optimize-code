%===========$Update Time :  2024-03-04 11:08:57 $=========
disp('Loading $Id: hal_tpms_var.m  2024-03-04 11:08:57    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KHAL_TPMSRESBUTT_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KHAL_TPMSRESBUTT_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VHAL_GetId_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_ChkId_flg', 	'flg',    0,    1,    'boolean',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VHAL_TPMSDataIn_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_TPMSID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_TPMSPressure_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VHAL_TPMSTemp_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VHAL_TPMSSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_TPMSPressureMi_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VHAL_TPMSCRC_crc', 	'crc',    0,    255,    'uint8',    '');
a2l_mon('VHAL_TPMSCRCCalc_crc', 	'crc',    0,    255,    'uint8',    '');
a2l_mon('VHAL_TPMSFAT_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_TPMSBattLow_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_TPMSStorge_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_LFID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_RFID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_LRID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_RRID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_ChkStorge_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_ChkLFID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_ChkRFID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_ChkLRID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_ChkRRID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_FlashLFSensorFail_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_FlashRFSensorFail_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_FlashLRSensorFail_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_FlashRRSensorFail_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_FlashLFWheelPSW_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRFWheelPSW_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashLRWheelPSW_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRRWheelPSW_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashLFPindi_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRFPindi_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashLRPindi_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRRPindi_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashLFP20_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRFP20_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashLRP20_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRRP20_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashLFWheelPress_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRFWheelPress_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashLRWheelPress_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRRWheelPress_raw8', 	'raw8',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashLFWheelTemp_C', 	'C',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRFWheelTemp_C', 	'C',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashLRWheelTemp_C', 	'C',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashRRWheelTemp_C', 	'C',    0,    255,    'uint8',    '');
a2l_mon('VHAL_FlashunlearnSfali_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_S1ID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_S2ID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_S3ID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_S4ID_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VHAL_Prepresstemptrust_flg', 	'flg',    0,    1,    'boolean',    '');
