
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
  close ( $_[0] ) or die "Can't close file descriptor: $!";
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


1;  # The module returns a true value to indicate it compiled successfully.

