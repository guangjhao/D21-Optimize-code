%===========$Update Time :  2024-02-16 16:36:43 $=========
disp('Loading $Id: dsc_var.m  2024-02-16 16:36:43    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KDSC_ActiveAllowTime_s', 	'sec',    0,    10,    'single',    '');
a2l_par('KDSC_DeactiveAllowTime_s', 	'sec',    0,    10,    'single',    '');
a2l_par('KDSC_ActiveSlope_deg', 	'deg',    -25,    25,    'single',    '');
a2l_par('KDSC_StandbySlope_deg', 	'deg',    -25,    25,    'single',    '');
a2l_par('KDSC_TurnAngLimit_deg', 	'deg',    0,    540,    'single',    '');
a2l_par('KDSC_TurnAngExit_deg', 	'deg',    0,    540,    'single',    '');
a2l_par('KDSC_MaxSpeed_kph', 	'kph',    0,    100,    'single',    '');
a2l_par('KDSC_MinSpeed_kph', 	'kph',    0,    100,    'single',    '');
a2l_par('KDSC_SpdRangeHigh_kph', 	'kph',    0,    100,    'single',    '');
a2l_par('KDSC_SpdRangeLow_kph', 	'kph',    0,    100,    'single',    '');
a2l_par('KDSC_TurnAngControlpoint1_kph', 	'kph',    0,    100,    'single',    '');
a2l_par('KDSC_TurnAngControlpoint1_deg', 	'deg',    0,    540,    'single',    '');
a2l_par('KDSC_TurnAngControlpoint2_kph', 	'kph',    0,    100,    'single',    '');
a2l_par('KDSC_TurnAngControlpoint2_deg', 	'deg',    0,    540,    'single',    '');
a2l_par('KDSC_SamplingTime_s', 	'sec',    0,    10,    'single',    '');
a2l_par('KDSC_FirstOrderInpTs_s', 	'sec',    0,    10,    'single',    '');
a2l_par('KINP_DISCButtReq_flg_ovrdval', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KINP_DISCButtReq_flg_ovrdflg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KDSC_BrkPedalOvrd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KDSC_TriggerTimes', 	'sec',    0,    1,    'single',    '');
a2l_par('KDSC_AccPedalOvrd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KDSC_BrkEnBand_pct', 	'sec',    0,    100,    'single',    '');
a2l_par('KDSC_BrkDisBand_pct', 	'sec',    0,    100,    'single',    '');
a2l_par('KDSC_CGRealAxle_m', 	'm',    0,    10,    'single',    '');
a2l_par('KDSC_LongAccelLimit_g', 	'g',    0,    1,    'single',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VDSC_TempWarning_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDSC_DISCLow_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDSC_TurningSpd_kph', 	'kph',    0,    250,    'single',    '');
a2l_mon('VDSC_LowSpd_kph', 	'kph',    0,    250,    'single',    '');
a2l_mon('VDSC_DISCEnableReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDSC_DISCTurnReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDSC_DISCNotTurnReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDSC_DISCActiveReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDSC_DISCActing_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDSC_DISCEstSlope_deg', 	'deg',    0,    40,    'single',    '');
a2l_mon('VDSC_ModeSwitch_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDSC_TurnLimitSpeed_kph', 	'kph',    0,    250,    'single',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VDSC_DISCTurn_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VDSC_DISCTargetSpd_kph', 	'kph',    0,    250,    'single',    '');
a2l_mon('VDSC_DISCSta_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VDSC_DISCButtSta_flg', 	'flg',    0,    1,    'boolean',    '');
