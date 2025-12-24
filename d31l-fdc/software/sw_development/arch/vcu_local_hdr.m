%% Header defining EBUS constants

% =========== $Id: vcu_local_hdr.m 1295 2014-07-10 03:09:34Z fenix $  =========
disp('Loading $Id: vcu_local_hdr.m 1295 2021-01-12 03:09:34Z foxtron $')

%-----------------------------
% General global constants
%-----------------------------

TRUE                 = boolean( 1 );
FALSE                = boolean( 0 );

ZERO_FLOAT          = single(0);
ZERO_INT            = uint8(0);
ONE_INT             = uint8(1);

ONE_PERCENT         = single( 0.01 );
HUNDRED             = single( 100 );
PI                  = single( pi );
GRAVITY_G           = single( 9.8 );

MINUSONE_FLOAT      = single(-1);
ONE_FLOAT           = single(1);

%-----------------------------
% Vehicle Parameters
%-----------------------------


%-----------------------------
% Unit conversion constants
%-----------------------------

KPH2MPS             = single( 1000/3600 );
%KPH2RPM             = single( 100/(12*pi*TIRE_RADIUS));
MPH2KPH             = single( 1.6093    );
MPS2KPH             = single( 1/KPH2MPS );
KPH2MPH             = single( 1/MPH2KPH );
RPM2RADPS           = single( 2*pi/60   );
RADPS2RPM           = single( 1/RPM2RADPS);
DEG2RAD             = single( pi/180    );
RAD2DEG             = single( 180/pi    );
W2KW                = single( 1/1000    ); % Will remove after later software review
XX2KXX              = single( 1e-3      );
KXX2XX              = single( 1000      );


EPSILON             = single( 1e-6      );
HOUR2SEC            = single( 3600      );
MIN2SEC             = single( 60	   );

Hr2min              = single( 60	   );
Hr2sec              = single( 3600	   );
W2Wh                = single(0.005/3600);
W2kW                = single(0.001);
pct                 = single(100);

INCH2MM             = single(25.4);
MM2METER            = single(0.001);
RADIUS2DIAMETER     = single(2);
DIAMETER2RADIUS     = single(0.5);

%-----------------------------
% CAN API constants
%-----------------------------
CANFDArray = zeros(1,64);

%-----------------------------
% TPMS API constants
%-----------------------------
TPMSArray           = zeros(1,9);
TPMSGetIdArray      = zeros(1,4);
TPMSDLC             = uint8(9);
TPMSCheckIdArray    = zeros(1,4);

%-----------------------------
% SYS API constants
%-----------------------------
SYSArray      = zeros(1,30);
SYSlength     = uint8(30);

%-----------------------------
% APS API constants
%-----------------------------
APSArray      = zeros(1,12);
APSLength     = uint8(12);

APSLevelArray      = zeros(1,8);
APSLevelLength     = uint8(8);

%-----------------------------
% DID Number and Length constants
%-----------------------------
DIDNum_XWDMode                  	=	uint16(0x0201);
DIDLen_XWDMode                  	=	uint16(1);

DIDNum_DKCKey                   	=	uint16(0x0202);
DIDLen_DKCKey                   	=	uint16(8);

DIDNum_DynoMode                 	=	uint16(0x0203);
DIDLen_DynoMode                 	=	uint16(1);

DIDNum_TurnLampFRThreCurr       	=	uint16(0x0301);
DIDLen_TurnLampFRThreCurr       	=	uint16(1);

DIDNum_TurnLampRRThreCurr       	=	uint16(0x0302);
DIDLen_TurnLampRRThreCurr       	=	uint16(1);

DIDNum_TurnLampFLThreCurr       	=	uint16(0x0303);
DIDLen_TurnLampFLThreCurr       	=	uint16(1);

DIDNum_TurnLampRLThreCurr       	=	uint16(0x0304);
DIDLen_TurnLampRLThreCurr       	=	uint16(1);

DIDNum_FMHTimer                 	=	uint16(0x0305);
DIDLen_FMHTimer                 	=	uint16(1);

DIDNum_AutoLock                 	=	uint16(0x0306);
DIDLen_AutoLock                 	=	uint16(1);

DIDNum_DRLDis                   	=	uint16(0x0307);
DIDLen_DRLDis                   	=	uint16(1);

DIDNum_LFSensorID               	=	uint16(0x0B01);
DIDLen_LFSensorID               	=	uint16(4);

DIDNum_RFSensorID               	=	uint16(0x0B02);
DIDLen_RFSensorID               	=	uint16(4);

DIDNum_LRSensorID               	=	uint16(0x0B03);
DIDLen_LRSensorID               	=	uint16(4);

DIDNum_RRSensorID               	=	uint16(0x0B04);
DIDLen_RRSensorID               	=	uint16(4);

DIDNum_WhlPres                  	=	uint16(0x0B05);
DIDLen_WhlPres                  	=	uint16(4);

DIDNum_WhlTmp                   	=	uint16(0x0B06);
DIDLen_WhlTmp                   	=	uint16(4);

DIDNum_WhlSensorBattSta         	=	uint16(0x0B07);
DIDLen_WhlSensorBattSta         	=	uint16(1);

DIDNum_LFLowPresThre            	=	uint16(0x0B08);
DIDLen_LFLowPresThre            	=	uint16(1);

DIDNum_RFLowPresThre            	=	uint16(0x0B09);
DIDLen_RFLowPresThre            	=	uint16(1);

DIDNum_LRLowPresThre            	=	uint16(0x0B0A);
DIDLen_LRLowPresThre            	=	uint16(1);

DIDNum_RRLowPresThre            	=	uint16(0x0B0B);
DIDLen_RRLowPresThre            	=	uint16(1);

DIDNum_SensorMode               	=	uint16(0x0B0C);
DIDLen_SensorMode               	=	uint16(1);

DIDNum_TPMSLearnSta             	=	uint16(0x0B0D);
DIDLen_TPMSLearnSta             	=	uint16(1);

DIDNum_USSConfig                	=	uint16(0x0901);
DIDLen_USSConfig                	=	uint16(16);

DIDNum_TireSize                 	=	uint16(0x0902);
DIDLen_TireSize                 	=	uint16(16);

DIDNum_APSFunConfig             	=	uint16(0x0903);
DIDLen_APSFunConfig             	=	uint16(16);

%-----------------------------
% DKC Decryption constants
%-----------------------------
global DKCResultData;
DKCResultData = uint8(zeros(1,16));

