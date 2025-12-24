/*==================================================================================================
 * Copyright 2024 (c) Foxtron Inc - All Rights Reserved
 *
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
==================================================================================================*/

typedef enum
{
    RTSG_CAN1_SG_DCDC_Status_1,
    RTSG_CAN1_SG_DCDC_Status_2,
    RTSG_CAN1_SG_EAC_Status_1,
    RTSG_CAN1_SG_EBC1,
    RTSG_CAN1_SG_EBC2,
    RTSG_CAN1_SG_EBC5,
    RTSG_CAN1_SG_EHPS_Status_1,
    RTSG_CAN1_SG_EMC1_EM1,
    RTSG_CAN1_SG_EPB1,
    RTSG_CAN1_SG_PDU_Status_1,
    RTSG_CAN2_SG_IVI1,
    RTSG_CAN2_SG_IVI2,
    RTSG_CAN2_SG_IVI3,
    RTSG_CAN2_SG_IVI_P20_0,
    RTSG_CAN2_SG_METER1,
    RTSG_CAN3_SG_BMS1,
    RTSG_CAN3_SG_BMS3,
    RTSG_CAN3_SG_BMS4,
    RTSG_CAN3_SG_BMS5,
    RTSG_CAN3_SG_BMS6,
    RTSG_CAN3_SG_BMS8,
    RTSG_CAN3_SG_CCU1,
    RTSG_CAN3_SG_CCU2,
    RTSG_CAN3_SG_MCU_B_R1,
    RTSG_CAN3_SG_MCU_B_R2,
    RTSG_CAN3_SG_Shifter1,
    RTSG_CAN4_SG_DKC1,
    RTSG_CAN4_SG_DKC2,
    RTSG_CAN4_SG_Z24_C1000_0,
    RTSG_CAN4_SG_Z24_CE100_0,
    RTSG_CAN4_SG_ZONE_DR1,
    RTSG_CAN4_SG_ZONE_DR_VCU,
    RTSG_CAN4_SG_ZONE_FR1,
    RTSG_CAN4_SG_ZONE_FR_VCU,
    RTSG_CAN4_SG_zGW_APTC1,
    RTSG_CAN4_SG_zGW_CANFr1,
    RTSG_CAN4_SG_zGW_LINDr1,
    RTSG_CAN5_SG_TBOX1,
    RTSG_CAN5_SG_TBOX2,
    RTSG_CAN5_SG_TBOX3,
    RTSG_CAN7_SG_Door_Fr1,
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
