#ifndef __FVT_API_H_
#define __FVT_API_H_

#include <stdint.h>
#include <stdbool.h>

/* Define quantity of Rx message and channel*/
#define NUM_CAN_CHANNEL 6
#define NUM_CAN_CH1_RX_MSG 6
#define NUM_CAN_CH2_RX_MSG 5
#define NUM_CAN_CH3_RX_MSG 21
#define NUM_CAN_CH4_RX_MSG 18
#define NUM_CAN_CH6_RX_MSG 3
#define NUM_CAN_CH7_RX_MSG 5

#define NUM_LIN_CHANNEL 0

#define CAR_MODEL           D31
#define CONTROLLER          FD
#define COUNTRY             TW
#define CUSTOMER            X
#define DRIVING_MODE        R
#define MODEL_YEAR          S

#define APP_MAJOR 7
#define APP_MINOR 18
#define APP_PATCH 0

typedef uint32_t vs_sleepy_state_t;
typedef uint8_t  vs_can_nm_stat_t;

/* CAN message API */
extern void    CANTransmit(uint8_t busId, uint16_t msgId, uint8_t fd, const uint8_t *Txdata, uint8_t dlc);
extern uint8_t CANReceive(uint8_t busId, uint16_t msgId, uint8_t *Rxdata, uint8_t dlc);
extern void    CANSetFilter(uint8_t busID, uint8_t num_msg, const uint16_t *filter);

/* ADC input */
extern void  ApiAdc_GroupConvert(void);
extern uint16_t ApiAdc_GetPedal1Vol(void);
extern uint16_t ApiAdc_GetPedal2Vol(void);
extern uint16_t ApiAdc_GetPedal1_5V_Vol(void);
extern uint16_t ApiAdc_GetPedal2_5V_Vol(void);

/* GPIO input*/
extern uint8_t ApiDio_GetHoodSW(void);
extern uint8_t ApiDio_GetTailgateSW(void);
extern uint8_t ApiDio_GetDrDoorSW(void);
extern uint8_t ApiDio_GetPsDoorSW(void);
extern uint8_t ApiDio_GetRRDoorSW(void);
extern uint8_t ApiDio_GetRLDoorSW(void);
extern uint8_t ApiDio_GetCentralDoorLockSW(void);
extern uint8_t ApiDio_GetHazardSW(void);
extern uint8_t ApiDio_GetBrakeSW(void);
extern uint8_t ApiDio_GetBrakeLampSW(void);
extern uint8_t ApiDio_GetTrunkHanSW(void);
extern uint8_t ApiDio_GetSeatSW(void);
extern uint8_t ApiDio_GetCrashSignal(void);

/* TPMS main */
extern void tpms_main(void);

/* TPMS input*/
extern bool ApiTPMS_GetRawData(uint8_t *TPMSData, uint8_t dlc);
extern bool ApiTPMS_GetIdLocation(unsigned long *GetIdLoc_raw);
extern bool ApiTPMS_GetCheckIdLocation(unsigned long *GetCheckIdLoc_raw);

/* TPMS output*/
extern void ApiTPMS_SetIdLocation(uint32_t *SetIdLoc_raw, bool SetChkId_flg, bool CheckFin_flg);

/* Get hardware version*/
extern uint8_t ApiSys_GetHWID(uint8_t *hw_id_buffer, uint8_t length);

/* Get SWID */
extern uint8_t ApiSys_GetSWID(uint8_t *buffer, uint8_t length);

/* Get A-core ready to sleep signal */
extern int8_t ApiSys_GetACoreReadyToSleep(void);

/* Get VINP_PwrReq_OTA_enum value */
extern uint8_t Apisys_GetVinpPwrReqOta(void);

/* Get VINP_AllowMoveThd_OTA_enum value */
extern uint8_t Apisys_GetVinpAllowMoveThdOta(void);

