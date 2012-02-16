#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"
source "$(dirname $0)/../ShellModules/PrintCommand.sh"


if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <src dir> <autogen cmd> <sentinel filename>"
fi

SRC_DIR="$1"
AUTOGEN_CMD="$2"
SENTINEL_FILENAME="$3"

if [ -z "$AUTOGEN_CMD" ]; then
  abort "Empty autogen command."
fi

pushd "$SRC_DIR" >/dev/null

print_command $AUTOGEN_CMD
$AUTOGEN_CMD

echo "Done" >"$SENTINEL_FILENAME"

popd >/dev/null
