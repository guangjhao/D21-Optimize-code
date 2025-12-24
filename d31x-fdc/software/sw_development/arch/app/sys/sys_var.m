%===========$Update Time :  2025-03-28 09:18:15 $=========
disp('Loading $Id: sys_var.m  2025-03-28 09:18:15    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('Dummy', 	'flg',    0,    1,    'boolean',    '');
a2l_par('KSYS_SlpDebounceTime_s', 	's',    0,    1000,    'single',    '');
a2l_par('KSYS_SleepTimeBuffer_sec', 	's',    0,    1800,    'single',    '');
a2l_par('KSYS_NvWrite1_enum', 	'',    0,    255,    'uint8',    '');
a2l_par('KSYS_NvWrite128_enum', 	'',    0,    255,    'uint8',    '');
a2l_par('KSYS_NvWrite256_enum', 	'',    0,    255,    'uint8',    '');
a2l_par('KSYS_NvWriteReq_flg', 	'flg',    0,    1,    'boolean',    '');

%% Monitored Signals
% Internal Signals %
a2l_mon('VSYS_NvmDataRead1_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSYS_NvmDataRead2_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSYS_NvmDataRead31_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSYS_NvmDataRead128_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSYS_NvmDataRead129_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSYS_NvmDataRead201_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSYS_NvmDataRead256_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSYS_NvWriteForSleep_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSYS_NvWriteOnChange_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSYS_NvWriteReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSYS_FdcSlpReq_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSYS_AcoreRebootCmdACKLatch_flg', 	'flg',    0,    1,    'boolean',    '');

%% Outputs Signals
% Outputs Signals %
a2l_mon('VSYS_HWVer1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_HWVer2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_HWVer3_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_CarModel1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_CarModel2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_CarModel3_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_ECU1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_ECU2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Major1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Major2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Minor1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Minor2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Patch1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Patch2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Country1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Country2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Variation_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Dash1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Change1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Change2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Dash2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_SHA1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_SHA2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_SHA3_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_SHA4_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_SHA5_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_SHA6_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_SHA7_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_SHA8_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_NvWriteReqRisingEdge_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSYS_FdcSlpReqRisingEdge_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSYS_FdcSlpTime_sec', 	'sec',    0,    10000000,    'single',    '');
a2l_mon('VSYS_PmicBootReason_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSYS_WisrBootReason_raw32', 	'raw32',    0,    4294967295,    'uint32',    '');
a2l_mon('VSYS_AcoreRebootCmdACK_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSYS_CurrentNmState_enum', 	'enum',    0,    255,    'uint8',    '');
a2l_mon('VSYS_ECUGen1_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_ECUGen2_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_PmicBootPath_raw32', 	'raw32',    0,    4294967295,    'uint32',    '');
a2l_mon('VSYS_DrivingMode_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_ModelYear_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Var4_cnt', 	'cnt',    0,    255,    'uint8',    '');
a2l_mon('VSYS_Var5_cnt', 	'cnt',    0,    255,    'uint8',    '');
