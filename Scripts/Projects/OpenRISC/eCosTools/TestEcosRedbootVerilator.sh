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

ECOS_REDBOOT_OBJ_DIR="$1"
shift
ECOS_REDBOOT_TEST_OBJ_DIR="$1"
shift

# TODO: adjust for Verilator

create_dir_if_not_exists "$ECOS_REDBOOT_TEST_OBJ_DIR"

pushd "$ECOS_REDBOOT_TEST_OBJ_DIR" >/dev/null

echo
echo "------- Running Redboot on Verilator simulation -------"

SIMULATION_LOG_FILENAME="$ECOS_REDBOOT_TEST_OBJ_DIR/Simulation.log"

or32-elf-sim --nosrv -f "$THIS_SCRIPT_DIR/or1ksim-redboot.cfg"  "$ECOS_REDBOOT_OBJ_DIR/install/bin/redboot.elf" 2>&1 | tee "$SIMULATION_LOG_FILENAME"

popd >/dev/null