/* Get VINP_EvccAplusPwrUpReq_flg value */
extern uint8_t Apisys_GetEvccAplusPwrUpReq(void);

/* Get CAN NM input */
extern void ApiCan_SetFrameRoutingEnable(uint8_t state);

/* set IVI_RST GPIO control */
extern void ApiDio_SetIviRst(uint8_t value);

/* APS input */
extern void    ApiAps_GetDist(uint8_t *PASData, uint8_t pas_length);
extern void    ApiAps_GetApsDist(uint16_t *APSData, uint8_t aps_length);
extern void    ApiAps_GetDistLevel(uint8_t *PASData, uint8_t length);
extern void    ApiAps_GetUssSta(uint8_t *PASData, uint8_t length);
extern uint8_t ApiAps_GetPASChime(void);
extern uint8_t ApiAps_GetSensorLayout(void);
extern uint8_t ApiAps_GetPASSystemFailSta(void);
extern uint8_t ApiAps_GetPASSystemMode(void);
extern uint8_t ApiAps_GetAPS_Progress_PCT(void);
extern uint8_t ApiAps_GetAPS_RQ_Display(void);
extern uint8_t ApiAps_GetAPS_SW_Ver(void);
extern uint8_t ApiAps_GetAPS_HW_Ver(void);
extern uint8_t ApiAps_GetAPS_ExitCondition(void);
extern float   ApiAps_GetAPS_Angle_Target(void);
extern uint8_t ApiAps_GetAPS_Sta_System(void);
extern uint8_t ApiAps_GetAPS_V_Rq_EPAS_Ctrl(void);
extern uint8_t ApiAps_GetAPS_Rq_EPAS_Ctrl(void);
extern uint8_t ApiAps_GetAPS_Req(void);
extern float   ApiAps_GetAPS_DecReq(void);
extern uint8_t ApiAps_GetAPS_DecReq_A(void);
extern float   ApiAps_GetAPS_SpeedCmd(void);
extern uint8_t ApiAps_GetAPS_ShftPosnReq(void);
extern uint8_t ApiAps_GetAPS_VMC_Req_A(void);
extern uint8_t ApiAps_GetCAAS_Sta(void);
extern uint8_t ApiAps_GetCAAS_VMC_Req_A(void);
extern uint8_t ApiAps_GetAPS_PwrReq_Cmd(void);
extern uint8_t ApiAps_GetRAPS_BCM_LockReq_Cmd(void);
extern uint8_t ApiAps_GetRAPS_BCM_Lamp_Cmd(void);
extern uint8_t ApiAps_GetRAPS_ErrWarn_enum(void);
extern uint8_t ApiAps_GetRAPS_ErrLv1_flg(void);

