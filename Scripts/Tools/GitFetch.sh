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

pushd "$REPO_DIR" >/dev/null

echo "Fetching updated content from git repository at URL \"$GIT_URL\"..."

# POSSIBLE OPTIMISATION: For the purposes of a daily build, maybe we just need to
#                        download the HEAD branches with something like this:
#                          git fetch origin +refs/heads/master:refs/remotes/origin/master

git fetch --all

popd >/dev/null

printf "This file acts as a flag that git repository:\n  %s\nwas successfully fetched at this location.\n" \
       "$GIT_URL" >"$SENTINEL_FILENAME"
