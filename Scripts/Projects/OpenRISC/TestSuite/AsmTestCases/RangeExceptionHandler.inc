

        // Range exception.
        .org    0xb00

        // TODO: The stack safety zone is not taken into consideration.

        PUSH r2
        PUSH r3

        // Overwrite the exception-triggering instruction with an l.nop.
        // Note that this could cause cache-coherency issues between the instruction and the data caches.
        // Note also that this does not work properly if the instruction that triggered the exception
        // is in a jump delay slot.
        //
        // As an alternative we could increment the SPR_EPCR_BASE register by 4 before returning from the exception,
        // which would skip the instruction that triggered it.
        
        MOVE_FROM_SPR  r2, SPR_EPCR_BASE  // Address of the instruction that triggered the exception.
        LOAD_IMMEDIATE r3, 0x15000000     // Opcode for l.nop
        l.sw    0(r2), r3

        // When running under the or1ksim simulator, the range exception is triggered on a positive edge
        // (when the overflow flag changes from 0 to 1).
        // However, when running the or1200 Verilog code included with ORPSoC V2 under the Icarus Verilog simulator,
        // the exception is trigged on a level basis. As a result, as soon as l.rfe returns from the exception,
        // the range exception triggers again, causing an infinite loop.
        // Therefore, we need to clear the OVE (overflow exception) flag in the SPR_ESR_BASE register
        // before returning from the exception. We could clear the OV (overflow) flag instead,
        // but the test cases check that flag as part of the expected results.
        // This issue was discussed in the mailing list, see the following thread:
        //  "Different SPR_EPCR_BASE address on range exception with or1ksim and with or1200"
        //  http://lists.openrisc.net/pipermail/openrisc/2012-April/001052.html
        
        MOVE_FROM_SPR r2, SPR_ESR_BASE
        LOAD_IMMEDIATE r3, ~SPR_SR_OVE
        l.and  r2, r2, r3
        MOVE_TO_SPR SPR_ESR_BASE, r2
        
        POP r3
        POP r2

        l.rfe