DID_VCUKey = uint16(0x0202); % 0x0202

global DIDVCUKeyREADBuff;
DIDVCUKeyREADBuff = uint8(zeros(1,8)); % 8 bytes

DIDVCUKeyLength = uint16(8); 

RAW_RANDOMNUMBERY_DEFAULT = uint8([0xb8,0x1e,0xf6,0x14,0xe8,0xef,0xcd,0x8d]); % 0xb81ef614e8efcd8d

%-----------------------------
% HWID API constants
%-----------------------------
global HWIDBuff;
HWIDBuff = uint8(zeros(1,4));

global HWIDLength;
HWIDLength = uint8(4);

%-----------------------------
% FLASH API constants
%-----------------------------

global DID_XWD;
DID_XWD = uint16(513);

global DIDREADBuff;
DIDREADBuff = uint8(zeros(1,1));

global FlashREADBuff;
FlashREADBuff = uint8(zeros(1,256));

global FlashWRITEBuff;
FlashWRITEBuff = Simulink.Signal;
FlashWRITEBuff.CoderInfo.StorageClass = 'ExportedGlobal';
FlashWRITEBuff.DataType = 'uint8';

%-----------------------------
% DTC_List API constants
%-----------------------------

global VDTC_DTCArray_raw32;
VDTC_DTCArray_raw32 = Simulink.Signal;
VDTC_DTCArray_raw32.CoderInfo.StorageClass = 'ExportedGlobal';
VDTC_DTCArray_raw32.DataType = 'uint32';

global VDTC_HeaderArray_raw32;
VDTC_HeaderArray_raw32 = Simulink.Signal;
VDTC_HeaderArray_raw32.CoderInfo.StorageClass = 'ExportedGlobal';
VDTC_HeaderArray_raw32.DataType = 'uint32';

%#########################################################################
% Model execution period
%#########################################################################

C_TICK_TIME_S                    = single(0.005);
C_TASK_5MS_S                     = (	C_TICK_TIME_S      	)	;
C_TASK_10MS_S                    = (	C_TICK_TIME_S * 2  	)	;
C_TASK_100MS_S                   = (	C_TICK_TIME_S * 20 	)	;
C_TASK_1000MS_S                  = (	C_TICK_TIME_S * 200	)	;
C_TASK_30000MS_S                  = (	C_TICK_TIME_S * 6000	)	;
C_TASK_31000MS_S                  = (	C_TICK_TIME_S * 6200	)	;
%#########################################################################
% Model ENUMs
%#########################################################################


%% -------------------------HAL---------------------------------------%

% VHAL_TPMSSta_enum
ENUM_TPMSSTA_NORMAL                     = uint8(  0  );
ENUM_TPMSSTA_LOWBATTERY                 = uint8(  2  );
ENUM_TPMSSTA_TRIGGER                    = uint8(  4  );
ENUM_TPMSSTA_FAT                        = uint8(  8  );
ENUM_TPMSSTA_STORAGE                    = uint8(  16  );

% BSW_NM_STATE
ENUM_NMMCURRENTSTATE_SLEEP              = uint8(  1  );

%% -------------------------INP---------------------------------------%

% For INP library use
ENUM_FAULTSTATE_PASS                      = uint8(  0  );
ENUM_FAULTSTATE_FAIL                      = uint8(  1  );
ENUM_FAULTSTATE_INDETERMINATE             = uint8(  2  );

% VINP_ChrgPlugSta_enum
ENUM_CHRGPLUGSTA_NONE           = uint8(  0  );
ENUM_CHRGPLUGSTA_AC             = uint8(  1  );
ENUM_CHRGPLUGSTA_DC             = uint8(  2  );

% VINP_ExtChrgSta_enum
ENUM_EXTCHRGSTS_NOACTION        = uint8(  0  );
ENUM_EXTCHRGSTS_CHARGING        = uint8(  1  );
ENUM_EXTCHRGSTS_COMPLETE        = uint8(  2  );
ENUM_EXTCHRGSTS_FAULT           = uint8(  3  );

% VINP_OBCFaultSta_enum
ENUM_OBCFAULT_NOFAULT           = uint8(  0  );
ENUM_OBCFAULT_DCVOLT            = uint8(  1  );
ENUM_OBCFAULT_ACVOLT            = uint8(  2  );

% VINP_ShifterHandleCmd_enum
ENUM_SHIFTCOMMAND_N             = uint8(  4  );
ENUM_SHIFTCOMMAND_R             = uint8(  7  );
ENUM_SHIFTCOMMAND_P             = uint8(  2  );
ENUM_SHIFTCOMMAND_D             = uint8(  5  );
ENUM_SHIFTCOMMAND_NONE          = uint8(  0  );

% VINP_HVBattReady4Pre_enum
ENUM_HVBATTREADYPRE_NOTREADY        = uint8(  0  );
ENUM_HVBATTREADYPRE_READY           = uint8(  1  );
ENUM_HVBATTREADYPRE_FAULT           = uint8(  2  );

% VINP_CrashOutputSts_enum
ENUM_CRASHSTATE_NOCRASH             = uint8(  0  );

% VINP_CSWDimSw_enum
ENUM_CSWDIMSW_RELEASE               = uint8(  0  );
ENUM_CSWDIMSW_PRESS                 = uint8(  1  );
ENUM_CSWDIMSW_INVALID               = uint8(  3  );

% VINP_PBWMotorPos_enum
ENUM_PBWPOSITION_DISABLE            = uint8(  0  );
ENUM_PBWPOSITION_MOVING             = uint8(  1  );
ENUM_PBWPOSITION_PARKING            = uint8(  2  );
ENUM_PBWPOSITION_PARKED             = uint8(  3  );
ENUM_PBWPOSITION_BETWEEN            = uint8(  4  );
ENUM_PBWPOSITION_UNPARKING          = uint8(  5  );
ENUM_PBWPOSITION_UNPARKED           = uint8(  6  );

% VINP_PDKeyAreaPS_enum
ENUM_PDKEYRAWPS_UNAVALIABLE 		= uint8(  0  );
ENUM_PDKEYRAWPS_INPS 				= uint8(  1  );
ENUM_PDKEYRAWPS_OUTPS 				= uint8(  2  );
ENUM_PDKEYRAWPS_RESERVE 			= uint8(  3  );

