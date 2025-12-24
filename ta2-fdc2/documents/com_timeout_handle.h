/*==================================================================================================
 * Copyright 2024 (c) Foxtron Inc - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
==================================================================================================*/

typedef enum
{
    RTSG_CAN1_SG_AC_BTMS_C1000_0,
    RTSG_CAN1_SG_AC_BTMS_C1000_1,
    RTSG_CAN1_SG_AC_BTMS_C1000_2,
    RTSG_CAN1_SG_AC_BTMS_C1000_4,
    RTSG_CAN1_SG_AC_BTMS_C5000_0,
    RTSG_CAN1_SG_ASC1_A,
    RTSG_CAN1_SG_EBC1,
    RTSG_CAN1_SG_EBC2,
    RTSG_CAN1_SG_EBC5,
    RTSG_CAN1_SG_ECAS_DM1,
    RTSG_CAN1_SG_EMC1_EM1,
    RTSG_CAN1_SG_HRW,
    RTSG_CAN1_SG_TC1,
    RTSG_CAN1_SG_TPMS1,
    RTSG_CAN1_SG_TPMS2,
    RTSG_CAN1_SG_TPMS3,
    RTSG_CAN1_SG_VDC1,
    RTSG_CAN2_SG_IVI_C100_0,
    RTSG_CAN3_SG_B2TM_Info,
    RTSG_CAN3_SG_B2V_BattInfo1,
    RTSG_CAN3_SG_B2V_CurrentLimit,
    RTSG_CAN3_SG_B2V_Fult1_32960,
    RTSG_CAN3_SG_B2V_ST1,
    RTSG_CAN3_SG_B2V_ST2,
    RTSG_CAN3_SG_B2V_ST4,
    RTSG_CAN3_SG_B2V_ST5,
    RTSG_CAN3_SG_EWP1,
    RTSG_CAN3_SG_TM_MCUSta1,
    RTSG_CAN3_SG_TM_MCUSta2,
    RTSG_CAN3_SG_TM_MCUSta3,
    RTSG_CAN4_SG_ZFR_C100_0,
    RTSG_CAN4_SG_ZFR_C5000_0,
    RTSG_CAN4_SG_ZFR_CE100_0,
    RTSG_CAN4_SG_ZRR_C5000_0,
    RTSG_CAN4_SG_ZRR_CE100_0,
    RTSG_CAN4_SG_ZRR_CE100_1,
    RTSG_CAN4_SG_zGW_CANRr1_C50_0,
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
