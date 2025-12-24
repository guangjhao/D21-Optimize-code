% Header defining EBUS constants

% =========== $Id: vcu_local_hdr.m 1295 2014-07-10 03:09:34Z fenix $  =========
disp('Loading $Id: vcu_local_hdrTA2.m 1295 2021-01-12 03:09:34Z foxtron $')

%-----------------------------
% General global constants
%-----------------------------

TRUE                 = boolean( 1 );
FALSE                = boolean( 0 );

ZERO_FLOAT          = single(0);

ZERO_INT            = uint8(0);
ONE_INT             = uint8(1);
TWO_INT             = uint8(2);
FOUR_INT            = uint8(4);
EIGHT_INT           = uint8(8);
TEN_INT             = uint8(10);
SIXTEEN_INT         = uint8(16);
ZERO_INT16          = uint16(0);
ZERO_INT32          = uint32(0);

ONE_PERCENT         = single( 0.01 );
HUNDRED             = single( 100 );
THOUSAND            = single( 1000 );
SIXTY               = single( 60 );
TWO                 = single( 2 );
PI                  = single( pi );
MINUS_ONE           = single( -1 );
EPS                 = single( eps );

%-----------------------------
% Vehicle Parameters
%-----------------------------

TM_GEAR_RATIO        = single( 10.9 ); 

FINAL_DRIVE_RATIO    = single( 3.143 );
TIRE_RADIUS          = single( 0.327 );

%-----------------------------
% Unit conversion constants
%-----------------------------

KPH2MPS             = single( 1000/3600 );
KPH2KPS             = single( 1/3600 );
KPH2RPM             = single( 100/(12*pi*TIRE_RADIUS));
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

SINGLEMAXCNT       = single(655350);
MAX16BITCNT        = single(65535);

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



% VFUN_EVSystemState_enum
ENUM_EVSTATE_OFF      		= uint8(  0  );
ENUM_EVSTATE_PLUGIN      	= uint8(  1  );
ENUM_EVSTATE_EV             = uint8(  2  );

%-----------------------------------------------------------------
% VPSA_Keystatus_enum
%----------------------------------------------------------------- 
ENUM_KEYSTATUS_OFF          = uint8(  0  );
ENUM_KEYSTATUS_ON           = uint8(  1  );
ENUM_KEYSTATUS_START        = uint8(  2  );

%-----------------------------------------------------------------
% VPMM_SysPowerMode_enum
%-----------------------------------------------------------------              
ENUM_PMMMODE_INITIALIZE        = uint8(  0  );
ENUM_PMMMODE_STANDBY           = uint8(  1  );
ENUM_PMMMODE_POWERUP           = uint8(  2  );
ENUM_PMMMODE_DRIVE             = uint8(  3  );
ENUM_PMMMODE_POWERDOWN         = uint8(  4  );
ENUM_PMMMODE_SLEEP             = uint8(  5  );
ENUM_PMMMODE_AFTERRUN          = uint8(  6  );
ENUM_PMMMODE_CHARGE            = uint8(  7  );
ENUM_PMMMODE_IDLE              = uint8(  8  );
ENUM_PMMMODE_LVBATCHRG         = uint8(  9  );
%-----------------------------------------------------------------
% VPMM_PowerUpState_enum
%-----------------------------------------------------------------    
ENUM_PUSTATE_INITIALIZE           = uint8(  0  );
ENUM_PUSTATE_DRIVESAFE            = uint8(  1  );
ENUM_PUSTATE_HVRLYCHECK           = uint8(  2  );
ENUM_PUSTATE_BCUPOSRLYCLOSED      = uint8(  3  );
ENUM_PUSTATE_DCDCRLYCLOSED        = uint8(  4  );
ENUM_PUSTATE_PDURLYCLOSED         = uint8(  5  );
ENUM_PUSTATE_DCDCENABLE           = uint8(  6  );
ENUM_PUSTATE_EHPSENABLE           = uint8(  7  );
ENUM_PUSTATE_PDUMCURLYCLOSED      = uint8(  8  );
ENUM_PUSTATE_MCUENABLE            = uint8(  9  );
ENUM_PUSTATE_EACPRESCHECK         = uint8(  10  );
ENUM_PUSTATE_COMPLETED            = uint8(  11  );
ENUM_PUSTATE_POWERUPFAIL          = uint8(  12  );

%-----------------------------------------------------------------
% VPMM_PowerUpFault_enum
%----------------------------------------------------------------- 
ENUM_PUFAULT_NOFAULT                     = uint8(  0  );
ENUM_PUFAULT_HVCHECKFAIL                 = uint8(  1  );
ENUM_PUFAULT_HVRLYCHKFAIL                = uint8(  2  );
ENUM_PUFAULT_BATTUPFAIL                  = uint8(  3  );
ENUM_PUFAULT_DCDCRLYUPFAIL               = uint8(  4  );
ENUM_PUFAULT_CACRLYUPFAIL                = uint8(  5  );
ENUM_PUFAULT_EHPSRLYUPFAIL               = uint8(  6  );
ENUM_PUFAULT_ACMAINRLYUPFAIL             = uint8(  7  );
ENUM_PUFAULT_DCDCENABLEFAIL              = uint8(  8  );
ENUM_PUFAULT_EHPSENABLEFAIL              = uint8(  9  );
ENUM_PUFAULT_MCUPRECHRGFAIL              = uint8(  10 );
ENUM_PUFAULT_MCUENABLEFAIL               = uint8(  11 );
ENUM_PUFAULT_AIRPRESS                    = uint8(  12 );
ENUM_PUFAULT_ALINTERLOCK                 = uint8(  13 );

%-----------------------------------------------------------------
% VPMM_PowerDownState_enum
%----------------------------------------------------------------- 
ENUM_PDSTATE_MCUDISABLE                   = uint8(  0  );
ENUM_PDSTATE_PDUDISABLE                   = uint8(  1  );
ENUM_PDSTATE_BCUPWRDOWN                   = uint8(  2  );
ENUM_PDSTATE_MCUDISCHRG                   = uint8(  3  );
ENUM_PDSTATE_PDURLYOPEN                   = uint8(  4  );
ENUM_PDSTATE_PDCOMPLETED                  = uint8(  5  );
ENUM_PDSTATE_MCUDISCHRGFS                 = uint8(  6  );
ENUM_PDSTATE_MCUPASSDISCHRG               = uint8(  7  );
ENUM_PDSTATE_BCUNEGRLUFS                  = uint8(  8  );
ENUM_PDSTATE_FSCOMPLETED                  = uint8(  9  );

%-----------------------------------------------------------------
% VPMM_PowerDownFault_enum
%----------------------------------------------------------------- 

ENUM_PDFAULT_NOFAULT                          = uint8(  0  );
ENUM_PDFAULT_MCUDISABLE                       = uint8(  1  );
ENUM_PDFAULT_EHPSDISABLE                      = uint8(  2  );
ENUM_PDFAULT_EACDISABLE                       = uint8(  3  );
ENUM_PDFAULT_DCDCDISABLE                      = uint8(  4  );
ENUM_PDFAULT_BCUDISABLE                       = uint8(  5  );
ENUM_PDFAULT_MCURLYOPEN                       = uint8(  6  );
ENUM_PDFAULT_EHPSRLYOPEN                      = uint8(  7  );
ENUM_PDFAULT_EACRLYOPEN                       = uint8(  8  );
ENUM_PDFAULT_ACRLYOPEN                        = uint8(  9  );
ENUM_PDFAULT_DCDCRLYOPEN                      = uint8(  10  );
ENUM_PDFAULT_MCUDISCHRG                       = uint8(  11  );

%-----------------------------------------------------------------
% VPMM_BattHVDem_enum
%----------------------------------------------------------------- 
ENUM_BATTHVDEM_RESERVED             = uint8(  0  );
ENUM_BATTHVDEM_POWERON              = uint8(  1  );
ENUM_BATTHVDEM_POWEROFF             = uint8(  2  );
ENUM_BATTHVDEM_INVALID              = uint8(  3  );

%-----------------------------------------------------------------
% VPMM_HVSysReady_enum
%----------------------------------------------------------------- 
ENUM_HVSYSREADY_NOTREADY        = uint8(  0  );   
ENUM_HVSYSREADY_READY           = uint8(  1  );
ENUM_HVSYSREADY_ERROR           = uint8(  2  );
ENUM_HVSYSREADY_NOTAVALIABLE    = uint8(  3  );

