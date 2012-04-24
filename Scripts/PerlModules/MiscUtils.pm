
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

package MiscUtils;

require Exporter;
  @ISA = qw(Exporter);

  # Symbols to export by default.
  @EXPORT = qw( write_stdout close_or_die );

  # Symbols to export on request.
  @EXPORT_OK = qw();

use strict;
use warnings;

use Pod::Usage;
use IO::Handle;


use constant EXIT_CODE_SUCCESS => 0;
use constant EXIT_CODE_FAILURE_ARGS  => 1;
use constant EXIT_CODE_FAILURE_ERROR => 2;

use constant TRUE  => 1;
use constant FALSE => 0;


#------------------------------------------------------------------------

sub write_stdout ( $ )
{
  my $str = shift;

  ( print STDOUT $str ) or
     die "Error writing to standard output: $!\n";
}


#------------------------------------------------------------------------
#
# Thin wrapper around close().
#

sub close_or_die ( $ )
{
  close ( $_[0] ) or die "Cannot close file descriptor: $!";
}


#------------------------------------------------------------------------

sub get_cmdline_help_from_pod ( $ )
{
  my $pathToThisScript = shift;

  my $memFileContents = "";

  open( my $memFile, '>', \$memFileContents )
      or die "Cannot open log memory file: $@";

  binmode( $memFile );  # Avoids CRLF conversion.


  pod2usage( -exitval    => "NOEXIT",
             -verbose    => 2,
             -noperldoc  => 1,  # Perl does not come with the perl-doc package as standard (at least on Debian 4.0).
             -input      => $pathToThisScript,
             -output     => $memFile );

  $memFile->close();

  return $memFileContents;
}


#------------------------------------------------------------------------

sub entry_point ( $ $ )
{
  my $mainRoutine = shift;
  my $scriptName  = shift;

  eval
  {
    my $exitCode = &$mainRoutine();
    exit $exitCode;
  };

  my $errorMessage = $@;

  # We want the error message to be the last thing on the screen,
  # so we need to flush the standard output first.
  STDOUT->flush();

  print STDERR "\nError running $scriptName: $errorMessage";

  exit EXIT_CODE_FAILURE_ERROR;
}


#------------------------------------------------------------------------
#
# Formats an elapsed in seconds into a human-friendly string,
# with hours, minutes, etc.
#
# Code copied from http://perlmonks.thepen.com/110550.html
#

  sub plural_suffix ( $ )
  {
    my $number = shift;

    return ( $number == 1 ) ? "" : "s";
  }

sub human_friendly_elapsed_time ( $ )
{
  my $seconds = shift;
	
  my ( $weeks, $days, $hours, $minutes, $sign, $res ) = qw/0 0 0 0 0/;

  $sign = $seconds == abs $seconds ? '' : '-';
  $seconds = abs $seconds;

  ($seconds, $minutes) = ($seconds % 60, int($seconds / 60)) if $seconds;
  ($minutes, $hours  ) = ($minutes % 60, int($minutes / 60)) if $minutes;
  ($hours  , $days   ) = ($hours   % 24, int($hours   / 24)) if $hours;
  ($days   , $weeks  ) = ($days    %  7, int($days    /  7)) if $days;

  $res = sprintf '%d second%s', $seconds, plural_suffix( $seconds );
  $res = sprintf "%d minute%s $res", $minutes, plural_suffix( $minutes ) if $minutes or $hours or $days or $weeks;
  $res = sprintf "%d hour%s $res"  , $hours  , plural_suffix( $hours   ) if $hours   or $days  or $weeks;
  $res = sprintf "%d day%s $res"   , $days   , plural_suffix( $days    ) if $days    or $weeks;
  $res = sprintf "%d week%s $res"  , $weeks  , plural_suffix( $weeks   ) if $weeks;

  return "$sign$res";
}


1;  # The module returns a true value to indicate it compiled successfully.

