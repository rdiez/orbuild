#!/bin/bash

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

set -o errexit
SANDBOX_DIR="$(readlink -f "$(dirname "$0")/../../../..")"

source "$SANDBOX_DIR/Scripts/ShellModules/StandardShellHeader.sh"

if [ $# -ne 1 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

FILENAME="$1"
shift

{
  echo "\`define RTL_SIM"
  echo "\`define SIMULATOR_ICARUS"
  echo "\`define TEST_NAME_STRING \"TestSuiteSimulation\""
} >"$FILENAME"
