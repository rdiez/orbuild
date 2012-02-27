#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

REPO_DIR="$1"
SENTINEL_FILENAME="$2"
BRANCH_FLAGS="$3"

pushd "$REPO_DIR" >/dev/null

echo "Branching git repository at \"$REPO_DIR\"..."

git branch $BRANCH_FLAGS

popd "$REPO_DIR" >/dev/null

printf "This file acts as a flag that git repository:\n  %s\nwas successfully branched.\n" \
       "$REPO_DIR" >"$SENTINEL_FILENAME"