%-----------------------------------------------------------------
% VPMM_DrivelineRelease_enum
%----------------------------------------------------------------- 
ENUM_DRIVELINERELEASE_NOTRELEASE      = uint8(  0  );
ENUM_DRIVELINERELEASE_RELEASE         = uint8(  1  );
ENUM_DRIVELINERELEASE_ERROR           = uint8(  2  );
ENUM_DRIVELINERELEASE_NOTAVALIABLE    = uint8(  3  );

%-----------------------------------------------------------------
% VPMM_DCDCRlyDem_enum
%----------------------------------------------------------------- 
ENUM_DCDCRLYDEM_NOTAVALIABLE      = uint8(  0  );
ENUM_DCDCRLYDEM_CLOSE             = uint8(  1  );
ENUM_DCDCRLYDEM_OPEN              = uint8(  2  );

%-----------------------------------------------------------------
% VPMM_CACRlyDem_enum
%----------------------------------------------------------------- 
ENUM_CACRLYDEM_NOTAVALIABLE   = uint8(  0  );
ENUM_CACRLYDEM_CLOSE          = uint8(  1  );
ENUM_CACRLYDEM_OPEN           = uint8(  2  );

%-----------------------------------------------------------------
% VPMM_EHPSRlyDem_enum
%----------------------------------------------------------------- 
ENUM_EHPSRLYDEM_NOTAVALIABLE    = uint8(  0  );
ENUM_EHPSRLYDEM_CLOSE           = uint8(  1  );
ENUM_EHPSRLYDEM_OPEN            = uint8(  2  );

%-----------------------------------------------------------------
% VPMM_MCUHVLoopDem_enum
%----------------------------------------------------------------- 
ENUM_MCUHVLOOP_NOREQUEST           = uint8(  0  );
ENUM_MCUHVLOOP_POWERON             = uint8(  1  );
ENUM_MCUHVLOOP_POWEROFF            = uint8(  2  );
ENUM_MCUHVLOOP_NOTAVAILIABLE       = uint8(  3  );

%-----------------------------------------------------------------
% VPMM_ACHVLoopDem_enum
%----------------------------------------------------------------- 
ENUM_ACHVLOOP_NOREQUEST         = uint8(  0  );
ENUM_ACHVLOOP_POWERON           = uint8(  1  );
ENUM_ACHVLOOP_POWEROFF          = uint8(  2  );
ENUM_ACHVLOOP_NOTAVAILIABLE     = uint8(  3  );

%-----------------------------------------------------------------
% VPMM_ChrgState_enum
%----------------------------------------------------------------- 
ENUM_CHRGSTATE_CHECKHVRLYOPEN         = uint8(  0  );
ENUM_CHRGSTATE_BCUNEGRLYCLOSED        = uint8(  1  );
ENUM_CHRGSTATE_DCDCRLYCLOSED          = uint8(  2  );
ENUM_CHRGSTATE_ACRLYCLOSED            = uint8(  3  );
ENUM_CHRGSTATE_DCDCENABLE             = uint8(  4  );
ENUM_CHRGSTATE_CHKCHRGSTA             = uint8(  5  );
ENUM_CHRGSTATE_CHARGING               = uint8(  6  );
ENUM_CHRGSTATE_FINISH                 = uint8(  7  );
ENUM_CHRGSTATE_ERROR                  = uint8(  8  );
%-----------------------------------------------------------------
% VPMM_ChrgFault_enum
%----------------------------------------------------------------- 
ENUM_CHRGFAULT_NOFAULT                = uint8(  0  );
ENUM_CHRGFAULT_RLYCHKFAIL             = uint8(  1  );
ENUM_CHRGFAULT_BCUNEGFAIL             = uint8(  2  );
ENUM_CHRGFAULT_DCDCRLYFAIL            = uint8(  3  );
ENUM_CHRGFAULT_ACRLYFAIL              = uint8(  4  );
ENUM_CHRGFAULT_DCDCENABLE             = uint8(  5  );
ENUM_CHRGFAULT_BCUTIMEOUT             = uint8(  6  );
ENUM_CHRGFAULT_PDUHVFAIL              = uint8(  7  );
ENUM_CHRGFAULT_BCUHVFAIL              = uint8(  8 );
ENUM_CHRGFAULT_HVILFAIL               = uint8(  9  );

%-----------------------------------------------------------------
% VPMM_ActiveDischargeReq_enum
%----------------------------------------------------------------- 
ENUM_ACTIVEDCHRGREQ_NOREQUEST             = uint8(  0  );
ENUM_ACTIVEDCHRGREQ_DISCHRG               = uint8(  1  );
ENUM_ACTIVEDCHRGREQ_ERROR                 = uint8(  2  );
ENUM_ACTIVEDCHRGREQ_INVALID               = uint8(  3  );

%-----------------------------------------------------------------
% VPMM_ExtTorquePrevent_enum
%----------------------------------------------------------------- 
ENUM_TORQUEPRVENT_NOREQUEST         = uint8(  0  );
ENUM_TORQUEPRVENT_ACTIVE            = uint8(  1  );
ENUM_TORQUEPRVENT_ERROR             = uint8(  2  );
ENUM_TORQUEPRVENT_NOTAVAILABLE      = uint8(  3  );

%-----------------------------------------------------------------
% VDHP_APSSingalSts_enum
%----------------------------------------------------------------- 
ENUM_APSSTS_GOHOME         = uint8(  0  );
ENUM_APSSTS_PASS           = uint8(  1  );
ENUM_APSSTS_CHOICEMIN      = uint8(  2  );
ENUM_APSSTS_ONESTILL       = uint8(  3 );
ENUM_APSSTS_SLOWLIMIT      = uint8(  4  );
ENUM_APSSTS_DISCREFAIL     = uint8(  5  );

%-----------------------------------------------------------------
% VDHP_AccPedalLearningState_enum
%----------------------------------------------------------------- 
ENUM_APSLEARNSTATE_STANDBY          = uint8 ( 0 );
ENUM_APSLEARNSTATE_ZP               = uint8 ( 1 );
ENUM_APSLEARNSTATE_FP               = uint8 ( 2 );
ENUM_APSLEARNSTATE_COMPLETED        = uint8 ( 3 );
ENUM_ACCPADALLEARNSTATE_ABORTED     = uint8 ( 4 );



%-----------------------------------------------------------------
% VACC_CoolFanReq_enum
%-----------------------------------------------------------------              
ENUM_COOLFANREQ_OFF      = uint8(  0  );
ENUM_COOLFANREQ_LOW      = uint8(  1  );
ENUM_COOLFANREQ_HI       = uint8(  2  );



%-----------------------------------------------------------------
% VACC_PECoolingMode_enum
%-----------------------------------------------------------------                   
ENUM_ACCMODE_OFF                      = uint8(  0  );
ENUM_ACCMODE_SERVICE                  = uint8(  1  );
ENUM_ACCMODE_CHARGING                 = uint8(  2  );
ENUM_ACCMODE_COOLING                  = uint8(  3  );
ENUM_ACCMODE_AFTERRUNNING             = uint8(  4  );

%-----------------------------------------------------------------
%VACC_FanTempThres_enum
%----------------------------------------------------------------- 
ENUM_THRESTYPE_HIGH               = uint8(  1  );
ENUM_THRESTYPE_MEDIUM             = uint8(  2  );
ENUM_THRESTYPE_LOW                = uint8(  3  );
ENUM_THRESTYPE_OFF                = uint8(  4  );



%-----------------------------------------------------------------
% VOUTP_ACReq_enum
%-----------------------------------------------------------------
ENUM_ACREQ_NO                     = uint8(  0  );
ENUM_ACREQ_COOLINGON              = uint8(  1  );
ENUM_ACREQ_COOLINGONLIM           = uint8(  2  );
ENUM_ACREQ_PWRLIM                 = uint8(  3  );
ENUM_ACREQ_OFF                    = uint8(  4  );
ENUM_ACREQ_HEATING                = uint8(  5  );

%-----------------------------------------------------------------
% VINP_CoolingFanStatus_enum
%-----------------------------------------------------------------
ENUM_FANREQ_OFF                     = uint8(  0  );
ENUM_FANREQ_LOW                     = uint8(  1  );
ENUM_FANREQ_HIGH                    = uint8(  2  );
ENUM_FANREQ_INVALID                 = uint8(  3  );


