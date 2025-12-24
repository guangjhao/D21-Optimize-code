%===========$Update Time :  2025-05-08 18:42:10 $=========
disp('Loading $Id: hal_can3_var.m  2025-05-08 18:42:10    foxtron $      FVT_export_businfo_v3.0 2022-09-06')
%% Calibration Name, Units, Min, Max, Data Type, Comment

%% Outputs Signals
% Outputs Signals %
a2l_mon('VHAL_CANMsgInvalidB2TMInfo_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_B2THVRlySta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_CANMsgInvalidB2VBattInfo1_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_B2VBI1BattType_enum', 	'enum',    0,    15,    'uint8',    '');
a2l_mon('VHAL_CANMsgInvalidB2VCurrentLimit_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_B2VAPlsDischgCurr_A', 	'A',    0,    6553.5,    'single',    '');
a2l_mon('VHAL_B2VAvaPlsChgCurr_A', 	'A',    0,    6553.5,    'single',    '');
a2l_mon('VHAL_CANMsgInvalidB2VFult132960_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_B2VHVILFault_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_CANMsgInvalidB2VST1_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_B2VACChgConnSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_B2VACChgNegRlySta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VACChgPosRlySta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VBMUHVSta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VChgMode_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VChgSta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VDCChgConnSta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VDCChgN1RlySta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VDCChgP1RlySta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VMainNegRlySta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_CANMsgInvalidB2VST2_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_B2VFaultCode_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_B2VFaultLv_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VPackCurr_A', 	'A',    -1000,    1000,    'single',    '');
a2l_mon('VHAL_B2VPackInsideVol_V', 	'V',    0,    1000,    'single',    '');
a2l_mon('VHAL_B2VRqHVPwrOff_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_B2VSOC_pct', 	'pct',    0,    100,    'single',    '');
a2l_mon('VHAL_CANMsgInvalidB2VST4_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_B2VMinTempPos_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_CANMsgInvalidB2VST5_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_B2VCellMinVol_V', 	'V',    0,    65.535,    'single',    '');
a2l_mon('VHAL_CANMsgInvalidEWP1_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_EWPPEFault_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_CANMsgInvalidTMMCUSta1_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_AtvDisChgEnFbk_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_MCUCtrlMdSta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VHAL_MCUIGBTEnFbk_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_MotorSpd_rpm', 	'rpm',    -15000,    15000,    'single',    '');
a2l_mon('VHAL_MotorTrq_Nm', 	'Nm',    -5000,    5000,    'single',    '');
a2l_mon('VHAL_CANMsgInvalidTMMCUSta2_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_MCUFailGrade_enum', 	'enum',    0,    15,    'uint8',    '');
a2l_mon('VHAL_MCUTemp_C', 	'C',    -40,    215,    'single',    '');
a2l_mon('VHAL_MCUTrqLimHi_Nm', 	'Nm',    0,    5000,    'single',    '');
a2l_mon('VHAL_MCUTrqLimLo_Nm', 	'Nm',    -5000,    0,    'single',    '');
a2l_mon('VHAL_MotorTemp_C', 	'C',    -40,    215,    'single',    '');
a2l_mon('VHAL_CANMsgInvalidTMMCUSta3_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_MCUDCCur_A', 	'A',    -1000,    1000,    'single',    '');
a2l_mon('VHAL_MCUDCVol_V', 	'V',    0,    1000,    'single',    '');
a2l_mon('VHAL_MCUFailCode_enum', 	'enum',    0,    255,    'uint8',    '');
