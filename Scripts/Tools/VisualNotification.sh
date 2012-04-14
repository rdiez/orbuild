#!/bin/bash

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 1 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

REPORT_FILENAME="$1"

if [[ $OSTYPE = "cygwin" ]]
then
  cygstart "$REPORT_FILENAME"
else
  # The user has hopefully installed the xdg-utils package beforehand.
  xdg-open "$REPORT_FILENAME"
fi