%-----------------------------------------------------------------
% VTQR_TMMCUCtrlModeSet_enum
%-----------------------------------------------------------------
ENUM_TMMCUCTRLMODE_TOR                   = uint8(  0  );
ENUM_TMMCUCTRLMODE_SPD                   = uint8(  1  );

%-----------------------------------------------------------------
% VTQD_TMRotateDirectionReq_enum
%-----------------------------------------------------------------
ENUM_TMROTATEDIRECTREQ_NONE              = uint8(  0  );
ENUM_TMROTATEDIRECTREQ_FWD               = uint8(  1  );
ENUM_TMROTATEDIRECTREQ_REV               = uint8(  2  );
%ENUM_TMROTATEDIRECTREQ_DEFAULT           = uint8(  3  );

%-----------------------------------------------------------------
% VDIP_GearLampOnReq_enum
%-----------------------------------------------------------------
ENUM_GEARLAMP_P                             = uint8(  0  );
ENUM_GEARLAMP_R                             = uint8(  1  );
ENUM_GEARLAMP_N                             = uint8(  2  );
ENUM_GEARLAMP_D                             = uint8(  3  );

%-----------------------------------------------------------------
% VDHP_EAPS12RangeSta_enum
%-----------------------------------------------------------------

ENUM_RANGESTA_12IN                          = uint8(  0  );
ENUM_RANGESTA_1OUT                          = uint8(  1  );
ENUM_RANGESTA_2OUT                          = uint8(  2  );
ENUM_RANGESTA_12OUT                         = uint8(  3  );

%%
%#########################################################################
% Input ENUMs
%#########################################################################
%-----------------------------------------------------------------
% Hardwire
%-----------------------------------------------------------------
%VFUN_EVDriveMode_enum
ENUM_EVDRIVEMODE_NORMAL        = uint8(  0  );
ENUM_EVDRIVEMODE_HIGHWAY       = uint8(  1  );
ENUM_EVDRIVEMODE_MOUNTAIN      = uint8(  2  );
ENUM_EVDRIVEMODE_ECOPT         = uint8(  3  );
ENUM_EVDRIVEMODE_ECOAC         = uint8(  4  );
ENUM_EVDRIVEMODE_ECOPTAC       = uint8(  5  );





%-----------------------------------------------------------------
% EBS3
%-----------------------------------------------------------------
% VINP_EBSBrakeSw_enum
ENUM_BRAKEPEDAL_RELEASED            = uint8(  0  );
ENUM_BRAKEPEDAL_PRESSED             = uint8(  1  );
ENUM_BRAKEPEDAL_ERROR               = uint8(  2  );
ENUM_BRAKEPEDAL_INVALID             = uint8(  3  );


% VINP_EM1OvrCtrlMDriv_enum 
% VINP_EM1OvrCtrlMBrk_enum
ENUM_EBSTORQUEREQ_NOREQ         = uint8(  0  );
ENUM_EBSTORQUERWQ_SPEED         = uint8(  1  );
ENUM_EBSTORQUERWQ_TORQUE        = uint8(  2  );
ENUM_EBSTORQUERWQ_LIMIT         = uint8(  3  );



%-----------------------------------------------------------------
% PEU
%-----------------------------------------------------------------
% VINP_MCUPrechrgRlySts_enum
ENUM_MCUPRECHRGRLYSTS_OPEN          = uint8(  0  );
ENUM_MCUPRECHRGRLYSTS_CLOSED        = uint8(  1  );
ENUM_MCUPRECHRGRLYSTS_WELDED        = uint8(  2  ); 
ENUM_MCUPRECHRGRLYSTS_FAILTOCLOSE   = uint8(  3  );

% VINP_MCUMainRlySts_enum
ENUM_MCUMAINRLYSTS_OPEN            = uint8(  0  );
ENUM_MCUMAINRLYSTS_CLOSED          = uint8(  1  );
ENUM_MCUMAINRLYSTS_WELDED          = uint8(  2  );
ENUM_MCUMAINRLYSTS_FAILTOCLOSE     = uint8(  3  );

%VINP_MCUHVLoopSts_enum
ENUM_MCUHVLOOPSTS_OPEN             = uint8(  0  );
ENUM_MCUHVLOOPSTS_PRECHARGE        = uint8(  1  );
ENUM_MCUHVLOOPSTS_PRECHARGEFIN     = uint8(  2  );
ENUM_MCUHVLOOPSTS_FAILED           = uint8(  3  );

%VINP_ACPrechrgRlySts_enum
ENUM_ACPRECHRGRLYSTS_OPEN            = uint8(  0  );
ENUM_ACPRECHRGRLYSTS_CLOSED          = uint8(  1  );
ENUM_ACPRECHRGRLYSTS_WELDED          = uint8(  2  );
ENUM_ACPRECHRGRLYSTS_FAILTOCLOSE     = uint8(  3  );

%VINP_ACMainRlySts_enum
ENUM_ACMAINRLYSTS_OPEN            = uint8(  0  );
ENUM_ACMAINRLYSTS_CLOSED          = uint8(  1  );
ENUM_ACMAINRLYSTS_WELDED          = uint8(  2  );
ENUM_ACMAINRLYSTS_FAILTOCLOSE     = uint8(  3  );

%VINP_ACHVLoopSts_enum
ENUM_ACHVLOOPSTS_OPEN             = uint8(  0  );
ENUM_ACHVLOOPSTS_PRECHARGE        = uint8(  1  );
ENUM_ACHVLOOPSTS_CLOSED           = uint8(  2  );
ENUM_ACHVLOOPSTS_FAILED           = uint8(  3  );

%VINP_CACRlySts_enum
ENUM_CACRLYSTS_OPEN            = uint8(  0  );
ENUM_CACRLYSTS_CLOSED          = uint8(  1  );
ENUM_CACRLYSTS_WELDED          = uint8(  2  );
ENUM_CACRLYSTS_FAILTOCLOSE     = uint8(  3  );

%VINP_EHPSRlySts_enum;VINP_PDUEHPSRlySta_enum
ENUM_EHPSRLYSTS_OPEN           = uint8(  0  );
ENUM_EHPSRLYSTS_CLOSED         = uint8(  1  );
ENUM_EHPSRLYSTS_WELDED         = uint8(  2  );
ENUM_EHPSRLYSTS_FAILTOCLOSE    = uint8(  3  );

%VINP_DCDCRlySts_enum
ENUM_DCDCRLYSTS_OPEN           = uint8(  0  );
ENUM_DCDCRLYSTS_CLOSED         = uint8(  1  );
ENUM_DCDCRLYSTS_WELDED         = uint8(  2  );
ENUM_DCDCRLYSTS_FAILTOCLOSE    = uint8(  3  );

%VINP_DCDCEnableStatus_enum
ENUM_DCDCENABLESTS_INITIAL      = uint8(  0  );
ENUM_DCDCENABLESTS_READY        = uint8(  1  );
ENUM_DCDCENABLESTS_RUN          = uint8(  2  );
ENUM_DCDCENABLESTS_FAULT        = uint8(  3  );

%VINP_PEUSelfChkSts_enum
ENUM_PEUSELFCHKSTS_NOFAULT        = uint8(  0  );
ENUM_PEUSELFCHKSTS_FAULT          = uint8(  1  );
ENUM_PEUSELFCHKSTS_RESERVED       = uint8(  2  );
ENUM_PEUSELFCHKSTS_NOTAVALIABLE   = uint8(  3  );

%VINP_EHPSEnableStatus_enum
ENUM_EHPSENABLESTS_INITIAL         = uint8(  0  );
ENUM_EHPSENABLESTS_READY           = uint8(  1  );
ENUM_EHPSENABLESTS_RUN             = uint8(  2  );
ENUM_EHPSENABLESTS_FAULT           = uint8(  3  );

%VINP_CACEnableStatus_enum;VINP_EACEnSta_enum
ENUM_CACENABLESTS_INITIAL          = uint8(  0  );
ENUM_CACENABLESTS_READY            = uint8(  1  );
ENUM_CACENABLESTS_RUN              = uint8(  2  );
ENUM_CACENABLESTS_FAULT            = uint8(  3  );