% VINP_PDKeyAreaLockUnlock_enum
ENUM_PDKEYRAWLULOCK_UNAVALIABLE 	= uint8(  0  );
ENUM_PDKEYRAWLULOCK_INLOCK          = uint8(  1  );
ENUM_PDKEYRAWLULOCK_INUNLOCK 		= uint8(  2  );
ENUM_PDKEYRAWLULOCK_RESERVE 		= uint8(  3  );

% VINP_DCDCFaultSta_enum
ENUM_DCDCFAULTSTA_NOTWORKING        = uint8(  0  );
ENUM_DCDCFAULTSTA_WORKING           = uint8(  1  );
ENUM_DCDCFAULTSTA_ANYFAULTLV1       = uint8(  2  );
ENUM_DCDCFAULTSTA_ANYFAULTLV2       = uint8(  3  );

% VINP_ADASACCSta_enum
ENUM_ADASACCSTA_OFF                 = uint8(  0  );
ENUM_ADASACCSTA_STANDBY             = uint8(  1  );
ENUM_ADASACCSTA_ACTIVE              = uint8(  2  );
ENUM_ADASACCSTA_OVERRIDE            = uint8(  3  );
ENUM_ADASACCSTA_SHUTOFF             = uint8(  4  );
ENUM_ADASACCSTA_ERROR               = uint8(  5  );
ENUM_ADASACCSTA_DISABLE             = uint8(  6  );

% VINP_OFFACMODE_enum
ENUM_OFFACMODE_OFF                  = uint8(  0  );
ENUM_OFFACMODE_ON                   = uint8(  1  );
ENUM_OFFACMODE_PET                  = uint8(  2  );
ENUM_OFFACMODE_CAMP                 = uint8(  3  );
ENUM_OFFACMODE_INVALID              = uint8(  7  );

% VINP_IVIPWModeReq_enum
ENUM_IVIPWMODEREQ_NRM               = uint8(  0  );
ENUM_IVIPWMODEREQ_SPORT             = uint8(  1  );
ENUM_IVIPWMODEREQ_ECO               = uint8(  2  );
ENUM_IVIPWMODEREQ_NOREQUEST         = uint8(  3  );

% VINP_IVIPwrLockSW_enum
ENUM_IVIPWRLOCKSW_RELEASE           = uint8(  0  );
ENUM_IVIPWRLOCKSW_PRESS             = uint8(  1  );
ENUM_IVIPWRLOCKSW_INVALID           = uint8(  2  );
ENUM_IVIPWRLOCKSW_UNDEFINED         = uint8(  3  );

% VINP_PwrReq_OTA_enum
ENUM_PWRREQOTA_NOREQUEST 		= uint8(  0  );
ENUM_PWRREQOTA_REQPOWERON 		= uint8(  1  );
ENUM_PWRREQOTA_REQPOWEROFF 		= uint8(  2  );
ENUM_PWRREQOTA_REQPOWERSTDBY 	= uint8(  3  );
ENUM_PWRREQOTA_INVALID	 		= uint8(  4  );

% VINP_SchedChgwake_flg
ENUM_SCHEDCHG_STANDBY	 	    = uint8(  0  );
ENUM_SCHEDCHG_WAKE	 		    = uint8(  1  );

% VINP_HVBPreheatPrecoolSta_enum
ENUM_HVBPRESTA_DEFAULT 			= uint8(  0  );
ENUM_HVBPRESTA_PREHEAT 			= uint8(  1  );
ENUM_HVBPRESTA_PRECOOL 			= uint8(  2  );

% VINP_RePwrReqTboxT_enum
ENUM_REPWRREQTBOX_NOREQUEST		= uint8(  0  );
ENUM_REPWRREQTBOX_REQVEHCHK 	= uint8(  1  );
ENUM_REPWRREQTBOX_REQACTEMP 	= uint8(  2  );
ENUM_REPWRREQTBOX_REQDTC 		= uint8(  3  );
ENUM_REPWRREQTBOX_REQRADIO 		= uint8(  4  );
ENUM_REPWRREQTBOX_REQON 		= uint8(  5  );
ENUM_REPWRREQTBOX_REQPWROFF	 	= uint8(  6  );

% VINP_RePwrReqDKCT_enum
ENUM_REPWRREQDKC_NOREQUEST		= uint8(  0  );
ENUM_REPWRREQDKC_REQVEHCHK 		= uint8(  1  );
ENUM_REPWRREQDKC_REQACTEMP 		= uint8(  2  );
ENUM_REPWRREQDKC_REQDTC 		= uint8(  3  );
ENUM_REPWRREQDKC_REQRADIO 		= uint8(  4  );
ENUM_REPWRREQDKC_REQON 			= uint8(  5  );
ENUM_REPWRREQDKC_REQPWROFF	 	= uint8(  6  );

% VINP_AllowMovThd_OTA_enum
ENUM_ALLOWMOV_ALLOWREADY 		= uint8(  0  );
ENUM_ALLOWMOV_NOTALLOWREADY 	= uint8(  1  );
ENUM_ALLOWMOV_INVALID 			= uint8(  2  );

% VINP_AVMOFFRecButt_flg
ENUM_AVMOFFRECBUTT_OFF 	        = uint8(  0  );
ENUM_AVMOFFRECBUTT_ON 		    = uint8(  1  );

% VINP_MCUWarnF_enum
% VINP_MCUWarnR_enum
ENUM_MCUWARN_LV0                            = uint8(  0  );
ENUM_MCUWARN_LV1                            = uint8(  1  );
ENUM_MCUWARN_LV2                            = uint8(  2  );
ENUM_MCUWARN_LV3                            = uint8(  3  );
ENUM_MCUWARN_NOERROR                        = uint8(  7  );

% VINP_EPBErrSta_enum
ENUM_EPBERROR_NORMAL                        = uint8(  0  );
ENUM_EPBERROR_FAILED                        = uint8(  1  );
ENUM_EPBERROR_DIAGMODE                      = uint8(  2  );

% VINP_EPBSta_enum
ENUM_EPBSTA_APPLIED                         = uint8(  0  );
ENUM_EPBSTA_APPLYING                        = uint8(  1  );
ENUM_EPBSTA_RELEASED                        = uint8(  2  );
ENUM_EPBSTA_RELEASING                       = uint8(  3  );
ENUM_EPBSTA_UNKNOWN                         = uint8(  4  );

% VINP_FrEDUDrtSta_flg
% VINP_RrEDUDrtSta_flg
ENUM_EDUDRTSTA_NORMAL                       = uint8(  0  );
ENUM_EDUDRTSTA_DERATING                     = uint8(  1  );

