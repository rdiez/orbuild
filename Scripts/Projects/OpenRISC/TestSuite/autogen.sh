#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../../../ShellModules/StandardShellHeader.sh"
source "$(dirname $0)/../../../ShellModules/PrintCommand.sh"
source "$(dirname $0)/../../../ShellModules/FileUtils.sh"

# set -x  # Trace the commands as they are executed.

if [ $# -ne 1 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

TARGET_HOST="$1"

CONFIG_SUB_FILENAME="config.sub"

# Make sure that config.sub gets regenerated, see below for more information.
delete_file_if_exists "$CONFIG_SUB_FILENAME"

patch_for_or1k_support ()
{
  # Autoconf (as of version 2.68) does not recognise the architecture name "or1k",
  # so edit the generated file config.sub and replace all references to "or32" with "or1k".
  # This issue was discussed in the mailing list, see the following thread:
  #  'The "or1k" architecture name is not recognised by autoconf'
  #  http://lists.openrisc.net/pipermail/openrisc/2012-May/001213.html

  echo "Replacing or32 with or1k in $CONFIG_SUB_FILENAME ..."
  sed --in-place -e "s/\bor32\b/or1k/g" "$CONFIG_SUB_FILENAME"
}


CMD="autoreconf --warnings=all --install"
print_command $CMD
$CMD

case "$TARGET_HOST" in
  or32-elf) echo "Nothing to do here" >/dev/null;;
  or1k-elf) patch_for_or1k_support;;
  *)        abort "Unknown target host $TARGET_HOST .";;
esac