%VINP_HVILSta_enum
ENUM_PEUHVILSTA_NORMAL               = uint8(  0  );
ENUM_PEUHVILSTA_PEUERROR             = uint8(  1  );
ENUM_PEUHVILSTA_EHPSERROR            = uint8(  2  );
ENUM_PEUHVILSTA_EACERROR             = uint8(  3  );

%-----------------------------------------------------------------
% BMS
%-----------------------------------------------------------------
% VINP_BMSHVSts_enum
ENUM_BMSHVSTS_HVOPEN            = uint8(  0  );
ENUM_BMSHVSTS_PRECHECK          = uint8(  1  );
ENUM_BMSHVSTS_HVCLOSED          = uint8(  2  );
ENUM_BMSHVSTS_FAILTOHVON        = uint8(  3  );

% VINP_MainNegRelaySts_enum
ENUM_MAINNEGRLYSTS_RESERVED    = uint8(  0  );
ENUM_MAINNEGRLYSTS_OPEN        = uint8(  1  );
ENUM_MAINNEGRLYSTS_CLOSED      = uint8(  2  );
ENUM_MAINNEGRLYSTS_INVALID     = uint8(  3  );

% VINP_DCChrgConnectSts_enum
ENUM_PLUGINSTS_NOPLUGIN                  = uint8(  0  );
ENUM_PLUGINSTS_PLUGIN                    = uint8(  1  );
ENUM_PLUGINSTS_HALFPLUGIN                = uint8(  2  );
ENUM_PLUGINSTS_INVALID                   = uint8(  3  );

% VHAL_ACCSLim_enum
ENUM_ACCSLIM_NONE                       = uint8(  0  );
ENUM_ACCSLIM_16A                        = uint8(  1  );
ENUM_ACCSLIM_32A                        = uint8(  2  );
ENUM_ACCSLIM_80A                        = uint8(  3  );

% VHAL_ChgCurrType_enum
ENUM_CHRGTYPE_NONE                     = uint8(  0  );
ENUM_CHRGTYPE_AC                       = uint8(  1  );
ENUM_CHRGTYPE_DC                       = uint8(  2  );
ENUM_CHRGTYPE_INVALID                  = uint8(  3  );

%VINP_BMSChrgStatus_enum
ENUM_BMSCHRGSTS_NOTCHRG           = uint8(  0  );
ENUM_BMSCHRGSTS_CHARGING          = uint8(  1  );   
ENUM_BMSCHRGSTS_FINISH            = uint8(  2  );
ENUM_BMSCHRGSTS_ERROR             = uint8(  3  );

%VINP_B2VRqHVPwrOff_enum
ENUM_HVPWROFFREQ_INVALID          = uint8(  0  );
ENUM_HVPWROFFREQ_POWEROFF         = uint8(  1  );
ENUM_HVPWROFFREQ_NOREQUEST        = uint8(  2  );

%VINP_B2VMainNegRlySta_enum || VINP_B2VDCChgN1RlySta ||
%VINP_B2VDCChrgP1RlySta
ENUM_B2VRLYSTA_OPEN         = uint8( 1 );
ENUM_B2VRLYSTA_CLOSED       = uint8( 2 );
ENUM_B2VRLYSTA_INVALID      = uint8( 3 );

%-----------------------------------------------------------------
% MCU
%-----------------------------------------------------------------
%VINP_EVDLshutdown_enum
ENUM_EVDLSHOUTDOWN_NOREQUEST = uint8(0);
ENUM_EVDLSHOUTDOWN_SHOUTDOWN = uint8(1);
ENUM_EVDLSHOUTDOWN_ERROR = uint8(2);
ENUM_EVDLSHOUTDOWN_NOTAVAILIABLE = uint8(3);

% VINP_ActualDriveDir_enum
ENUM_ACTDRIVEDIR_NEUTRAL                  = uint8(  0  );
ENUM_ACTDRIVEDIR_D                        = uint8(  1  );
ENUM_ACTDRIVEDIR_R                        = uint8(  2  ); 

% VHAL_TMMCUFault_enum (TM MCU Fault)
ENUM_TMMCUFAULT_NONE                     = uint8(  0  );
ENUM_TMMCUFAULT_TMSTUCK                  = uint8(  1  );
ENUM_TMMCUFAULT_IGBTOVERCURRENT          = uint8(  2  );
ENUM_TMMCUFAULT_TMOVERSPD                = uint8(  3  );
ENUM_TMMCUFAULT_TMDIRCTIONFAULT          = uint8(  4  );
ENUM_TMMCUFAULT_PCURRENTDURINGREG        = uint8(  5  );
ENUM_TMMCUFAULT_IGBTOVRTEMP              = uint8(  6  );
ENUM_TMMCUFAULT_UVWCABLEOPEN             = uint8(  7  );
ENUM_TMMCUFAULT_CANAERROR                = uint8(  8  );
ENUM_TMMCUFAULT_CANBERROR                = uint8(  9  );
ENUM_TMMCUFAULT_PNOVRVOLT                = uint8(  10  );
ENUM_TMMCUFAULT_PNUNDERVOLT              = uint8(  11  );
ENUM_TMMCUFAULT_UVWSHORT                 = uint8(  12  );
ENUM_TMMCUFAULT_PHASECURROVRFLOW         = uint8(  13  );
ENUM_TMMCUFAULT_UCTOFFSET                = uint8(  14  );
ENUM_TMMCUFAULT_WCTOFFSET                = uint8(  15  );
ENUM_TMMCUFAULT_PNCTOFFSET               = uint8(  16  );
ENUM_TMMCUFAULT_RDXERROR                 = uint8(  17  );
ENUM_TMMCUFAULT_NA1                      = uint8(  18  );
ENUM_TMMCUFAULT_NA2                      = uint8(  19  );
ENUM_TMMCUFAULT_ENCODERAERR              = uint8(  20  );
ENUM_TMMCUFAULT_ENCODERBERR              = uint8(  21  );

%VINP_MCUFailGrade_enum
ENUM_MCUFAILGRADE_NONE                     = uint8(  0  );
ENUM_MCUFAILGRADE_WARNING                  = uint8(  1  );
ENUM_MCUFAILGRADE_LIGHT                    = uint8(  2  );
ENUM_MCUFAILGRADE_SEVERE                   = uint8(  3  );

%VINP_MCUCtrlMdSta_enum
ENUM_MCUCTRLMDSTA_RESERVED                = uint8(  0  );
ENUM_MCUCTRLMDSTA_SPEED                   = uint8(  1  );
ENUM_MCUCTRLMDSTA_TORQUE                  = uint8(  2  );
ENUM_MCUCTRLMDSTA_ACTDISCHRG              = uint8(  3  );
%-----------------------------------------------------------------
% DHP
%-----------------------------------------------------------------

ENUM_ACCPADALLEARNSTATE_STANDBY           = uint8(  0  );
ENUM_ACCPADALLEARNSTATE_RUNNING           = uint8(  1  );
ENUM_ACCPADALLEARNSTATE_ABORT             = uint8(  2  );
ENUM_ACCPADALLEARNSTATE_COMPLETED         = uint8(  3  );
ENUM_ACCPADALLEARNSTATE_RANGEERROR        = uint8(  4  );

ENUM_FAULTSTATE_PASS                      = uint8(  0  );
ENUM_FAULTSTATE_FAIL                      = uint8(  1  );
ENUM_FAULTSTATE_INDETERMINATE             = uint8(  2  );

% GW1 
%-----------------------------------------------------------------
% VINP_EcoModeSetReq_enum
%-----------------------------------------------------------------              
ENUM_ECOMODESETREQ_NOREQUEST    = uint8(  0  );
ENUM_ECOMODESETREQ_NORMAL       = uint8(  1  );
ENUM_ECOMODESETREQ_POWERECO     = uint8(  2  );
ENUM_ECOMODESETREQ_ACECO        = uint8(  3  );
ENUM_ECOMODESETREQ_SUPERECO     = uint8(  4  );
ENUM_ECOMODESETREQ_INVALID      = uint8(  15  );

% BCM3
%-----------------------------------------------------------------
% VINP_LowBatReq_enum
%----------------------------------------------------------------- 
ENUM_LOWBATREQ_NOREQUEST    = uint8(  0  );
ENUM_LOWBATREQ_TEN          = uint8(  1  );
ENUM_LOWBATREQ_TWENTY       = uint8(  2  );
ENUM_LOWBATREQ_THIRTY       = uint8(  3  );
ENUM_LOWBATREQ_FORTY        = uint8(  4  );
ENUM_LOWBATREQ_FIFTY        = uint8(  5  );
ENUM_LOWBATREQ_INVALID      = uint8(  7  );