% VINP_SysMode_enum
ENUM_SYSMODE_PRODUCT              	= uint8(  0  );
ENUM_SYSMODE_ENGINEERING          	= uint8(  1  );
ENUM_SYSMODE_MANUFACTURE          	= uint8(  2  );
ENUM_SYSMODE_EXHIBITION           	= uint8(  3  );
ENUM_SYSMODE_DIAGNOSISOFF         	= uint8(  4  );
ENUM_SYSMODE_DEVELOPING           	= uint8(  5  );

% VINP_TimeGapLevel_enum
ENUM_TIMEGAPLEVEL_OFF               = uint8(  0  );
ENUM_TIMEGAPLEVEL_LEVEL1            = uint8(  1  );
ENUM_TIMEGAPLEVEL_LEVEL2            = uint8(  2  );
ENUM_TIMEGAPLEVEL_LEVEL3            = uint8(  3  );
ENUM_TIMEGAPLEVEL_LEVEL4            = uint8(  4  );

% VINP_ZoneSpdCtrlMode_enum
ENUM_ZONESPDCTRLMODE_OFF          	= uint8(  0  );
ENUM_ZONESPDCTRLMODE_ACC          	= uint8(  1  );
ENUM_ZONESPDCTRLMODE_CC           	= uint8(  2  );
ENUM_ZONESPDCTRLMODE_LIM          	= uint8(  3  );
ENUM_ZONESPDCTRLMODE_ISA          	= uint8(  4  );
ENUM_ZONESPDCTRLMODE_INVALID      	= uint8(  5  );
 
% VINP_ADASISASta_enum
ENUM_ADASISASTA_OFF               	= uint8(  0  );
ENUM_ADASISASTA_ACTIVE            	= uint8(  1  );
ENUM_ADASISASTA_ERROR             	= uint8(  2  );
ENUM_ADASISASTA_DISABLE           	= uint8(  3  );

% VINP_APSStaSys_enum
ENUM_APSSYSTEMSTA_ENABLE			= uint8(  1  );
ENUM_APSSYSTEMSTA_ACTIVE			= uint8(  2  );
ENUM_APSSYSTEMSTA_REMOTEACTIVE		= uint8(  4  );

% VINP_ESCADASSta_enum
ENUM_ESCADASSTA_INTERNAL			= uint8(  0  );
ENUM_ESCADASSTA_PREFILL           	= uint8(  1  );
ENUM_ESCADASSTA_AEB               	= uint8(  2  );
ENUM_ESCADASSTA_DECCONTROL        	= uint8(  3  );
ENUM_ESCADASSTA_VEHHOLD           	= uint8(  4  );
ENUM_ESCADASSTA_VEHASTANDSTILL    	= uint8(  5  );
ENUM_ESCADASSTA_HAPTICBRAKE       	= uint8(  6  );

% VINP_TargetType_enum
ENUM_TARGETTYPE_NONE              	= uint8(  0  );
ENUM_TARGETTYPE_PEDESTRAIN        	= uint8(  1  );
ENUM_TARGETTYPE_VEHICLE           	= uint8(  2  );
ENUM_TARGETTYPE_TWOWHEEL          	= uint8(  3  );
ENUM_TARGETTYPE_TRUCK             	= uint8(  4  );

%% -----------------------PMM------------------------------------
% VPMM_PowerSta_enum
ENUM_POWERSTA_OFF               = uint8(  0  );
ENUM_POWERSTA_OFFC              = uint8(  1  );
ENUM_POWERSTA_OFFA              = uint8(  2  );
ENUM_POWERSTA_STANDBY           = uint8(  3  );
ENUM_POWERSTA_ON                = uint8(  4  );
ENUM_POWERSTA_READY             = uint8(  5  );

% VPMM_SysPowerMode_enum
ENUM_PWRSTASW_OFF               = uint8(  0  );
ENUM_PWRSTASW_OFFCHVCHRG 		= uint8(  1  );
ENUM_PWRSTASW_OFFA              = uint8(  2  );
ENUM_PWRSTASW_STANDBY 			= uint8(  3  );
ENUM_PWRSTASW_ON                = uint8(  4  );
ENUM_PWRSTASW_READY             = uint8(  5  );
ENUM_PWRSTASW_PWRUP             = uint8(  6  );
ENUM_PWRSTASW_PWRDOWN           = uint8(  7  );
ENUM_PWRSTASW_HVCHRGPREACT      = uint8(  8  );
ENUM_PWRSTASW_OFFCLVCHRG 		= uint8(  9  );
ENUM_PWRSTASW_ONHVCHRG 			= uint8(  10  );

% VPMM_PowerUpState_enum 
ENUM_PUSTATE_INITIALIZE             = uint8(  0  );
ENUM_PUSTATE_BATTPACK               = uint8(  1  );
ENUM_PUSTATE_DCDCENABLE             = uint8(  2  );
ENUM_PUSTATE_OBCENABLE              = uint8(  3  );
ENUM_PUSTATE_MCUENABLE              = uint8(  4  );
ENUM_PUSTATE_COMPLETED              = uint8(  5  );
ENUM_PUSTATE_POWERUPFAIL            = uint8(  6  );
ENUM_PUSTATE_SAFETYCHK              = uint8(  7  );
ENUM_PUSTATE_DRVSAFETYCHK           = uint8(  8  );
ENUM_PUSTATE_HVSYSCHK               = uint8(  9  );

% VPMM_PowerUpFault_enum
ENUM_PUFAULT_NOFAULT 					= uint8(  0  );
ENUM_PUFAULT_PRECHRGCHKFAIL 			= uint8(  1  );
ENUM_PUFAULT_BATTUPFAIL 				= uint8(  2  );
ENUM_PUFAULT_DCDCENABLEFAIL 			= uint8(  3  );
ENUM_PUFAULT_OBCENABLEFAIL 				= uint8(  4  );
ENUM_PUFAULT_MCUENABLEFAIL 				= uint8(  5  );
ENUM_PUFAULT_SAFETYCHKFAIL 				= uint8(  6  );
ENUM_PUFAULT_DRVSAFETYCHKFAIL 			= uint8(  7  );
ENUM_PUFAULT_DCDCSETVOLTFAIL 			= uint8(  8  );

