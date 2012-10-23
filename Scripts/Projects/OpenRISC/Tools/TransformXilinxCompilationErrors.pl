#!/usr/bin/perl

# This script is a quick hack that transforms errors like:
#
#   ERROR:HDLCompiler:806 - "../main.vhd" Line 32: Syntax error near "o1".
#
# into:
#
#   /full/path/main.vhd:806: error: Line 32: Syntax error near "o1".
#
# This is so that the compilation errors from the 'fuse' compiler included in the Xilinx Webpack
# can be interpreted by emacs, and the user can click on them to jump to the right line
# in the VHDL or Verilog source code.
#
#
#  ----------------- License -----------------
#
# Copyright (C) 2012 R. Diez
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License version 3 as published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License version 3 for more details.
#
# You should have received a copy of the GNU Affero General Public License version 3
# along with this program.  If not, see L<http://www.gnu.org/licenses/>.
#

use strict;
use warnings; 

use IO::Handle;
use Cwd;

use constant EXIT_CODE_SUCCESS        => 0;
use constant EXIT_CODE_FAILURE_ARG    => 1;
use constant EXIT_CODE_FAILURE_ERR    => 2;


sub write_stderr ( $ )
{
  my $str = shift;

  ( print STDERR $str ) or
      die "Cannot write to standard error: $!\n";
}

sub write_stdout ( $ )
{
  my $str = shift;

  ( print STDOUT $str ) or
      die "Cannot write to standard error: $!\n";
}


#------------------------------------------------------------------------
#
# Collects the new-line characters at the end of the string,
# returns them as a string.
#
# Any combination or number of 0x0D and 0x0A are collected, that is,
# multiple new-line characters or group of characters are collected
# together, so you may want to make sure there's only 1 line in the string passed.
#
# Returns the empty string if no 0x0D or 0x0A characters are present at the end.
#

sub collect_eol_characters ( $ )
{
  my $line = shift;

  # NOTE: The 's' option after m// is needed so that ^ only matches the beginning of the line,
  #       even if there are embedded new-line characters. Otherwise, the following
  #       string fails to collec the trailing new-line characters: "\nab\n\r\r\n".
  #
  # \012 is LF, \n, 10, 0x0A
  # \015 is CR, \r, 13, 0x0D
  #
  # See self-test routine below, for test cases against this regular expression.
  
  my @captured = $line =~ m/ ^              # Beginning of string.
                             .*?            # Anything at the beginning, non greedy.
                            ([\012\015]+)   # Capture the group of new-line characters.
                            $               # End of string.
                           /sx;

  if ( scalar(@captured) < 1 )
  {
    return "";
  }
  else
  {
    return $captured[0];
  }
}


#------------------------------------------------------------------------
#
# Removes any end-of-line character combination from the end of the string.
#

sub remove_trailing_eol ( $ )
{
  my $l = shift;

  my $eol_chars = collect_eol_characters( $l );
  return substr( $l, 0, length($l) - length($eol_chars) );
}


#------------------------------------------------------------------------

