#!/bin/bash

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

set -o errexit
source "$(dirname $0)/../../../ShellModules/StandardShellHeader.sh"

# set -x  # Trace the commands as they are executed.

if [ $# -ne 1 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

FILENAME="$1"

# Autoconf (as of version 2.68) does not recognise the architecture name "or1k",
# so edit the generated file config.sub and replace all references to "or32" with "or1k".
# This issue was discussed in the mailing list, see the following thread:
#  'The "or1k" architecture name is not recognised by autoconf'
#  http://lists.openrisc.net/pipermail/openrisc/2012-May/001213.html

echo "Replacing or32 with or1k in $FILENAME ..."
sed --in-place -e "s/\bor32\b/or1k/g" "$FILENAME"

