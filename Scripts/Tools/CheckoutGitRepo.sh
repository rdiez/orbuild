#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 6 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <git url> <dest subdir> <base dir> <sentinel filename> <branch> <timestamp>"
fi

GIT_URL="$1"
DEST_DIR="$2"
BASE_DIR="$3"
SENTINEL_FILENAME="$4"
BRANCH="$5"
TIMESTAMP="$6"

REPO_DIR="$BASE_DIR/$DEST_DIR"

pushd "$REPO_DIR" >/dev/null

if [ -n "$TIMESTAMP" ] && [ -n "$BRANCH" ]; then
  abort "This script does not support both a branch and a timestamp argument at the same time."
fi

if [ -n "$TIMESTAMP" ]; then

  COMMIT_ID="$(git rev-list -n 1 --before="$TIMESTAMP" origin/master)"

  if [ -z "$COMMIT_ID" ]; then
    abort "The git repository \"$GIT_URL\" does not have a history at timestamp \"$TIMESTAMP\"."
  fi

  echo "Checking out git repository from URL \"$GIT_URL\" at timestamp \"$TIMESTAMP\"..."

  git checkout "$COMMIT_ID"

  abort "TODO: git merge missing here"

elif [ -n "$BRANCH" ]; then

  echo "Checking out git repository from URL \"$GIT_URL\" at branch \"origin/$BRANCH\"..."
  git checkout "origin/$BRANCH"
  abort "TODO: git merge missing here"

else

  echo "Checking out git repository from URL \"$GIT_URL\"..."
  git checkout

  echo "Merging any changes from upstream git..."
  git merge FETCH_HEAD

fi

popd >/dev/null

printf "This file acts as a flag that git repository:\n  %s was successfully checked out at this location at timestamp: \"%s\".\n" "$GIT_URL" "$TIMESTAMP" >"$SENTINEL_FILENAME"
