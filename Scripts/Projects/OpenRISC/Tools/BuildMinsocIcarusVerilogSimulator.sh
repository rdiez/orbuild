#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit

source "$(dirname $0)/../../../ShellModules/StandardShellHeader.sh"
source "$(dirname $0)/../../../ShellModules/PrintCommand.sh"
source "$(dirname $0)/../../../ShellModules/FileUtils.sh"

if [ $# -ne 4 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

MINSOC_CHECKOUT_DIR="$1"
shift
VERILOG_INCLUDE_DIR="$1"
shift
IVERILOG_EXE_DIR="$1"
shift
IVERILOG_EXE_FILENAME="$1"
shift

TEST_BENCH_DIR="$MINSOC_CHECKOUT_DIR/bench/verilog"

pushd "$IVERILOG_EXE_DIR" >/dev/null

# The test framework may generate files like test-defines.v and or1200_defines.v,
# and the generated files should have precedence over any other files with the same name,
# therefore this include path must come first.
OR1200_INCLUDE=" -I $VERILOG_INCLUDE_DIR"

OR1200_INCLUDE+=" -I $MINSOC_CHECKOUT_DIR/backend/std"  # For minsoc_defines.v and so on.
OR1200_INCLUDE+=" -y $MINSOC_CHECKOUT_DIR/bench/verilog"  # For minsoc_memory_model.v and so on.

OR1200_INCLUDE+=" -I $MINSOC_CHECKOUT_DIR/rtl/verilog"  # For the test bench's version of timescale.v
OR1200_INCLUDE+=" -y $MINSOC_CHECKOUT_DIR/rtl/verilog"  # For the minsoc_top module and so on.


OR1200_INCLUDE+=" -y $MINSOC_CHECKOUT_DIR/rtl/verilog/or1200/rtl/verilog" # For the OR1200 core.

OR1200_INCLUDE+=" -I $MINSOC_CHECKOUT_DIR/rtl/verilog/adv_debug_sys/Hardware/adv_dbg_if/rtl/verilog"
OR1200_INCLUDE+=" -y $MINSOC_CHECKOUT_DIR/rtl/verilog/adv_debug_sys/Hardware/adv_dbg_if/rtl/verilog"

OR1200_INCLUDE+=" -I $MINSOC_CHECKOUT_DIR/rtl/verilog/adv_debug_sys/Hardware/jtag/tap/rtl/verilog"
OR1200_INCLUDE+=" -y $MINSOC_CHECKOUT_DIR/rtl/verilog/adv_debug_sys/Hardware/jtag/tap/rtl/verilog"

OR1200_INCLUDE+=" -y $MINSOC_CHECKOUT_DIR/rtl/verilog/adv_debug_sys/Software/adv_jtag_bridge/sim_rtl"

OR1200_INCLUDE+=" -I $MINSOC_CHECKOUT_DIR/rtl/verilog/uart16550/rtl/verilog"
OR1200_INCLUDE+=" -y $MINSOC_CHECKOUT_DIR/rtl/verilog/uart16550/rtl/verilog"

OR1200_INCLUDE+=" -I $MINSOC_CHECKOUT_DIR/rtl/verilog/ethmac/rtl/verilog"
OR1200_INCLUDE+=" -y $MINSOC_CHECKOUT_DIR/rtl/verilog/ethmac/rtl/verilog"

ALL_INCLUDES="$OR1200_INCLUDE"

COMPILE_CMD="iverilog"
COMPILE_CMD+=" -gno-std-include"
COMPILE_CMD+=" -Wall -Wno-timescale"
COMPILE_CMD+=" -g2001"
COMPILE_CMD+=" -o $IVERILOG_EXE_FILENAME"
COMPILE_CMD+=" $ALL_INCLUDES "
COMPILE_CMD+=" $TEST_BENCH_DIR/minsoc_bench.v"

print_command $COMPILE_CMD
printf "\n"

$COMPILE_CMD

popd >/dev/null
