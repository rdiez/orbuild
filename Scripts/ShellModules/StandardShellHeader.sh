
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

abort ()
{
    echo >&2 && echo "Error in script \"$0\": $*" >&2
    exit 1
}

if [ "${BASH_VERSION:-first}" != "${BASH_VERSION:-second}" ]
then
  abort "Variable \"BASH_VERSION\" is not set, did you run this script with sh instead of bash?"
fi

if [ "$BASH_VERSION" \< "3.2" ]
then
    abort "This bash version \"$BASH_VERSION\" is too old."
fi

if [ -o errexit ]
then
    :  # Do nothing
else
    abort "Bash option errexit must be turned on before including this file."
fi

set -o nounset
set -o pipefail
set -o posix    # Make command substitution subshells inherit the errexit option.
                # Otherwise, the 'command' in this example will not fail for non-zero exit codes:  echo "$(command)"
