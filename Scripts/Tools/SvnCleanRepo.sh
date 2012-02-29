#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 1 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

SVN_REPO_DIR="$1"

pushd "$SVN_REPO_DIR" >/dev/null

svn status --no-ignore | grep '^[?I]' | awk '{print $2}' | xargs rm -rf

popd >/dev/null
