#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

SRC_DIR="$1"
AUTOGEN_CMD="$2"
SENTINEL_FILENAME="$3"

if [ -z "$AUTOGEN_CMD" ]; then
  abort "Empty autogen command."
fi

pushd "$SRC_DIR" >/dev/null

printf "$AUTOGEN_CMD\n\n"
eval "$AUTOGEN_CMD"

echo "Done" >"$SENTINEL_FILENAME"

popd >/dev/null
