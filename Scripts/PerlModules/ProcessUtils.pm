
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

package ProcessUtils;

use strict;
use warnings;

use File::Temp;
use Fcntl qw/F_SETFD F_GETFD FD_CLOEXEC/;

use FileUtils;
use StringUtils;


sub run_process_exit_code_0 ( $ )
{
  my $cmdLine = shift;

  my $exitCode = ProcessUtils::run_process( $cmdLine );

  if ( $exitCode != 0 )
  {
    die "Error running the following command line: $cmdLine\n";
  }
}


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


sub clear_cloexec_flag ( $ )
{
  my $fh = shift;

  my $oldFlags = fcntl( $fh, F_GETFD, 0 );
  my $newFlags = $oldFlags & ~FD_CLOEXEC;

  fcntl( $fh, F_SETFD, $newFlags ) or
    die "Cannot clear close-on-exec flag (FD_CLOEXEC) on file descriptor: $!\n";
}


sub run_process_capture_output ( $ $ $ )
{
  my $cmd_line = shift;
  my $stdout_capture = shift;  # ref to array
  my $stderr_capture = shift;  # ref to array

  use constant USE_TMPNAM => 0;  # tmpnam() has known security and timing issues.

  my $child_stdout_file_name;
  my $child_stderr_file_name;

  my $stdoutFile;
  my $stderrFile;

  if ( USE_TMPNAM )
  {
    $child_stdout_file_name = tmpnam();
    $child_stderr_file_name = tmpnam();
  }
  else
  {
    $stdoutFile = File::Temp->new( UNLINK => 1 );
    $stderrFile = File::Temp->new( UNLINK => 1 );

    clear_cloexec_flag( $stdoutFile );
    clear_cloexec_flag( $stderrFile );

    # For standard applications, the documentation for File::Temp suggests using a filename like /dev/fd/123,
    # but Bash recognises those filenames and handles them differently, so we cannot do that here.
    # This is an excerpt from the bash documentation:
    #    Bash handles several filenames specially when they are used in redirections, as described in the following table:
    #      /dev/fd/fd    If fd is a valid integer, file descriptor fd is duplicated.

    $child_stdout_file_name = "&" . fileno( $stdoutFile );
    $child_stderr_file_name = "&" . fileno( $stderrFile );
  }

  my $cmd_line_to_use = $cmd_line . " >$child_stdout_file_name 2>$child_stderr_file_name"; 

  my $exit_code = run_process( $cmd_line_to_use );

  eval
  {
    if ( USE_TMPNAM )
    {
      @$stdout_capture = FileUtils::read_text_file( $child_stdout_file_name );
      @$stderr_capture = FileUtils::read_text_file( $child_stderr_file_name );
    }
    else
    {
      $stdoutFile->seek( 0, SEEK_SET ) or die "Cannot seek to the beginning of the file: $!\n";
      $stderrFile->seek( 0, SEEK_SET ) or die "Cannot seek to the beginning of the file: $!\n";

      @$stdout_capture = readline( $stdoutFile );
      @$stderr_capture = readline( $stderrFile );
    }
  };

  if ( $@ )
  {
    die qq<Error reading captured output from child process, > .
        qq<the previous system() call probably failed for command line "$cmd_line_to_use", > .
        qq<the error is: $@>;
  }

  if ( USE_TMPNAM )
  {
    unlink( $child_stdout_file_name ) # Hopes that unlink() reports errors like open(), etc.
        or die "Cannot delete file \"$child_stdout_file_name\": $!"; 

    unlink( $child_stderr_file_name ) # Hopes that unlink() reports errors like open(), etc.
        or die "Cannot delete file \"$child_stderr_file_name\": $!"; 
  }

  if ( $exit_code != 0 )
  {
    die "Error running process, the exit code was $exit_code, the command line was: $cmd_line_to_use\n";
  }
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
