%===========$Update Time :  2025-05-09 09:42:22 $=========
disp('Loading $Id: v2l_cal.m  2025-05-09 09:42:22    foxtron $      FVT_export_businfo_v2.0 2021-11-02')

a2l_cal('KV2L_HVBattSOCLimit_pct',     15); 
a2l_cal('KV2L_SOCV2LSetLimit_pct',     15); 
a2l_cal('KV2L_OBCACCurrInfLimit_A',     0.5); 
a2l_cal('KV2L_HVPOGrpUpperLimit_pct',     90); 
a2l_cal('KV2L_HVPOGrplowerLimit_pct',     20); 
a2l_cal('KV2L_HVPOGrpCheckOvrd_flg',     1); 
a2l_cal('AV2L_SOCV2LLimit_X_pct',     [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]);
a2l_cal('MV2L_SOCV2LLimit_Y_pct',     [20 25 30 35 40 45 50 55 60 65 70 75 80 15 0 0]);
