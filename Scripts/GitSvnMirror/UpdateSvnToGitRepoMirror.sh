#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 2 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <git dir> <fetch args>"
fi

GIT_DIR="$1"
FETCH_ARGS="$2"

ATTEMPT_COUNT=5  # At least one, as the first time also counts.

echo "Updating the git repository at \"$GIT_DIR\"..."

pushd "$GIT_DIR" >/dev/null

for (( c=1; ; c++ ))
do

  set +o errexit

  # TODO: Option --authors-file may be useful to map the subversion user names to the git ones.

  # The Apache Foundation uses parameter --log-window-size to accelerate the download.
  # However, with this argument 'git svn fetch' prints some error messages
  # you should allegedly not be alarmed by, but it then reliably fails to fetch anything
  # from the or1ksim repository:
  #   git svn fetch --log-window-size=10000
  git svn fetch $FETCH_ARGS

  EXIT_CODE=$?

  set -o errexit


  if [ $EXIT_CODE -eq 0 ]; then
    break
  fi

  if (( $c == $ATTEMPT_COUNT )); then
    echo "Giving up retrying."
    exit $EXIT_CODE
  fi

  echo "Failed, retrying $(($c+1)) of $ATTEMPT_COUNT..."

done


# TODO: The Apache Foundation performs 2 extra steps here:
#
# # Map the remote git-svn branches to local Git branches
# git for-each-ref refs/remotes | cut -d / -f 3- | grep -v @ | grep -v tags/ | while read ref
# do
#     git update-ref "refs/heads/$ref" "refs/remotes/$ref"
# done
# git for-each-ref refs/heads | cut -d / -f 3- | while read ref
# do
#     git rev-parse "refs/remotes/$ref" > /dev/null 2>&1 ||
#         git update-ref -d "refs/heads/$ref" "refs/heads/$ref"
# done
# 
# # Map git-svn pseudo-tags from refs/remotes/tags/* to real Git tags
# Possible explanation about this found here:
#   http://www.adamfranco.com/2010/12/05/mirroring-a-subversion-repository-on-github/
#   I may be doing something wrong, but it seems that Subversion tags
#   come through git svn as git branches rather than as git “tag” objects.
#   Basically they are a branch with a single commit that just adds the tag message,
#   but no content change. Using git show I found I could grab the parent id,
#   message, and other metadata from the “tag-branch”, then feed that into
#   git tag to create actual tag objects in the git repository.
# git for-each-ref refs/remotes/tags | cut -d / -f 4- | grep -v @ | while read tag
# do
#     n=`git for-each-ref --format="%(committername)" "refs/remotes/tags/$tag"`
#     e=`git for-each-ref --format="%(committeremail)" "refs/remotes/tags/$tag"`
#     d=`git for-each-ref --format="%(committerdate)" "refs/remotes/tags/$tag"`
#     GIT_COMMITTER_NAME="$n" GIT_COMMITTER_EMAIL="$e" GIT_COMMITTER_DATE="$d" \
#         git tag -f -m "$tag" "$tag" "refs/remotes/tags/$tag"
# done
# git tag | while read tag
# do
#     git rev-parse "refs/remotes/tags/$tag" > /dev/null 2>&1 ||
#         git tag -d "$tag"
# done

# TODO: An alternative I found on the Internet:
## Make the git master branch always track the svn trunk
#git update-ref refs/heads/master refs/remotes/trunk
#
## Copy all other remote branches (svn branches and tags) to normal git branches
#git for-each-ref refs/remotes | cut -d / -f 3- | grep -v -x trunk | grep -v @ | while read ref do git update-ref "refs/heads/$ref" "refs/remotes/$ref" done
#
## Prune branches or tags that have been removed in svn
#git for-each-ref refs/heads | cut -d / -f 3- | grep -v -x master | while read ref do git rev-parse "refs/remotes/$ref" > /dev/null 2>&1 || git update-ref -d "refs/heads/$ref" "refs/heads/$ref" done


# TODO: You may need this if you are directly serving this repository on the web:
#   git update-server-info


echo "Garbage collecting the git repository..."
git gc --auto

# We don't really need to rebase or to update the checked out files,
# but it's nice to see the latest files locally.
echo "Rebasing the checkout files against the remote changes..."
git svn rebase --local

echo "Finished updating the git repository."

popd >/dev/null
