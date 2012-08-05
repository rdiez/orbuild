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


echo "------- Modifying the IP configuration -------"
# Here we do some crude editing of the configuration file:

# 1) Set a default IP address.
CFG_FILENAME="ecos.ecc"
DEF_IP_LINE="cdl_component CYGDAT_REDBOOT_DEFAULT_IP_ADDR {"
IP_ADDR="user_value 1 \"192, 168, 254, 1\""
sed --in-place -e"s/$DEF_IP_LINE/$DEF_IP_LINE\n$IP_ADDR/" "$CFG_FILENAME"

# 2) Disable DHCP/BOOTP, to prevent having to wait for the attempts to timeout
#    before using Redboot's console.
NO_BOOTP_LINE="cdl_option CYGSEM_REDBOOT_DEFAULT_NO_BOOTP {"
NO_BOOTP_SETTING="user_value 1"
sed --in-place -e"s/$NO_BOOTP_LINE/$NO_BOOTP_LINE\n$NO_BOOTP_SETTING/" "$CFG_FILENAME"


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