sub main ()
{
  # Autoflush helps prevent the warnings and errors getting intermixed
  # when this script is invoked from a shell that is redirecting the output.
  autoflush STDOUT;
  autoflush STDERR;

  if ( scalar(@ARGV) != 0 )
  {
    write_stderr( "\nError running $0: this script takes no arguments." );
    return EXIT_CODE_FAILURE_ARG;
  }


  # while ( ! eof( *STDIN ) )
  for ( ; ; )
  {
    my $line = readline( *STDIN );
    if ( !defined $line )
    {
      last if not $!;
      die "Readline from stdin failed: ". remove_trailing_eol( $! ) . "\n";
    }

    # Transform info lines like this, so that emacs does not identify them as errors:
    #   INFO:HDLCompiler:1769 - Analyzing Verilog file

    my @capturedInfo =
                   $line =~ m/ ^                 # Beginning of string.
                             (INFO):HDLCompiler:
                             (\d+)               # Error number.
                             \x20-\x20           # The string ' - '
                             (.*)                # Anything else.
                             $                   # End of string.
                             /sxo;

    if ( scalar( @capturedInfo ) == 3 )
    {
      write_stdout( $capturedInfo[0] .
                    ":HDLCompiler-" .
                    $capturedInfo[1] .
                    " - " .
                    remove_trailing_eol( $capturedInfo[2] ) .
                    "\n" );
      next;
    }


    # Look for a single-line error message like:
    #   WARNING:HDLCompiler:872 - "/path/filename.v" Line 18: blah blah
    my @capturedSingleLine =
                   $line =~ m/ ^                 # Beginning of string.
                             (ERROR|WARNING):HDLCompiler:
                             (\d+)               # Error number.
                             \x20-\x20"          # The string ' - \"'
                             (.*?)               # Filename, non greedy.
                             "\x20Line\x20       # The string '" Line '.
                             (\d+)               # Line number.
                             :\x20               # The string ': '.
                             (.*)                # Anything else.
                             $                   # End of string.
                             /sxo;

    if ( scalar( @capturedSingleLine ) == 5 )
    {
      my $absFilepath = Cwd::abs_path( $capturedSingleLine[2] );
      if ( not defined $absFilepath )
      {
        # This can happen with precompiled libraries, as the original source code
        # is not at the same location (if available at all).
        $absFilepath = $capturedSingleLine[2];
      }

      write_error_message( $capturedSingleLine[0],
                           $capturedSingleLine[1],
                           $absFilepath,
                           $capturedSingleLine[3],
                           remove_trailing_eol( $capturedSingleLine[4] ) );
      next;
    }


    # A first line like:
    #   ERROR:HDLCompiler:806 -

    my @captured = $line =~ m/ ^                 # Beginning of string.
                             (ERROR|WARNING):HDLCompiler:
                             (\d+)               # Error number.
                             \x20-               # The string ' -'
                             $                   # End of string.
                             /sxo;

    if ( scalar( @captured ) == 0 )
    {
      write_stdout( $line );
      next;
    }

    # A second line like:
    #   "/path/filename.v" Line 14: Syntax

    my $line2 = readline( *STDIN );

    my @captured2 = $line2 =~ m/ ^                # Beginning of string.
                                \s*               # Some blanks
                                "                 # A double-quotation mark ('"').
                                (.*?)             # Filename, non greedy.
                                "\x20Line\x20     # The string '" Line '.
                                (\d+)             # Line number.
                                :\x20             # The string ': '.
                                (.*)              # Anything else.
                                $                 # End of string.
                               /sxo;

    if ( scalar( @captured2 ) == 0 )
    {
      write_stdout( $line2 );
      next;
    }

    if ( scalar( @captured2 ) != 3 )
    {
      die "Internal error during regex matching.\n";
    }

    write_error_message( $captured[0],
                         $captured[1],
                         Cwd::abs_path( $captured2[0] ),
                         $captured2[1],
                         remove_trailing_eol( $captured2[2] ) );
  }

  return EXIT_CODE_SUCCESS;
}


sub write_error_message ( $ $ $ $ $ )
{
  my $errorOrWarning = shift;
  my $errorNumber    = shift;
  my $filename       = shift;
  my $lineNumber     = shift;
  my $errorMessage   = shift;

  my $type = lc $errorOrWarning;

  write_stdout( "$filename:$lineNumber: $type $errorNumber: $errorMessage\n" );
}


# ----------- Entry point -----------

# Just call the main() routine. Note that main() returns the process exit code.

my $ret_val;

eval
{
  $ret_val = main();
};

if ( $@ )
{
  write_stderr( "\nError running $0: $@" );
  exit EXIT_CODE_FAILURE_ERR;
}

exit $ret_val;

# End of program
