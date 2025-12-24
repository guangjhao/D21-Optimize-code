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


FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C1000_0_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_AC_BTMS_C1000_0);
	VHAL_CANMsgInvalidACBTMSC10000_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C1000_0_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_AC_BTMS_C1000_0);
	VHAL_CANMsgInvalidACBTMSC10000_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C1000_1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_AC_BTMS_C1000_1);
	VHAL_CANMsgInvalidACBTMSC10001_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C1000_1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_AC_BTMS_C1000_1);
	VHAL_CANMsgInvalidACBTMSC10001_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C1000_2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_AC_BTMS_C1000_2);
}

FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C1000_2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_AC_BTMS_C1000_2);
}

FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C1000_4_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_AC_BTMS_C1000_4);
	VHAL_CANMsgInvalidACBTMSC10004_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C1000_4_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_AC_BTMS_C1000_4);
	VHAL_CANMsgInvalidACBTMSC10004_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C5000_0_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_AC_BTMS_C5000_0);
	VHAL_CANMsgInvalidACBTMSC50000_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_AC_BTMS_C5000_0_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_AC_BTMS_C5000_0);
	VHAL_CANMsgInvalidACBTMSC50000_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_ASC1_A_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_ASC1_A);
	VHAL_CANMsgInvalidASC1A_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_ASC1_A_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_ASC1_A);
	VHAL_CANMsgInvalidASC1A_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EBC1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_EBC1);
	VHAL_CANMsgInvalidEBC1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EBC1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_EBC1);
	VHAL_CANMsgInvalidEBC1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EBC2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_EBC2);
	VHAL_CANMsgInvalidEBC2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EBC2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_EBC2);
	VHAL_CANMsgInvalidEBC2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EBC5_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_EBC5);
	VHAL_CANMsgInvalidEBC5_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EBC5_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_EBC5);
	VHAL_CANMsgInvalidEBC5_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_ECAS_DM1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_ECAS_DM1);
	VHAL_CANMsgInvalidECASDM1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_ECAS_DM1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_ECAS_DM1);
	VHAL_CANMsgInvalidECASDM1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EMC1_EM1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_EMC1_EM1);
	VHAL_CANMsgInvalidEMC1EM1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_EMC1_EM1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_EMC1_EM1);
	VHAL_CANMsgInvalidEMC1EM1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_HRW_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_HRW);
	VHAL_CANMsgInvalidHRW_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_HRW_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_HRW);
	VHAL_CANMsgInvalidHRW_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_TC1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_TC1);
	VHAL_CANMsgInvalidTC1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_TC1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_TC1);
	VHAL_CANMsgInvalidTC1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN1_SG_TPMS1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_TPMS1);
}

FUNC(void, COM_APPL_CODE) CAN1_SG_TPMS1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_TPMS1);
}

FUNC(void, COM_APPL_CODE) CAN1_SG_TPMS2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_TPMS2);
}

FUNC(void, COM_APPL_CODE) CAN1_SG_TPMS2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_TPMS2);
}

FUNC(void, COM_APPL_CODE) CAN1_SG_TPMS3_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_TPMS3);
}

FUNC(void, COM_APPL_CODE) CAN1_SG_TPMS3_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_TPMS3);
}

FUNC(void, COM_APPL_CODE) CAN1_SG_VDC1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN1_SG_VDC1);
}

FUNC(void, COM_APPL_CODE) CAN1_SG_VDC1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN1_SG_VDC1);
}

