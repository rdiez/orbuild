
# Returns the number of processors + 1. Probably not the best value for make -j .

get_make_j_val ()
{
  # $1 = name of the variable name to return the value in

  local GET_MAKE_J_VAL_RET_VAR_NAME="$1"
  local -i GET_MAKE_J_VAL_RET_VALUE

  local -i GET_MAKE_J_VAL_PROCESSOR_COUNT

  # Environment variable NUMBER_OF_PROCESSORS is always set under Windows.
  # Later note: Cygwin seems to support getconf _NPROCESSORS_ONLN too (as of Feb 2012).
  if [ "${NUMBER_OF_PROCESSORS:-first}" == "${NUMBER_OF_PROCESSORS:-second}" ]
  then

    GET_MAKE_J_VAL_PROCESSOR_COUNT=$NUMBER_OF_PROCESSORS

  else

    GET_MAKE_J_VAL_PROCESSOR_COUNT="$(getconf _NPROCESSORS_ONLN)"

  fi

  if [ $GET_MAKE_J_VAL_PROCESSOR_COUNT -lt 1 ]
  then
    abort "Cannot determine the number of processors."
  fi

  GET_MAKE_J_VAL_RET_VALUE=$(( GET_MAKE_J_VAL_PROCESSOR_COUNT + 1 ))

  eval "$GET_MAKE_J_VAL_RET_VAR_NAME=\$GET_MAKE_J_VAL_RET_VALUE"
} 
