#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 4 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <compressed filename> <destination dir> <sentinel filename> <created destination subdirectory>"
fi

COMPRESSED_FILENAME="$1"
DEST_DIR="$2"
SENTINEL_FILENAME="$3"
CREATED_DESTINATION_SUBDIR="$4"

if [ -d "$CREATED_DESTINATION_SUBDIR" ]; then
  echo "Deleting previous incomplete or outdated directory \"$CREATED_DESTINATION_SUBDIR\"..."
  rm -rf "$CREATED_DESTINATION_SUBDIR"
fi

echo "Unpacking file \"$COMPRESSED_FILENAME\"..."

case "$COMPRESSED_FILENAME" in
  *.tgz|*.tar.gz) tar --extract --gzip  --directory "$DEST_DIR" --file "$COMPRESSED_FILENAME";;
  *.tar.bz2)      tar --extract --bzip2 --directory "$DEST_DIR" --file "$COMPRESSED_FILENAME";;
  *)              abort "Cannot guess archive type of file \"$COMPRESSED_FILENAME\".";;
esac

if ! [ -d "$CREATED_DESTINATION_SUBDIR" ]; then
  abort "The archive file \"$COMPRESSED_FILENAME\" has not created the expected subdirectory \"$CREATED_DESTINATION_SUBDIR\" when unpacking to directory \"$DEST_DIR\"."
fi

# The sentinel file is now stored outside the uncompressed directory.
#if [ -e "$SENTINEL_FILENAME" ]; then
#  abort "The archive file \"$COMPRESSED_FILENAME\" contains a file called \"$SENTINEL_FILENAME\", whose name collides with the sentinel filename that should be created after unpacking the archive."
#fi

printf "This file acts as a flag that archive:\n  %s\nwas successfully unpacked at this location:\n  %s\n" \
       $COMPRESSED_FILENAME $CREATED_DESTINATION_SUBDIR \
       >"$SENTINEL_FILENAME"
