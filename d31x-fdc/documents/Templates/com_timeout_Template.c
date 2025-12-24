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
#include "SWC_FDC_type.h"
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


#ifdef __cplusplus
}
#endif

/** @} */
