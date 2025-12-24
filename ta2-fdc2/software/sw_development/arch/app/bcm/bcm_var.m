%===========$Update Time :  2025-04-14 19:05:54 $=========
disp('Loading $Id: bcm_var.m  2025-04-14 19:05:54    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KBCM_FireBuzzerEN_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KBCM_BSDFlashONT_cnt', 	'cnt',    0,    3000,    'uint16',    '');
a2l_par('KBCM_BSDFlashOFFT_cnt', 	'cnt',    0,    3000,    'uint16',    '');
a2l_par('KBCM_BSDRedMode_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_par('KBCM_BSDWarnReqLv_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_par('KBCM_LampONV_V', 	'V',    0,    5,    'single',    '');
a2l_par('KBCM_LampOFFV_V', 	'V',    0,    5,    'single',    '');
a2l_par('KBCM_LightDelayOFFT_Cnt', 	'cnt',    0,    3000,    'uint16',    '');
a2l_par('KBCM_LightDelayONT_Cnt', 	'cnt',    0,    3000,    'uint16',    '');
a2l_par('KBCM_FLTurnLPLv_A', 	'mA',    0,    60000,    'single',    '');
a2l_par('KBCM_RLTurnLPLv_A', 	'mA',    0,    60000,    'single',    '');
a2l_par('KBCM_FRTurnLPLv_A', 	'mA',    0,    60000,    'single',    '');
a2l_par('KBCM_RRTurnLPLv_A', 	'mA',    0,    60000,    'single',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VBCM_FDCBCMLBeamCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMPLampCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMHBeamCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMSMKLCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMSMKRCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMDVRSignalLCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMDVRSignalRCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMBSDBuzzerCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMSLTLpCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMSRTLpCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMLTurnLpCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRTurnLpCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMStopINDCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMSTOPBALLCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMInnerCallBellCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMCallBellCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMWiperHCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMWasherCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMWiperLCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMLDRLCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRDRLCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRFLampCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_TurnLpPatternSta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VBCM_FDCBCMFDoorSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMMDoorSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRDoorSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRoomLpAmbCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMLBSDRCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMLBSDYCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRBSDRCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRBSDYCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMEmExitSWSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_InnerBuzzerModeSta_enum', 	'enum',    0,    5,    'uint8',    '');
a2l_mon('VBCM_FDCBCMInnerBuzzerCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRoomLpAmbSetSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRoomLpSetSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMFRoomLpSetSta_pct', 	'pct',    0,    100,    'uint8',    '');
a2l_mon('VBCM_FDCBCMFRoomLpCmd_pct', 	'pct',    0,    100,    'uint8',    '');
a2l_mon('VBCM_FDCBCMMRoomLpSetSta_pct', 	'pct',    0,    100,    'uint8',    '');
a2l_mon('VBCM_FDCBCMMRoomLpCmd_pct', 	'pct',    0,    100,    'uint8',    '');
a2l_mon('VBCM_FDCBCMRRoomLpSetSta_pct', 	'pct',    0,    100,    'uint8',    '');
a2l_mon('VBCM_FDCBCMRRoomLpCmd_pct', 	'pct',    0,    100,    'uint8',    '');
a2l_mon('VBCM_FDCBCMHelpINDCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMOSDrOpenSWSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VBCM_FDCBCMEmSVCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMFDOpenSVCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMFDCloseSVCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMMDOpenSVCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMMDCloseSVCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMLTurnSWSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRTurnSWSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMRGearSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMBrakeCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDCBCMTurnBuzzerENSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_WakeUp_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_KeepWakeUp_flg', 	'flg',    0,    1,    'boolean',    '');