/* APS output */
extern void ApiAps_SetVehSpeed(float sig);
extern void ApiAps_SetShiftGearPosn(uint8_t sig);
extern void ApiAps_SetFrontSensorON(uint8_t cmd);
extern void ApiAps_SetVehSpeedTO(uint8_t cmd);
extern void ApiAps_SetFrontSensorSwTO(uint8_t cmd);
extern void ApiAps_SendChrgPlugSta(uint8_t sig);
extern void ApiAps_SetActAPSPosn(float sig);
extern void ApiAps_SetBrkPedalPos(float sig);
extern void ApiAps_SetPwrSta(uint8_t sig);
extern void ApiAps_SetLF_RawWhlSpeed(float sig);
extern void ApiAps_SetRF_RawWhlSpeed(float sig);
extern void ApiAps_SetLR_RawWhlSpeed(float sig);
extern void ApiAps_SetRR_RawWhlSpeed(float sig);
extern void ApiAps_SetLF_RawWhlSpeed_V(uint8_t sig);
extern void ApiAps_SetRF_RawWhlSpeed_V(uint8_t sig);
extern void ApiAps_SetLR_RawWhlSpeed_V(uint8_t sig);
extern void ApiAps_SetRR_RawWhlSpeed_V(uint8_t sig);
extern void ApiAps_SetLF_WhlRotDir(uint8_t sig);
extern void ApiAps_SetRF_WhlRotDir(uint8_t sig);
extern void ApiAps_SetLR_WhlRotDir(uint8_t sig);
extern void ApiAps_SetRR_WhlRotDir(uint8_t sig);
extern void ApiAps_SetLF_PulseCount_V(uint8_t sig);
extern void ApiAps_SetRF_PulseCount_V(uint8_t sig);
extern void ApiAps_SetLR_PulseCount_V(uint8_t sig);
extern void ApiAps_SetRR_PulseCount_V(uint8_t sig);
extern void ApiAps_SetLF_PulseCount(uint16_t sig);
extern void ApiAps_SetRF_PulseCount(uint16_t sig);
extern void ApiAps_SetLR_PulseCount(uint16_t sig);
extern void ApiAps_SetRR_PulseCount(uint16_t sig);
extern void ApiAps_SetAPS_Active(uint8_t sig);
extern void ApiAps_SetAPS_CtrlAvail(uint8_t sig);
extern void ApiAps_SetShifter_Handle_Cmd(uint8_t sig);
extern void ApiAps_SetDriIntend(uint8_t sig);
extern void ApiAps_SetEPS_AOI_Control(uint8_t sig);
extern void ApiAps_SetSAS_Angle(float sig);
extern void ApiAps_SetSAS_Speed(float sig);
extern void ApiAps_SetSAS_Speed_Valid(uint8_t sig);
extern void ApiAps_SetSAS_CAL(uint8_t sig);
extern void ApiAps_SetSAS_OK(uint8_t sig);
extern void ApiAps_SetGRADE(float sig);
extern void ApiAps_SetYawRate(float sig);
extern void ApiAps_SetLatAccel(float sig);
extern void ApiAps_SetLongAccel(float sig);
extern void ApiAps_SetMCPressure(float sig);
extern void ApiAps_SetYawRate_V(uint8_t sig);
extern void ApiAps_SetLatAccel_V(uint8_t sig);
extern void ApiAps_SetLongAccel_V(uint8_t sig);
extern void ApiAps_SetMCPressure_V(uint8_t sig);
extern void ApiAps_SetBrkSw_Sta(uint8_t sig);
extern void ApiAps_SetBrkSw_V(uint8_t sig);
extern void ApiAps_SetESC_Standstill(uint8_t sig);
extern void ApiAps_SetESC_APS_Sta(uint8_t sig);
extern void ApiAps_SetEPBExtReleaseAvail(uint8_t sig);
extern void ApiAps_SetEPBExtApplyAvail(uint8_t sig);
extern void ApiAps_SetEPBErrSta(uint8_t sig);
extern void ApiAps_SetEPBSta(uint8_t sig);
extern void ApiAps_SetAllDoorSW(uint8_t sig);
extern void ApiAps_SetHoodSW(uint8_t sig);
extern void ApiAps_SetTailgate_SW(uint8_t sig);
extern void ApiAps_SetAVM_parking_cancel(uint8_t sig);
extern void ApiAps_SetAVM_parking_excute(uint8_t sig);
extern void ApiAps_SetAVM_Parking_mode(uint8_t sig);
extern void ApiAps_SetAVM_Err_STA(uint8_t sig);
extern void ApiAps_SetIVI_Status(uint8_t sig);
extern void ApiAps_SetCAAS_Sw(uint8_t sig);
extern void ApiAps_SetIVI_Screen(uint8_t sig);
extern void ApiAps_SetCAAS_CtrlAvail(uint8_t sig);
extern void ApiAps_SetABS_Active(uint8_t sig);
extern void ApiAps_SetTCS_Active(uint8_t sig);
extern void ApiAps_SetDriverSeatBeltCmd(uint8_t sig);
extern void ApiAps_SetDrDoorSW(uint8_t sig);
extern void ApiAps_SetPsDoorSW(uint8_t sig);
extern void ApiAps_SetRLDoorSW(uint8_t sig);
extern void ApiAps_SetRRDoorSW(uint8_t sig);
extern void ApiAps_SetRFPressIndi(uint8_t sig);
extern void ApiAps_SetLFPressIndi(uint8_t sig);
extern void ApiAps_SetRRPressIndi(uint8_t sig);
extern void ApiAps_SetLRPressIndi(uint8_t sig);
extern void ApiAps_SetsigAmbAirT(float sig);
extern void ApiAps_SetVehActSpd(float sig);
extern void ApiAps_SetCAAS_Active(uint8_t sig);
extern void ApiAps_SetAPS_PwrReqAvail_Sta(uint8_t sig);
extern void ApiAps_SetDKC_PDkeyAreaRAPS_Sta(uint8_t sig);
extern void ApiAps_SetDKC_ParkingMode_Cmd(uint8_t sig);
extern void ApiAps_SetP_UID_LowPower(uint8_t sig);
extern void ApiAps_SetDr_SeatSta(uint8_t sig);
extern void ApiAps_SetVCU_RAPS_ErrLv2_flg(uint8_t sig);
extern void ApiAps_SetVCU_RAPS_ErrLv3_flg(uint8_t sig);
extern void ApiAps_SetIVI_UserTakeOver_APS_Sta(uint8_t sig);

