/*
   This TAP submodule handles reads and writes to the DEBUG TAP register
   when the main JTAG TAP has selected the DEBUG instruction in its IR register.

   Note that the DEBUG register, depending on the current command, does not always have
   a fixed length from the JTAG client's point of view, unlike most other JTAG registers.
   Some operations take an indeterminate amount of time, as the TAP has to cross clock
   domains and the CPU may be currently busy. How long the CPU remains busy may depend
   on how long the current CPU Wishbone operation takes, but keep in mind that some
   other DMA device (like the Ethernet controller) can take hold of the Wishbone bus
   for a long time.

   During such operations, shifting bits out of the DEBUG register will deliver 0 while in progress,
   and 1 when complete (followed by other resulting data, see the description for each).
   This means that data from the other JTAG devices on the chain will not
   be shifted through. All other TAPs in the JTAG chain are usually kept in BYPASS mode
   in order to simplify matters and minize the length of the total chain during the wait.

   Note that, in this implementation, the input side of the DEBUG register is not connected
   with the output side. All bits shifted out of the DEBUG register, when not currently performing
   any debug operation, will be zero. This is another reason to keep any other devices
   in the chain in BYPASS mode.

   This TAP submodule starts such lengthy DEBUG operations when reaching the Update-DR state
   (when the DEBUG register is updated), instead of triggering at the usual Capture-DR state.
   Therefore, the JTAG client should make sure that, when the shifting is complete,
   the DEBUG NOP command is left in the DEBUG register, as the client cannot avoid going through
   Update-DR once again after leaving the Shift-DR state. That's pretty easy to achieve,
   as the NOP command has an opcode consisting of just zeroes. The JTAG client only has to
   keep shifting zeroes in while waiting for a lengthy DEBUG command to complete.

   It is possible to interrupt the TAP side of those lengthy operations by leaving the
   Shift-DR state early and going through Update-DR before the operation is complete.
   However, the CPU side may take some time to realise that the client is no longer
   issuing the original operation, so there is a window of opportunity for the CPU
   to write to the wrong register or memory address as a result. Therefore, the JTAG client
   should try to be patient and only abort an operation as a last resort.


   Author(s):
       R. Diez (in 2012)
       Nathan Yawn (nathan.yawn@opencores.org)

   NOTE: R. Diez has rewritten this module substantially and since then
         it has only been tested against the OR10 OpenRISC implementation.

   Copyright (C) 2008 - 2012 Authors

   This source file may be used and distributed without
   restriction provided that this copyright statement is not
   removed from the file and that any derivative work contains
   the original copyright notice and the associated disclaimer.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3
   as published by the Free Software Foundation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License version 3 for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

`include "or10_defines.v"
`include "simulator_features.v"

module tap_or10
  #( parameter ENABLE_TRACE = 0,
     parameter SPR_NUMBER_WIDTH = 16  // You shouldn't need to change this, as it must match the CPU interface.
   )
   (
    input                            jtag_tck_i,
    input                            jtag_tdi_i,
    output reg                       jtag_tdo_o,

    input                            is_tap_state_test_logic_reset_i,
    input                            is_tap_state_shift_dr_i,
    input                            is_tap_state_update_dr_i,
    // input                         is_tap_state_capture_dr_i,  // Not needed by this submodule.

    input                            is_tap_current_instruction_debug_i,

    output reg [SPR_NUMBER_WIDTH-1:0]    cpu_spr_number_o,
    input  [`OR10_OPERAND_WIDTH-1:0]     cpu_data_i,
    output reg [`OR10_OPERAND_WIDTH-1:0] cpu_data_o,
    output reg                           cpu_stb_o,
    output reg                           cpu_we_o,
    input                                cpu_ack_i,
    input                                cpu_err_i,
    input                                cpu_is_stalled_i
   );

   localparam TRACE_PREFIX = "JTAG TAP OR10 debug submodule: ";

   // Clock domain crossing synchroniser for the Debug Interface.

   wire synchronised_cpu_is_stalled_i;
   wire synchronised_cpu_ack_i;

   clock_domain_crossing_synchroniser clock_domain_crossing_synchroniser_cpu_is_stalled_i( jtag_tck_i, cpu_is_stalled_i, synchronised_cpu_is_stalled_i );
   clock_domain_crossing_synchroniser clock_domain_crossing_synchroniser_cpu_ack_i       ( jtag_tck_i, cpu_ack_i       , synchronised_cpu_ack_i        );


   localparam CPU_STATE_WIDTH = 3;

   localparam CPU_STATE_IDLE                 = 0;
   localparam CPU_STATE_WAITING_FOR_CPU_IDLE = 1;
   localparam CPU_STATE_DATA_WRITTEN         = 2;
   localparam CPU_STATE_STB_WRITTEN          = 3;
   localparam CPU_STATE_WAITING_FOR_ACK      = 4;

   reg [CPU_STATE_WIDTH-1:0] current_cpu_state;


   localparam DEBUG_CMD_LEN = 3;  // Note that we could optimise one bit away.

   localparam DEBUG_CMD_NOP            = 3'd0;  // Must be all zeros in order to optimise the JTAG speed: when waiting for a lengthy
                                                // debug operation to complete, the JTAG client will shift zeros in, and when the
                                                // 'finished' indication is shifted out and arrives at the client, the resulting
                                                // command will be NOP, so there's no need to shift a NOP in afterwards.

   localparam DEBUG_CMD_IS_CPU_STALLED = 3'd1;  // Queries whether the CPU is stalled, the result is immediately available and consists of
                                                // a single bit ('0' for not stalled, '1' for stalled). This operation does not influence
                                                // the CPU in any way.

   localparam DEBUG_CMD_WRITE_CPU_SPR  = 3'd2;  // Followed by 16 bits with the CPU SPR number and with 32 bits of data. The result is
                                                // a sequence of zero bits while in progress, the first '1' bit indicates that
                                                // the operation finished. The next bit is an error indication ('1' if error). In case of success,
                                                // the next 32 bits contain the SPR value read back from the CPU, which is useful when reading
                                                // from RAM in a single operation (write memory address, read memory data back).

   localparam DEBUG_CMD_READ_CPU_SPR   = 3'd3;  // Followed by 16-bits with the CPU SPR number. The result is the same as for DEBUG_CMD_WRITE_CPU_SPR.


   localparam OPERATION_COMPLETE_FLAG    = 1'b1;
   localparam OPERATION_IN_PROGRESS_FLAG = 1'b0;

   localparam OPERATION_SUCCEEDED_FLAG   = 1'b0;
   localparam OPERATION_FAILED_FLAG      = 1'b1;

   localparam DOES_NOT_MATTER_BIT        = 1'b0;  // A value of x would probably allow for better optimisation,
                                                  // but I am not sure yet whether that would be OK. Filling with zeros help debugging.


   // The longest command has the structure: <command opcode (3 bits)> + <SPR number (16 bits)> + <new SPR value (32 bits)>
   localparam SHIFT_REG_LEN = DEBUG_CMD_LEN + SPR_NUMBER_WIDTH + `OR10_OPERAND_WIDTH;
   `define TAP_OR10_CMD_OPCODE  50:48
   `define TAP_OR10_CMD_SPR_NUM 47:32
   `define TAP_OR10_CMD_SPR_VAL 31:0

   reg [SHIFT_REG_LEN-1:0] input_shift_reg;
   reg [SHIFT_REG_LEN-1:0] current_cmd;  // Latched input_shift_reg.

   // The longest command reply has the structure: <data (32 bits)> + <error bit> + <finished bit (always 1)>
   localparam OUTPUT_REG_LEN = `OR10_OPERAND_WIDTH + 1 + 1;
   reg [OUTPUT_REG_LEN-1:0] output_shift_reg;


   function [14*8-1:0] get_cmd_name;
      input [DEBUG_CMD_LEN-1:0] cmd_code;
      begin
         case ( cmd_code )
           DEBUG_CMD_NOP:            get_cmd_name = "NOP";
           DEBUG_CMD_READ_CPU_SPR:   get_cmd_name = "READ_CPU_SPR";
           DEBUG_CMD_WRITE_CPU_SPR:  get_cmd_name = "WRITE_CPU_SPR";
           DEBUG_CMD_IS_CPU_STALLED: get_cmd_name = "IS_CPU_STALLED";
           default:                  get_cmd_name = "<unknown>";
         endcase
      end
   endfunction


   task automatic stop_cpu_transaction;
      begin
         cpu_stb_o         <= 0;
         cpu_spr_number_o  <= {SPR_NUMBER_WIDTH{1'bx}};
         cpu_data_o        <= {`OR10_OPERAND_WIDTH{1'bx}};
         cpu_we_o          <= 1'bx;
      end
   endtask


   task automatic step_state_machine_update;

      output [SHIFT_REG_LEN-1:0]   next_cmd;
      inout  [CPU_STATE_WIDTH-1:0] next_cpu_state;

      reg [14*8-1:0] next_cmd_name;

      begin
         // In case there was some other operation going on, stop it now.
         // If the JTAG client is patient enough, we should never need to stop anything.
         if ( next_cpu_state != CPU_STATE_IDLE )
           begin
              `ASSERT_FALSE;
           end
         stop_cpu_transaction;

         if ( ENABLE_TRACE )
           begin
              next_cmd_name = get_cmd_name( input_shift_reg[`TAP_OR10_CMD_OPCODE] );
              $display( "%sCommand set to \"%0s\".", TRACE_PREFIX, next_cmd_name );
           end

         next_cmd = input_shift_reg;

         case ( input_shift_reg[`TAP_OR10_CMD_OPCODE] )
           DEBUG_CMD_NOP:
             begin
                output_shift_reg <= {OUTPUT_REG_LEN{DOES_NOT_MATTER_BIT}};
                next_cpu_state = CPU_STATE_IDLE;
             end

           DEBUG_CMD_IS_CPU_STALLED:
             begin
                // The result is available immediately and consists of just 1 bit of data.
                output_shift_reg <= { {OUTPUT_REG_LEN-1{DOES_NOT_MATTER_BIT}}, synchronised_cpu_is_stalled_i };
                next_cpu_state = CPU_STATE_IDLE;
             end

           DEBUG_CMD_READ_CPU_SPR, DEBUG_CMD_WRITE_CPU_SPR:
             begin
                output_shift_reg <= { {OUTPUT_REG_LEN-1{DOES_NOT_MATTER_BIT}}, OPERATION_IN_PROGRESS_FLAG };
                next_cpu_state = CPU_STATE_WAITING_FOR_CPU_IDLE;
             end

           default:
             begin
                `ASSERT_FALSE;
                output_shift_reg <= {OUTPUT_REG_LEN{DOES_NOT_MATTER_BIT}};
                // If the JTAG user writes an invalid command, just ignore it and go to
                // the idle state, so that writing further commands will work later on.
                next_cpu_state = CPU_STATE_IDLE;
             end
         endcase
      end
   endtask


   task automatic step_state_machine_shift;

      reg [SHIFT_REG_LEN-1:0] new_shift_reg_val;

      begin
         // ------ Shift one bit in ------

         // The input side of the Debug Register is not connected to the output,
         // so shifting data in is totally independent from shifting data out.
         new_shift_reg_val = { jtag_tdi_i, input_shift_reg[SHIFT_REG_LEN-1:1] };

         if ( ENABLE_TRACE )
           begin
              // For 51 bits we need 13 hex digits.
              // $display( "%sShifting bit %1d in, bit %1d out, resulting register value: 0x%13h, value in tdo_cpu0: %1d.",
              //           TRACE_PREFIX, jtag_tdi_i, jtag_tdo_o, new_shift_reg_val, tdo_cpu0 );
           end

         input_shift_reg <= new_shift_reg_val;


         // ------ Shift one bit out ------
         // Always shift, although for most commandos there is no need to shift anything.
         output_shift_reg <= { DOES_NOT_MATTER_BIT, output_shift_reg[OUTPUT_REG_LEN-1:1] };
      end
   endtask


   task automatic step_state_machine_tick;

      input [SHIFT_REG_LEN-1:0]   next_cmd;
      inout [CPU_STATE_WIDTH-1:0] next_cpu_state;

      reg [SPR_NUMBER_WIDTH-1:0]  combined_spr_number;

      begin

         case ( next_cpu_state )
           CPU_STATE_IDLE:
             begin
                // Nothing to do here.
             end

           CPU_STATE_WAITING_FOR_CPU_IDLE:
             begin
                output_shift_reg <= { {OUTPUT_REG_LEN-1{DOES_NOT_MATTER_BIT}}, OPERATION_IN_PROGRESS_FLAG };

                // Do not start the next operation until the CPU has gone back to the idle state.
                // Otherwise, we may issue the next debug interface transaction
                // and still be reading the answer from the previous one.
                if ( synchronised_cpu_ack_i == 0 )
                  begin
                     combined_spr_number = next_cmd[`TAP_OR10_CMD_SPR_NUM];

                     if ( next_cmd[`TAP_OR10_CMD_OPCODE] == DEBUG_CMD_READ_CPU_SPR )
                       begin
                          if ( ENABLE_TRACE )
                            $display( "%sReading from SPR group %0d, register %0d...",
                                      TRACE_PREFIX,
                                      combined_spr_number[`OR10_SPR_GRP_NUMBER],
                                      combined_spr_number[`OR10_SPR_REG_NUMBER] );

                          cpu_spr_number_o  <= next_cmd[`TAP_OR10_CMD_SPR_NUM];
                          cpu_data_o        <= {`OR10_OPERAND_WIDTH{1'bx}};
                          cpu_we_o          <= 0;
                       end
                     else
                       begin
                          if ( next_cmd[`TAP_OR10_CMD_OPCODE] != DEBUG_CMD_WRITE_CPU_SPR )
                            begin
                               `ASSERT_FALSE;
                            end

                          if ( ENABLE_TRACE )
                            $display( "%sWriting to SPR group %0d, register %0d, data 0x%08h.",
                                      TRACE_PREFIX,
                                      combined_spr_number[`OR10_SPR_GRP_NUMBER],
                                      combined_spr_number[`OR10_SPR_REG_NUMBER],
                                      next_cmd[`TAP_OR10_CMD_SPR_VAL] );

                          cpu_spr_number_o  <= next_cmd[`TAP_OR10_CMD_SPR_NUM];
                          cpu_data_o        <= next_cmd[`TAP_OR10_CMD_SPR_VAL];
                          cpu_we_o          <= 1;
                       end

                     next_cpu_state = CPU_STATE_DATA_WRITTEN;
                  end
             end

           CPU_STATE_DATA_WRITTEN:
             begin
                output_shift_reg <= { {OUTPUT_REG_LEN-1{DOES_NOT_MATTER_BIT}}, OPERATION_IN_PROGRESS_FLAG };
                cpu_stb_o <= 1;
                next_cpu_state = CPU_STATE_WAITING_FOR_ACK;
             end

           CPU_STATE_WAITING_FOR_ACK:
             begin
                output_shift_reg <= { {OUTPUT_REG_LEN-1{DOES_NOT_MATTER_BIT}}, OPERATION_IN_PROGRESS_FLAG };

                if ( synchronised_cpu_ack_i )
                  begin
                     if ( cpu_err_i )
                       begin
                          if ( ENABLE_TRACE )
                            $display( "%sThe CPU dbg interface answered with error.", TRACE_PREFIX );

                          output_shift_reg <= { {`OR10_OPERAND_WIDTH{DOES_NOT_MATTER_BIT}}, OPERATION_FAILED_FLAG, OPERATION_COMPLETE_FLAG };
                       end
                     else
                       begin
                          if ( next_cmd[`TAP_OR10_CMD_OPCODE] == DEBUG_CMD_READ_CPU_SPR )
                            begin
                               if ( ENABLE_TRACE )
                                 begin
                                    $display( "%sSPR register value read: 0x%08h.",
                                              TRACE_PREFIX,
                                              cpu_data_i );
                                 end

                               output_shift_reg <= { cpu_data_i, OPERATION_SUCCEEDED_FLAG, OPERATION_COMPLETE_FLAG };
                            end
                          else if ( next_cmd[`TAP_OR10_CMD_OPCODE] == DEBUG_CMD_WRITE_CPU_SPR )
                            begin
                               if ( ENABLE_TRACE )
                                 begin
                                    // $display( "%sThe CPU dbg interface answered OK to the write operation.", TRACE_PREFIX );
                                 end

                               // When writing to an SPR, the value read back in cpu_data_i does not matter and can be random garbage.
                               // However, when reading from a memory address, we write the address and read the data back
                               // in the same operation. Therefore, we must read and shift out here the data in cpu_data_i.
                               output_shift_reg <= { cpu_data_i, OPERATION_SUCCEEDED_FLAG, OPERATION_COMPLETE_FLAG };
                            end
                          else
                            begin
                               // $display( "Unexpected command code of 0x%1h", next_cmd[`TAP_OR10_CMD_OPCODE] );
                               `ASSERT_FALSE;
                               output_shift_reg <= {OUTPUT_REG_LEN{DOES_NOT_MATTER_BIT}};
                            end
                       end

                     next_cpu_state = CPU_STATE_IDLE;
                     stop_cpu_transaction;
                  end
             end
           default:
             begin
                `ASSERT_FALSE;
             end
         endcase
      end
   endtask


   // The top-level TAP needs the value of jtag_tdo_o at the next negedge of jtag_tck_i,
   // and not as usual at the next posedge, therefore we cannot use operator "<="
   // (non-blocking) to set it, we must use an 'assign' (blocking) operator.
   always @(*)
     begin
        jtag_tdo_o = output_shift_reg[0];
     end


   task automatic check_at_most_one_is_tap_state_xxx;
      integer at_most_one_counter;
      begin
        // When simulating, check that at most one of the is_tap_state_xxx signals is active.
        at_most_one_counter = 0;

        if ( is_tap_state_test_logic_reset_i )  at_most_one_counter = at_most_one_counter + 1;
        if ( is_tap_state_shift_dr_i )          at_most_one_counter = at_most_one_counter + 1;
        if ( is_tap_state_update_dr_i )         at_most_one_counter = at_most_one_counter + 1;
        // if ( is_tap_state_capture_dr_i )     at_most_one_counter = at_most_one_counter + 1;

        if ( at_most_one_counter > 1 )
          begin
             `ASSERT_FALSE;
          end
      end
   endtask


   task automatic step_state_machine;

      reg [SHIFT_REG_LEN-1:0]   next_cmd;
      reg [CPU_STATE_WIDTH-1:0] next_cpu_state;

      begin
         next_cmd       = current_cmd;
         next_cpu_state = current_cpu_state;

         // This can start and complete a short debug operation, or start a lengthy one.
         if ( is_tap_state_update_dr_i )
           step_state_machine_update( next_cmd, next_cpu_state );

         if ( is_tap_state_shift_dr_i )
           step_state_machine_shift;

         // When a lengthy debug operation finishes, this will write to the output register the results.
         step_state_machine_tick( next_cmd, next_cpu_state );

         current_cmd       <= next_cmd;
         current_cpu_state <= next_cpu_state;
      end
   endtask


   initial
     begin
        current_cpu_state  = CPU_STATE_IDLE;
        input_shift_reg    = {SHIFT_REG_LEN{1'bx}};
        current_cmd        = {SHIFT_REG_LEN{1'bx}};

        // The following code corresponds to stop_cpu_transaction:
        cpu_stb_o         = 0;
        cpu_spr_number_o  = {SPR_NUMBER_WIDTH{1'bx}};
        cpu_data_o        = {`OR10_OPERAND_WIDTH{1'bx}};
        cpu_we_o          = 1'bx;
     end

   always @( posedge jtag_tck_i )
     begin
        // $display( "%s< JTAG clock tick begin >", TRACE_PREFIX );

        check_at_most_one_is_tap_state_xxx;

        if ( is_tap_state_test_logic_reset_i || !is_tap_current_instruction_debug_i )
          begin
             // If you modify this code, please update the 'initial' section too.
             current_cpu_state <= CPU_STATE_IDLE;
             input_shift_reg   <= {SHIFT_REG_LEN{1'bx}};
             current_cmd       <= {SHIFT_REG_LEN{1'bx}};

             stop_cpu_transaction;
          end
        else
          step_state_machine;

        // $display( "%s< JTAG clock tick end >", TRACE_PREFIX );
     end

endmodule