%-----------------------------------------------------------------
% VINP_ChgTimeCur_enum   (OBU Cal Charge time Data)
%----------------------------------------------------------------- 
ENUM_CHGTIMECUR_16A          = uint8(  0  );
ENUM_CHGTIMECUR_32A          = uint8(  1  );
ENUM_CHGTIMECUR_50A          = uint8(  2  );
ENUM_CHGTIMECUR_80A          = uint8(  3  );
ENUM_CHGTIMECUR_INVALID      = uint8(  7  );

%-----------------------------------------------------------------
% VINP_ACCSLimit_enum
%----------------------------------------------------------------- 
%ENUM_ACCSLIM_NO             = uint8(  0  );
%ENUM_ACCSLIM_16A            = uint8(  1  );
%ENUM_ACCSLIM_32A            = uint8(  2  );
%ENUM_ACCSLIM_80A            = uint8(  3  );

% VDIP_HVBSOCLoWrnSetPt_enum
%-----------------------------------------------------------------
ENUM_HVBSOCLOWRNSETPT_NOREQUEST                      = uint8(  0  );
ENUM_HVBSOCLOWRNSETPT_10PCT                          = uint8(  1  );
ENUM_HVBSOCLOWRNSETPT_20PCT                          = uint8(  2  );
ENUM_HVBSOCLOWRNSETPT_30PCT                          = uint8(  3  );
ENUM_HVBSOCLOWRNSETPT_40PCT                          = uint8(  4  );
ENUM_HVBSOCLOWRNSETPT_50PCT                          = uint8(  5  );
ENUM_HVBSOCLOWRNSETPT_INVALID                        = uint8(  7  );
%-----------------------------------------------------------------
% VDIP_HVBSOCLoWrn_enum
%-----------------------------------------------------------------
ENUM_HVBSOCLOWRN_NORMAL                          = uint8(  0  );
ENUM_HVBSOCLOWRN_LOW                             = uint8(  1  );
ENUM_HVBSOCLOWRN_EXTREMELOW                      = uint8(  2  );
ENUM_HVBSOCLOWRN_INVALID                         = uint8(  3  );
%-----------------------------------------------------------------
% VPSA_PEPSIgnSta_enum
%-----------------------------------------------------------------
ENUM_PEPSIGNSTA_NO                               = uint8( 0 ) ;
ENUM_PEPSIGNSTA_OFF                              = uint8( 1 ) ;
ENUM_PEPSIGNSTA_ON                               = uint8( 2 ) ;
%-----------------------------------------------------------------
% VPSA_PEPSPwrMode_enum
%-----------------------------------------------------------------
ENUM_PEPSPWRMODE_OFF                               = uint8( 0 ) ;
ENUM_PEPSPWRMODE_ACC                               = uint8( 1 ) ;
ENUM_PEPSPWRMODE_ON                                = uint8( 2 ) ;
ENUM_PEPSPWRMODE_ST                                = uint8( 4 ) ;
%-----------------------------------------------------------------
% VPSA_EXCUTEMODE_enum
%-----------------------------------------------------------------
ENUM_PSAMODE_STARTUP                           = uint8( 0 ) ;
ENUM_PSAMODE_INITIALIZE                        = uint8( 1 ) ;
ENUM_PSAMODE_FREESTART                         = uint8( 2 ) ;
ENUM_PSAMODE_AUTHSTART                         = uint8( 3 ) ;
ENUM_PSAMODE_LEARNMODE                         = uint8( 4 ) ;
ENUM_PSAMODE_STARTOVR                          = uint8( 5 ) ;
ENUM_PSAMODE_IDLE                              = uint8( 6 ) ; 
%-----------------------------------------------------------------
% VINP_EcoModeSet_enum
%-----------------------------------------------------------------
ENUM_ECOSet_OFF                                = uint8( 0 ) ;
ENUM_ECOSet_ON                                 = uint8( 2 ) ;
%-----------------------------------------------------------------
% VPSA_IMMOSID_enum
%-----------------------------------------------------------------
ENUM_IMMOSID_NO                                = uint8( 0 ) ;
ENUM_IMMOSID_RANDNUM                           = uint8( 1 ) ;
ENUM_IMMOSID_AUTHRESULT                        = uint8( 2 ) ;
ENUM_IMMOSID_CRKERR                            = uint8( 3 ) ;
%-----------------------------------------------------------------
% VPSA_StartFault_enum
%-----------------------------------------------------------------
ENUM_STARTFAULT_NOFAULT                        = uint8( 0 ) ;
ENUM_STARTFAULT_NOCRKREQ                       = uint8( 1 ) ;
ENUM_STARTFAULT_AUTHFAIL                       = uint8( 2 ) ;
ENUM_STARTFAULT_AUTHTIMEOUT                    = uint8( 3 ) ;
ENUM_STARTFAULT_NOCRKFORIMMO                   = uint8( 4 ) ;
ENUM_STARTFAULT_IMMONOREPLY                    = uint8( 5 ) ;
ENUM_STARTFAULT_VCUVIRGIN                      = uint8( 6 ) ;
ENUM_STARTFAULT_PTNOREADY                      = uint8( 7 ) ;
%-----------------------------------------------------------------
% VPSA_ECMResSID_enum
%-----------------------------------------------------------------
ENUM_ECMRESSID_NO                              = uint8( 0 ) ;
ENUM_ECMRESSID_REPTLENSTA                      = uint8( 1 ) ;
ENUM_ECMRESSID_RESSETLENCMD                    = uint8( 5 ) ;
%-----------------------------------------------------------------
% VPSA_ECMRepSID_enum
%-----------------------------------------------------------------
ENUM_ECMREPSID_NO                             = uint8( 0 ) ;
ENUM_ECMREPSID_REPTLENSTA                     = uint8( 1 ) ;
ENUM_ECMREPSID_SHAREONECODE                   = uint8( 2 ) ;
ENUM_ECMREPSID_SHARETWOCODE                   = uint8( 3 ) ;
ENUM_ECMREPSID_SHARETHREECODE                 = uint8( 4 ) ;
ENUM_ECMREPSID_RESSETLENCMD                   = uint8( 5 ) ;
ENUM_ECMREPSID_POSREPLYSC                     = uint8( 6 ) ;
%-----------------------------------------------------------------
% VPSA_AESEncErr_enum
%-----------------------------------------------------------------
ENUM_AESENCERR_NO                             = uint8( 0 ) ;
ENUM_AESENCERR_SCVIRGIN                       = uint8( 1 ) ;
ENUM_AESENCERR_SKCVIRGIN                      = uint8( 2 ) ;
ENUM_AESENCERR_IMMONOREPLY                    = uint8( 3 ) ;
ENUM_AESENCERR_WRONGKEYCODE                   = uint8( 4 ) ;
ENUM_AESENCERR_SCINVALID                      = uint8( 5 ) ;
ENUM_AESENCERR_SKCINVALID                     = uint8( 6 ) ;
%-----------------------------------------------------------------
% VPSA_CrkErrType_enum
%-----------------------------------------------------------------
ENUM_CRKERRTYPE_NO                             = uint8( 0 ) ;
ENUM_CRKERRTYPE_VCUVIRGIN                      = uint8( 1 ) ;
ENUM_CRKERRTYPE_IMMONOREPLY                    = uint8( 2 ) ;
ENUM_CRKERRTYPE_WRONGKEYCODE                   = uint8( 3 ) ;
ENUM_CRKERRTYPE_STCRKFAIL                      = uint8( 4 ) ;
%-----------------------------------------------------------------
% VINP_CAPERepSID_enum
%-----------------------------------------------------------------
ENUM_CAPEREPSID_NO                             = uint8( 0 ) ;
ENUM_CAPEREPSID_SYSLENACTIVE                   = uint8( 1 ) ;
ENUM_CAPEREPSID_SHAREONECODE                   = uint8( 2 ) ;
ENUM_CAPEREPSID_SHARETWOCODE                   = uint8( 3 ) ;
ENUM_CAPEREPSID_SHARETHREECODE                 = uint8( 4 ) ;
ENUM_CAPEREPSID_REQSETLENCMD                   = uint8( 5 ) ;
ENUM_CAPEREPSID_PUBLISHSC                      = uint8( 6 ) ;
ENUM_CAPEREPSID_ECMVERTRIG                     = uint8( 7 ) ;
ENUM_CAPEREPSID_CLRECMLENSTA                   = uint8( 8 ) ;
ENUM_CAPEREPSID_CLRESCLLENSTA                  = uint8( 9 ) ;
ENUM_CAPEREPSID_ESCLVERTRIG                    = uint8( 10 ) ;
%-----------------------------------------------------------------
% VINP_ECMLearnSID_enum
%-----------------------------------------------------------------
ENUM_ECMLENSID_NO                             = uint8( 0 ) ;
ENUM_ECMLENSID_SYSLENACTIVE                   = uint8( 1 ) ;
ENUM_ECMLENSID_REQSAVEONECODE                 = uint8( 2 ) ;
ENUM_ECMLENSID_REQSAVETWOCODE                 = uint8( 3 ) ;
ENUM_ECMLENSID_REQSAVETHREECODE               = uint8( 4 ) ;
ENUM_ECMLENSID_REQSETLENCMD                   = uint8( 5 ) ;
% ENUM_ECMLENSID_PUBLISHSC                      = uint8( 6 ) ;
ENUM_ECMLENSID_VERTRIG                        = uint8( 7 ) ;
%-----------------------------------------------------------------
% OBU_SubCharge_enum
%-----------------------------------------------------------------
ENUM_SUBCHRSW_ON                             = uint8( 2 ) ;
ENUM_SUBCHRSW_OFF                            = uint8( 1 ) ;
ENUM_SUBCHRSW_INVALID                        = uint8( 0 ) ;
ENUM_SUBCHRSTA_ON                            = uint8( 2 ) ;
ENUM_SUBCHRSTA_OFF                           = uint8( 1 ) ;
ENUM_SUBCHRSTA_INVALID                       = uint8( 0 ) ;
%-----------------------------------------------------------------
% VINP_ESCLRepSID_enum
%-----------------------------------------------------------------
ENUM_ESCLREPSID_NO                           = uint8( 0 ) ;
ENUM_ESCLREPSID_REPORTLENSTA                 = uint8( 1 ) ;
ENUM_ESCLREPSID_SHAREONECODE                 = uint8( 2 ) ;
ENUM_ESCLREPSID_SHARETWOCODE                 = uint8( 3 ) ;
ENUM_ESCLREPSID_SHARETHREECODE               = uint8( 4 ) ;
ENUM_ESCLREPSID_REQSETLENCMD                 = uint8( 5 ) ;
ENUM_ESCLREPSID_PUBLISHSC                    = uint8( 6 ) ;
%----------------------------------------------------------------
% VINP_ACCSLim_enum
%----------------------------------------------------------------
ENUM_ACCLIMITCURR_NONE                      = uint8( 0 );
ENUM_ACCLIMITCURR_16A                       = uint8( 1 );
ENUM_ACCLIMITCURR_32A                       = uint8( 2 );
ENUM_ACCLIMITCURR_80A                       = uint8( 3 );
%----------------------------------------------------------------
% VINP_Acclimitcurr_enum
%----------------------------------------------------------------
ENUM_PLUGMAXCUR_Invalid                   = uint8( 7 );
ENUM_PLUGMAXCUR_15A                       = uint8( 0 );
ENUM_PLUGMAXCUR_30A                       = uint8( 1 );
ENUM_PLUGMAXCUR_50A                       = uint8( 2 );
ENUM_PLUGMAXCUR_80A                       = uint8( 3 );
%----------------------------------------------------------------
% VACC_FanSta_enum 
%----------------------------------------------------------------
ENUM_FANSTA_Hi                                   = uint8( 2 );
ENUM_FANSTA_Low                                  = uint8( 1 );
ENUM_FANSTA_OFF                                  = uint8( 0 );

