%===========$Update Time :  2025-04-23 15:27:44 $=========
disp('Loading $Id: hal_gpio_var.m  2025-04-23 15:27:44    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_mon('VHAL_AccelPedal1Vol_raw', 	'raw',    0,    10,    'single',    '');
a2l_mon('VHAL_AccelPedal2Vol_raw', 	'raw',    0,    10,    'single',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VHAL_AccelPedal1Vol_V', 	'V',    0,    10,    'single',    '');
a2l_mon('VHAL_AccelPedal2Vol_V', 	'V',    0,    10,    'single',    '');
a2l_mon('VHAL_CrashInputFreq_Hz', 	'Hz',    0,    10000,    'single',    '');
a2l_mon('VHAL_CrashInputDuty_pct', 	'pct',    0,    100,    'single',    '');
a2l_mon('VHAL_BrakeSWGPIO_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_EmergencyExitSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_TailgateSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_LeftTurnSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_RightTurnSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_FrontDoorSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_MidDoorSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_OSDoorSwOpen_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_OSDoorSwClose_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_HazardSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_BrakeLampSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_TrunkHanSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_SeatSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_CrashSignalGPIO_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_HWID1_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_HWID2_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_HWID3_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_HWID4_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VHAL_PushButton_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_AlcoholPass_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VHAL_BmsAplus_flg', 	'flg',    0,    1,    'boolean',    '');
