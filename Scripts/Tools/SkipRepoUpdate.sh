#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

REPOSITORY_NAME="$1"
SKIPPED_MESSAGE="$2"
SENTINEL_FILENAME="$3"

echo "($SKIPPED_MESSAGE - $REPOSITORY_NAME)"

printf "This file acts as a flag that the updating of repository %s was skipped.\n" \
       "$REPOSITORY_NAME" >"$SENTINEL_FILENAME"