/* APS output timeout */
extern void ApiAps_SetBrkPedalPosTO(uint8_t to);
extern void ApiAps_SetLF_RawWhlSpeedTO(uint8_t to);
extern void ApiAps_SetRF_RawWhlSpeedTO(uint8_t to);
extern void ApiAps_SetLR_RawWhlSpeedTO(uint8_t to);
extern void ApiAps_SetRR_RawWhlSpeedTO(uint8_t to);
extern void ApiAps_SetLF_RawWhlSpeed_VTO(uint8_t to);
extern void ApiAps_SetRF_RawWhlSpeed_VTO(uint8_t to);
extern void ApiAps_SetLR_RawWhlSpeed_VTO(uint8_t to);
extern void ApiAps_SetRR_RawWhlSpeed_VTO(uint8_t to);
extern void ApiAps_SetLF_WhlRotDirTO(uint8_t to);
extern void ApiAps_SetRF_WhlRotDirTO(uint8_t to);
extern void ApiAps_SetLR_WhlRotDirTO(uint8_t to);
extern void ApiAps_SetRR_WhlRotDirTO(uint8_t to);
extern void ApiAps_SetLF_PulseCount_VTO(uint8_t to);
extern void ApiAps_SetRF_PulseCount_VTO(uint8_t to);
extern void ApiAps_SetLR_PulseCount_VTO(uint8_t to);
extern void ApiAps_SetRR_PulseCount_VTO(uint8_t to);
extern void ApiAps_SetLF_PulseCountTO(uint8_t to);
extern void ApiAps_SetRF_PulseCountTO(uint8_t to);
extern void ApiAps_SetLR_PulseCountTO(uint8_t to);
extern void ApiAps_SetRR_PulseCountTO(uint8_t to);
extern void ApiAps_SetShifter_Handle_CmdTO(uint8_t to);
extern void ApiAps_SetDriIntendTO(uint8_t to);
extern void ApiAps_SetEPS_AOI_ControlTO(uint8_t to);
extern void ApiAps_SetSAS_AngleTO(uint8_t to);
extern void ApiAps_SetSAS_SpeedTO(uint8_t to);
extern void ApiAps_SetSAS_Speed_ValidTO(uint8_t to);
extern void ApiAps_SetSAS_CALTO(uint8_t to);
extern void ApiAps_SetSAS_OKTO(uint8_t to);
extern void ApiAps_SetGRADETO(uint8_t to);
extern void ApiAps_SetYawRateTO(uint8_t to);
extern void ApiAps_SetLatAccelTO(uint8_t to);
extern void ApiAps_SetLongAccelTO(uint8_t to);
extern void ApiAps_SetMCPressureTO(uint8_t to);
extern void ApiAps_SetYawRate_VTO(uint8_t to);
extern void ApiAps_SetLatAccel_VTO(uint8_t to);
extern void ApiAps_SetLongAccel_VTO(uint8_t to);
extern void ApiAps_SetMCPressure_VTO(uint8_t to);
extern void ApiAps_SetBrkSw_StaTO(uint8_t to);
extern void ApiAps_SetBrkSw_VTO(uint8_t to);
extern void ApiAps_SetESC_StandstillTO(uint8_t to);
extern void ApiAps_SetESC_APS_StaTO(uint8_t to);
extern void ApiAps_SetEPBExtReleaseAvailTO(uint8_t to);
extern void ApiAps_SetEPBExtApplyAvailTO(uint8_t to);
extern void ApiAps_SetEPBErrStaTO(uint8_t to);
extern void ApiAps_SetEPBStaTO(uint8_t to);
extern void ApiAps_SetAVM_parking_cancelTO(uint8_t to);
extern void ApiAps_SetAVM_parking_excuteTO(uint8_t to);
extern void ApiAps_SetAVM_Parking_modeTO(uint8_t to);
extern void ApiAps_SetAVM_Err_STATO(uint8_t to);
extern void ApiAps_SetIVI_StatusTO(uint8_t to);
extern void ApiAps_SetCAAS_SwTO(uint8_t to);
extern void ApiAps_SetIVI_ScreenTO(uint8_t to);
extern void ApiAps_SetABS_ActiveTO(uint8_t to);
extern void ApiAps_SetTCS_ActiveTO(uint8_t to);
extern void ApiAps_SetDriverSeatBeltCmdTO(uint8_t to);
extern void ApiAps_SetRFPressIndiTO(uint8_t to);
extern void ApiAps_SetLFPressIndiTO(uint8_t to);
extern void ApiAps_SetRRPressIndiTO(uint8_t to);
extern void ApiAps_SetLRPressIndiTO(uint8_t to);
extern void ApiAps_SetsigAmbAirTTO(uint8_t to);
extern void ApiAps_SetAPS_PwrReqAvail_StaTO(uint8_t to);
extern void ApiAps_SetDKC_PDkeyAreaRAPS_StaTO(uint8_t to);
extern void ApiAps_SetDKC_ParkingMode_CmdTO(uint8_t to);
extern void ApiAps_SetP_UID_LowPowerTO(uint8_t to);
extern void ApiAps_SetDr_SeatStaTO(uint8_t to);
extern void ApiAps_SetVCU_RAPS_ErrLv2_flgTO(uint8_t to);
extern void ApiAps_SetVCU_RAPS_ErrLv3_flgTO(uint8_t to);
extern void ApiAps_SetIVI_UserTakeOver_APS_StaTO(uint8_t to);
extern void ApiAps_SetDummyTO(void);