% VPMM_PowerDownState_enum
ENUM_PDSTATE_INITIALIZE 			= uint8(  0  );
ENUM_PDSTATE_DCDCDISABLE 			= uint8(  1  );
ENUM_PDSTATE_BATTPACK 				= uint8(  2  );
ENUM_PDSTATE_MCUDISCHRG 			= uint8(  3  );
ENUM_PDSTATE_OBCDISABLE 			= uint8(  4  );
ENUM_PDSTATE_COMPLETE 				= uint8(  5  );
ENUM_PDSTATE_MLVSAFETYCHK 			= uint8(  6  );
ENUM_PDSTATE_MCUDISABLE 			= uint8(  7  );

% VPMM_PowerDownFault_enum
ENUM_PDFAULT_NOFAULT 				= uint8(  0  );
ENUM_PDFAULT_DCDCDISABLE 			= uint8(  1  );
ENUM_PDFAULT_DCDCSTOP 				= uint8(  2  );
ENUM_PDFAULT_OBCDISABLE 			= uint8(  3  );
ENUM_PDFAULT_BATTPDFAIL 			= uint8(  4  );
ENUM_PDFAULT_MCUDISCHRG 			= uint8(  5  );
ENUM_PDFAULT_MCUDISABLE 			= uint8(  6  );
ENUM_PDFAULT_MLVSAFETYFAIL			= uint8(  7  );

% VPMM_HVSysReadyToCharge_enum
ENUM_CHRGREADY_DISCHARGE                  = uint8(  0  );
ENUM_CHRGREADY_CHARGE                     = uint8(  1  );
ENUM_CHRGREADY_FAULT                      = uint8(  2  );
ENUM_CHRGREADY_DISABLE                    = uint8(  3  );

% VPMM_ChrgState_enum (~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~)
ENUM_CHRGSTATE_INITIALIZE         = uint8(  0  );
ENUM_CHRGSTATE_POWERUP            = uint8(  1  );
ENUM_CHRGSTATE_CHARGING           = uint8(  2  );
ENUM_CHRGSTATE_POWERDOWN          = uint8(  3  );
ENUM_CHRGSTATE_FINISH             = uint8(  4  );

% VPMM_ChrgFault_enum (~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~)
ENUM_CHRGFAULT_NOFAULT            = uint8(  0  );

% VPMM_LVSilentChrgSta_enum
ENUM_SILENTCHRGSTA_NONE           = uint8(  0  );
ENUM_SILENTCHRGSTA_CHARGING       = uint8(  1  );
ENUM_SILENTCHRGSTA_COMPLETE       = uint8(  2  );
ENUM_SILENTCHRGSTA_FAULT          = uint8(  3  );

% VPMM_HVChrgPreActionSta_enum
ENUM_CHGPREACT_NOACT 				= uint8(  0  ); 
ENUM_CHGPREACT_REQUESTING 			= uint8(  1  );
ENUM_CHGPREACT_COMPLETE 			= uint8(  2  );
ENUM_CHGPREACT_FAIL 				= uint8(  3  );

% VPMM_HVChrgPreActionErrSta_enum
ENUM_CHGPREACTERRSTA_NOERR 			= uint8(  0  );
ENUM_CHGPREACTERRSTA_OBCPRE			= uint8(  1  );
ENUM_CHGPREACTERRSTA_OBCENA			= uint8(  2  );

% VINP_rePowerSta_enum
ENUM_REMOTECMD_OFF 			    	= uint8(  0  );
ENUM_REMOTECMD_OFFC 				= uint8(  1  );
ENUM_REMOTECMD_OFFA 				= uint8(  2  );
ENUM_REMOTECMD_STANDBY 				= uint8(  3  );
ENUM_REMOTECMD_ON    				= uint8(  4  );

% VPMM_PDKeySta_enum
ENUM_PDKEYSTA_PS 					= uint8(  0  );
ENUM_PDKEYSTA_UNLOCK 				= uint8(  1  );
ENUM_PDKEYSTA_LOCK 					= uint8(  2  );
ENUM_PDKEYSTA_UNAVALIABLE 			= uint8(  3  );

% VPMM_HVBSOCSta_enum
ENUM_HVBSOCSTA_NORMAL               = uint8(  0  );
ENUM_HVBSOCSTA_SOCLOW               = uint8(  1  );
ENUM_HVBSOCSTA_INVALID              = uint8(  2  );

% VPMM_LVSilentChrgLv_enum
ENUM_SILENTCHRGLV_INVALID           = uint8(  0  );
ENUM_SILENTCHRGLV_LV1               = uint8(  1  );
ENUM_SILENTCHRGLV_LV2               = uint8(  2  );
ENUM_SILENTCHRGLV_LV3               = uint8(  3  );

% VPMM_ReVehThdChkSta_enum
ENUM_REVEHSTA_CHECKOK 				= uint8(  0  );
ENUM_REVEHSTA_GEARPOSITIONERROR		= uint8(  1  );
ENUM_REVEHSTA_HVBERR 				= uint8(  2  );
ENUM_REVEHSTA_VEHNOTSTEADYSTATE		= uint8(  3  );
ENUM_REVEHSTA_ANTITHEFTNOTARM		= uint8(  4  );
ENUM_REVEHSTA_ANYDOOROPEN 			= uint8(  5  );
ENUM_REVEHSTA_HVBSOCLOW	 			= uint8(  6  );
ENUM_REVEHSTA_CHECKINVALID			= uint8(  7  );

% VPMM_PwrStaSelect_enum
ENUM_PWRSTASELECT_NOREQUEST	    = uint8(  0  );
ENUM_PWRSTASELECT_GOON 			= uint8(  1  );
ENUM_PWRSTASELECT_GOOFFC 		= uint8(  2  );
ENUM_PWRSTASELECT_GOOFFA	 	= uint8(  3  );

% VPMM_PwrUpReq_enum
ENUM_PWRUPREQ_NOREQUEST 		= uint8(  0  );
ENUM_PWRUPREQ_USERREQPU		 	= uint8(  1  );
ENUM_PWRUPREQ_SYSREQPU		 	= uint8(  2  );

% VPMM_PwrStaConstraint_enum
ENUM_PWRCONSTRAINT_NOREQUEST			= uint8(  0  );
ENUM_PWRCONSTRAINT_PWRSTAON 			= uint8(  1  );
ENUM_PWRCONSTRAINT_HVACTIVE				= uint8(  2  );
ENUM_PWRCONSTRAINT_ONFORTIME		 	= uint8(  3  );
ENUM_PWRCONSTRAINT_HVFORTIME 			= uint8(  4  );

