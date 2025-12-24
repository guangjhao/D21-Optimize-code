/*==================================================================================================
 * Copyright 2024 (c) Foxtron Inc - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
==================================================================================================*/

typedef enum
{
    RTSG_CAN1_SG_ABM1
    RTSG_COUNT,
} rtsg_index_t;

/*
    Recode Signal's current state,
    and to prevent from duplicate notification to SWC_CGW
*/
typedef enum
{
    RTSG_STATE_INIT,    /*Current value is ComSignalInitValue*/
    RTSG_STATE_RXACK,   /*Current value is what ECU received*/
    RTSG_STATE_TIMEOUT, /*Current value is ComTimeoutSubstitutionValue*/
} rtsg_state_t;

extern rtsg_state_t g_rtsg_states[RTSG_COUNT];
