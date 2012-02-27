#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"
source "$(dirname $0)/../ShellModules/PrintCommand.sh"


if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

OBJ_DIR="$1"
EXTRA_MAKE_ARGS="$2"
SENTINEL_FILENAME="$3"

pushd "$OBJ_DIR" >/dev/null

# echo "The inherited MAKEFLAGS are: $MAKEFLAGS"

CMD="make -s $EXTRA_MAKE_ARGS"
print_command $CMD
$CMD

echo "Done" >"$SENTINEL_FILENAME"

popd >/dev/null
