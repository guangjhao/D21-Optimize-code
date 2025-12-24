/*==================================================================================================
 * Copyright 2024 (c) Foxtron Inc - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
==================================================================================================*/

typedef enum
{
    RTSG_CAN1_SG_ABM1,
    RTSG_CAN1_SG_EPB1,
    RTSG_CAN1_SG_EPS1,
    RTSG_CAN1_SG_ESC1,
    RTSG_CAN1_SG_ESC5,
    RTSG_CAN1_SG_eBST1,
    RTSG_CAN2_SG_HMI1,
    RTSG_CAN2_SG_IVI1,
    RTSG_CAN2_SG_IVI2,
    RTSG_CAN2_SG_IVI3,
    RTSG_CAN2_SG_METER1,
    RTSG_CAN3_SG_BMS1,
    RTSG_CAN3_SG_BMS3,
    RTSG_CAN3_SG_BMS4,
    RTSG_CAN3_SG_BMS5,
    RTSG_CAN3_SG_BMS6,
    RTSG_CAN3_SG_BMS8,
    RTSG_CAN3_SG_CCU1,
    RTSG_CAN3_SG_CCU2,
    RTSG_CAN3_SG_EBM1,
    RTSG_CAN3_SG_MCU_B_F1,
    RTSG_CAN3_SG_MCU_B_F2,
    RTSG_CAN3_SG_MCU_B_R1,
    RTSG_CAN3_SG_MCU_B_R2,
    RTSG_CAN3_SG_MCU_N_F1,
    RTSG_CAN3_SG_MCU_N_F2,
    RTSG_CAN3_SG_MCU_N_F3,
    RTSG_CAN3_SG_MCU_N_R1,
    RTSG_CAN3_SG_MCU_N_R2,
    RTSG_CAN3_SG_MCU_N_R3,
    RTSG_CAN3_SG_Shifter1,
    RTSG_CAN3_SG_Shifter2,
    RTSG_CAN4_SG_DKC1,
    RTSG_CAN4_SG_DKC2,
    RTSG_CAN4_SG_PTG1,
    RTSG_CAN4_SG_ZONE_DR1,
    RTSG_CAN4_SG_ZONE_DR_VCU,
    RTSG_CAN4_SG_ZONE_FR1,
    RTSG_CAN4_SG_ZONE_FR_VCU,
    RTSG_CAN4_SG_ZONE_L1,
    RTSG_CAN4_SG_ZONE_L2,
    RTSG_CAN4_SG_ZONE_R1,
    RTSG_CAN4_SG_ZONE_R2,
    RTSG_CAN4_SG_zGW_APTC1,
    RTSG_CAN4_SG_zGW_CANFr1,
    RTSG_CAN4_SG_zGW_LINDr1,
    RTSG_CAN4_SG_zGW_LINFr1,
    RTSG_CAN4_SG_zGW_SEAT1,
    RTSG_CAN5_SG_TBOX1,
    RTSG_CAN5_SG_TBOX2,
    RTSG_CAN5_SG_TBOX3,
    RTSG_CAN6_SG_FCM1,
    RTSG_CAN6_SG_FCM3,
    RTSG_CAN6_SG_SRR1,
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