% VPMM_PwrDownReq_enum
ENUM_PWRDOWNREQ_NOREQUEST			= uint8(  0  );
ENUM_PWRDOWNREQ_USERREQPD			= uint8(  1  );
ENUM_PWRDOWNREQ_SYSREQPD		 	= uint8(  2  );

% VPMM_TCountSta_enum
ENUM_TCOUNTSTA_NOCOUNTING 		= uint8(  0  );
ENUM_TCOUNTSTA_TIMMERCOUNTING 	= uint8(  1  );
ENUM_TCOUNTSTA_COUNTINGFINISH 	= uint8(  2  );

% VPMM_PwrStaTOSta_enum
ENUM_PWRSTATOSTA_NORMAL 	= uint8(  0  );
ENUM_PWRSTATOSTA_TIMEOUT 	= uint8(  1  );

% VPMM_LowSOCWarn_enum
ENUM_LOWSOCWARN_NORMAL 		= uint8(  0  );
ENUM_LOWSOCWARN_HVSOCLOW 	= uint8(  1  );

% VPMM_Sched_ChgTOSta_enum
ENUM_SCHEDCHGTO_NORMAL 	    = uint8(  0  );
ENUM_SCHEDCHGTO_TIMEOUT 	= uint8(  1  );

% VPMM_OTAPwrReqOFFChkSta_enum
% VPMM_OTAPwrReqStdChkSta_enum
ENUM_OTACHKSTA_NOREQUEST    = uint8(  0  );
ENUM_OTACHKSTA_NOTIMEOUT    = uint8(  1  );
ENUM_OTACHKSTA_TIMEOUT      = uint8(  2  );

%% ----------------------DHP----------------------------------------%
% VDHP_EAPS12RangeSta_enum
ENUM_RANGESTA_12IN                          = uint8(  0  );
ENUM_RANGESTA_1OUT                          = uint8(  1  );
ENUM_RANGESTA_2OUT                          = uint8(  2  );
ENUM_RANGESTA_12OUT                         = uint8(  3  );

% VDHP_EAPSErrType_enum
ENUM_EAPSERRTYPE_NORMAL 	                = uint8(  0  );
ENUM_EAPSERRTYPE_LIMITED 	                = uint8(  1  );
ENUM_EAPSERRTYPE_NOAPS 	                    = uint8(  2  );

%% ------------------ACC-----------------------------------------%
% VACC_HVTHCMSysAvail_enum
ENUM_THCMSYS_INVALID                    = uint8(  0  );
ENUM_THCMSYS_ACTIVE                     = uint8(  1  );
ENUM_THCMSYS_INACTIVE                   = uint8(  2  );
ENUM_THCMSYS_FAULT                      = uint8(  3  );

% VACC_LVBattVoltSta_enum
ENUM_LVBATTSTA_NORMAL                   = uint8(  0  );                                                                                                                                                                                            
ENUM_LVBATTSTA_FAIL                     = uint8(  1  );
ENUM_LVBATTSTA_RESERVED                 = uint8(  2  );
ENUM_LVBATTSTA_INVALID                  = uint8(  3  );

%% -------------------------TQD----------------------------------------%

% VTQD_GearActualPosn_enum               
ENUM_GEARACTUALPOSN_P                    = uint8(  1  );
ENUM_GEARACTUALPOSN_R                    = uint8(  2  );
ENUM_GEARACTUALPOSN_N                    = uint8(  3  );
ENUM_GEARACTUALPOSN_D                    = uint8(  4  );
ENUM_GEARACTUALPOSN_INVALID              = uint8(  0  );

% VTQD_GearShiftCMD_enum
ENUM_GEARSHIFTCMD_P                      = uint8(  1  );
ENUM_GEARSHIFTCMD_R                      = uint8(  2  );
ENUM_GEARSHIFTCMD_N                      = uint8(  3  );
ENUM_GEARSHIFTCMD_D                      = uint8(  4  );
ENUM_GEARSHIFTCMD_NONE                   = uint8(  0  );

% VTQD_EVDriveMode_enum
ENUM_DRIVEMODE_NRM                       = uint8(  0  );
ENUM_DRIVEMODE_ECO                       = uint8(  1  );
ENUM_DRIVEMODE_SPORT                     = uint8(  2  );
ENUM_DRIVEMODE_LAUNCH                    = uint8(  3  );

% VTQD_EVRegenMode_enum
ENUM_REGENMODE_D                        = uint8(  0  );
ENUM_REGENMODE_B                        = uint8(  1  );

% VTQD_TqSource_enum
ENUM_TQSOURCE_INVALID                   = uint8(  0  );
ENUM_TQSOURCE_INTERNAL                  = uint8(  1  );
ENUM_TQSOURCE_ABS                       = uint8(  2  );
ENUM_TQSOURCE_ROLLABS                   = uint8(  3  ); %Rolling regen(A type) + ABS regen(B type) request
ENUM_TQSOURCE_TCS                       = uint8(  4  );
ENUM_TQSOURCE_CC                        = uint8(  5  );
ENUM_TQSOURCE_ADAS                      = uint8(  6  );
ENUM_TQSOURCE_MSA                       = uint8(  7  );
ENUM_TQSOURCE_APS                       = uint8(  8  );
ENUM_TQSOURCE_ADASFORCEIDLE             = uint8(  9  );

% VTQD_PGearReqCmd_enum
ENUM_PGEARREQCMD_DISABLE                    = uint8(  0  );
ENUM_PGEARREQCMD_LOCK                       = uint8(  1  );
ENUM_PGEARREQCMD_UNLOCK                     = uint8(  2  );
ENUM_PGEARREQCMD_HOLD                       = uint8(  3  );

% VPMM_DrivetrainSelect_enum
ENUM_DRIVETRAIN_RWD                         = uint8(  0  );
ENUM_DRIVETRAIN_FWD                         = uint8(  1  );
ENUM_DRIVETRAIN_AWD                         = uint8(  2  );

% VTQD_TMRotateDirction_enum
ENUM_TMROTATEDIRECTACT_STOP                 = uint8(  0  );
ENUM_TMROTATEDIRECTACT_FORWARD              = uint8(  1  );
ENUM_TMROTATEDIRECTACT_REVERSE              = uint8(  2  );