FUNC(void, COM_APPL_CODE) CAN2_SG_IVI_C100_0_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN2_SG_IVI_C100_0);
	VHAL_CANMsgInvalidIVIC1000_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN2_SG_IVI_C100_0_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN2_SG_IVI_C100_0);
	VHAL_CANMsgInvalidIVIC1000_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2TM_Info_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_B2TM_Info);
	VHAL_CANMsgInvalidB2TMInfo_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2TM_Info_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_B2TM_Info);
	VHAL_CANMsgInvalidB2TMInfo_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_BattInfo1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_B2V_BattInfo1);
	VHAL_CANMsgInvalidB2VBattInfo1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_BattInfo1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_B2V_BattInfo1);
	VHAL_CANMsgInvalidB2VBattInfo1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_CurrentLimit_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_B2V_CurrentLimit);
	VHAL_CANMsgInvalidB2VCurrentLimit_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_CurrentLimit_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_B2V_CurrentLimit);
	VHAL_CANMsgInvalidB2VCurrentLimit_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_Fult1_32960_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_B2V_Fult1_32960);
	VHAL_CANMsgInvalidB2VFult132960_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_Fult1_32960_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_B2V_Fult1_32960);
	VHAL_CANMsgInvalidB2VFult132960_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_ST1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_B2V_ST1);
	VHAL_CANMsgInvalidB2VST1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_ST1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_B2V_ST1);
	VHAL_CANMsgInvalidB2VST1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_ST2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_B2V_ST2);
	VHAL_CANMsgInvalidB2VST2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_ST2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_B2V_ST2);
	VHAL_CANMsgInvalidB2VST2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_ST4_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_B2V_ST4);
	VHAL_CANMsgInvalidB2VST4_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_ST4_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_B2V_ST4);
	VHAL_CANMsgInvalidB2VST4_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_ST5_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_B2V_ST5);
	VHAL_CANMsgInvalidB2VST5_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_B2V_ST5_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_B2V_ST5);
	VHAL_CANMsgInvalidB2VST5_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_EWP1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_EWP1);
	VHAL_CANMsgInvalidEWP1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_EWP1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_EWP1);
	VHAL_CANMsgInvalidEWP1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_TM_MCUSta1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_TM_MCUSta1);
	VHAL_CANMsgInvalidTMMCUSta1_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_TM_MCUSta1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_TM_MCUSta1);
	VHAL_CANMsgInvalidTMMCUSta1_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_TM_MCUSta2_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_TM_MCUSta2);
	VHAL_CANMsgInvalidTMMCUSta2_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_TM_MCUSta2_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_TM_MCUSta2);
	VHAL_CANMsgInvalidTMMCUSta2_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_TM_MCUSta3_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN3_SG_TM_MCUSta3);
	VHAL_CANMsgInvalidTMMCUSta3_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN3_SG_TM_MCUSta3_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN3_SG_TM_MCUSta3);
	VHAL_CANMsgInvalidTMMCUSta3_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZFR_C100_0_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZFR_C100_0);
	VHAL_CANMsgInvalidZFRC1000_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZFR_C100_0_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZFR_C100_0);
	VHAL_CANMsgInvalidZFRC1000_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZFR_C5000_0_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZFR_C5000_0);
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZFR_C5000_0_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZFR_C5000_0);
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZFR_CE100_0_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZFR_CE100_0);
	VHAL_CANMsgInvalidZFRCE1000_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZFR_CE100_0_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZFR_CE100_0);
	VHAL_CANMsgInvalidZFRCE1000_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZRR_C5000_0_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZRR_C5000_0);
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZRR_C5000_0_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZRR_C5000_0);
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZRR_CE100_0_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZRR_CE100_0);
	VHAL_CANMsgInvalidZRRCE1000_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZRR_CE100_0_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZRR_CE100_0);
	VHAL_CANMsgInvalidZRRCE1000_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZRR_CE100_1_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_ZRR_CE100_1);
	VHAL_CANMsgInvalidZRRCE1001_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_ZRR_CE100_1_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_ZRR_CE100_1);
	VHAL_CANMsgInvalidZRRCE1001_flg = true;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_CANRr1_C50_0_ComNotification(void)
{
    fvt_rtsg_notification_handler(RTSG_CAN4_SG_zGW_CANRr1_C50_0);
	VHAL_CANMsgInvalidzGWCANRr1C500_flg = false;
}

FUNC(void, COM_APPL_CODE) CAN4_SG_zGW_CANRr1_C50_0_ComTimeoutNotification(void)
{
    fvt_rtsg_timeout_handler(RTSG_CAN4_SG_zGW_CANRr1_C50_0);
	VHAL_CANMsgInvalidzGWCANRr1C500_flg = true;
}


#ifdef __cplusplus
}
#endif

/** @} */
