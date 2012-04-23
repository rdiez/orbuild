#!/bin/bash

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

set -o errexit
SANDBOX_DIR="$(readlink -f "$(dirname "$0")/../../..")"
source "$SANDBOX_DIR/Scripts/ShellModules/StandardShellHeader.sh"

if [ $# -ne 4 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

START_TIME_UTC="$(date +"%Y-%m-%d %T %z" --utc)"

SUBPROJECT_NUMBER="$1"
shift

SUBPROJECT_OUTPUT_DIR="$(readlink -f $1)"
shift

REPORTS_BASEDIR="$1"
shift

REPORT_FILENAME="$1"
shift

REPORTS_SUBDIR="Reports"

create_dir_if_not_exists ()
{
    # $1 = dir name

    if ! test -d "$1"
    then
        echo "Creating directory \"$1\" ..."
        mkdir --parents "$1"
    fi
}


if [ -d "$SUBPROJECT_OUTPUT_DIR" ]; then
  echo "Deleting previous output directory $SUBPROJECT_OUTPUT_DIR..."
  rm -rf "$SUBPROJECT_OUTPUT_DIR"
fi

mkdir "$SUBPROJECT_OUTPUT_DIR"


# The example submakefile is reusing the orbuild infrastructure, so
# we need to redirect the output directories here:
export ORBUILD_PUBLIC_REPORTS_DIR="$SUBPROJECT_OUTPUT_DIR/$REPORTS_BASEDIR/$REPORTS_SUBDIR"
export ORBUILD_INTERNAL_REPORTS_DIR="$SUBPROJECT_OUTPUT_DIR/SubprojectInternalReports"
export ORBUILD_COMMAND_SENTINELS_DIR="$SUBPROJECT_OUTPUT_DIR/SubprojectSentinels"

create_dir_if_not_exists "$ORBUILD_PUBLIC_REPORTS_DIR"
create_dir_if_not_exists "$ORBUILD_INTERNAL_REPORTS_DIR"
create_dir_if_not_exists "$ORBUILD_COMMAND_SENTINELS_DIR"


make -k --no-builtin-variables --warn-undefined-variables \
     -C "$(dirname $0)" \
     SUBPROJECT_OUTPUT_DIR="$SUBPROJECT_OUTPUT_DIR" \
     SUBPROJECT_NUMBER=$SUBPROJECT_NUMBER \
     -f Submakefile \
     all

perl "$ORBUILD_TOOLS/GenerateBuildReport.pl" \
     --title "Subproject $SUBPROJECT_NUMBER build report" \
     --startTimeUtc "$START_TIME_UTC" \
     "$ORBUILD_INTERNAL_REPORTS_DIR" \
     "$SUBPROJECT_OUTPUT_DIR/$REPORTS_BASEDIR" \
     "$REPORTS_SUBDIR" \
     "$REPORT_FILENAME"
