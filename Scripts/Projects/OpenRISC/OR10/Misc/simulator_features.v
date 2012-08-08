/*
   Copyright (C) 2012, R. Diez

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

// Include this header file only once.
`ifndef simulator_features_included
`define simulator_features_included


// Define UNIQUE, IS_SIMULATION, etc. depending on the platform.

`ifdef MY_XILINX_XST  // I could not find a predefined macro for XST, so I had to add one to the ISE project configuration.

  `define UNIQUE
  `define IS_SIMULATION 0
  `define FINISH_WITH_ERROR_EXIT_CODE
  `define ASSERT_FALSE

`elsif __ICARUS__

  // Icarus Verilog does not support the 'unique case' clause, as of July 2012.
  // I tried with -g2005 and -gsystem-verilog, -g2009 did not work at all.
  `define UNIQUE

   // Icarus Verilog does not support the 'final' clause, as of July 2012.
   // I tried with -g2005 and -gsystem-verilog, -g2009 did not work at all.
   //   `define SUPPORTS_FINAL defined

  `define IS_SIMULATION 1

  `define FINISH_WITH_ERROR_EXIT_CODE $finish_and_return(1)

  // Icarus Verilog does not seem to support `__FILE__ and `__LINE__ yet.
  `define ASSERT_FALSE $display( "ERROR: Assertion failed." ); `FINISH_WITH_ERROR_EXIT_CODE

`elsif XILINX_ISIM

  `define UNIQUE
  `define IS_SIMULATION 1

  // Note that Xilinx ISim does not support $finish_and_return, so there is no special exit code on error.
  `define FINISH_WITH_ERROR_EXIT_CODE $finish

  `define ASSERT_FALSE $display( "ERROR: Assertion failed at %0s:%0d.", `__FILE__, `__LINE__ ); `FINISH_WITH_ERROR_EXIT_CODE

`elsif VERILATOR

  `define IS_SIMULATION 1
  `define UNIQUE unique
  `define SUPPORTS_FINAL defined

  // Note that Verilator does not support $finish_and_return, so there is no special exit code on error.
  `define FINISH_WITH_ERROR_EXIT_CODE $finish

  `define ASSERT_FALSE $display( "ERROR: Assertion failed at %0s:%0d.", `__FILE__, `__LINE__ ); `FINISH_WITH_ERROR_EXIT_CODE

`else
  `error "Unknown platform."
`endif

`endif  // Include this header file only once.
