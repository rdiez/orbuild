#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"
source "$(dirname $0)/../ShellModules/PrintCommand.sh"


if [ $# -lt 5 ]; then
  abort "Invalid number of command-line arguments. Usage: $0 <user-friendly name> log-filename.txt report-filename.txt < report-always | report-on-error > command ..."
fi


USER_FRIENDLY_NAME="$1"
shift

LOG_FILENAME="$1"
shift

REPORT_FILENAME="$1"
shift

REPORT_OPTION="$1"
shift


case "$REPORT_OPTION" in
  report-always)   REPORT_ALWAYS=1;;
  report-on-error) REPORT_ALWAYS=0;;
  *)               abort "Invalid keep log argument '$REPORT_OPTION'.";;
esac


START_UPTIME="$(</proc/uptime)"
# Remove the period and anything afterwards, keep only the integer part.
START_UPTIME="${START_UPTIME%%.*}"

START_TIME_LOCAL="$(date +"%Y-%m-%d %T %z")"
START_TIME_UTC="$(date +"%Y-%m-%d %T %z" --utc)"

{
    # Print the executed command with proper quoting, so that the user can
    # copy-and-paste the command from the log file and expect it to work.
    echo "Log file for component \"$USER_FRIENDLY_NAME\""
    printf "%s" "Command: "
    print_command "$@"

    echo "Current directory: $PWD"
    echo "This file's character encoding: ${LANG:-(unknown)}"
    echo "Start time:  Local: $START_TIME_LOCAL, UTC: $START_TIME_UTC"
    echo
} >"$LOG_FILENAME"

set +o errexit

{
    "$@"
} 2>&1 | tee --append "$LOG_FILENAME"

CAPTURED_PIPESTATUS=( ${PIPESTATUS[*]} )

set -o errexit

if [ ${CAPTURED_PIPESTATUS[1]} -ne 0 ]; then
    abort "tee failed with exit code ${CAPTURED_PIPESTATUS[1]}"
fi

EXIT_CODE=${CAPTURED_PIPESTATUS[0]}

FINISH_TIME_LOCAL="$(date +"%Y-%m-%d %T %z")"
FINISH_TIME_UTC="$(date +"%Y-%m-%d %T %z" --utc)"

FINISH_UPTIME="$(</proc/uptime)"
# Remove the period and anything afterwards, keep only the integer part.
FINISH_UPTIME="${FINISH_UPTIME%%.*}"
ELAPSED_SECONDS="$(($FINISH_UPTIME - $START_UPTIME))"

{
    echo
    echo "End of log file for component \"$USER_FRIENDLY_NAME\""
    echo "Finish time: Local: $FINISH_TIME_LOCAL, UTC: $FINISH_TIME_UTC"

    seconds=$(( $ELAPSED_SECONDS%60 ))
    minutes=$(( $ELAPSED_SECONDS/60%60 ))
    hours=$(( $ELAPSED_SECONDS/60/60 ))
    echo "Elapsed time: $hours hours, $minutes minutes and $seconds seconds"

    if [ $EXIT_CODE -eq 0 ]; then
      echo "Command succeeded (exit code 0)"
    else
      echo "Command failed with exit code $EXIT_CODE"
    fi

} >>"$LOG_FILENAME"


if [ $EXIT_CODE -eq 0 ]; then

    if [ $REPORT_ALWAYS -eq 0 ]; then
        GENERATE_REPORT=0
    else
        GENERATE_REPORT=1
    fi

else
    echo "Command failed, you can inspect the log file at: $LOG_FILENAME" >&2
    GENERATE_REPORT=1
fi


if [ $GENERATE_REPORT -eq 0 ]; then

    # echo "Discarding log file"
    rm "$LOG_FILENAME"

    if [ -e "$REPORT_FILENAME" ]; then
        # echo "Deleting old failure report"
        rm "$REPORT_FILENAME"
    fi

else

    {
      echo "UserFriendlyName=$USER_FRIENDLY_NAME"
      echo "ExitCode=$EXIT_CODE"
      echo "LogFile=$LOG_FILENAME"

      echo "StartTimeLocal=$START_TIME_LOCAL"
      echo "StartTimeUTC=$START_TIME_UTC"

      echo "FinishTimeLocal=$FINISH_TIME_LOCAL"
      echo "FinishTimeUTC=$FINISH_TIME_UTC"

      echo "ElapsedSeconds=$ELAPSED_SECONDS"
    } >"$REPORT_FILENAME"

fi

exit $EXIT_CODE
