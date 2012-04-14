#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 1 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <number of log lines>"
fi


for ((  i = 0 ;  i < $1;  i++  ))
do
  echo "Line text $((i+1)) line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text line text "
done