% VTQD_ShiftGearPosn_enum
ENUM_GEARPOSNTOCAN_P                        = uint8(  0  );
ENUM_GEARPOSNTOCAN_R                        = uint8(  7  );
ENUM_GEARPOSNTOCAN_N                        = uint8(  4  );
ENUM_GEARPOSNTOCAN_D                        = uint8(  5  );
ENUM_GEARPOSNTOCAN_FAIL                     = uint8(  6  );

% VTQD_PButtonSta_enum
ENUM_PBUTTON_RELEASED                       = uint8(  0  );
ENUM_PBUTTON_PRESSED                        = uint8(  1  );
ENUM_PBUTTON_INVALID                        = uint8(  2  );

% VTQD_RegenMode_enum
ENUM_REGENLEVEL_OFF  		                = uint8(  0  );
ENUM_REGENLEVEL_LV1  			            = uint8(  1  );
ENUM_REGENLEVEL_LV2  			            = uint8(  2  );
ENUM_REGENLEVEL_LV3                         = uint8(  3  );
ENUM_REGENLEVEL_LV4  			            = uint8(  4  );
ENUM_REGENLEVEL_LV5  			            = uint8(  5  );
ENUM_REGENLEVEL_OPD  			            = uint8(  6  );
ENUM_REGENLEVEL_INVALID  			        = uint8(  7  );

% VINP_RDCActive_enum
ENUM_CANRDCACTSTA_NOREQUEST                 = uint8(  0  );
ENUM_CANRDCACTSTA_RAMPOUT                   = uint8(  1  );
ENUM_CANRDCACTSTA_EXITIMMEDIATELY           = uint8(  2  );

% VTQD_RDCActSta_enum
ENUM_RDCACTSTA_NOREQUEST                    = uint8(  0  );
ENUM_RDCACTSTA_RAMPOUT                      = uint8(  1  );
ENUM_RDCACTSTA_EXITIMMEDIATELY              = uint8(  2  );

% VTQD_APSReq_enum
ENUM_APSREQ_NOREQUEST                       = uint8(  0  );
ENUM_APSREQ_DECELCTRL                       = uint8(  1  );
ENUM_APSREQ_BRKHOLD                         = uint8(  2  );
ENUM_APSREQ_EPB                             = uint8(  3  );

%VTQD_IVIPwrLockSta_enum
ENUM_PWRLOCKSta_UNLOCKED                    = uint8(  0  );
ENUM_PWRLOCKSta_LOCKED                      = uint8(  1  );
ENUM_PWRLOCKSta_INVALID                     = uint8(  2  );

%% -------------BCM--------------------------------------------------
% KBCM_Antitheft_enum_ovrdval
ENUM_ANTITHEFT_DISARM                       = uint8(  0  );
ENUM_ANTITHEFT_ARM                          = uint8(  1  );
ENUM_ANTITHEFT_WAIT                         = uint8(  2  );
ENUM_ANTITHEFT_ALARM                        = uint8(  3  );


%% -------------TQR--------------------------------------------------
% VTQR_FrTqZeroTrans_enum
% VTQR_RrTqZeroTrans_enum
ENUM_TQZEROTRANS_NOZEROTRANS                = uint8(  0  );
ENUM_TQZEROTRANS_POSITIVE                   = uint8(  1  );
ENUM_TQZEROTRANS_NEGATIVE                   = uint8(  2  );

%% -------------------------NMM----------------------------------------%
% VNMM_SysNMmSta_enum
ENUM_SYSNMMSTA_SLEEP                        = uint8(  0  );
ENUM_SYSNMMSTA_REPEAT                       = uint8(  1  );
ENUM_SYSNMMSTA_NORMAL                       = uint8(  2  );
ENUM_SYSNMMSTA_READYSLEEP                   = uint8(  3  );

%% -------------------------V2L----------------------------------------%
% VV2L_ReqV2LIVIPopup_enum
ENUM_REQV2LIVI_NOREQUEST                    = uint8(  0  );
ENUM_REQV2LIVI_CHECKPLUG                    = uint8(  1  );
ENUM_REQV2LIVI_PLUGINSWOFF                  = uint8(  2  );
ENUM_REQV2LIVI_STOPBYSOC                    = uint8(  3  );
ENUM_REQV2LIVI_SOCTOOLOW                    = uint8(  4  );
ENUM_REQV2LIVI_TIMEUP                       = uint8(  5  );
ENUM_REQV2LIVI_FAULT                        = uint8(  6  ); 

% VINP_V2LSta_enum
ENUM_V2LSTA_NOPLUG                          = uint8(  0  ); 
ENUM_V2LSTA_PLUGIN                          = uint8(  1  );
ENUM_V2LSTA_SWON                            = uint8(  2  );
ENUM_V2LSTA_ERROR                           = uint8(  3  );

% VINP_OBCV2LSta_enum
ENUM_OBCV2LSTA_NOTWORKING                   = uint8(  0  );
ENUM_OBCV2LSTA_WORKING                      = uint8(  1  );
ENUM_OBCV2LSTA_FAULT                        = uint8(  2  );

% VV2L_ReqOBCV2LEna_enum
ENUM_REQOBCV2L_NOREQUEST                    = uint8(  0  );
ENUM_REQOBCV2L_EXTERNALDISCHRG              = uint8(  1  );
ENUM_REQOBCV2L_INTERNALDISCHRG              = uint8(  2  );

%% -------------------------VMC----------------------------------------%
% VVMC_APSShiftPosnReq_enum
ENUM_APSSHIFTPOSNREQ_DEFAULT        = uint8(  0  );
ENUM_APSSHIFTPOSNREQ_PARK           = uint8(  2  );
ENUM_APSSHIFTPOSNREQ_NEUTRAL        = uint8(  4  );
ENUM_APSSHIFTPOSNREQ_DRIVE          = uint8(  5  );
ENUM_APSSHIFTPOSNREQ_FAILURE        = uint8(  6  );
ENUM_APSSHIFTPOSNREQ_REVERSE        = uint8(  7  );

% VVMC_MSACtrlSta_enum	
ENUM_ADASMSASTA_OFF               = uint8(  0  );
ENUM_ADASMSASTA_STANDBY           = uint8(  1  );
ENUM_ADASMSASTA_ACTIVE            = uint8(  2  );
ENUM_ADASMSASTA_UNDERSPEED        = uint8(  3  );
ENUM_ADASMSASTA_OVERSPEED         = uint8(  4  );
ENUM_ADASMSASTA_ERROR             = uint8(  5  );
ENUM_ADASMSASTA_INVAILD           = uint8(  6  );
ENUM_ADASMSASTA_UNLIMIT           = uint8(  7  );
ENUM_ADASMSASTA_ANTILIMIT         = uint8(  8  );

