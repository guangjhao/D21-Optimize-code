%===========$Update Time :  2024-12-05 14:47:51 $=========
disp('Loading $Id: v2l_var.m  2024-12-05 14:47:51    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KV2L_HVBattSOCLimit_pct', 	'pct',    0,    20,    'single',    '');
a2l_par('KV2L_SOCV2LSetLimit_pct', 	'pct',    0,    20,    'single',    '');
a2l_par('AV2L_SOCV2LLimit_X_pct', 	'pct',    0,    15,    'single',    '');
a2l_par('MV2L_SOCV2LLimit_Y_pct', 	'pct',    0,    80,    'single',    '');
a2l_par('KV2L_OBCACCurrInfLimit_A', 	'A',    -40,    87.75,    'single',    '');
a2l_par('KV2L_HVPOGrpUpperLimit_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KV2L_HVPOGrplowerLimit_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KV2L_HVPOGrpCheckOvrd_flg', 	'flg',    0,    1,    'boolean',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VV2L_PerdV2LTimer_s', 	's',    0,    28800,    'single',    '');
a2l_mon('VV2L_SOCV2LLimit_pct', 	'pct',    0,    80,    'single',    '');
a2l_mon('VV2L_PerdV2LSet_s', 	's',    0,    28800,    'single',    '');
a2l_mon('VV2L_HVPOGrpCheck_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VV2L_ReqExtrV2LIVIPopup_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VV2L_ReqIntrV2LIVIPopup_enum', 	'enum',    0,    255,    'uint8',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VV2L_ReqOBCV2LEna_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VV2L_ReqV2LIVIPopup_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VV2L_ReqV2LIVIDisChrg_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VV2L_ReqOBCExtrV2LEna_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VV2L_ReqOBCIntrV2LEna_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VV2L_HVPO120VGrpALDSt_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VV2L_HVPO120VGrpBLDSt_enum', 	'enum',    0,    255,    'uint8',    '');
