#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../../ShellModules/StandardShellHeader.sh"
source "$(dirname $0)/../../ShellModules/PrintCommand.sh"


if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

VERILATOR_BIN_DIR="$1"
ICARUS_VERILOG_BIN_DIR="$2"
ORPSOCV2_CHECKOUT_DIR="$3"

printf "\n------------ Verilator lint begin ------------\n\n"

CMD="$VERILATOR_BIN_DIR/bin/verilator"
CMD+=" --lint-only -language 1364-2001 -Wall --error-limit 10000 -Wno-UNUSED -Wno-fatal"
CMD+=" -I$ORPSOCV2_CHECKOUT_DIR/sim/vlt"
CMD+=" -I$ORPSOCV2_CHECKOUT_DIR/rtl/verilog/include"
CMD+=" -I$ORPSOCV2_CHECKOUT_DIR/bench/verilog/include"
CMD+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/or1200"
CMD+=" $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/or1200/or1200_top.v"

print_command $CMD
printf "\n"
$CMD

printf "\n------------ Verilator lint end ------------\n\n"

printf "\n------------ Icarus Verilog lint begin ------------\n\n"

CMD="$ICARUS_VERILOG_BIN_DIR/bin/iverilog"
CMD+=" -gno-std-include"
CMD+=" -Wall -Wno-timescale"
CMD+=" -g2001"
CMD+=" -o /dev/null"
CMD+=" -I$ORPSOCV2_CHECKOUT_DIR/sim/vlt"
CMD+=" -I$ORPSOCV2_CHECKOUT_DIR/rtl/verilog/include"
CMD+=" -I$ORPSOCV2_CHECKOUT_DIR/bench/verilog/include"
CMD+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/or1200"
CMD+=" $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/or1200/or1200_top.v"

print_command $CMD
printf "\n"
$CMD

printf "\n------------ Icarus Verilog lint end ------------\n\n"
