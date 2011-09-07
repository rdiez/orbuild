#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <obj dir> <extra make args> <sentinel filename>"
fi

OBJ_DIR="$1"
EXTRA_MAKE_ARGS="$2"
SENTINEL_FILENAME="$3"

pushd "$OBJ_DIR" >/dev/null

make -s $EXTRA_MAKE_ARGS

echo "Done" >"$SENTINEL_FILENAME"

popd >/dev/null