% VVMC_ExtraMSACtrlSta_enum
ENUM_EXTRAMSACTRLSTA_OFF             = uint8(  0  );
ENUM_EXTRAMSACTRLSTA_ANTISPEEDLIMIT  = uint8(  1  );

%% -----------------------GPIO------------------------------------
% VHAL_HWID_enum
ENUM_HWID_XA                = uint8(  0  );
ENUM_HWID_XB1               = uint8(  1  );
ENUM_HWID_XB2               = uint8(  2  );
ENUM_HWID_XC                = uint8(  3  );
ENUM_HWID_XC2               = uint8(  4  );
ENUM_HWID_XD                = uint8(  5  );

%% -----------------------TPM------------------------------------
% VTPM_A1_enum
% VTPM_A2_enum
% VTPM_A3_enum
% VTPM_A4_enum
% VTPM_S1L_enum
% VTPM_S2L_enum
% VTPM_S3L_enum
% VTPM_S4L_enum
ENUM_AN_NONE                 = uint8(  0  );
ENUM_AN_LF                   = uint8(  1  );
ENUM_AN_RF                   = uint8(  2  );
ENUM_AN_LR                   = uint8(  3  );
ENUM_AN_RR                   = uint8(  4  );
ENUM_AN_ELSE                 = uint8(  5  );

% VTPM_S1LowPindi_enum
% VTPM_S2LowPindi_enum
% VTPM_S3LowPindi_enum
% VTPM_S4LowPindi_enum
ENUM_SNLOWPINDI_NORMAL       = uint8(  0  );
ENUM_SNLOWPINDI_HIGH         = uint8(  1  ); 
ENUM_SNLOWPINDI_LOW          = uint8(  2  );

% VTPM_LFPressIndi_enum
% VTPM_RFPressIndi_enum
% VTPM_LRPressIndi_enum
% VTPM_RRPressIndi_enum
ENUM_PRESSINDI_NORMAL        = uint8(  0  );
ENUM_PRESSINDI_HIGH          = uint8(  1  );
ENUM_PRESSINDI_LOW           = uint8(  2  );
ENUM_PRESSINDI_INVALID       = uint8(  3  );

% VTPM_TPMSWarnIndi_enum
ENUM_TPMSWARNINDI_OFF        = uint8(  0  );
ENUM_TPMSWARNINDI_ON         = uint8(  1  );
ENUM_TPMSWARNINDI_FLASH      = uint8(  2  );
ENUM_TPMSWARNINDI_INVALID    = uint8(  3  );

% VOUTP_TPMSLearnStatus_enum
ENUM_TPMSLearnStatus_NOTLEARN   = uint8(  0  );
ENUM_TPMSLearnStatus_LEARNED	= uint8(  1  );
ENUM_TPMSLearnStatus_LEARNFAIL	= uint8(  2  );

% VHAL_TPMSSensorIDRegSta_enum  
ENUM_TPMSSNESORIDREGSTA_START    = uint8(  1  );
ENUM_TPMSSNESORIDREGSTA_STOP     = uint8(  2  );
ENUM_TPMSSNESORIDREGSTA_FINISHED = uint8(  3  );
%% -----------------------DKC------------------------------------
% VDKC_DKCAuthSta_enum
ENUM_DKCAuthSta_NORMAL          = uint8(  0  );
ENUM_DKCAuthSta_DECRYPTIONFAIL  = uint8(  1  );
ENUM_DKCAuthSta_TIMEERROR       = uint8(  2  );
ENUM_DKCAuthSta_INVALID         = uint8(  3  );

%% -----------------------DDM------------------------------------
% VDDM_CANBrkSW2Sta_enum
% VDDM_BrkPedalPosSta_enum
ENUM_BRKSTA_OFF          	= uint8(  0  );
ENUM_BRKSTA_ON  		    = uint8(  1  );
ENUM_BRKSTA_ERROR           = uint8(  2  );

% VDDM_BrakeSW_enum
ENUM_BRKSW_OFF              = uint8(  0  );
ENUM_BRKSW_ON               = uint8(  1  );
ENUM_BRKSW_INVALID          = uint8(  2  );

% VDDM_DrSeatSta_enum
ENUM_DRSEATSTA_EMPTY        = uint8(  0  );
ENUM_DRSEATSTA_OCCUPIED     = uint8(  1  );
ENUM_DRSEATSTA_INVALID      = uint8(  2  );

% VINP_OBCFaultSta_enum
ENUM_OBCFAULTSTA_NOTWORKING         = uint8(  0  );
ENUM_OBCFAULTSTA_WORKING            = uint8(  1  );
ENUM_OBCFAULTSTA_ANYFAULT           = uint8(  2  );
ENUM_OBCFAULTSTA_INVALID            = uint8(  3  );

% VINP_ZoneDrMalfunLevel_enum
% VINP_ZoneFrMalfunLevel_enum
ENUM_ZONEMALFUNLV_NORMAL            = uint8(  0  );
ENUM_ZONEMALFUNLV_1ST               = uint8(  1  );
ENUM_ZONEMALFUNLV_2ND               = uint8(  2  );
ENUM_ZONEMALFUNLV_3RD               = uint8(  3  );
ENUM_ZONEMALFUNLV_4TH               = uint8(  4  );
ENUM_ZONEMALFUNLV_INVALID           = uint8(  5  );

% VAPM_SNSRLayout_enum
ENUM_NOMESSAGE          = uint8(  0  );
ENUM_APS                = uint8(  1  );
ENUM_APA                = uint8(  2  );
ENUM_PAS_F4R4           = uint8(  3  );
ENUM_PAS_F2R4           = uint8(  4  );
ENUM_PAS_R4             = uint8(  5  );
ENUM_PAS_R2F2           = uint8(  6  );
ENUM_PAS_R2             = uint8(  7  );

% VDDM_VehMalfunLevelTemp_enum
ENUM_VEHMALFUNLV_NORMAL            = uint8(  0  );
ENUM_VEHMALFUNLV_1ST               = uint8(  1  );
ENUM_VEHMALFUNLV_2ND               = uint8(  2  );
ENUM_VEHMALFUNLV_3RD               = uint8(  3  );
ENUM_VEHMALFUNLV_4TH               = uint8(  4  );
