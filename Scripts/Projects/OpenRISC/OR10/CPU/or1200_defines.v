
// Include this header file only once.
`ifndef or1200_defines_included
`define or1200_defines_included

// These constants come from the OR1200 CPU implementation, but they are not specific to that project
// and should probably be called OR1000_xxx instead (for the OpenRISC 1000 Architecture).

//-----------------------------------------------------------------
// SPR Registers
//-----------------------------------------------------------------

// SPR Groups
`define OR1200_SPR_GROUP_SYS    5'd00
`define OR1200_SPR_GROUP_DMMU   5'd01
`define OR1200_SPR_GROUP_IMMU   5'd02
`define OR1200_SPR_GROUP_DC     5'd03
`define OR1200_SPR_GROUP_IC     5'd04
`define OR1200_SPR_GROUP_MAC    5'd05
`define OR1200_SPR_GROUP_DU     5'd06
`define OR1200_SPR_GROUP_PM     5'd08
`define OR1200_SPR_GROUP_PIC    5'd09
`define OR1200_SPR_GROUP_TT     5'd10
`define OR1200_SPR_GROUP_FPU    5'd11

// SPR Group: System
`define OR1200_SPRGRP_SYS_VR        11'h0    // Version Register.
`define OR1200_SPRGRP_SYS_UPR       11'h1    // Unit Present Register.
`define OR1200_SPRGRP_SYS_CPUCFGR   11'h2
`define OR1200_SPRGRP_SYS_DMMUCFGR  11'h3
`define OR1200_SPRGRP_SYS_IMMUCFGR  11'h4
`define OR1200_SPRGRP_SYS_DCCFGR    11'h5
`define OR1200_SPRGRP_SYS_ICCFGR    11'h6
`define OR1200_SPRGRP_SYS_DCFGR     11'h7
`define OR1200_SPRGRP_SYS_NPC       11'h010  // Next PC.
`define OR1200_SPRGRP_SYS_SR        11'h011  // 17 in decimal. Supervision Register.
`define OR1200_SPRGRP_SYS_EPCR      11'h020  // Exception PC Register.
`define OR1200_SPRGRP_SYS_EEAR      11'h030  // Exception Effective Address Register.
`define OR1200_SPRGRP_SYS_ESR       11'h040  // Exception Status Register.

// SPR Group: Tick Timer
`define OR1200_TT_OFS_TTMR  0
`define OR1200_TT_OFS_TTCR  1

// SPR Group: Programmable Interrupt Controller (PIC)
`define OR1200_PIC_OFS_PICMR  0
`define OR1200_PIC_OFS_PICSR  2

// SPR SR Register bits
`define OR1200_SR_SM    0
`define OR1200_SR_TEE   1
`define OR1200_SR_IEE   2  // External Interrupt Exception Enabled
`define OR1200_SR_DCE   3
`define OR1200_SR_ICE   4
`define OR1200_SR_DME   5
`define OR1200_SR_IME   6
`define OR1200_SR_LEE   7
`define OR1200_SR_CE    8
`define OR1200_SR_F     9
`define OR1200_SR_CY   10
`define OR1200_SR_OV   11
`define OR1200_SR_OVE  12
`define OR1200_SR_DSX  13
`define OR1200_SR_EPH  14
`define OR1200_SR_FO   15
`define OR1200_SR_TED  16

// Tick Timer Mode Register (TTMR) bits
`define OR1200_TT_TTMR_TP  27:0  // Timer Period.
`define OR1200_TT_TTMR_IP  28    // Interrupt Pending.
`define OR1200_TT_TTMR_IE  29    // Interrupt Enabled.
`define OR1200_TT_TTMR_M   31:30  // Mode.


`endif  // Include this header file only once.
