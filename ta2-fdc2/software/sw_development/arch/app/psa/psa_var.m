%===========$Update Time :  2025-05-12 21:01:23 $=========
disp('Loading $Id: psa_var.m  2025-05-12 21:01:23    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KPSA_Keystatus_enum_dovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KPSA_Keystatus_enum_dovrdval', 	'enum',    0,    2,    'uint8',    '');
a2l_par('KPSA_BrkPedalSWON_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KPSA_VehspdSafe_kph', 	'kph',    0,    15,    'uint8',    '');
a2l_par('KPSA_AllowedGearPos_enum', 	'enum',    0,    2,    'uint8',    '');
a2l_par('KPSA_BrkOnTimeForEMStop_s', 	's',    0,    10,    'single',    '');
a2l_par('KPSA_PBOnTimeForEMStop_s', 	's',    0,    10,    'single',    '');
a2l_par('KPSA_PBTrigHoldtime_s', 	's',    0,    10,    'single',    '');
a2l_par('KPSA_KeystatusWaitTime_s', 	's',    0,    10,    'single',    '');
a2l_par('KPSA_AfterrunWaitTime_s', 	's',    0,    1800,    'single',    '');
a2l_par('KPSA_APSPosnSafe_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KPSA_AlcLockPassTime_s', 	's',    0,    100,    'single',    '');
a2l_par('KPSA_AlcLockPass_ovrdflg_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KPSA_AlcLockPass_ovrdval_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KPSA_ActTimeEmergencySD_s', 	's',    0,    3600,    'single',    '');
a2l_par('KPSA_RcvTimeEmergencySD_s', 	's',    0,    3600,    'single',    '');
a2l_par('KPSA_FakeWakeRESET_flg', 	'flg',    0,    1,    'boolean',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VPSA_Keystatus_enum', 	'enum',    0,    2,    'uint8',    '');
a2l_mon('VPSA_PBtrig_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VPSA_EmergencyShutDown_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VPSA_AlcLockPass_flg', 	'flg',    0,    1,    'boolean',    '');
