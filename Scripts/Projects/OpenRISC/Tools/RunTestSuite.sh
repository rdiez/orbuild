#!/bin/bash

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

set -o errexit
SANDBOX_DIR="$(readlink -f "$(dirname "$0")/../../../..")"

source "$SANDBOX_DIR/Scripts/ShellModules/StandardShellHeader.sh"
source "$SANDBOX_DIR/Scripts/ShellModules/FileUtils.sh"

if [ $# -ne 7 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

START_TIME_UTC="$(date +"%Y-%m-%d %T %z" --utc)"

REPORTS_BASEDIR="$1"
shift
REPORT_FILENAME="$1"
shift
ORTS_EXES_BIN_DIR="$1"
shift
ORPSOCV2_CHECKOUT_DIR="$1"
shift
OPENRISC_BARE_TARGET="$1"
shift
OUTPUT_DIR="$1"
shift
TEST_TYPE="$1"
shift

REPORTS_SUBDIR="Reports"

create_dir_if_not_exists "$OUTPUT_DIR"

# The submakefile is reusing the orbuild infrastructure, so
# we need to redirect the output directories here:
export ORBUILD_PUBLIC_REPORTS_DIR="$OUTPUT_DIR/$REPORTS_BASEDIR/$REPORTS_SUBDIR"
export ORBUILD_INTERNAL_REPORTS_DIR="$OUTPUT_DIR/SubprojectInternalReports"
export ORBUILD_COMMAND_SENTINELS_DIR="$OUTPUT_DIR/SubprojectSentinels"

create_dir_if_not_exists "$ORBUILD_PUBLIC_REPORTS_DIR"
create_dir_if_not_exists "$ORBUILD_INTERNAL_REPORTS_DIR"
create_dir_if_not_exists "$ORBUILD_COMMAND_SENTINELS_DIR"

ORBUILD_COMPONENT_GROUPS_FILENAME="$ORBUILD_INTERNAL_REPORTS_DIR/ComponentGroups.lst"
# Truncate the file if it already exists.
printf "" > "$ORBUILD_COMPONENT_GROUPS_FILENAME"

if [ $ORBUILD_STOP_ON_FIRST_ERROR -eq 0 ]; then
  K_FLAG=-k
else
  K_FLAG=
fi

# Even if the make invokation fails, we should try to generate the report nevertheless.
set +o errexit

make $K_FLAG --no-builtin-variables --warn-undefined-variables \
     -C "$(dirname $0)" \
     OUTPUT_DIR="$OUTPUT_DIR" \
     ORTS_EXES_BIN_DIR="$ORTS_EXES_BIN_DIR" \
     TEST_TYPE="$TEST_TYPE" \
     ORPSOCV2_CHECKOUT_DIR="$ORPSOCV2_CHECKOUT_DIR" \
     OPENRISC_BARE_TARGET="$OPENRISC_BARE_TARGET" \
     ORBUILD_COMPONENT_GROUPS_FILENAME="$ORBUILD_COMPONENT_GROUPS_FILENAME" \
     -f RunTestSuiteMakefile \
     all

MAKE_EXIT_CODE=$?

set -o errexit


perl "$ORBUILD_TOOLS/GenerateBuildReport.pl" \
     --title "Test suite run $TEST_TYPE report" \
     --startTimeUtc "$START_TIME_UTC" \
     --componentGroupsFilename "$ORBUILD_COMPONENT_GROUPS_FILENAME" \
     "$ORBUILD_INTERNAL_REPORTS_DIR" \
     "$OUTPUT_DIR/$REPORTS_BASEDIR" \
     "$REPORTS_SUBDIR" \
     "$REPORT_FILENAME"

exit $MAKE_EXIT_CODE
