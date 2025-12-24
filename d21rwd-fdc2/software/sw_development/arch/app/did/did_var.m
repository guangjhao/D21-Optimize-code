%===========$Update Time :  2025-05-26 11:04:17 $=========
disp('Loading $Id: did_var.m  2025-05-26 11:04:17    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Calibration Name, Units, Min, Max, Data Type, Comment
a2l_par('KDID_WarnUpPropActiveThres_s', 	'sec',    0,    65535,    'uint16',    '');
a2l_par('KDID_WarnUpVehOperThres_s', 	'sec',    0,    1000,    'single',    '');
a2l_par('KDID_WarnUpVehOperThres_mph', 	'mph',    0,    250,    'single',    '');
a2l_par('KDID_WarnUpVehOperIdleThres_s', 	'sec',    0,    250,    'single',    '');
a2l_par('KDID_WarnUpVehOperIdleThres_mph', 	'mph',    0,    250,    'single',    '');
a2l_par('KDID_PropActiveTripThres_s', 	'sec',    0,    10,    'single',    '');
a2l_par('KDID_PSARResetThres_sec', 	'sec',    0,    4294967295,    'uint32',    '');
a2l_par('KDID_IPSAVehSpdThres_kph', 	'sec',    0,    2,    'single',    '');
a2l_par('KDID_CPSAVehSpdThres_kph', 	'sec',    0,    100,    'single',    '');
a2l_par('ADID_TempRange_C', 	'pct',    0,    100,    'single',    '');
a2l_par('ADID_DODRange_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('ADID_SOCRange_pct', 	'pct',    0,    100,    'single',    '');
a2l_par('KDID_DoDChrgCycle_s', 	'sec',    0,    10,    'single',    '');
a2l_par('KDID_RESSTTEMPRNGAXIS_enum', 	'enum',    0,    1,    'uint8',    '');
a2l_par('KDID_RESSTIMESOCRNGAXIS_enum', 	'enum',    0,    1,    'uint8',    '');
a2l_par('KDID_RESSCNTSDODRNGAXIS_enum', 	'enum',    0,    1,    'uint8',    '');
a2l_par('KDID_TestInput_raw', 	'sec',    0,    10000,    'single',    '');
a2l_par('KDID_FiveKmEquivEnergy_Wh', 	'Wh',    0,    4294967295,    'single',    '');
a2l_par('KDID_FlashInitDIDModelVersion_raw', 	'enum',    0,    255,    'uint8',    '');
a2l_par('KDID_DIDModelVersion_raw', 	'enum',    0,    255,    'uint8',    '');

%% Monitored Signals
% Internal Signals %

%% Outputs Signals
% Outputs Signals %
a2l_mon('VDID_VSS_kph', 	'kph',    0,    255,    'single',    '');
a2l_mon('VDID_RUNTM_s', 	's',    0,    65535,    'uint16',    '');
a2l_mon('VDID_MILDIST_km', 	'km',    0,    65535,    'single',    '');
a2l_mon('VDID_CLRDIST_km', 	'km',    0,    65535,    'single',    '');
a2l_mon('VDID_APPD_pct', 	'pct',    0,    100,    'single',    '');
a2l_mon('VDID_APPE_pct', 	'pct',    0,    100,    'single',    '');
a2l_mon('VDID_ODOMETER_km', 	'km',    0,    429496729.5,    'single',    '');
a2l_mon('VDID_NUMPSATRIPSFLTMEMCLR_cnt', 	'cnt',    0,    65535,    'uint16',    '');
a2l_mon('VDID_PSAR_sec', 	'sec',    0,    4294967295,    'uint32',    '');
a2l_mon('VDID_PSAL_sec', 	'sec',    0,    4294967295,    'uint32',    '');
a2l_mon('VDID_IPSAR_sec', 	'sec',    0,    4294967295,    'uint32',    '');
a2l_mon('VDID_IPSAL_sec', 	'sec',    0,    4294967295,    'uint32',    '');
a2l_mon('VDID_CPSAR_sec', 	'sec',    0,    4294967295,    'uint32',    '');
a2l_mon('VDID_CPSAL_sec', 	'sec',    0,    4294967295,    'uint32',    '');
a2l_mon('VDID_PKER_kphsqr', 	'kphsqr',    0,    4294967295,    'single',    '');
a2l_mon('VDID_PKEL_kphsqr', 	'kphsqr',    0,    4294967295,    'single',    '');
a2l_mon('VDID_ResetCDEODTR_km', 	'km',    0,    429496729.5,    'single',    '');
a2l_mon('VDID_CDEODTR_km', 	'km',    0,    429496729.5,    'single',    '');
a2l_mon('VDID_CDEODTL_km', 	'km',    -40,    215,    'single',    '');
a2l_mon('VDID_QTYPSATRIPSR_cnt', 	'cnt',    0,    4294967295,    'uint32',    '');
a2l_mon('VDID_QTYPSATRIPSL_cnt', 	'cnt',    0,    4294967295,    'uint32',    '');
a2l_mon('VDID_PROTOCOLID_enum', 	'enum',    0,    2,    'uint8',    '');
a2l_mon('VDID_PKERNumerator_kphsqr', 	'kphsqr',    0,    3.4028e+38,    'single',    '');
a2l_mon('VDID_PKELNumerator_kphsqr', 	'kphsqr',    0,    3.4028e+38,    'single',    '');
a2l_mon('VDID_DIDModelVersion_raw', 	'raw',    0,    255,    'uint8',    '');
a2l_mon('VDID_DIDModelVersionChksum_raw', 	'raw',    0,    255,    'uint8',    '');
