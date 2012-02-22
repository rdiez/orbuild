#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 6 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <git url> <dest subdir> <base dir> <sentinel filename> <timestamp> <extra git checkout args>"
fi

GIT_URL="$1"
DEST_DIR="$2"
BASE_DIR="$3"
SENTINEL_FILENAME="$4"
TIMESTAMP="$5"
EXTRA_GIT_CHECKOUT_ARGS="$6"

REPO_DIR="$BASE_DIR/$DEST_DIR"

pushd "$REPO_DIR" >/dev/null

if [ -n "$TIMESTAMP" ]; then

  COMMIT_ID="$(git rev-list -n 1 --before="$TIMESTAMP" origin/master)"

  if [ -z "$COMMIT_ID" ]; then
    abort "The git repository \"$GIT_URL\" does not have a history at timestamp \"$TIMESTAMP\"."
  fi

  echo "Checking out git repository from URL \"$GIT_URL\" at timestamp \"$TIMESTAMP\"..."

  git checkout $EXTRA_GIT_CHECKOUT_ARGS "$COMMIT_ID"

  abort "TODO: git merge missing here"

else

  echo "Checking out git repository from URL \"$GIT_URL\"..."
  git checkout $EXTRA_GIT_CHECKOUT_ARGS

  echo "Merging any changes from upstream git..."
  CURRENT_BRANCH="$(git name-rev --name-only HEAD)"
  git merge "$CURRENT_BRANCH"

fi

popd >/dev/null

printf "This file acts as a flag that git repository:\n  %s was successfully checked out at this location at timestamp: \"%s\".\n" "$GIT_URL" "$TIMESTAMP" >"$SENTINEL_FILENAME"
