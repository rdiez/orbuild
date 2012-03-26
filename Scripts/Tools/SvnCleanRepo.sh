#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 1 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

SVN_REPO_DIR="$1"

pushd "$SVN_REPO_DIR" >/dev/null


# Grep yields an exit code of 1 if it finds no matches. Turn that eventual exit code to 0, which
# bash interprets as success.

svn status --no-ignore \
  | { set +o errexit; grep '^[?I]'; grep_exit_code=$?; if [ $grep_exit_code -eq 1 ]; then exit 0; else exit $grep_exit_code; fi } \
  | awk '{print $2}' \
  | xargs --no-run-if-empty  rm -rf

popd >/dev/null
