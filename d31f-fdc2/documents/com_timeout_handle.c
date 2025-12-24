/*==================================================================================================
 * Copyright 2022 (c) Foxtron Inc - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
==================================================================================================*/

#ifdef __cplusplus
extern "C"
{
#endif


/*==================================================================================================
*                                        INCLUDE FILES
* 1) system and project includes
* 2) needed interfaces from external units
* 3) internal and external interfaces from this unit
==================================================================================================*/
#include <string.h>
#include <TSAutosar.h>      /* EB specific standard types */
#include <ComStack_Types.h> /* AUTOSAR Standard type */
#include "Com_Cbk.h"
#include "Com_Api_Static.h"
#include "Rte_Intern.h"
#include "Os_api.h"
#include "PlatformTypes.h"
#include "SWC_HALIN_type.h"
#include "logging.h"
#include "com_timeout_handle.h"

/*==================================================================================================
*                          LOCAL TYPEDEFS (STRUCTURES, UNIONS, ENUMS)
==================================================================================================*/

/*==================================================================================================
*                                       LOCAL MACROS
==================================================================================================*/
#define COM_SIGNAL_TIMEOUT_NOTIFY_SWC_CGW_EVENT (0x0002u)
#define SETEVENT_SWC_CGW_FAIL_STRING            "SetEvent NOTIFY_SWC_CGW failed*\r\n"

/*==================================================================================================
*                                      LOCAL CONSTANTS
==================================================================================================*/

/*==================================================================================================
*                                      LOCAL VARIABLES
==================================================================================================*/
rtsg_state_t g_rtsg_states[RTSG_COUNT] = { RTSG_STATE_INIT };

/*==================================================================================================
*                                      GLOBAL CONSTANTS
==================================================================================================*/

/*==================================================================================================
*                                      GLOBAL VARIABLES
==================================================================================================*/

/*==================================================================================================
*                                   LOCAL FUNCTION PROTOTYPES
==================================================================================================*/
static void fvt_rtsg_timeout_handler(rtsg_index_t timeout_rtsg_index);
static void fvt_rtsg_notification_handler(rtsg_index_t rxack_rtsg_index);

/*==================================================================================================
*                                       LOCAL FUNCTIONS
==================================================================================================*/
static void fvt_rtsg_timeout_handler (rtsg_index_t timeout_rtsg_index)
{
    if (g_rtsg_states[timeout_rtsg_index] != RTSG_STATE_TIMEOUT)
    {
        g_rtsg_states[timeout_rtsg_index] = RTSG_STATE_TIMEOUT;

        if (SetEvent(SWC_CGW_Task, COM_SIGNAL_TIMEOUT_NOTIFY_SWC_CGW_EVENT) != E_OK)
        {
            /*Event set failed*/
            Logging_Printf(SETEVENT_SWC_CGW_FAIL_STRING);
        }
    }
}

static void fvt_rtsg_notification_handler (rtsg_index_t rxack_rtsg_index)
{
    if (g_rtsg_states[rxack_rtsg_index] != RTSG_STATE_RXACK)
    {
        g_rtsg_states[rxack_rtsg_index] = RTSG_STATE_RXACK;
    }
}

/*==================================================================================================
*                                       GLOBAL FUNCTIONS
==================================================================================================*/


FUNC(void, COM_APPL_CODE) CAN1_SG_ABM1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_ABM1);
	VHAL_CANMsgInvalidABM1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_ABM1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_ABM1);
	VHAL_CANMsgInvalidABM1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EPB1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_EPB1);
	VHAL_CANMsgInvalidEPB1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EPB1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_EPB1);
	VHAL_CANMsgInvalidEPB1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EPS1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_EPS1);
	VHAL_CANMsgInvalidEPS1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EPS1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_EPS1);
	VHAL_CANMsgInvalidEPS1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_ESC1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_ESC1);
	VHAL_CANMsgInvalidESC1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_ESC1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_ESC1);
	VHAL_CANMsgInvalidESC1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_ESC5_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_ESC5);
	VHAL_CANMsgInvalidESC5_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_ESC5_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_ESC5);
	VHAL_CANMsgInvalidESC5_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_eBST1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_eBST1);
	VHAL_CANMsgInvalideBST1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_eBST1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_eBST1);
	VHAL_CANMsgInvalideBST1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_HMI1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN2_SG_HMI1);
	VHAL_CANMsgInvalidHMI1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_HMI1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN2_SG_HMI1);
	VHAL_CANMsgInvalidHMI1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_IVI1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN2_SG_IVI1);
	VHAL_CANMsgInvalidIVI1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_IVI1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN2_SG_IVI1);
	VHAL_CANMsgInvalidIVI1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_IVI2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN2_SG_IVI2);
	VHAL_CANMsgInvalidIVI2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_IVI2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN2_SG_IVI2);
	VHAL_CANMsgInvalidIVI2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_IVI3_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN2_SG_IVI3);
	VHAL_CANMsgInvalidIVI3_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_IVI3_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN2_SG_IVI3);
	VHAL_CANMsgInvalidIVI3_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_METER1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN2_SG_METER1);
	VHAL_CANMsgInvalidMETER1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_METER1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN2_SG_METER1);
	VHAL_CANMsgInvalidMETER1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_BMS1);
	VHAL_CANMsgInvalidBMS1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_BMS1);
	VHAL_CANMsgInvalidBMS1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS3_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_BMS3);
	VHAL_CANMsgInvalidBMS3_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS3_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_BMS3);
	VHAL_CANMsgInvalidBMS3_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS4_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_BMS4);
	VHAL_CANMsgInvalidBMS4_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS4_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_BMS4);
	VHAL_CANMsgInvalidBMS4_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS5_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_BMS5);
	VHAL_CANMsgInvalidBMS5_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS5_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_BMS5);
	VHAL_CANMsgInvalidBMS5_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS6_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_BMS6);
	VHAL_CANMsgInvalidBMS6_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS6_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_BMS6);
	VHAL_CANMsgInvalidBMS6_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS8_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_BMS8);
	VHAL_CANMsgInvalidBMS8_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_BMS8_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_BMS8);
	VHAL_CANMsgInvalidBMS8_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_CCU1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_CCU1);
	VHAL_CANMsgInvalidCCU1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_CCU1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_CCU1);
	VHAL_CANMsgInvalidCCU1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_CCU2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_CCU2);
	VHAL_CANMsgInvalidCCU2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_CCU2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_CCU2);
	VHAL_CANMsgInvalidCCU2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_EBM1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_EBM1);
	VHAL_CANMsgInvalidEBM1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_EBM1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_EBM1);
	VHAL_CANMsgInvalidEBM1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_B_F1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_B_F1);
	VHAL_CANMsgInvalidMCUBF1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_B_F1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_B_F1);
	VHAL_CANMsgInvalidMCUBF1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_B_F2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_B_F2);
	VHAL_CANMsgInvalidMCUBF2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_B_F2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_B_F2);
	VHAL_CANMsgInvalidMCUBF2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_B_R1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_B_R1);
	VHAL_CANMsgInvalidMCUBR1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_B_R1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_B_R1);
	VHAL_CANMsgInvalidMCUBR1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_B_R2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_B_R2);
	VHAL_CANMsgInvalidMCUBR2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_B_R2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_B_R2);
	VHAL_CANMsgInvalidMCUBR2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_F1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_N_F1);
	VHAL_CANMsgInvalidMCUNF1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_F1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_N_F1);
	VHAL_CANMsgInvalidMCUNF1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_F2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_N_F2);
	VHAL_CANMsgInvalidMCUNF2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_F2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_N_F2);
	VHAL_CANMsgInvalidMCUNF2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_F3_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_N_F3);
	VHAL_CANMsgInvalidMCUNF3_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_F3_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_N_F3);
	VHAL_CANMsgInvalidMCUNF3_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_R1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_N_R1);
	VHAL_CANMsgInvalidMCUNR1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_R1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_N_R1);
	VHAL_CANMsgInvalidMCUNR1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_R2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_N_R2);
	VHAL_CANMsgInvalidMCUNR2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_R2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_N_R2);
	VHAL_CANMsgInvalidMCUNR2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_R3_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_MCU_N_R3);
	VHAL_CANMsgInvalidMCUNR3_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_MCU_N_R3_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_MCU_N_R3);
	VHAL_CANMsgInvalidMCUNR3_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_Shifter1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_Shifter1);
	VHAL_CANMsgInvalidShifter1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_Shifter1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_Shifter1);
	VHAL_CANMsgInvalidShifter1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_Shifter2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_Shifter2);
	VHAL_CANMsgInvalidShifter2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_Shifter2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_Shifter2);
	VHAL_CANMsgInvalidShifter2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_BodyZone_DR1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_BodyZone_DR1);
	VHAL_CANMsgInvalidBodyZoneDR1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_BodyZone_DR1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_BodyZone_DR1);
	VHAL_CANMsgInvalidBodyZoneDR1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_BodyZone_DR2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_BodyZone_DR2);
	VHAL_CANMsgInvalidBodyZoneDR2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_BodyZone_DR2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_BodyZone_DR2);
	VHAL_CANMsgInvalidBodyZoneDR2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_BodyZone_PS1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_BodyZone_PS1);
	VHAL_CANMsgInvalidBodyZonePS1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_BodyZone_PS1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_BodyZone_PS1);
	VHAL_CANMsgInvalidBodyZonePS1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_BodyZone_PS2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_BodyZone_PS2);
	VHAL_CANMsgInvalidBodyZonePS2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_BodyZone_PS2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_BodyZone_PS2);
	VHAL_CANMsgInvalidBodyZonePS2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_DKC1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_DKC1);
	VHAL_CANMsgInvalidDKC1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_DKC1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_DKC1);
	VHAL_CANMsgInvalidDKC1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_DKC2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_DKC2);
	VHAL_CANMsgInvalidDKC2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_DKC2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_DKC2);
	VHAL_CANMsgInvalidDKC2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_PTG1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_PTG1);
	VHAL_CANMsgInvalidPTG1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_PTG1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_PTG1);
	VHAL_CANMsgInvalidPTG1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZONE_DR1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZONE_DR1);
	VHAL_CANMsgInvalidZONEDR1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZONE_DR1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZONE_DR1);
	VHAL_CANMsgInvalidZONEDR1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZONE_DR_VCU_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZONE_DR_VCU);
	VHAL_CANMsgInvalidZONEDRVCU_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZONE_DR_VCU_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZONE_DR_VCU);
	VHAL_CANMsgInvalidZONEDRVCU_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZONE_FR1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZONE_FR1);
	VHAL_CANMsgInvalidZONEFR1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZONE_FR1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZONE_FR1);
	VHAL_CANMsgInvalidZONEFR1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZONE_FR_VCU_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZONE_FR_VCU);
	VHAL_CANMsgInvalidZONEFRVCU_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZONE_FR_VCU_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZONE_FR_VCU);
	VHAL_CANMsgInvalidZONEFRVCU_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_APTC1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_zGW_APTC1);
	VHAL_CANMsgInvalidzGWAPTC1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_APTC1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_zGW_APTC1);
	VHAL_CANMsgInvalidzGWAPTC1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_CANFr1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_zGW_CANFr1);
	VHAL_CANMsgInvalidzGWCANFr1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_CANFr1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_zGW_CANFr1);
	VHAL_CANMsgInvalidzGWCANFr1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_LINDr1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_zGW_LINDr1);
	VHAL_CANMsgInvalidzGWLINDr1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_LINDr1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_zGW_LINDr1);
	VHAL_CANMsgInvalidzGWLINDr1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_LINDr2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_zGW_LINDr2);
	VHAL_CANMsgInvalidzGWLINDr2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_LINDr2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_zGW_LINDr2);
	VHAL_CANMsgInvalidzGWLINDr2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_LINFr1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_zGW_LINFr1);
	VHAL_CANMsgInvalidzGWLINFr1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_LINFr1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_zGW_LINFr1);
	VHAL_CANMsgInvalidzGWLINFr1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_LINFr2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_zGW_LINFr2);
	VHAL_CANMsgInvalidzGWLINFr2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_LINFr2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_zGW_LINFr2);
	VHAL_CANMsgInvalidzGWLINFr2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_SEAT1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_zGW_SEAT1);
	VHAL_CANMsgInvalidzGWSEAT1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_SEAT1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_zGW_SEAT1);
	VHAL_CANMsgInvalidzGWSEAT1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN5_SG_TBOX1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN5_SG_TBOX1);
}

