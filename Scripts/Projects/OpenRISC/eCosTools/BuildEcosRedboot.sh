#!/bin/bash

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

set -o errexit
SANDBOX_DIR="$(readlink -f "$(dirname "$0")/../../../..")"

source "$SANDBOX_DIR/Scripts/ShellModules/StandardShellHeader.sh"
source "$SANDBOX_DIR/Scripts/ShellModules/FileUtils.sh"

if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

ECOS_CHECKOUT_DIR="$1"
shift
ECOS_CONFIG_TOOL_BIN_DIR="$1"
shift
ECOS_OBJ_DIR="$1"
shift

create_dir_if_not_exists "$ECOS_OBJ_DIR"

echo
echo "------- Building eCos' Redboot -------"
echo "Buildin in directory $ECOS_OBJ_DIR"

pushd "$ECOS_OBJ_DIR" >/dev/null

export ECOS_REPOSITORY="$ECOS_CHECKOUT_DIR/packages"

CFG_TOOL="$ECOS_CONFIG_TOOL_BIN_DIR/bin/ecosconfig"

echo
echo "------- Creating the eCos' Redboot configuration -------"
CMD="\"$CFG_TOOL\" --enable-debug new orpsoc redboot"
echo "$CMD"
eval "$CMD"

echo
echo "------- Adding the ethernet driver to the eCos' Redboot configuration -------"
CMD="\"$CFG_TOOL\" add CYGPKG_IO_ETH_DRIVERS"
echo "$CMD"
eval "$CMD"


CFG_FILENAME="ecos.ecc"
echo
echo "------- Modifying the $CFG_FILENAME configuration file -------"
# Here we do some crude editing of the configuration file:

CHANGE_MARKER="#  The following setting was added by script $(basename $0)"

# Set a default IP address.
DEF_IP_LINE="cdl_component CYGDAT_REDBOOT_DEFAULT_IP_ADDR {"
IP_ADDR="user_value 1 \"192, 168, 254, 1\""
sed --in-place -e"s/$DEF_IP_LINE/$DEF_IP_LINE\n  $CHANGE_MARKER\n  $IP_ADDR/" "$CFG_FILENAME"

# Disable DHCP/BOOTP, to prevent having to wait for the attempts to timeout
# before using Redboot's console.
NO_BOOTP_LINE="cdl_option CYGSEM_REDBOOT_DEFAULT_NO_BOOTP {"
NO_BOOTP_SETTING="user_value 1"
sed --in-place -e"s/$NO_BOOTP_LINE/$NO_BOOTP_LINE\n  $CHANGE_MARKER\n  $NO_BOOTP_SETTING/" "$CFG_FILENAME"

# Back up the modified configuration file. The eCos configuration tool reparses and regenerates it,
# so our changes are reformatted. However, the original file we changed is useful when developing this script.
cp "$CFG_FILENAME" "${CFG_FILENAME}_as_modified_by_$(basename $0)"

echo
echo "------- Checking the eCos' Redboot configuration -------"
CMD="\"$CFG_TOOL\" check"
echo $CMD
eval "$CMD"

echo
echo "------- Creating the eCos' Redboot build tree -------"
CMD="\"$CFG_TOOL\" tree"
echo $CMD
eval "$CMD"


if [ $ORBUILD_STOP_ON_FIRST_ERROR -eq 0 ]; then
  K_FLAG=-k
else
  K_FLAG=
fi

echo
echo "------- Building eCos' Redboot -------"
CMD="make $K_FLAG --no-builtin-variables"
echo $CMD
eval "$CMD"

popd >/dev/null
