#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 2 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

URL="$1"
DOWNLOAD_CACHE_DIR="$2"

NAME_ONLY="${URL##*/}"

TARGET_FILENAME="$DOWNLOAD_CACHE_DIR/$NAME_ONLY"

if [ -f "$TARGET_FILENAME" ]; then
  echo "File \"$URL\" already exists in the download cache."
  exit 0
fi

TEMP_TARGET_FILENAME="$TARGET_FILENAME.download-in-progress"

echo "Downloading URL \"$URL\"..."

# Optional flags: --silent, --ftp-pasv, --ftp-method nocwd
curl --location --show-error --url "$URL" --output "$TEMP_TARGET_FILENAME"

# Test the archive before committing it to the download cache.
# Some GNU mirrors use HTML redirects that curl cannot follow,
# and once a corrupt archive lands in the download cache,
# it will stay corrupt until the user manually purges the cache.

archive_test_failed()
{
  ERR_MSG="Downloaded archive file \"$URL\" failed the integrity test, see above for the detailed error message. "
  ERR_MSG="${ERR_MSG}The file may be corrupt, or curl may not have been able to follow a redirect properly. "
  ERR_MSG="${ERR_MSG}Try downloading the archive file from another mirror. "
  ERR_MSG="${ERR_MSG}You can inspect the corrupt file at \"$TEMP_TARGET_FILENAME\"."
  abort "$ERR_MSG"
}

trap "archive_test_failed" ERR

case "$TARGET_FILENAME" in
  *.tgz|*.tar.gz) tar --list --gzip  --file "$TEMP_TARGET_FILENAME" >/dev/null;;
  *.tar.bz2)      tar --list --bzip2 --file "$TEMP_TARGET_FILENAME" >/dev/null;;
  *)              abort "Cannot guess archive type of file \"$NAME_ONLY\".";;
esac

trap - ERR

mv "$TEMP_TARGET_FILENAME" "$TARGET_FILENAME"

# echo "Finished downloading file \"$URL\" to \"$TARGET_FILENAME\"."
