#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


# This script helps automatically keep a git clone of a subversion repository up to date.
# The focus is on the OpenRISC subversion repositories at opencores.org ,
# which require a login and password for access.
#
# The steps to use this script are:
# 
# 1) Manually clone the subversion repository like this:
#
#      git svn init --username=<login> http://opencores.org/ocsvn/openrisc/openrisc/trunk/<project name>
#
#      TODO: The Apache Foundation performs the following extra steps here:
#        git config gitweb.owner "The Apache Software Foundation"
#        echo "git://git.apache.org/$GIT_DIR" > "$GIT_DIR/cloneurl"
#        echo "http://git.apache.org/$GIT_DIR" >> "$GIT_DIR/cloneurl"
#        echo "$DESCRIPTION" > "$GIT_DIR/description"
#        touch "$GIT_DIR/git-daemon-export-ok"
#
#        # Normally you get "ref: refs/heads/master" in the .git/HEAD file"
#        echo "ref: refs/heads/trunk" > "$GIT_DIR/HEAD"
#
#        git update-server-info
#
#    About branches and tags:
#      Project or1ksim has tags in the subversion repository, but not branches.
#      I have not been able to import the tags into git. I have tried all thinkable combinations,
#      but as soon as I specify the -t option to "git svn init", the fetch operation downloads nothing at all.
#
#    About the credentials:
#      Subversion will ask for a password and cache the credentials.
#      Caching the credentials is necessary because, although "git svn" does
#      understand Subversion's option --username , it does not understand Subversion's
#      option --password .
#
#      If you ever need to change the cached username or password for that repository,
#      you'll have to manually do this on the git repository:
#        git svn fetch --username=<login>
#      You'll then be asked for the password, and the new credentials will be cached.
#
#      I thought running the following command would refresh the credentials globally,
#      but that does not seem to be the case.
#        (does not work) svn log -rHEAD --username <login> svn://example.com/svn-repo
#
#      You may be able to automate your credentials in some other way, for example,
#      with SSH keys. Or you may not need any authentication at all.
#
# 2) Run this script like this every now and then to update the git repository from subversion:
#
#      bash UpdateSvnToGitRepoMirror.sh  svn://example.com/svn-repo svn-repo/
#
#    If the update fails, this script will retry a number of times before giving up.
#
# 3) If you have made local changes to your repository, you may want to rebase your changes:
#      git svn rebase --local
#
# 4) If you wish to further clone or push the git repository, keep in mind that
#    the subversion information is not automatically cloned.
#    Alternatives to overcome this issue are:
#    a) Clone the git repository with rsync.
#    b) Initialise the destination repository with the same "git svn init" parameters.
#       It is possible to do that on an existing clone, search the Internet for
#       "Rebuilding git-svn metadata" for details.
#    c) Do nothing. The other cloned git repositories will carry no links to
#       the orignal subversion repository, but that's not a problem if you only
#       intend to develop on a patch basis.
#


if [ $# -ne 1 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <svn url> <git dir>"
fi

GIT_DIR="$1"

ATTEMPT_COUNT=5  # At least one, as the first time also counts.

echo "Updating git repository at \"$GIT_DIR\"..."

pushd "$GIT_DIR" >/dev/null

for (( c=1; ; c++ ))
do

  set +o errexit

  # TODO: Option --authors-file may be useful to map the subversion user names to the git ones.

  # The Apache Foundation uses parameter --log-window-size to accelerate the download.
  git svn fetch --log-window-size=10000

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
