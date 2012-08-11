
# Print the executed command with proper quoting, so that the user can
# copy-and-paste the command from the log file and expect it to work.
#
# Examples of usage:
#
#   REMOVE_SOME_PREFIX_BEFORE_EXECUTING_WITH_REST_OF_ARGS="$1"
#   shift
#   print_command "$@"
#   "$@"
#
#   CMD="my-command --my-arg"
#   print_command $CMD
#   $CMD
#
# However, if you use 'eval' to run commands, do not use 'print_command', use 'echo' instead,
# or 'printf' in order to print extra newline characters portably:
#
#   CMD="my-command --my-arg"
#   printf "$CMD\n\n"
#   eval "$CMD"

print_command ()
{
  for arg
  do
	printf '%q ' "$arg"
  done
  printf "\n"
} 
