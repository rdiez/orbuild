#!/bin/bash

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

set -o errexit

THIS_SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
SANDBOX_DIR="$(readlink -f "$THIS_SCRIPT_DIR/../../../..")"

source "$SANDBOX_DIR/Scripts/ShellModules/StandardShellHeader.sh"
source "$SANDBOX_DIR/Scripts/ShellModules/FileUtils.sh"

if [ $# -ne 2 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

ECOS_OBJ_DIR="$1"
shift
ECOS_TEST_OBJ_DIR="$1"
shift

create_dir_if_not_exists "$ECOS_TEST_OBJ_DIR"

pushd "$ECOS_TEST_OBJ_DIR" >/dev/null

echo
echo "------- Building the simple test executable -------"

ECOS_INSTALL_DIR="$ECOS_OBJ_DIR/install"

or32-elf-g++ \
  -g \
  -O0 \
  -Wall \
  -fno-rtti \
  -fno-exceptions \
  -nostdlib \
  -I$ECOS_INSTALL_DIR/include \
  -I$SANDBOX_DIR/Scripts/Projects/OpenRISC/TestSuite/LibcBare \
  -L$ECOS_INSTALL_DIR/lib \
  -T$ECOS_INSTALL_DIR/lib/target.ld \
  "$THIS_SCRIPT_DIR/EcosSimpleTest.cpp" \
  -o "EcosSimpleTest.elf"

echo
echo "------- Running the simple test simulation -------"

SIMULATION_LOG_FILENAME="$ECOS_TEST_OBJ_DIR/Simulation.log"

or32-elf-sim --nosrv -f "$THIS_SCRIPT_DIR/or1ksim-with-jump-delay-slot.cfg"  "EcosSimpleTest.elf" 2>&1 | tee "$SIMULATION_LOG_FILENAME"

echo "------- Analysing the simulation log file -------"

"$THIS_SCRIPT_DIR/AnalyseLog.pl" "$SIMULATION_LOG_FILENAME" "$THIS_SCRIPT_DIR/EcosSimpleTest.TestResults"

popd >/dev/null
