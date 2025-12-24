%===========$Update Time :  2024-04-02 13:11:34 $=========
disp('Loading $Id: nmm_var.m  2024-04-02 13:11:34    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KNMM_NormalTimeoutChk_s', 	's',    0,    600,    'single',    '');
a2l_par('KNMM_SleepTimeoutChk_s', 	's',    0,    600,    'single',    '');
a2l_par('KNMM_RdySlpStaDelay_s', 	's',    0,    600,    'single',    '');
a2l_par('KNMM_NrmStaDelay_s', 	's',    0,    600,    'single',    '');
a2l_par('KNMM_NoNMIdDebounce_s', 	's',    0,    10,    'single',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VNMM_AppWakeReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VNMM_NoNMIdDebounced_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VNMM_HandledAcoreRdySlp_flg', 	'flg',    0,    1,    'boolean',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VNMM_AllCANTxReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VNMM_NMmTxReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VNMM_Awake_enum', 	'enum',    0,    15,    'uint8',    '');
a2l_mon('VNMM_CSB_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VNMM_ErrorState_enum', 	'enum',    0,    8,    'uint8',    '');
a2l_mon('VNMM_NodeID_enum', 	'enum',    0,    127,    'uint8',    '');
a2l_mon('VNMM_PNI_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VNMM_RptMsgReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VNMM_WakeUp_enum', 	'enum',    0,    15,    'uint8',    '');
a2l_mon('VNMM_ActiveWU_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VNMM_SysNMmSta_enum', 	'enum',    0,    15,    'uint8',    '');
a2l_mon('VNMM_NetworkReq_flg', 	'flg',    0,    1,    'boolean',    '');
