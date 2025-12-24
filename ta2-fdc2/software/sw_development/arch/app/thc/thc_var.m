%===========$Update Time :  2025-04-10 21:23:09 $=========
disp('Loading $Id: thc_var.m  2025-04-10 21:23:09    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('ATHC_ChargingPEUEWPReq_X_C', 	'C',    -50,    150,    'single',    '');
a2l_par('MTHC_ChargingPEUEWPReq_Y_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('ATHC_ChargingPEUFanReq_X_C', 	'C',    -50,    150,    'single',    '');
a2l_par('MTHC_ChargingPEUFanReq_Y_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('ATHC_CoolingMCUFanReq_X_C', 	'C',    -30,    150,    'single',    '');
a2l_par('MTHC_CoolingMCUFanReq_Y_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('ATHC_CoolingMCUEWPReq_X_C', 	'C',    -30,    150,    'single',    '');
a2l_par('MTHC_CoolingMCUEWPReq_Y_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('ATHC_CoolingTMFanReq_X_C', 	'C',    -30,    150,    'single',    '');
a2l_par('MTHC_CoolingTMFanReq_Y_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('ATHC_CoolingTMEWPReq_X_C', 	'C',    -30,    150,    'single',    '');
a2l_par('MTHC_CoolingTMEWPReq_Y_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('ATHC_CoolingPEUFanReq_X_C', 	'C',    -50,    150,    'single',    '');
a2l_par('MTHC_CoolingPEUFanReq_Y_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('ATHC_CoolingPEUEWPReq_X_C', 	'C',    -50,    150,    'single',    '');
a2l_par('MTHC_CoolingPEUEWPReq_Y_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('KTHC_AfterrunningModeCoolFanReq_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KTHC_AfterrunningModeEWPPEReq_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('KTHC_AfterrunMCUStartTemp_C', 	'C',    -50,    255,    'single',    '');
a2l_par('KTHC_AfterrunMCUStopTemp_C', 	'C',    -50,    255,    'single',    '');
a2l_par('KTHC_AfterrunTMStartTemp_C', 	'C',    -50,    255,    'single',    '');
a2l_par('KTHC_AfterrunTMStopTemp_C', 	'C',    -50,    255,    'single',    '');
a2l_par('KTHC_MCUDerationCoolFanReq_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KTHC_PEUDerationCoolFanReq_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KTHC_MCUDerationEWPPEReq_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('KTHC_PEUDerationEWPPEReq_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('KTHC_MCUTempErrCoolFanReq_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KTHC_TMTempErrCoolFanReq_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KTHC_PEUTempErrCoolFanReq_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KTHC_MCUTempErrEWPPEReq_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('KTHC_TMTempErrEWPPEReq_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('KTHC_PEUTempErrEWPPEReq_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('KTHC_PEUDerationTemp_C', 	'C',    -50,    255,    'single',    '');
a2l_par('KTHC_MCUTempError_C', 	'C',    -50,    255,    'single',    '');
a2l_par('KTHC_TMTempError_C', 	'C',    -50,    255,    'single',    '');
a2l_par('KTHC_PEUTempError_C', 	'C',    -50,    255,    'single',    '');
a2l_par('KTHC_EWPPEFaultSpd_rpm', 	'rpm',    0,    15000,    'single',    '');
a2l_par('KTHC_EWPFaultBypassSwitch_flag', 	'flag',    0,    1,    'boolean',    '');
a2l_par('KTHC_CoolingEWPEnSpdDem_rpm', 	'rpm',    0,    15000,    'single',    '');
a2l_par('KTHC_CoolingEWPDisSpdDem_rpm', 	'rpm',    0,    15000,    'single',    '');
a2l_par('KTHC_CoolingFanPWMEn_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KTHC_CoolingFanPWMDis_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KTHC_ServiceModeON_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KTHC_ServiceModeCoolFanCMD_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KTHC_ServiceModeCoolFanReq_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KTHC_ServiceModeEWPPECMD_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KTHC_ServiceModeEWPPEReq_rpm', 	'rpm',    0,    6000,    'single',    '');
a2l_par('KTHC_LostEWPCoolingFan_pct', 	'pct',    0,    100,    'single',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VTHC_PECoolingMode_enum', 	'enum',    0,    4,    'uint8',    '');
a2l_mon('VTHC_ServiceMode_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VTHC_ChargingMode_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VTHC_CoolingMode_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VTHC_OriginalEWPSpdDem_rpm', 	'rpm',    0,    300000,    'single',    '');
a2l_mon('VTHC_EWPSpdDemRelay_flg', 	'flg',    0,    1,    'boolean',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VTHC_EWPPEReq_rpm', 	'rpm',    0,    6375,    'single',    '');
a2l_mon('VTHC_CoolFanReq_pct', 	'pct',    0,    100,    'single',    '');
a2l_mon('VTHC_AfterrunningMode_flg', 	'flg',    0,    1,    'boolean',    '');
