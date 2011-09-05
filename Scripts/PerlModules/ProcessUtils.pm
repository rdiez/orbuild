
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

package ProcessUtils;

use strict;
use warnings;

use File::Temp;

use FileUtils;
use StringUtils;


sub run_process ( $ )
{
  my $cmd_line = shift;

  my $ret = system( $cmd_line );

  if ( $ret == -1 )
  {
    die qq<Failed to execute command line "$cmd_line" with system() call, >.
        qq<the error returned is "$!">;
  }

  my $exit_code   = $ret >> 8;
  my $signal_num  = $ret & 127;
  my $dumped_core = $ret & 128;
  
  if ( $signal_num != 0 || $dumped_core != 0 )
  {
    die "Error: child process \"$cmd_line\" died: " .
        reason_died_from_wait_code( $ret );
  }

  return $exit_code;
}


sub reason_died_from_wait_code ( $ )
{
  my $wait_code = shift;
  
  my $exit_code   = $wait_code >> 8;
  my $signal_num  = $wait_code & 127;
  my $dumped_core = $wait_code & 128;
  
  if ( $signal_num != 0 )
  {
    return "Indication of signal $signal_num.";
  }
  
  if ( $dumped_core != 0 )
  {
    return "Indication of core dump.";
  }

  return "Exit code $exit_code.";
}


sub run_process_capture_output ( $ $ $ )
{
  my $cmd_line = shift;
  my $stdout_capture = shift;  # ref to array
  my $stderr_capture = shift;  # ref to array

  # TODO: for security reasons, try to avoid tmpnam().
  my $child_stdout_file_name = tmpnam();
  my $child_stderr_file_name = tmpnam();

  my $cmd_line_to_use = $cmd_line . " >$child_stdout_file_name 2>$child_stderr_file_name"; 

  my $exit_code = run_process( $cmd_line_to_use );

  eval
  {
    @$stdout_capture = FileUtils::read_text_file( $child_stdout_file_name );
    @$stderr_capture = FileUtils::read_text_file( $child_stderr_file_name );
  };

  if ( $@ )
  {
    die qq<Error reading captured output from child process, > .
        qq<the previous system() call probably failed for command line "$cmd_line", > .
        qq<the error is: $@>;
  }

  unlink( $child_stdout_file_name ) # Hopes that unlink() reports errors like open(), etc.
    or die "Cannot delete file \"$child_stdout_file_name\": $!"; 

  unlink( $child_stderr_file_name ) # Hopes that unlink() reports errors like open(), etc.
    or die "Cannot delete file \"$child_stderr_file_name\": $!"; 

  return $exit_code;
}


sub run_process_capture_single_value_output ( $ )
{
  my $cmd = shift;

  my ( @capturedStdout, @capturedStderr );

  ProcessUtils::run_process_capture_output( $cmd, \@capturedStdout, \@capturedStderr );

  if ( 0 != scalar( @capturedStderr ) )
  {
      die "Child process for command \"$cmd\" failed: " . join( "", @capturedStderr ) . "\n";
  }

  if ( 1 != scalar( @capturedStdout ) )
  {
      die "Unexpected output from child process for command \"$cmd\": " . join( "", @capturedStdout ) . "\n";
  }

  return StringUtils::trim_blanks( $capturedStdout[ 0 ] );
}


1;  # The module returns a true value to indicate it compiled successfully.
