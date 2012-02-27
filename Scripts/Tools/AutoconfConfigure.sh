#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 5 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

SRC_DIR="$1"
OBJ_DIR="$2"
PREFIX_DIR="$3"
EXTRA_CONFIG_FLAGS="$4"
SENTINEL_FILENAME="$5"

if ! test -d "$OBJ_DIR"; then
  mkdir -p "$OBJ_DIR"
fi

pushd "$OBJ_DIR" >/dev/null

CMD="$SRC_DIR/configure  --prefix=$PREFIX_DIR  $EXTRA_CONFIG_FLAGS"

$CMD

echo "Done" >"$SENTINEL_FILENAME"

popd >/dev/null
