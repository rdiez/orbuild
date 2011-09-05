#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <git url> <base dir> <sentinel filename>"
fi

GIT_URL="$1"
BASE_DIR="$2"
SENTINEL_FILENAME="$3"

NAME_ONLY="${GIT_URL##*/}"

REPO_DIR="$BASE_DIR/$NAME_ONLY"

pushd "$BASE_DIR" >/dev/null

if [ -d "$REPO_DIR" ] && ! [ -e "$SENTINEL_FILENAME" ]; then
  # As far as I know, "git clone" cannot resume an interrupted transfer,
  # so delete the existing repository and start from scratch.
  echo "Deleting previous incomplete or outdated repository clone at \"$REPO_DIR\"..."
  rm -rf "$REPO_DIR"
fi


if [ -d "$REPO_DIR" ]; then

  pushd "$REPO_DIR" >/dev/null

  echo "Fetching updated content from git repository at URL \"$GIT_URL\"..."

  # POSSIBLE OPTIMISATION: For the purposes of a daily build, maybe we just need to
  #                        download the HEAD branches with something like this:
  #                          git fetch origin +refs/heads/master:refs/remotes/origin/master

  git fetch --all

  popd >/dev/null

else

  echo "Cloning git repository at URL \"$GIT_URL\"..."

  git clone --no-checkout "$GIT_URL"

  if ! [ -d "$REPO_DIR" ]; then
    abort "The git repository \"$GIT_URL\" has not created the expected subdirectory \"$NAME_ONLY\" when checking out in directory \"$BASE_DIR\"."
  fi

fi


popd "$BASE_DIR" >/dev/null

printf "This file acts as a flag that git repository:\n  %s\nwas successfully cloned/fetched out at this location.\n" "$GIT_URL" >"$SENTINEL_FILENAME"
