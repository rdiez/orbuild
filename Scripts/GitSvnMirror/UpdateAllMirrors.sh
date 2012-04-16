#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
SCRIPT_DIR="$(dirname $(readlink -f "$0"))"
source "$SCRIPT_DIR/../ShellModules/StandardShellHeader.sh"
# source "$SCRIPT_DIR/../ShellModules/MakeJVal.sh"


delete_file_if_exists ()
{
    if [ -f "$1" ]
    then
        rm -f "$1"
    fi
}


create_dir_if_not_exists ()
{
    if ! test -d "$1"
    then
        echo "Creating directory \"$1\" ..."
        mkdir --parents "$1"
    fi
}


ORBUILD_SANDBOX="$(readlink -f "$SCRIPT_DIR/../..")"
ORBUILD_TOOLS="$ORBUILD_SANDBOX/Scripts/Tools"
MIRROR_TOOLS="$ORBUILD_SANDBOX/Scripts/GitSvnMirror"
BASE_MIRROR_DIR="$ORBUILD_SANDBOX/GitSvnMirrors"
GIT_BASE_DIR="$BASE_MIRROR_DIR/Repositories"

ALL_INTERNAL_REPORTS_DIR="$BASE_MIRROR_DIR/InternalReports"
ALL_PUBLIC_REPORTS_DIR="$BASE_MIRROR_DIR/PublicReports"

create_dir_if_not_exists "$ALL_INTERNAL_REPORTS_DIR"
create_dir_if_not_exists "$ALL_PUBLIC_REPORTS_DIR"
create_dir_if_not_exists "$GIT_BASE_DIR"

SLOT_COUNT=100  #  Keep a more than 3 months' worth of logs and reports.

ROTATE_DIR_CMD="perl $ORBUILD_SANDBOX/Scripts/Tools/RotateDir.pl \
                --dir-naming-scheme date \
                --slot-count $SLOT_COUNT \
                --dir-name-prefix Timestamp- \
                --timestamp "$(date +"%Y-%m-%d" --utc)" \
                --output-only-new-dir-name"

INTERNAL_REPORTS_DIR=$($ROTATE_DIR_CMD "$ALL_INTERNAL_REPORTS_DIR")
PUBLIC_REPORTS_DIR=$($ROTATE_DIR_CMD "$ALL_PUBLIC_REPORTS_DIR")

MAKEFILE_REPORT_FILENAME="$INTERNAL_REPORTS_DIR/makefile.report"
MAKEFILE_LOG_FILENAME="$PUBLIC_REPORTS_DIR/makefile-log.txt"
TOP_LEVEL_FRIENDLY_NAME="top-level process"

# Updating the repositories is done sequentially for these reasons:
# 1) Sometimes the user needs to manually enter a username and a password,
#    and the parallel build mixes the console messages in a confusing way.
# 2) If 2 processes try to interactively ask for a username at the same time,
#    one of them will fail, because the other one is holding the console input.
# 3) Most repositories come from the same server, and we don't want
#    to overload the connection.
# get_make_j_val MAKE_J_VAL
MAKE_J_VAL=1


# If the following command fails, it normally writes a report file
# with the failure reason. This report is then integrated
# later in the global report.
# In case the script fails too early, the report file is deleted
# before this point, so that the report generator will fail too.
set +o errexit

"$ORBUILD_TOOLS/RunAndReport.sh"  "TOP_LEVEL" \
                                  "$TOP_LEVEL_FRIENDLY_NAME" \
                                  "$MAKEFILE_LOG_FILENAME" \
                                  "$MAKEFILE_REPORT_FILENAME" \
                                  report-always \
    make -C "$INTERNAL_REPORTS_DIR" \
        ORBUILD_SANDBOX="$ORBUILD_SANDBOX" \
        ORBUILD_GIT_BASE_DIR="$GIT_BASE_DIR" \
        ORBUILD_REPORTS_DIR="$INTERNAL_REPORTS_DIR" \
        ORBUILD_LOGS_DIR="$PUBLIC_REPORTS_DIR" \
        --no-builtin-variables --warn-undefined-variables \
        -f "$MIRROR_TOOLS/Makefile" \
        -k -s -j "$MAKE_J_VAL" \
        update-all-git-svn-mirrors

set -o errexit

REPORT_NAME_ONLY="Status.html"
REPORT_FILENAME="$PUBLIC_REPORTS_DIR/$REPORT_NAME_ONLY"

if [ "${ORBUILD_GIT_URL_PREFIX:-first}" != "${ORBUILD_GIT_URL_PREFIX:-second}" ]
then
  ORBUILD_GIT_URL_PREFIX="file://$GIT_BASE_DIR/"
fi

perl "$MIRROR_TOOLS/GenerateGitSvnMirrorReport.pl" \
         "$INTERNAL_REPORTS_DIR" \
         "$GIT_BASE_DIR" \
         "$MAKEFILE_REPORT_FILENAME" \
         "$REPORT_FILENAME" \
         "$ORBUILD_GIT_URL_PREFIX"

LATEST_LINK_NAME="$ALL_PUBLIC_REPORTS_DIR/LatestReport"

ln --symbolic --no-dereference --force "$PUBLIC_REPORTS_DIR" "$LATEST_LINK_NAME"

if [[ $OSTYPE = "cygwin" ]]
then
  printf "The generated update report is:\nCygwin : %s\nWindows: %s\n" \
         "$LATEST_LINK_NAME/$REPORT_NAME_ONLY" \
         "$(cygpath -w "$PUBLIC_REPORTS_DIR/$REPORT_NAME_ONLY")"
else
  printf "The generated update report is:\n$LATEST_LINK_NAME/$REPORT_NAME_ONLY\n"
fi
