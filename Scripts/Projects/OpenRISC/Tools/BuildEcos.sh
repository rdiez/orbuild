#!/bin/bash

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

set -o errexit
SANDBOX_DIR="$(readlink -f "$(dirname "$0")/../../../..")"

source "$SANDBOX_DIR/Scripts/ShellModules/StandardShellHeader.sh"
source "$SANDBOX_DIR/Scripts/ShellModules/FileUtils.sh"

if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

ECOS_CHECKOUT_DIR="$1"
shift
ECOS_CONFIG_TOOL_BIN_DIR="$1"
shift
ECOS_OBJ_DIR="$1"
shift

create_dir_if_not_exists "$ECOS_OBJ_DIR"

pushd "$ECOS_OBJ_DIR" >/dev/null

export ECOS_REPOSITORY="$ECOS_CHECKOUT_DIR/packages"

CFG_TOOL="$ECOS_CONFIG_TOOL_BIN_DIR/bin/ecosconfig"

echo
echo "------- Creating the eCos configuration -------"
CMD="\"$CFG_TOOL\" --enable-debug new orpsoc"
echo "$CMD"
eval "$CMD"

echo
echo "------- Checking the eCos configuration -------"
CMD="\"$CFG_TOOL\" check"
echo $CMD
eval "$CMD"

echo
echo "------- Creating the eCos build tree -------"
CMD="\"$CFG_TOOL\" tree"
echo $CMD
eval "$CMD"


if [ $ORBUILD_STOP_ON_FIRST_ERROR -eq 0 ]; then
  K_FLAG=-k
else
  K_FLAG=
fi

echo
echo "------- Building eCos -------"
CMD="make $K_FLAG --no-builtin-variables"
echo $CMD
eval "$CMD"

echo
echo "------- Building the eCos tests -------"
CMD="make $K_FLAG --no-builtin-variables tests"
echo $CMD
eval "$CMD"

popd >/dev/null
