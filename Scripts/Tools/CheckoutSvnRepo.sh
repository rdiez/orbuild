#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 6 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <svn url> <base dir> <sentinel filename> <login> <password>"
fi

SVN_URL="$1"
BASE_DIR="$2"
SENTINEL_FILENAME="$3"
TIMESTAMP="$4"
USER_LOGIN="$5"
USER_PASSWORD="$6"

NAME_ONLY="${SVN_URL##*/}"

START_LOCALTIME="$(date +"%Y-%m-%d %T %z")"
START_UTC="$(date +"%Y-%m-%d %T %z" --utc)"

pushd "$BASE_DIR" >/dev/null

if [ -z "$USER_LOGIN" ]; then
  LOGIN_ARGS=""
else
  LOGIN_ARGS="--username "$USER_LOGIN" --password "$USER_PASSWORD" --no-auth-cache"
fi

if [ -z "$TIMESTAMP" ]; then
  echo "Checking out subversion repository at URL \"$SVN_URL\"..."
  TIMESTAMP_ARG=""
else
  echo "Checking out subversion repository at URL \"$SVN_URL\" at timestamp \"$TIMESTAMP\"..."
  TIMESTAMP_ARG="-r{$TIMESTAMP}"
fi

svn checkout $TIMESTAMP_ARG $LOGIN_ARGS --quiet --non-interactive "$SVN_URL"

if ! [ -d "$NAME_ONLY" ]; then
  abort "The subversion repository \"$SVN_URL\" has not created the expected subdirectory \"$NAME_ONLY\" when checking out in directory \"$BASE_DIR\"."
fi

popd >/dev/null

printf "This file acts as a flag that subversion repository:\n  %s\nwas successfully checked out at location:\n  %s\nThe checkout started at local time %s, UTC %s.\n" \
       "$SVN_URL" "$BASE_DIR" "$START_LOCALTIME" "$START_UTC" \
       >"$SENTINEL_FILENAME"
