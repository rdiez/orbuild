
# Print the executed command with proper quoting, so that the user can
# copy-and-paste the command from the log file and expect it to work.

print_command ()
{
  for arg
  do
	printf '%q ' "$arg"
  done
  printf "\n"
} 