%----------------------------------------------------------------
% VINP_ChargeCurrentType_enum
%----------------------------------------------------------------
ENUM_CHARGECURRETYP_None                                    = uint8( 0 );
ENUM_CHARGECURRETYP_ACCharge                                = uint8( 1 );
ENUM_CHARGECURRETYP_DCCharge                                = uint8( 2 );
ENUM_CHARGECURRETYP_ChargeCurrInvalid                       = uint8( 3 );


%----------------------------------------------------------------
% VDHP_LowIdleAccPedal_enum
%----------------------------------------------------------------
ENUM_LOWIDLEPEDAL_FALSE                                 = uint8( 0 );
ENUM_LOWIDLEPEDAL_TRUE                                  = uint8( 1 );
ENUM_LOWIDLEPEDAL_ERROR                                 = uint8( 2 );
ENUM_LOWIDLEPEDAL_NOTAVAIL                              = uint8( 3 );

%----------------------------------------------------------------
% VINP_TransReqGear_enum
%----------------------------------------------------------------
ENUM_TARGETGEAR_D1                                 = uint8( 245 );
ENUM_TARGETGEAR_D2                                 = uint8( 244 );
ENUM_TARGETGEAR_D3                                 = uint8( 243 );
ENUM_TARGETGEAR_DRIVE                              = uint8( 252 );
ENUM_TARGETGEAR_NEUTRAL                            = uint8( 125 );
ENUM_TARGETGEAR_REVERSE                            = uint8( 223 );
ENUM_TARGETGEAR_NONE                               = uint8( 224 );
ENUM_TARGETGEAR_ERROR                              = uint8( 254 );

%----------------------------------------------------------------
% VINP_ASRBrakeCtrlAtc_enum
%----------------------------------------------------------------
ENUM_ASRSTATE_INACTIVE                                 = uint8( 0 );
ENUM_ASRSTATE_ACTIVE                                   = uint8( 1 );
ENUM_ASRSTATE_RESERVED                                 = uint8( 2 );
ENUM_ASRSTATE_NOTAVAILABLE                             = uint8( 3 );


%----------------------------------------------------------------
% VINP_AntiLBrakABSAct_enum
%----------------------------------------------------------------
ENUM_ABSSTATE_INACTIVE                                 = uint8( 0 );
ENUM_ABSSTATE_ACTIVE                                   = uint8( 1 );
ENUM_ABSSTATE_RESERVED                                 = uint8( 2 );
ENUM_ABSSTATE_NOTAVAILABLE                             = uint8( 3 );

% VINP_TMRotateDirection_enum
ENUM_TMROTATEDIRECTACT_NONE                  = uint8(  0  );
ENUM_TMROTATEDIRECTACT_FORWARD               = uint8(  1  );
ENUM_TMROTATEDIRECTACT_REVERSE               = uint8(  2  ); 
ENUM_TMROTATEDIRECTACT_INVALID               = uint8(  3  ); 

%----------------------------------------------------------------
% VINP_MCUFailGrade_enum
%----------------------------------------------------------------
ENUM_MCUFAULT_NOFAULT                                 = uint8( 0 );
ENUM_MCUFAULT_FAULTLV1                                 = uint8( 1 );
ENUM_MCUFAULT_FAULTLV2                                 = uint8( 2 );
ENUM_MCUFAULT_FAULTLV3                                 = uint8( 3 );


%-----------------------------------------------------------------
% VTQD_GearActualPosn_enum
%-----------------------------------------------------------------                   
ENUM_GEARACTUALPOSN_P                    = uint8(  8  );
ENUM_GEARACTUALPOSN_N                    = uint8(  0  );
ENUM_GEARACTUALPOSN_D                    = uint8(  1  );
ENUM_GEARACTUALPOSN_INVALID              = uint8(  6  );
ENUM_GEARACTUALPOSN_R                    = uint8(  2  );

%----------------------------------------------------------------
% VINP_ADASShftPosnReq_enum
%----------------------------------------------------------------
ENUM_ADASGEARREQ_NOREQ                                    = uint8( 0 );
ENUM_ADASGEARREQ_P                                        = uint8( 1 );
ENUM_ADASGEARREQ_NEU                                      = uint8( 2 );
ENUM_ADASGEARREQ_D                                        = uint8( 3 );
ENUM_ADASGEARREQ_R                                        = uint8( 7 );

