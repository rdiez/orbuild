#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 4 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

GIT_URL="$1"
DEST_DIR="$2"
BASE_DIR="$3"
SENTINEL_FILENAME="$4"

REPO_DIR="$BASE_DIR/$DEST_DIR"

pushd "$BASE_DIR" >/dev/null

if [ -d "$REPO_DIR" ]; then
  # As far as I know, "git clone" cannot resume an interrupted transfer,
  # so delete the existing repository and start from scratch.
  echo "Deleting previous incomplete or outdated repository clone at \"$REPO_DIR\"..."
  rm -rf "$REPO_DIR"
fi

echo "Cloning git repository at URL \"$GIT_URL\"..."

CMD="git clone --no-checkout $GIT_URL $DEST_DIR"
echo "$CMD"
eval "$CMD"

if ! [ -d "$REPO_DIR" ]; then
  abort "The git repository \"$GIT_URL\" has not created the expected subdirectory \"$DEST_DIR\" when checking out in directory \"$BASE_DIR\"."
fi

popd "$BASE_DIR" >/dev/null

printf "This file acts as a flag that git repository:\n  %s\nwas successfully cloned at location:\n  %s\n" \
       "$GIT_URL" "$REPO_DIR" >"$SENTINEL_FILENAME"
