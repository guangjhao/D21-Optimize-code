%===========$Update Time :  2024-08-27 16:21:19 $=========
disp('Loading $Id: bcm_var.m  2024-08-27 16:21:19    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KBCM_Dummy_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KBCM_ShowUPT_cnt', 	'cnt',    0,    3000,    'uint16',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VBCM_OutMode_enum', 	'enum',    0,    255,    'uint8',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VBCM_HornCtrl_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FRHaltBrakeSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VBCM_FRDisIntEmCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FROpenClosePBCmd_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VBCM_DoorStaSta_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VBCM_BrakeLamp_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_LDRL_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_RDRL_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_ReverseLamp_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_RrFogLamp_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_HBeam_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_LBeam_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_PosLamp_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_HazardSW_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_LTurnLP_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_RTurnLP_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_LSMLPCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_RSMLPCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_TurnLpLActiveCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_TurnLpRActiveCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_BBuzzerCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FrWiperL_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FrWiperH_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_WasherCtrl_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VBCM_RrRmLampBrightCmd_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VBCM_WelcomeDemoSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FrAtmoLampCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_RrAtmoLampCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_TgateHDSWLSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_TgateHDSWRSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_TgateSWLSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_TgateSWRSta_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_LTgateRelCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_RTgateRelCmd_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VBCM_FDDoorOpen_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VBCM_FDDoorstate_enum', 	'enum',    0,    255,    'uint8',    '');
