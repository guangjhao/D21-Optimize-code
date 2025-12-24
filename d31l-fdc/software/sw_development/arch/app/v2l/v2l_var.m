%===========$Update Time :  2023-09-27 13:53:15 $=========
disp('Loading $Id: v2l_var.m  2023-09-27 13:53:15    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KV2L_HVBattSOCLimit_pct', 	'pct',    0,    20,    'single',    '');
a2l_par('KV2L_SOCV2LSetLimit_pct', 	'pct',    0,    20,    'single',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VV2L_PerdV2LSet_s', 	's',    0,    28800,    'single',    '');
a2l_mon('VV2L_PerdV2LTimer_s', 	's',    0,    28800,    'single',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VV2L_ReqOBCV2LEna_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VV2L_ReqV2LIVIPopup_enum', 	'enum',    0,    255,    'uint8',    '');
