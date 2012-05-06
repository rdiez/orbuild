#!/usr/bin/perl

=head1 OVERVIEW

This tool compares the given test log file with the expected test results.
It's a simplified 'expect' replacement for automated tests suites
that operate like DejaGnu.

See any of the *.TestResults files for an example of how to write such files.

=head1 USAGE

S<perl AnalyseLog.pl [options] E<lt>file.logE<gt> E<lt>expected_lines.txtE<gt>>

=head1 OPTIONS

=over

=item *

B<-h, --help>

Print this help text.

=item *

B<--license>

Print the license.

=back

=head1 EXIT CODE

Exit code: 0 on success, some other value on error.

=head1 FEEDBACK

Please send feedback to rdiezmail-openrisc at yahoo.de

=head1 LICENSE

Copyright (C) 2012 R. Diez

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License version 3 as published by
the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License version 3 for more details.

You should have received a copy of the GNU Affero General Public License version 3
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut


use strict;
use warnings; 

use FindBin;
use Getopt::Long;
use IO::Handle;

use constant THIS_SCRIPT_DIR => $FindBin::Bin;

use lib THIS_SCRIPT_DIR . "/../../../PerlModules";
use MiscUtils;
use FileUtils;
use AGPL3;

use constant SCRIPT_NAME => $0;

use integer;


use constant RT_REPORT => 1;
use constant RT_EXIT   => 2;


# ----------- main routine, the script entry point is at the bottom -----------

sub main ()
{
  my $arg_help             = 0;
  my $arg_h                = 0;
  my $arg_license          = 0;

  my $result = GetOptions(
                 'help'                =>  \$arg_help,
                 'h'                   =>  \$arg_h,
                 'license'             =>  \$arg_license
                );

  if ( not $result )
  {
    # GetOptions has already printed an error message.
    return MiscUtils::EXIT_CODE_FAILURE_ARGS;
  }

  if ( $arg_help || $arg_h )
  {
    write_stdout( "\n" . MiscUtils::get_cmdline_help_from_pod( SCRIPT_NAME ) );
    return MiscUtils::EXIT_CODE_SUCCESS;
  }

  if ( $arg_license )
  {
    write_stdout( AGPL3::get_agpl3_license_text() );
    return MiscUtils::EXIT_CODE_SUCCESS;
  }


  if ( 2 != scalar @ARGV )
  {
    die "Invalid number of arguments. Run this tool with the --help option for usage information.\n";
  }

  my $logFilename    = shift @ARGV;
  my $expectFilename = shift @ARGV;

  write_stdout( qq<Analysing test log file "$logFilename" with expected data in "$expectFilename"...\n> );

  open( my $logFile, "<$logFilename" )
    or die "Cannot open file \"$logFilename\": $!\n";

  binmode( $logFile );  # Also avoids CRLF conversion.


  open( my $expectFile, "<$expectFilename" )
    or die "Cannot open file \"$expectFilename\": $!\n";

  binmode( $expectFile );  # Also avoids CRLF conversion.
  
  analyse_log( $logFile, $expectFile, $logFilename, $expectFilename );

  FileUtils::close_or_die( $logFile );
  FileUtils::close_or_die( $expectFile  );

  write_stdout( qq<Log analysis completed, the test log matches the expected results.\n> );

  return MiscUtils::EXIT_CODE_SUCCESS;
}


sub analyse_log ( $ $ )
{
  my $logFile        = shift;
  my $expectFile     = shift;
  my $logFilename    = shift;
  my $expectFilename = shift;

  my $logFileLineNumber = 0;

  for ( my $expectFileLineNumber = 1; ; ++$expectFileLineNumber )
  {
    my $expectLine = readline( $expectFile );

    last if not defined $expectLine;

    $expectLine = strip_comment( $expectLine );

    $expectLine = StringUtils::trim_blanks( $expectLine );

    next if ( $expectLine eq "" );

    # write_stdout( "Expect line: $expectLine\n");

    my ( $expectedResultType, $expectedResultValue ) = parse_result( $expectLine );

    if ( not defined $expectedResultType )
    {
      die qq<Invalid expected expression \"$expectLine\" at line $expectFilename:$expectFileLineNumber.\n>;
    }

    my ( $nextResultType, $nextResultValue, $nextResultStr ) = get_next_result( $logFile, \$logFileLineNumber );

    if ( not defined $nextResultType )
    {
      die qq<End of log file reached while looking for result "$expectLine" at line $expectFilename:$expectFileLineNumber.\n>;
    }

    # write_stdout( "Next result in log: $nextResult\n");

    if ( $nextResultType != $expectedResultType or $nextResultValue ne $expectedResultValue )
    {
      die qq<The log file result "$nextResultStr" does not match the expected result "$expectLine". File positions are: "$expectFilename:$expectFileLineNumber" and "$logFilename:$logFileLineNumber".\n>;
    }
  }

  
  # Check that the log file does not contain any more results than specified in the expect file.

  my ( $nextResultType, $nextResultValue, $nextResultStr ) = get_next_result( $logFile );

  if ( defined $nextResultType )
  {
    die qq<End of expected file reached while trying to match result "$nextResultStr" at line $logFilename:$logFileLineNumber.\n>;
  }
}


sub get_next_result ( $ $ )
{
  my $logFile = shift;
  my $logFileLineNumber = shift;  # Reference to scalar with the line number.

  for ( ; ; )
  {
    my $logLine = readline( $logFile );

    return ( undef, undef, undef ) if not defined( $logLine );

    ++$$logFileLineNumber;

    $logLine = StringUtils::trim_blanks( $logLine );

    next if ( $logLine eq "" );

    # write_stdout( "Log line: $logLine\n");

    my ( $resultType, $resultValue ) = parse_result( $logLine );

    # Ignore anything that cannot be parsed as a test result.
    next if not defined $resultType;

    return ( $resultType, $resultValue, $logLine );
  }
}


sub parse_result ( $ )
{
  my $str = shift;

  my @reportParts = $str =~ m/  ^
                                report\(
                                (.+?)
                                \);
                                $     /ox;

  # write_stdout( "Log line: $str, match count: " . scalar(@reportParts) . "\n" );

  if ( scalar( @reportParts ) == 1 )
  {
      return ( RT_REPORT, $reportParts[ 0 ] );
  }


  my @exitParts = $str =~ m/  ^
                              exit\(
                              (.+?)
                              \)
                              $     /ox;

  if ( scalar( @exitParts ) == 1 )
  {
      return ( RT_EXIT, $exitParts[ 0 ] );
  }

  return ( undef, undef );
}


sub strip_comment ( $ )
{
    my $str = shift;

    my $commentCharIndex = index( $str, '#' );

    if ( $commentCharIndex == -1 )
    {
        return $str;
    }
    else
    {
        return substr( $str, 0, $commentCharIndex );
    }
}


#------------------------------------------------------------------------

MiscUtils::entry_point( \&main, SCRIPT_NAME );