FUNC(void, COM_APPL_CODE) CAN5_SG_TBOX1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN5_SG_TBOX1);
}

FUNC(void, COM_APPL_CODE) CAN5_SG_TBOX2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN5_SG_TBOX2);
	VHAL_CANMsgInvalidTBOX2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN5_SG_TBOX2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN5_SG_TBOX2);
	VHAL_CANMsgInvalidTBOX2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN5_SG_TBOX3_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN5_SG_TBOX3);
	VHAL_CANMsgInvalidTBOX3_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN5_SG_TBOX3_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN5_SG_TBOX3);
	VHAL_CANMsgInvalidTBOX3_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_FCM1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN6_SG_FCM1);
	VHAL_CANMsgInvalidFCM1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_FCM1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN6_SG_FCM1);
	VHAL_CANMsgInvalidFCM1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_FCM2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN6_SG_FCM2);
	VHAL_CANMsgInvalidFCM2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_FCM2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN6_SG_FCM2);
	VHAL_CANMsgInvalidFCM2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_FCM3_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN6_SG_FCM3);
	VHAL_CANMsgInvalidFCM3_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_FCM3_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN6_SG_FCM3);
	VHAL_CANMsgInvalidFCM3_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_FCM4_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN6_SG_FCM4);
	VHAL_CANMsgInvalidFCM4_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_FCM4_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN6_SG_FCM4);
	VHAL_CANMsgInvalidFCM4_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_SRR1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN6_SG_SRR1);
	VHAL_CANMsgInvalidSRR1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN6_SG_SRR1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN6_SG_SRR1);
	VHAL_CANMsgInvalidSRR1_flg = true;
}


#ifdef __cplusplus
}
#endif

/** @} */
