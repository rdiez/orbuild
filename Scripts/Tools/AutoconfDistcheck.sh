#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 2 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <obj dir> <sentinel filename>"
fi

OBJ_DIR="$1"
SENTINEL_FILENAME="$2"

pushd "$OBJ_DIR" >/dev/null

make -s --no-builtin-variables  distcheck

echo "Done" >"$SENTINEL_FILENAME"

popd >/dev/null
