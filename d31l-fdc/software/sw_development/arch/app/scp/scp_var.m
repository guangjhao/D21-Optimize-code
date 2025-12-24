%===========$Update Time :  2024-07-31 11:42:27 $=========
disp('Loading $Id: scp_var.m  2024-07-31 11:42:27    foxtron $      FVT_export_businfo_v3.0 2022-09-06')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KSCP_IniGWVehSpeed_kph', 	'kph',    0,    255.875,    'single',    '');
a2l_par('KSCP_IniGWBrkPedalPos_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KSCP_IniGWBrkPedalPosSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSCP_IniGWMCPressure_bar', 	'bar',    -9.7,    195,    'single',    '');
a2l_par('KSCP_IniGWBrkSwV_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSCP_IniGWMCPressureV_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSCP_IniGWBrkSwSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSCP_IniGWIVIPTGStaSW_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KSCP_IniGWIVIPTGModeSW_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KSCP_IniGWWalkawayLockSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSCP_IniGWApproachUnlockSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSCP_IniGWTurnSwTimeSet_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KSCP_IniGWSenstivityPosition_enum', 	'enum',    0,    15,    'uint8',    '');
a2l_par('KSCP_IniGWOFFACMODE_enum', 	'enum',    0,    7,    'uint8',    '');
a2l_par('KSCP_IniGWIVIPTGOpenHeight_enum', 	'enum',    0,    7,    'uint8',    '');
a2l_par('KSCP_IniGWDSEATentryfunset_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSCP_IniGWHeadLampSW_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KSCP_IniGWPSEATventreq_enum', 	'enum',    0,    7,    'uint8',    '');
a2l_par('KSCP_IniGWDSEATantiset_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSCP_IniGWHoodLatchSW_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KSCP_IniGWIVIPTGUSStaSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSCP_IniGWIVIISAOffsetSpd_enum', 	'enum',    0,    14,    'uint8',    '');
a2l_par('KSCP_IniGWDSEATventreq_enum', 	'enum',    0,    7,    'uint8',    '');
a2l_par('KSCP_IniGWIVITimeSecond_s', 	's',    0,    63,    'single',    '');
a2l_par('KSCP_IniGWIVITimeMonth_MONTH', 	'MONTH',    0,    12,    'single',    '');
a2l_par('KSCP_IniGWIVITimeCheck_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_par('KSCP_IniGWIVITimeHour_hr', 	'hr',    0,    31,    'single',    '');
a2l_par('KSCP_IniGWIVILocatedSTA_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_par('KSCP_IniGWIVITimeDay_DAY', 	'DAY',    0,    31,    'single',    '');
a2l_par('KSCP_IniGWIVITimeMinute_min', 	'min',    0,    63,    'single',    '');
a2l_par('KSCP_IniGWIVITimeYear_YEAR', 	'YEAR',    2000,    2127,    'single',    '');
a2l_par('KSCP_IniGWSWCmodeSta_flg', 	'flg',    0,    1,    'boolean',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VSCP_CAN4FDVCU1VehSpeed_kph', 	'kph',    0,    255.875,    'single',    '');
a2l_mon('VSCP_CAN4FDDKC1BrkPedalPos_pct', 	'pct',    0,    100,    'single',    '');
a2l_mon('VSCP_CAN4FDDKC1BrkPedalPosSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CAN4FDDKC1MCPressure_bar', 	'bar',    -9.7,    195,    'single',    '');
a2l_mon('VSCP_CAN4FDDKC1BrkSwV_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CAN4FDDKC1MCPressureV_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CAN4FDDKC1BrkSwSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CAN4FDDKC1IVIPTGStaSW_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1IVIPTGModeSW_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1WalkawayLockSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CAN4FDDKC1ApproachUnlockSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CAN4FDDKC1TurnSwTimeSet_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1SenstivityPosition_enum', 	'enum',    0,    15,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1OFFACMODE_enum', 	'enum',    0,    7,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1IVIPTGOpenHeight_enum', 	'enum',    0,    7,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1DSEATentryfunset_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CAN4FDDKC1HeadLampSW_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1PSEATventreq_enum', 	'enum',    0,    7,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1DSEATantiset_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CAN4FDDKC1HoodLatchSW_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1IVIPTGUSStaSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CAN4FDDKC1IVIISAOffsetSpd_enum', 	'enum',    0,    14,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1DSEATventreq_enum', 	'enum',    0,    7,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1IVITimeSecond_s', 	's',    0,    63,    'single',    '');
a2l_mon('VSCP_CAN4FDDKC1IVITimeMonth_MONTH', 	'MONTH',    0,    12,    'single',    '');
a2l_mon('VSCP_CAN4FDDKC1IVITimeCheck_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1IVITimeHour_hr', 	'hr',    0,    31,    'single',    '');
a2l_mon('VSCP_CAN4FDDKC1IVILocatedSTA_enum', 	'enum',    0,    3,    'uint8',    '');
a2l_mon('VSCP_CAN4FDDKC1IVITimeDay_DAY', 	'DAY',    0,    31,    'single',    '');
a2l_mon('VSCP_CAN4FDDKC1IVITimeMinute_min', 	'min',    0,    63,    'single',    '');
a2l_mon('VSCP_CAN4FDDKC1IVITimeYear_YEAR', 	'YEAR',    2000,    2127,    'single',    '');
a2l_mon('VSCP_CAN5FDCONN1SWCmodeSta_flg', 	'flg',    0,    1,    'boolean',    '');
