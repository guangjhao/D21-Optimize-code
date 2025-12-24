%===========$Update Time :  2025-03-28 09:48:17 $=========
disp('Loading $Id: scp_var.m  2025-03-28 09:48:17    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KSCP_DelayECBAMandECDT_s', 	's',    0,    3600,    'single',    '');
a2l_par('KSCP_DelayECDTandECDT_s', 	's',    0,    3600,    'single',    '');
a2l_par('KSCP_DelayECDTandRCBAM_s', 	's',    0,    3600,    'single',    '');
a2l_par('KSCP_DelayRCBAMandRCDT_s', 	's',    0,    3600,    'single',    '');
a2l_par('KSCP_DelayRCDTandRCDT_s', 	's',    0,    3600,    'single',    '');
a2l_par('KSCP_DelayRCDTandECBAM_s', 	's',    0,    3600,    'single',    '');
a2l_par('KSCP_MCUMaxRefTq_Nm', 	'Nm',    -10000,    10000,    'single',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VSCP_triggerBAM_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_CFGEM1Ctrl_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_CFGEM1BAMTSize_raw', 	'raw',    0,    65535,    'uint16',    '');
a2l_mon('VSCP_CFGEM1BAMTNum_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_CFGEM1BAMRsv_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_CFGEM1BAMPGN_raw', 	'raw',    0,    4294967295,    'uint32',    '');
a2l_mon('VSCP_triggerDT_flg', 	'flg',    0,    1,    'boolean',    '');
a2l_mon('VSCP_DTbyte0_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_DTbyte1_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_DTbyte2_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_DTbyte3_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_DTbyte4_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_DTbyte5_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_DTbyte6_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VSCP_DTbyte7_raw', 	'raw',    0,    255,    'uint8',    '');
