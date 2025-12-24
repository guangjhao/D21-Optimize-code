%===========$Update Time :  2024-07-05 14:34:56 $=========
disp('Loading $Id: inp_sys_array.m  2024-07-05 14:34:56    foxtron $      FVT_export_businfo_v2.0 2021-11-02')
%% Array declaration

global VINP_USSConfig_raw8;
VINP_USSConfig_raw8 = Simulink.Signal;
VINP_USSConfig_raw8.CoderInfo.StorageClass = 'ExportedGlobal';
VINP_USSConfig_raw8.DataType = 'uint8';

global VINP_TireSize_raw8;
VINP_TireSize_raw8 = Simulink.Signal;
VINP_TireSize_raw8.CoderInfo.StorageClass = 'ExportedGlobal';
VINP_TireSize_raw8.DataType = 'uint8';

global VINP_APSFunConfig_raw8;
VINP_APSFunConfig_raw8 = Simulink.Signal;
VINP_APSFunConfig_raw8.CoderInfo.StorageClass = 'ExportedGlobal';
VINP_APSFunConfig_raw8.DataType = 'uint8';
