%===========$Update Time :  2024-07-22 09:11:37 $=========
disp('Loading $Id: acc_var.m  2024-07-22 09:11:37    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KACC_LVBattErrLoThd_V', 	'V',    0,    50,    'single',    '');
a2l_par('KACC_LVBattErrHiThd_V', 	'V',    0,    50,    'single',    '');
a2l_par('KACC_LVBattErrFailtime_s', 	's',    0,    255,    'uint8',    '');
a2l_par('KACC_HVTHCMSysAvail_enum_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KACC_HVTHCMSysAvail_enum_ovrdval', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KACC_HVPwrAvail4THCM_W_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KACC_HVPwrAvail4THCM_W_ovrdval', 	'W',    0,    12650,    'single',    '');
a2l_par('KACC_THCMMaxPwrAvail_W', 	'W',    0,    12650,    'single',    '');
a2l_par('KACC_CACEnableFailTime_s', 	'sec',    0,    30000,    'single',    '');
a2l_par('KACC_TimePresEnoughThd_s', 	'sec',    0,    30000,    'single',    '');
a2l_par('KACC_TimeEACEnDemThd_s', 	'sec',    0,    30000,    'single',    '');
a2l_par('KACC_VehSpdThdForEHPS_kph', 	'kph',    -10,    1000,    'single',    '');
a2l_par('KACC_EHPSEnable_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KACC_EHPSEnable_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KACC_EHPSPSMCheckTime_s', 	's',    0,    3600,    'single',    '');
a2l_par('KACC_EACEnableFailTime_s', 	's',    0,    3600,    'single',    '');
a2l_par('KACC_EACReadyCheckP_kPa', 	'kpa',    0,    3000,    'single',    '');
a2l_par('KACC_EACReadyCheckTime_s', 	's',    0,    3600,    'single',    '');
a2l_par('KACC_EACStartPump_kPa', 	'kpa',    0,    3000,    'single',    '');
a2l_par('KACC_EACStopPump_kPa', 	'kpa',    0,    3000,    'single',    '');
a2l_par('KACC_EACStopPumpTime_s', 	's',    0,    3600,    'single',    '');
a2l_par('KACC_EngModeCheckTO_s', 	's',    0,    3600,    'single',    '');
a2l_par('KACC_EACPumpEngMode_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KACC_EACLowPrWarn_kPa', 	'kpa',    0,    3000,    'single',    '');
a2l_par('KACC_EACLowPressureTO_s', 	's',    0,    3600,    'single',    '');
a2l_par('KACC_EACSelfCheckTO_s', 	's',    0,    3600,    'single',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VACC_EHPSEnable_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EHPSPSMEn_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACRunResponErr_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACEnableFail_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACSelfCheckStart_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACPressLowSet_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACPressHighReset_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACNormalStart_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACEngModeStart_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACOperateStart_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACLowPressure_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACSelfCheckTO_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACSelfCheckPass_flg', 	'flg',    0,    1,    'boolean',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VACC_HVTHCMSysAvail_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VACC_LVBattVoltSta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VACC_VehHVPwrAvail4THCM_W', 	'W',    0,    12650,    'single',    '');
a2l_mon('VACC_EHPSEnDem_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VACC_CACPresWarnSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_CACTempWarnSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VACC_EACEnDem_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VACC_EACPreSelfChkSta_flg', 	'flg',    0,    1,    'boolean',    '');
