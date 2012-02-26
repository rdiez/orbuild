#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 6 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <svn url> <base dir> <sentinel filename> <login> <password>"
fi

SVN_URL="$1"
OUTPUT_DIR="$2"
SENTINEL_FILENAME="$3"
TIMESTAMP="$4"
USER_LOGIN="$5"
USER_PASSWORD="$6"

NAME_ONLY="${SVN_URL##*/}"

START_LOCALTIME="$(date +"%Y-%m-%d %T %z")"
START_UTC="$(date +"%Y-%m-%d %T %z" --utc)"

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

# The stdin redirection trick "</dev/null" does not work with Subversion when it wants to prompt for credentials,
# therefore pass the --non-interactive when appropriate.
if [ $ORBUILD_IS_INTERACTIVE_BUILD -eq 0 ]; then
  NON_INTERACTIVE_FLAG="--non-interactive"
else
  NON_INTERACTIVE_FLAG=""
fi

svn checkout $TIMESTAMP_ARG $LOGIN_ARGS --quiet $NON_INTERACTIVE_FLAG "$SVN_URL" "$OUTPUT_DIR"

# Now that we specify the output directory, we don't need this check any more:
#   if ! [ -d "$OUTPUT_DIR" ]; then
#     abort "The subversion repository \"$SVN_URL\" has not created the expected subdirectory \"$NAME_ONLY\" when checking out in directory \"$OUTPUT_DIR\"."
#   fi

printf "This file acts as a flag that subversion repository:\n  %s\nwas successfully checked out at location:\n  %s\nThe checkout started at local time %s, UTC %s.\n" \
       "$SVN_URL" "$OUTPUT_DIR" "$START_LOCALTIME" "$START_UTC" \
       >"$SENTINEL_FILENAME"
