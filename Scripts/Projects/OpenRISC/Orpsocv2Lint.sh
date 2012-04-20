#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit

source "$(dirname $0)/../../ShellModules/StandardShellHeader.sh"
source "$(dirname $0)/../../ShellModules/PrintCommand.sh"


create_dir_if_not_exists ()
{
    # $1 = dir name

    if ! test -d "$1"
    then
        echo "Creating directory \"$1\" ..."
        mkdir --parents "$1"
    fi
}


if [ $# -ne 6 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

VERILATOR_BIN_DIR="$1"
ICARUS_VERILOG_BIN_DIR="$2"
ORPSOCV2_CHECKOUT_DIR="$3"
LINT_TEMP_DIR="$4"
LEVEL="$5"
CONFIG="$6"

LINT_WITH_VERILATOR=true

TEMP_SUBDIR="$LINT_TEMP_DIR/$LEVEL-$CONFIG"

# The include path where this script generates the replacement or1200_defines.v file
# must be before the include path where the original or1200_defines.v is.
OR1200_INCLUDE=" -I$TEMP_SUBDIR"

OR1200_INCLUDE+=" -I$ORPSOCV2_CHECKOUT_DIR/sim/vlt"
OR1200_INCLUDE+=" -I$ORPSOCV2_CHECKOUT_DIR/rtl/verilog/include"
OR1200_INCLUDE+=" -I$ORPSOCV2_CHECKOUT_DIR/bench/verilog/include"
OR1200_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/or1200"

ORPSOC_INCLUDE=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/clkgen"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/arbiter"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/uart16550"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/intgen"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/ram_wb"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/dbg_if"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/jtag_tap"


TESTBENCH_INCLUDE=" -I$ORPSOCV2_CHECKOUT_DIR/sim/bin"
TESTBENCH_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/orpsoc_top"
TESTBENCH_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/bench/verilog"


lint_or1200 ()
{
  echo "Linting or1200"
  ALL_INCLUDES="$OR1200_INCLUDE"
  TOP_LEVEL_FILE="$ORPSOCV2_CHECKOUT_DIR/rtl/verilog/or1200/or1200_top.v"
}


lint_orpsoc ()
{
  echo "Linting orpsoc"
  TOP_LEVEL_FILE="$ORPSOCV2_CHECKOUT_DIR/rtl/verilog/orpsoc_top/orpsoc_top.v"
  ALL_INCLUDES="$OR1200_INCLUDE"
  ALL_INCLUDES+="$ORPSOC_INCLUDE"
}


lint_testbench ()
{
  echo "Linting the testbench"

  # The test bench only works with Icarus Verilog.
  LINT_WITH_VERILATOR=false

  TOP_LEVEL_FILE+="$ORPSOCV2_CHECKOUT_DIR/bench/verilog/orpsoc_testbench.v"
  ALL_INCLUDES="$OR1200_INCLUDE"
  ALL_INCLUDES+="$ORPSOC_INCLUDE"
  ALL_INCLUDES+="$TESTBENCH_INCLUDE"
}


case "$LEVEL" in
  or1200)    lint_or1200;;
  orpsoc)    lint_orpsoc;;
  testbench) lint_testbench;;
  *)         abort "Invalid lint level argument '$LEVEL'.";;
esac

create_dir_if_not_exists "$TEMP_SUBDIR"

"$ORBUILD_PROJECT_DIR/GenerateOr1200Config.pl" "$ORPSOCV2_CHECKOUT_DIR/rtl/verilog/include/or1200_defines.v" \
                                               "$TEMP_SUBDIR/or1200_defines.v" \
                                               "$CONFIG"

VERILATOR_LINT_FAILED=0

if $LINT_WITH_VERILATOR; then

  printf "\n------------ Verilator lint begin ------------\n\n"

  CMD="$VERILATOR_BIN_DIR/bin/verilator"
  CMD+=" --lint-only -language 1364-2001 -Wall --error-limit 10000 -Wno-UNUSED -Wno-fatal"
  CMD+=" $ALL_INCLUDES "
  CMD+=" $TOP_LEVEL_FILE "

  print_command $CMD
  printf "\n"

  if ! $CMD; then
    VERILATOR_LINT_FAILED=1
  fi

  printf "\n------------ Verilator lint end ------------\n\n"
else
  printf "\n------------ Linting with Verilator skipped ------------\n\n"
fi


printf "\n------------ Icarus Verilog lint begin ------------\n\n"

CMD="$ICARUS_VERILOG_BIN_DIR/bin/iverilog"
CMD+=" -gno-std-include"
CMD+=" -Wall -Wno-timescale"
CMD+=" -g2001"
CMD+=" -o /dev/null"
CMD+=" $ALL_INCLUDES "
CMD+=" $TOP_LEVEL_FILE "

print_command $CMD
printf "\n"

if ! $CMD; then
  ICARUS_VERILOG_LINT_FAILED=1
else
  ICARUS_VERILOG_LINT_FAILED=0
fi

printf "\n------------ Icarus Verilog lint end ------------\n\n"

AT_LEAST_ONE_FAILED=false

if [ $VERILATOR_LINT_FAILED -ne 0 ]; then
  echo "Error: Verilator lint failed, see above for details."
  AT_LEAST_ONE_FAILED=true
fi

if [ $ICARUS_VERILOG_LINT_FAILED -ne 0 ]; then
  echo "Error: Icarus Verilog lint failed, see above for details."
  AT_LEAST_ONE_FAILED=true
fi

if $AT_LEAST_ONE_FAILED; then
  exit 1
else
  exit 0
fi
