
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

package StringUtils;

use strict;
use warnings;


#------------------------------------------------------------------------
#
# Returns a true value if the string ends in the given 'ending'.
#

sub str_ends_with ( $ $ )
{
  my $str    = shift;
  my $ending = shift;
  
  if ( length($str) < length($ending) )
  {
    return 0;
  }

  return substr($str, -length($ending), length($ending)) eq $ending;
}


#------------------------------------------------------------------------
#
# Returns a true value if the string starts with the given 'beginning' argument.
#

sub str_starts_with ( $ $ )
{
  my $str = shift;
  my $beginning = shift;
  
  if ( length($str) < length($beginning) )
  {
    return 0;
  }

  return substr($str, 0, length($beginning)) eq $beginning;
}


#------------------------------------------------------------------------

sub str_remove_optional_suffix ( $ $ )
{
  my $str    = shift;
  my $ending = shift;

  if ( str_ends_with( $str, $ending ) )
  {
    return substr( $str, 0, length( $str ) - length( $ending ) );
  }
  else
  {
    return $str;
  }
}


#------------------------------------------------------------------------
#
# Useful to parse integer numbers.
#

sub has_non_digits ( $ )
{
  my $str = shift;

  my $scalar = $str =~ m/\D/;

  return $scalar;
}


#------------------------------------------------------------------------
#
# Removes leading and trailing blanks.
#
# Perl's definition of whitespace (blank characters) for the \s
# used in the regular expresion includes, among others, spaces, tabs,
# and new lines (\r and \n).
#

sub trim_blanks ( $ )
{
  my $retstr = shift;
  
  # NOTE: Removing blanks could perhaps be done faster with transliterations (tr///).
  
  # Strip leading blanks.
  $retstr =~ s/^\s*//;
  # Strip trailing blanks.
  $retstr =~ s/\s*$//;

  return $retstr; 
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
                           /osx;


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


1;  # The module returns a true value to indicate it compiled successfully.