/* SLEEP input */
extern uint8_t ApiSys_ReadAppData(uint8_t *AppData, uint32_t length);

/* SLEEP output */
extern int8_t  ApiSys_MCoreSleepRequest(vs_sleepy_state_t state, uint32_t wakeup_timer_s);
extern int8_t  ApiSys_SetCanNmState(vs_can_nm_stat_t state);
extern int8_t  ApiSys_SetSysPwrStat(uint8_t state);
extern uint8_t ApiSys_WriteAppData(uint8_t *Appdata, uint32_t length);
extern uint8_t ApiSys_GetDIDdata(uint16_t DID, uint8_t *buf, uint16_t length);

/* DKC Decryption */
extern void ApiAES_ECB_Decrypt(const uint8_t *aes_key, const uint8_t *raw_data, uint8_t *result_data);

/* UDS main */
extern void uds_main(void);

/* WatchDog manager CDD */
extern void ApiWdgM_AliveSupervision_0(void);
extern void ApiWdgM_WdgMMode_NormalOperation(void);
extern void ApiWdgM_WdgMMode_Shutdown(void);

/* NM CDD */
extern void    ApiNm_NetworkRelease(void);
extern void    ApiNm_NetworkRequest(void);
extern uint8_t ApiNm_Get_Status(void);
extern uint8_t ApiNm_RxNotificationGet(void);
extern void    ApiNm_RxNotificationClear(void);

