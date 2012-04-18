#!/bin/bash

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../ShellModules/StandardShellHeader.sh"


if [ $# -ne 1 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

REPORT_FILENAME="$1"

if [[ $OSTYPE = "cygwin" ]]
then

  # Cygwin does not have any means to display a system tray notification (as of April 2012).
  # I haven't found an easy alternative yet. Windows Scripting Host cannot do that,
  # and I don't want to start some .Net framework application for that purpose only.
  # Win32's function is called Shell_NotifyIcon.
  # Perl module Win32::GUI::NotifyIcon is not installed by default with Cygwin.

  cygstart "$REPORT_FILENAME"

else

  # Display a pop-up notification on the system tray.

  if type notify-send >/dev/null 2>&1 ;
  then
    notify-send "orbuild finished"
  else
    echo "Note: The notify-send tool is not installed, therefore no desktop notification will be issued."
  fi

  
  # Open the HTML report in a web browser.

  if type xdg-open >/dev/null 2>&1 ;
  then
  xdg-open "$REPORT_FILENAME"
  else
    echo "Note: The xdg-open tool is not installed, therefore the HTML report will not be opened automatically."
  fi

fi
