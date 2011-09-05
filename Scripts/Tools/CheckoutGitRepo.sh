#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 4 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <git url> <base dir> <sentinel filename> <timestamp>"
fi

GIT_URL="$1"
BASE_DIR="$2"
SENTINEL_FILENAME="$3"
TIMESTAMP="$4"

NAME_ONLY="${GIT_URL##*/}"

REPO_DIR="$BASE_DIR/$NAME_ONLY"

pushd "$REPO_DIR" >/dev/null

COMMIT_ID="$(git rev-list -n 1 --before="$TIMESTAMP" origin/master)"

if [ -z "$COMMIT_ID" ]; then
  abort "The git repository \"$GIT_URL\" does not have a history at timestamp \"$TIMESTAMP\"."
fi

echo "Checking out git repository from URL \"$GIT_URL\" at timestamp \"$TIMESTAMP\"..."

git checkout "$COMMIT_ID"

popd >/dev/null

printf "This file acts as a flag that git repository:\n  %s was successfully checked out at this location at timestamp: \"%s\".\n" "$GIT_URL" "$TIMESTAMP" >"$SENTINEL_FILENAME"
