%===========$Update Time :  2025-04-24 11:21:39 $=========
disp('Loading $Id: inp_ddm_var.m  2025-04-24 11:21:39    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KINP_ClearDTCcmd_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_ClearDTCcmd_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_ClearZevDTCcmd_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_ClearZevDTCcmd_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VINP_ClearDTCcmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VINP_ClearZevDTCcmd_flg', 	'flg',    0,    1,    'boolean',    '');