%----------------------------------------------------------------
% ADAS Valid inverse
%----------------------------------------------------------------
ADAS_TRUE                 = boolean( 0 );
ADAS_FALSE                = boolean( 1 );

%----------------------------------------------------------------
% VINP_ACCStatus_enum
%----------------------------------------------------------------
ENUM_ACCSTS_OFF                                           = uint8( 0 );
ENUM_ACCSTS_STANDBY                                       = uint8( 1 );
ENUM_ACCSTS_ACTIVE                                        = uint8( 2 );

%----------------------------------------------------------------
% VTQD_Tqnum2hex(single(1000))_enum
%----------------------------------------------------------------
ENUM_TQSOURCE_INTERNAL                                    = uint8( 0 );
ENUM_TQSOURCE_ADAS                                        = uint8( 2 );
ENUM_TQSOURCE_LIMIT                                       = uint8( 3 );
ENUM_TQSOURCE_ESC                                         = uint8( 5 );

%-----------------------------------------------------------------
% VINP_GearShiftPosn_enum
%-----------------------------------------------------------------              
ENUM_GEARSHIFTPOSN_P                    = uint8(  8  );
ENUM_GEARSHIFTPOSN_N                    = uint8(  0  );
ENUM_GEARSHIFTPOSN_D                    = uint8(  1  );
ENUM_GEARSHIFTPOSN_R                    = uint8(  2  );
ENUM_GEARSHIFTPOSN_INVALID              = uint8(  6  );

%-----------------------------------------------------------------
% VPMM_VCUMCUCtrlMd_enum || VTQD_VCUMCUCtrlMd_enum 
%-----------------------------------------------------------------    
ENUM_MCUCTRLMODE_NONE                     = uint8(  0  );
ENUM_MCUCTRLMODE_SPEED                    = uint8(  1  );
ENUM_MCUCTRLMODE_TORQUE                   = uint8(  2  );
ENUM_MCUCTRLMODE_ACTDISCHRG               = uint8(  3  );

%-----------------------------------------------------------------
% VSCP_EMRC1EMTquModeDrvBrk_enum
%----------------------------------------------------------------- 
ENUM_EMTqModeDrvBrk_Coast                     = uint8(  0  );
ENUM_EMTqModeDrvBrk_Accel                     = uint8(  1  );
ENUM_EMTqModeDrvBrk_Brake                     = uint8(  10  );

%-----------------------------------------------------------------
% VSCP_ETC2ActDriveDirect_enum
%----------------------------------------------------------------- 
ENUM_ETC2ACTDRIVEDIR_FORWARD                     = single(  1  );
ENUM_ETC2ACTDRIVEDIR_BACKWARD                    = single(  -1  );
ENUM_ETC2ACTDRIVEDIR_STILL                       = single(  0  ); % specific

%-----------------------------------------------------------------
% VINP_MCUFailGrade_enum
%----------------------------------------------------------------- 
ENUM_MCUFailGrade_NoFault                     = uint8(  0  );
ENUM_MCUFailGrade_Warning                     = uint8(  1  );
ENUM_MCUFailGrade_Fault                       = uint8(  2  );
ENUM_MCUFailGrade_Disable                     = uint8(  3  );

%-----------------------------------------------------------------
% VINP_EWPPEFault_enum
%----------------------------------------------------------------- 
ENUM_EWPPEFault_Running                     = uint8(  0  );
ENUM_EWPPEFault_OverCurrent                 = uint8(  1  );
ENUM_EWPPEFault_OverTemperature             = uint8(  2  );
ENUM_EWPPEFault_OverVoltage                 = uint8(  4  );
ENUM_EWPPEFault_UnderVoltage                = uint8(  5  );
ENUM_EWPPEFault_NoLoad                      = uint8(  32  );
ENUM_EWPPEFault_Abnormalload                = uint8(  48  );

%-----------------------------------------------------------------
% VSCP_EVCU1VehActDrvDir_enum
%----------------------------------------------------------------- 
ENUM_VEHACTDRVDIR_STILL                     = uint8(  0  );
ENUM_VEHACTDRVDIR_FORWARD                   = uint8(  1  );
ENUM_VEHACTDRVDIR_BACKWARD                  = uint8(  2  );
ENUM_VEHACTDRVDIR_ERROR                     = uint8(  3  );

%-----------------------------------------------------------------
% VTQD_CreepIND_enum
%----------------------------------------------------------------- 
ENUM_CREEPIND_READY                         = uint8(  0  );
ENUM_CREEPIND_RUNNING                       = uint8(  1  );
ENUM_CREEPIND_WARNING                       = uint8(  2  );
ENUM_CREEPIND_DISABLE                       = uint8(  3  );

%-----------------------------------------------------------------
% VTQD_TUpAIND_enum
%----------------------------------------------------------------- 
ENUM_TUPAIND_READY                         = uint8(  0  );
ENUM_TUPAIND_RUNNING                       = uint8(  1  );
ENUM_TUPAIND_WARNING                       = uint8(  2  );
ENUM_TUPAIND_DISABLE                       = uint8(  3  );

%-----------------------------------------------------------------
% VTQD_VCUEBSHHSw_enum
%-----------------------------------------------------------------
ENUM_VCUEBSHHSW_OFF             = uint8(  0  );
ENUM_VCUEBSHHSW_ON              = uint8(  1  );

%-----------------------------------------------------------------
% VTQD_VCUEBSRd4BR_enum
%-----------------------------------------------------------------
ENUM_VCUEBSRD4BR_NOTREADY             = uint8(  0  );
ENUM_VCUEBSRD4BR_READY                 = uint8(  1  );

%-----------------------------------------------------------------
% VSCP_VCUMCUGearSta_enum
%----------------------------------------------------------------- 
ENUM_VCUMCUGEAR_N                           = uint8(  0  );
ENUM_VCUMCUGEAR_D                           = uint8(  1  );
ENUM_VCUMCUGEAR_R                           = uint8(  2  );
ENUM_VCUMCUGEAR_INVAILD                     = uint8(  3  );

%-----------------------------------------------------------------
% VSCP_AirPressFFault_enum/VSCP_AirPressRFault_enum/VSCP_AirPressPFault_enum
%----------------------------------------------------------------- 
ENUM__AIRPRESSSENSOR_NONE                      = uint8(  0  );
ENUM__AIRPRESSSENSOR_SHORT                     = uint8(  1  );
ENUM__AIRPRESSSENSOR_OPEN                      = uint8(  2  );
ENUM__AIRPRESSSENSOR_STUCK                     = uint8(  3  );

%-----------------------------------------------------------------
% VINP_SASCaled_enum
%----------------------------------------------------------------- 
ENUM__SASCALED_NOTCALED                        = uint8(  0  );
ENUM__SASCALED_CALED                           = uint8(  1  );
ENUM__SASCALED_RESERVED                        = uint8(  2  );
ENUM__SASCALED_NOTAVAIL                        = uint8(  3  );

%-----------------------------------------------------------------
% VACC_EHPSSpdCtrlMode_enum
%----------------------------------------------------------------- 
ENUM_EHPSCTRLMODE_NORMAL                         = uint8(  1  );
ENUM_EHPSCTRLMODE_ZERO                           = uint8(  2  );
ENUM_EHPSCTRLMODE_FULLPWR                        = uint8(  3  );
ENUM_EHPSCTRLMODE_STEP1                          = uint8(  4  );

%-----------------------------------------------------------------
% VINP_DCDCErrLv_enum // VINP_EHPSErrLv_enum // VINP_EACErrLv_enum
%----------------------------------------------------------------- 
ENUM_PDUERRLV_NOERROR                           = uint8(  0  );
ENUM_PDUERRLV_LV1                               = uint8(  1  );
ENUM_PDUERRLV_LV2                               = uint8(  2  );
ENUM_PDUERRLV_LV3                               = uint8(  3  );
ENUM_PDUERRLV_LV4                               = uint8(  4  );

%-----------------------------------------------------------------
% VINP_HillHolderMode_enum
%----------------------------------------------------------------- 
ENUM_HHMODE_INACTIVE                = uint8(  0  );
ENUM_HHMODE_ACTIVE                  = uint8(  1  );
ENUM_HHMODE_CNAHGE2INACTIVE         = uint8(  2  );

%-----------------------------------------------------------------
% VINP_ASRHillHolderSw_enum
%----------------------------------------------------------------- 
ENUM_HHSW_INACTIVE                  = uint8(  0  );
ENUM_HHSW_ACTIVE                    = uint8(  1  );

