#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 4 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <src dir> <obj dir> <prefix dir> <sentinel filename>"
fi

SRC_DIR="$1"
OBJ_DIR="$2"
PREFIX_DIR="$3"
SENTINEL_FILENAME="$4"

if ! test -d "$OBJ_DIR"; then
  mkdir -p "$OBJ_DIR"
fi

pushd "$OBJ_DIR" >/dev/null

CMD="$SRC_DIR/configure $ORBUILD_AUTOCONF_CONFIGURE_ARGS --prefix=$PREFIX_DIR"

echo "Running command: $CMD"

$CMD

echo "Done" >"$SENTINEL_FILENAME"

popd >/dev/null
