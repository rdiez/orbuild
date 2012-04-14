#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../../ShellModules/StandardShellHeader.sh"


if [ $# -ne 2 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

MINSOC_CHECKOUT_DIR="$1"
MINSOC_INSTALLATION_TEST_DIR="$2"

if [ -d "$MINSOC_INSTALLATION_TEST_DIR" ]; then
  echo "Deleting previous incomplete or outdated test directory \"$MINSOC_INSTALLATION_TEST_DIR\"..."
  rm -rf "$MINSOC_INSTALLATION_TEST_DIR"
fi

mkdir "$MINSOC_INSTALLATION_TEST_DIR"
pushd "$MINSOC_INSTALLATION_TEST_DIR" >/dev/null

cp -r "$MINSOC_CHECKOUT_DIR/utils/setup" .

bash "setup/minsoc-install.sh"

popd >/dev/null