%-----------------------------------------------------------------
% VSCP_VCU5AlcLockSta_enum
%----------------------------------------------------------------- 
ENUM_ALCLOCKSTA_DEFAULT               = uint8(  0  );
ENUM_ALCLOCKSTA_PASS                  = uint8(  1  );
ENUM_ALCLOCKSTA_NG                    = uint8(  2  );

%-----------------------------------------------------------------
% VINP_EWPCtrlMdSta_enum
%----------------------------------------------------------------- 
ENUM_EWPCTRLMDSTA_INVALID                = uint8(  0  );
ENUM_EWPCTRLMDSTA_SPEED                  = uint8(  1  );
ENUM_EWPCTRLMDSTA_TORQUE                 = uint8(  2  );

%-----------------------------------------------------------------
% VINP_EHSPCtrlMdSta_enum
%----------------------------------------------------------------- 
ENUM_EHPSCTRLMDSTA_INVALID                = uint8(  0  );
ENUM_EHPSCTRLMDSTA_SPEED                  = uint8(  1  );
ENUM_EHPSCTRLMDSTA_TORQUE                 = uint8(  2  );

%-----------------------------------------------------------------
% VINP_EACCtrlMdSta_enum
%----------------------------------------------------------------- 
ENUM_EACCTRLMDSTA_INVALID                = uint8(  0  );
ENUM_EACCTRLMDSTA_SPEED                  = uint8(  1  );
ENUM_EACCTRLMDSTA_TORQUE                 = uint8(  2  );

%-----------------------------------------------------------------
% VINP_PDUACRlySta_enum
%----------------------------------------------------------------- 
ENUM_PDUACRLYSTA_OPEN                   = uint8(  0  );
ENUM_PDUACRLYSTA_CLOSE                  = uint8(  1  );
ENUM_PDUACRLYSTA_WELDED                 = uint8(  2  );
ENUM_PDUACRLYSTA_CLOSEFAILURE           = uint8(  3  );

%-----------------------------------------------------------------
% VINP_PDUACLoopSta_enum
%----------------------------------------------------------------- 
ENUM_PDUACLOOPSTA_OPEN                   = uint8(  0  );
ENUM_PDUACLOOPSTA_PRECHARGING            = uint8(  1  );
ENUM_PDUACLOOPSTA_PRECHARGEFINISH        = uint8(  2  );
ENUM_PDUACLOOPSTA_PRECHARGEFAULT         = uint8(  3  );

%-----------------------------------------------------------------
% VDMM_FDDemSta_enum
%----------------------------------------------------------------- 
ENUM_FDDEMSTA_NOREQUEST            = uint8(  0  );
ENUM_FDDEMSTA_OPEN                 = uint8(  1  );
ENUM_FDDEMSTA_CLOSES               = uint8(  2  );

%-----------------------------------------------------------------
% VDMM_RDDemSta_enum
%----------------------------------------------------------------- 
ENUM_RDDEMSTA_NOREQUEST            = uint8(  0  );
ENUM_RDDEMSTA_OPEN                 = uint8(  1  );
ENUM_RDDEMSTA_CLOSES               = uint8(  2  );

%-----------------------------------------------------------------
% VDMM_TDDemSta_enum
%----------------------------------------------------------------- 
ENUM_TDDEMSTA_NOREQUEST            = uint8(  0  );
ENUM_TDDEMSTA_OPEN                 = uint8(  1  );
ENUM_TDDEMSTA_CLOSES               = uint8(  2  );

%-----------------------------------------------------------------
% VPMM_LVBattInd_enum
%----------------------------------------------------------------- 
ENUM_LOWBATTVOLTAGE_NORMAL            = uint8(  0  );
ENUM_LOWBATTVOLTAGE_POWERDOWN         = uint8(  1  );
ENUM_LOWBATTVOLTAGE_POWERUP           = uint8(  2  );

%-----------------------------------------------------------------
% VSCP_VCUEBSHBSw_enum
%----------------------------------------------------------------- 
ENUM_VCUEBSHBSW_PASSIVE                  = uint8(  0  );
ENUM_VCUEBSHBSW_ACTIVE                   = uint8(  1  );
ENUM_VCUEBSHBSW_ERROR                    = uint8(  2  );
ENUM_VCUEBSHBSW_NOTAVAILABLE             = uint8(  3  );

%-----------------------------------------------------------------
% VINP_B2VDCChgConnSta_enum
%----------------------------------------------------------------- 
ENUM_B2VDCCHGCONNSTA_NOTCONNECT          = uint8(  0  );
ENUM_B2VDCCHGCONNSTA_CONNECT             = uint8(  1  );
ENUM_B2VDCCHGCONNSTA_HALFCONNECT         = uint8(  2  );
ENUM_B2VDCCHGCONNSTA_INVALID             = uint8(  3  );

%-----------------------------------------------------------------
% VTQD_ActDriveMode_enum // VAPP_ECPVCUDRM_enum
%----------------------------------------------------------------- 
ENUM_ECPVCUDRM_NORMAL                    = uint8(  0  );
ENUM_ECPVCUDRM_ECO                       = uint8(  1  );
ENUM_ECPVCUDRM_CONFORT                   = uint8(  2  );
ENUM_ECPVCUDRM_NOTAVAILABLE              = uint8(  3  );

% VINP_FRHalbrakeReq_enum // VINP_MDHalbrakeReq_enum // VINP_TDHalbrakeReq_enum
%----------------------------------------------------------------- 
ENUM_HALBRAKEREQ_NOTACTIVE               = uint8(  0  );
ENUM_HALBRAKEREQ_ACTIVE                  = uint8(  1  );
ENUM_HALBRAKEREQ_ERROR                   = uint8(  2  );
ENUM_HALBRAKEREQ_NOTAVAILABLE            = uint8(  3  );

% VINP_DCDCEACPCURlySta_enum
%----------------------------------------------------------------- 
ENUM_DCDCEACPCURLYSTA_OPEN           = uint8(  0  );
ENUM_DCDCEACPCURLYSTA_CLOSED         = uint8(  1  );
ENUM_DCDCEACPCURLYSTA_WELDED         = uint8(  2  );
ENUM_DCDCEACPCURLYSTA_FAILTOCLOSE    = uint8(  3  );

%VSCP_ComboKey_enum
%----------------------------------------------------------------- 
ENUM_COMBOKEY_NONE               = uint8(0);
ENUM_COMBOKEY_UP                 = uint8(1);  
ENUM_COMBOKEY_DOWN               = uint8(2);
ENUM_COMBOKEY_STOPLV             = uint8(3);
ENUM_COMBOKEY_M1                 = uint8(4);
ENUM_COMBOKEY_M2                 = uint8(5);
ENUM_COMBOKEY_RKNEE              = uint8(6);

%VINP_CP2VNLvReqFA_enum // VINP_CP2VNLvReqRA_enum
%----------------------------------------------------------------- 
ENUM_CP2VNLVREQ_NOREQUEST               = uint8(0);
ENUM_CP2VNLVREQ_LEVEL1                  = uint8(1);
ENUM_CP2VNLVREQ_LEVEL2                  = uint8(2);
ENUM_CP2VNLVREQ_LEVEL3                  = uint8(3);
ENUM_CP2VNLVREQ_PRESETLEVEL             = uint8(4);
ENUM_CP2VNLVREQ_CUSTOMERLLV             = uint8(5);
ENUM_CP2VNLVREQ_UPPER                   = uint8(6);
ENUM_CP2VNLVREQ_LOWER                   = uint8(7);
ENUM_CP2VNLVREQ_STOPLV                  = uint8(8);

%VINP_CP2VKneeReqFA_enum // VINP_CP2VKneeReqRA_enum // VINP_CP2VKneeReqRSide_enum
%----------------------------------------------------------------- 
ENUM_CP2VKNEEREQ_NOREQUEST              = uint8(0);
ENUM_CP2VKNEEREQ_REQUEST                = uint8(1);

%VSCP_FogTMSRlyCMD_enum
%-----------------------------------------------------------------
ENUM_FOGRLYENCMD_NOTAVAILABLE           = uint8(0);
ENUM_FOGRLYENCMD_ENABLE                 = uint8(1);
ENUM_FOGRLYENCMD_DISABLE                = uint8(2);

