%===========$Update Time :  2025-06-09 20:47:31 $=========
disp('Loading $Id: outp_array.m  2025-06-09 20:47:31    foxtron $      FVT_export_businfo_v3.0 2022-09-06')
%% Array declaration

global VOUTP_CALID_cnt;
VOUTP_CALID_cnt = Simulink.Signal;
VOUTP_CALID_cnt.CoderInfo.StorageClass = 'ExportedGlobal';
VOUTP_CALID_cnt.DataType = 'uint8';

global VOUTP_ECUNAME_cnt;
VOUTP_ECUNAME_cnt = Simulink.Signal;
VOUTP_ECUNAME_cnt.CoderInfo.StorageClass = 'ExportedGlobal';
VOUTP_ECUNAME_cnt.DataType = 'uint8';

global VOUTP_VinCode_cnt;
VOUTP_VinCode_cnt = Simulink.Signal;
VOUTP_VinCode_cnt.CoderInfo.StorageClass = 'ExportedGlobal';
VOUTP_VinCode_cnt.DataType = 'uint8';