/* IPCF CDD */
extern void     ApiIpcf_Event_Process(void);
extern uint16_t vs_api_get_battery_voltage_100mv(void);

/* Peripheral main */
extern void peripheral_main(void);

/* IMU CDD */
extern void    ApiImu_SetImuSta(uint8_t cmd);
extern uint8_t ApiImu_GetOffsetValue(int16_t *data, uint8_t length);
extern uint8_t ApiImu_GetSixAxisValue(int16_t *data, uint8_t length);

/* NVM Protect CDD */
extern uint8_t nvm_protect_get(void);

/* GetBootReason */
extern uint8_t  PMIC_GetBootReason(void);
extern uint32_t Power_GetWisr(void);

/* GetBootPath */
extern uint32_t pmic_get_boot_path(void);

/* ProcessDIDdata */
extern uint8_t ApiSys_VCUGetDIDdata(uint16_t DID, uint8_t *Data, uint16_t DataLength);
extern uint8_t ApiSys_VCUSetDIDdata(uint16_t DID, const uint8_t *Data, uint16_t DataLength);
extern uint8_t ApiSys_BCMGetDIDdata(uint16_t DID, uint8_t *Data, uint16_t DataLength);
extern uint8_t ApiSys_BCMSetDIDdata(uint16_t DID, const uint8_t *Data, uint16_t DataLength);
extern uint8_t ApiSys_TPMGetDIDdata(uint16_t DID, uint8_t *Data, uint16_t DataLength);
extern uint8_t ApiSys_TPMSetDIDdata(uint16_t DID, const uint8_t *Data, uint16_t DataLength);
extern uint8_t ApiSys_APSGetDIDdata(uint16_t DID, uint8_t *Data, uint16_t DataLength);
extern uint8_t ApiSys_APSSetDIDdata(uint16_t DID, const uint8_t *Data, uint16_t DataLength);
extern uint8_t ApiSys_FoxtronPiGetDIDdata(uint16_t DID, uint8_t *Data, uint16_t DataLength);
extern uint8_t ApiSys_FoxtronPiSetDIDdata(uint16_t DID, const uint8_t *Data, uint16_t DataLength);

/* DID routine control */
extern uint8_t ApiSys_TpmSensorIdRegisterGetSta(void);
extern void    ApiSys_TpmSensorIdRegisterSetResults(const uint8_t *u8Array2_TPMSSensorIDRegResults);
extern uint8_t ApiSys_ResetPedalZeroPosReq(void);
extern void    ApiSys_ResetPedalZeroPosDone(void);
extern uint8_t ApiSys_ReadPedalZeroPosReq(void);

/* ACoreReboot */
extern uint8_t ApiSys_GetACoreRebootRequest(void);
extern int8_t  ApiSys_SetMCoreRebootConfirm(void);

/* CAN Bus Off*/
extern bool api_nm_get_can_bus_off_state(uint8_t can_channel);
extern void api_nm_get_can_error_count(uint8_t can_channel, uint8_t *p_error_count, bool is_get_rx);

/* LOG */
extern void log_save_main(void);

/* Get Vin Code */
extern uint8_t uds_get_vin_code(uint8_t *buffer, uint16_t length);

#endif
