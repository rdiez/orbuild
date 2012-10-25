#!/bin/bash

# Copyright (C) 2011-2012 R. Diez - see the orbuild project for licensing information.

set -o errexit

source "$ORBUILD_SANDBOX/Scripts/ShellModules/StandardShellHeader.sh"

if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

VERILOG_INCLUDE_DIR="$1"
shift
IVERILOG_EXE_DIR="$1"
shift
IVERILOG_EXE_FILENAME="$1"
shift


OR10_BASE_DIR="$ORBUILD_PROJECT_DIR/OR10"
TEST_BENCH_DIR="$OR10_BASE_DIR/TestBench"

pushd "$IVERILOG_EXE_DIR" >/dev/null

PROJECT_FILENAME="project.prj"
TOP_LEVEL_MODULE="test_bench_iverilog_driver"

declare -a INCLUDE_PATHS=(
    --sourcelibdir $TEST_BENCH_DIR

    --sourcelibdir $OR10_BASE_DIR/WishboneSwitch
    --sourcelibdir $OR10_BASE_DIR/Memory

    --include      $OR10_BASE_DIR/CPU
    --sourcelibdir $OR10_BASE_DIR/CPU

    --sourcelibdir $OR10_BASE_DIR/CPU/FakeExternalComponents

    --include      $OR10_BASE_DIR/JTAG
    --sourcelibdir $OR10_BASE_DIR/JTAG

    --include      $OR10_BASE_DIR/Misc
    --sourcelibdir $OR10_BASE_DIR/Misc
  )

{
  echo "verilog work $TEST_BENCH_DIR/$TOP_LEVEL_MODULE.v"

  # The glbl.v module is needed by some precompiled library like xilinxcorelib_ver, see below.
  echo "verilog work $ORBUILD_XILINX_HOME/ISE_DS/ISE/verilog/src/glbl.v"

} >"$PROJECT_FILENAME"


COMPILE_CMD="$ORBUILD_PROJECT_DIR/Tools/RunXilinxTool.sh fuse"
COMPILE_CMD+=" --prj $PROJECT_FILENAME"
COMPILE_CMD+=" ${INCLUDE_PATHS[@]}"
COMPILE_CMD+=" --sourcelibext .v"

COMPILE_CMD+=" -o $IVERILOG_EXE_FILENAME"
COMPILE_CMD+=" --incremental"
#COMPILE_CMD+=" --verbose 2"

# These libraries are required when using multipliers generated with Xilinx' core generator.
COMPILE_CMD+=" -L xilinxcorelib_ver -L unisims_ver -L simprims_ver work.glbl"

# Unfortunately, this seems to have no effect on the error message syntax,
# so we have to resort to a script like transform-fuse-compilation-errors.pl (see below):
#  COMPILE_CMD+=" --intstyle xflow"

COMPILE_CMD+=" work.$TOP_LEVEL_MODULE"

COMPILE_CMD+=" 2>&1 | $ORBUILD_PROJECT_DIR/Tools/TransformXilinxCompilationErrors.pl"

printf "$COMPILE_CMD\n\n"
eval "$COMPILE_CMD"

popd >/dev/null
