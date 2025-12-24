%===========$Update Time :  2022-12-06 11:29:23 $=========
disp('Loading $Id: acc_var.m  2022-12-06 11:29:23    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KACC_LVBattErrLoThd_V', 	'V',    0,    50,    'single',    '');
a2l_par('KACC_LVBattErrHiThd_V', 	'V',    0,    50,    'single',    '');
a2l_par('KACC_LVBattErrFailtime_s', 	's',    0,    255,    'uint8',    '');
a2l_par('KACC_HVTHCMSysAvail_enum_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KACC_HVTHCMSysAvail_enum_ovrdval', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KACC_HVPwrAvail4THCM_W_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KACC_HVPwrAvail4THCM_W_ovrdval', 	'W',    0,    12650,    'single',    '');
a2l_par('KACC_THCMMaxPwrAvail_W', 	'W',    0,    12650,    'single',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VACC_HVTHCMSysAvail_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VACC_LVBattVoltSta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VACC_VehHVPwrAvail4THCM_W', 	'W',    0,    12650,    'single',    '');
