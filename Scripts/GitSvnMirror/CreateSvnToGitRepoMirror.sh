#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"

if [ $# -ne 6 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <git base dir> <git subdir> <git svn init cmd> <description> <init file> <description file>"
fi

GIT_BASE_DIR="$1"
GIT_SUBDIR="$2"
GIT_SVN_INIT_CMD="$3"
DESCRIPTION="$4"
INIT_FILE="$5"
DESCRIPTION_FILE="$6"

echo "Creating the git repository at \"$GIT_BASE_DIR/$GIT_SUBDIR\"..."

pushd "$GIT_BASE_DIR" >/dev/null

if [ -d "$GIT_SUBDIR" ]; then rm -rf "$GIT_SUBDIR"; fi

$GIT_SVN_INIT_CMD "$GIT_SUBDIR"

# TODO: The Apache Foundation performs the following extra steps here:
#  git config gitweb.owner "The Apache Software Foundation"
#  echo "git://git.apache.org/$$GIT_DIR" > "$$GIT_DIR/cloneurl"
#  echo "http://git.apache.org/$$GIT_DIR" >> "$$GIT_DIR/cloneurl"
#  echo "$$DESCRIPTION" > "$$GIT_DIR/description"
#  touch "$$GIT_DIR/git-daemon-export-ok"
#  # Normally you get "ref: refs/heads/master" in the .git/HEAD file"
#  echo "ref: refs/heads/trunk" > "$$GIT_DIR/HEAD"
#  git update-server-info

"$ORBUILD_SANDBOX/Scripts/GitSvnMirror/UpdateSvnToGitRepoMirror.sh"  "$GIT_BASE_DIR/$GIT_SUBDIR"

echo "$GIT_SVN_INIT_CMD $GIT_SUBDIR" >"$INIT_FILE"
echo "$DESCRIPTION" >"$DESCRIPTION_FILE"

echo "Finished creating the git repository at \"$GIT_BASE_DIR/$GIT_SUBDIR\"."

popd >/dev/null
