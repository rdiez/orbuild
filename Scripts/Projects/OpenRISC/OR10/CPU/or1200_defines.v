
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
`define OR1200_SPRGRP_SYS_GPR_BASE  11'd1024 // First GPR.

// SPR Group: Tick Timer
`define OR1200_TT_OFS_TTMR  0
`define OR1200_TT_OFS_TTCR  1

// SPR Group: Debug Unit (DU)

`define OR1200_DU_DVR0		11'd0
`define OR1200_DU_DVR1		11'd1
`define OR1200_DU_DVR2		11'd2
`define OR1200_DU_DVR3		11'd3
`define OR1200_DU_DVR4		11'd4
`define OR1200_DU_DVR5		11'd5
`define OR1200_DU_DVR6		11'd6
`define OR1200_DU_DVR7		11'd7

`define OR1200_DU_DMR1		11'd16
`define OR1200_DU_DSR       11'd20  // Debug Stop Register.
`define OR1200_DU_DRR       11'd21  // Debug Reason Register.
// These registers are new for the OR10 CPU, they are not part of the original OpenRISC specification.
`define OR1200_DU_EDIS      11'd200  // External Debug Interface Stall, makes the CPU stop at the next instruction.
`define OR1200_DU_READ_MEM_ADDR  11'd201  // Memory address for Debug Interface memory read access. Writing to this SPR
                                          // gives back the memory address contents. Note that this is a combined write/read operation
                                          // on the Debug Interface.
`define OR1200_DU_WRITE_MEM_ADDR 11'd202  // Memory address for Debug Interface memory write access.
`define OR1200_DU_WRITE_MEM_DATA 11'd203  // Memory data for Debug Interface memory write access. Writing to the SPR
                                          // triggers the actual memory write.

// SPR Group: Programmable Interrupt Controller (PIC)
`define OR1200_PIC_OFS_PICMR  0
`define OR1200_PIC_OFS_PICSR  2

// SPR SR's Register bits
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

// Tick Timer's Mode Register (TTMR) bits
`define OR1200_TT_TTMR_TP  27:0  // Timer Period.
`define OR1200_TT_TTMR_IP  28    // Interrupt Pending.
`define OR1200_TT_TTMR_IE  29    // Interrupt Enabled.
`define OR1200_TT_TTMR_M   31:30  // Mode.

// Debug Unit's Debug Stop Register (DSR) bits
`define OR1200_DU_DSR_WIDTH 14
`define OR1200_DU_DSR_RSTE  0
`define OR1200_DU_DSR_BUSEE 1
`define OR1200_DU_DSR_DPFE  2
`define OR1200_DU_DSR_IPFE  3
`define OR1200_DU_DSR_TTE   4
`define OR1200_DU_DSR_AE    5
`define OR1200_DU_DSR_IIE   6
`define OR1200_DU_DSR_IE    7
`define OR1200_DU_DSR_DME   8
`define OR1200_DU_DSR_IME   9
`define OR1200_DU_DSR_RE    10
`define OR1200_DU_DSR_SCE   11
`define OR1200_DU_DSR_FPE   12
`define OR1200_DU_DSR_TE    13

// Debug Unit's Debug Reason Register (DRR) bits
`define OR1200_DU_DRR_RSTE	0
`define OR1200_DU_DRR_BUSEE	1
`define OR1200_DU_DRR_DPFE	2
`define OR1200_DU_DRR_IPFE	3
`define OR1200_DU_DRR_TTE	4
`define OR1200_DU_DRR_AE	5
`define OR1200_DU_DRR_IIE	6
`define OR1200_DU_DRR_IE	7
`define OR1200_DU_DRR_DME	8
`define OR1200_DU_DRR_IME	9
`define OR1200_DU_DRR_RE	10
`define OR1200_DU_DRR_SCE	11
`define OR1200_DU_DRR_FPE	12
`define OR1200_DU_DRR_TE	13

// Debug Unit's Debug Mode Register 1 (DMR1) bits
`define OR1200_DU_DMR1_CW0	1:0
`define OR1200_DU_DMR1_CW1	3:2
`define OR1200_DU_DMR1_CW2	5:4
`define OR1200_DU_DMR1_CW3	7:6
`define OR1200_DU_DMR1_CW4	9:8
`define OR1200_DU_DMR1_CW5	11:10
`define OR1200_DU_DMR1_CW6	13:12
`define OR1200_DU_DMR1_CW7	15:14
`define OR1200_DU_DMR1_CW8	17:16
`define OR1200_DU_DMR1_CW9	19:18
`define OR1200_DU_DMR1_CW10	21:20
`define OR1200_DU_DMR1_ST	22
`define OR1200_DU_DMR1_BT	23
`define OR1200_DU_DMR1_DXFW	24
`define OR1200_DU_DMR1_ETE	25


`endif  // Include this header file only once.
