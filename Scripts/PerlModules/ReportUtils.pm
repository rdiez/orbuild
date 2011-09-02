
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

package ReportUtils;

use strict;
use warnings;

use XML::Parser;

use StringUtils;
use FileUtils;
use ConfigFile;


sub collect_all_reports ( $ $ $ )
{
  my $dirname            = shift;
  my $reportExtension    = shift;
  my $allReportsArrayRef = shift;

  my $globPattern = FileUtils::cat_path( $dirname, "*" . $reportExtension );

  my @matchedFiles = File::Glob::bsd_glob( $globPattern, &File::Glob::GLOB_ERR | &File::Glob::GLOB_NOSORT );

  if ( &File::Glob::GLOB_ERROR )
  {
    die "Error listing existing directories: $!\n";
  }

  foreach my $filename ( @matchedFiles )
  {
    # print "File found: $filename\n";

    if ( not -f $filename )
    {
      die "File \"$filename\" is not a regular file.\n" 
    }

    my %allEntries;

    load_report( $filename, \%allEntries );

    push @$allReportsArrayRef, \%allEntries;
  }
}


sub load_report ( $ $ )
{
  my $filename          = shift;
  my $allEntriesHashRef = shift;

  ConfigFile::read_config_file( $filename, $allEntriesHashRef );

  my %allPossibleKeywords = ( UserFriendlyName => 0,
                              ExitCode         => 0,
                              LogFile          => 0,
                              StartTimeLocal   => 0,
                              StartTimeUTC     => 0,
                              FinishTimeLocal  => 0,
                              FinishTimeUTC    => 0,
                              ElapsedSeconds   => 0 );

  # Check that all keywords are present in the report file.

  foreach my $key ( keys %$allEntriesHashRef )
  {
    my $val = $allPossibleKeywords{ $key };

    if ( not defined $val )
    {
      die "Invalid setting \"$key\" in report file \"$filename\"\n";
    }

    # Routine ConfigFile::read_config_file() already checks whethere
    # there are duplicates:
    #   if ( $val != 0 )
    #   {
    #     die "Duplicate setting \"$key\" in report file \"$filename\"\n";
    #   }

    $allPossibleKeywords{ $key } = 1;
  }

  foreach my $key ( keys %allPossibleKeywords )
  {
    if ( $allPossibleKeywords{ $key } == 0 )
    {
      die "Missing setting \"$key\" in report file \"$filename\"\n";
    }
  }
}


sub check_valid_html ( $ )
{
  my $str = shift;

  # At the moment, the only check is that the string is valid XML,
  # but we could probably test more.
  my $parser = XML::Parser->new();

  $parser->parse( $str );
}


sub replace_marker ( $ $ $ )
{
  my $strRef      = shift;  # Reference to a string, like this:  \$string
  my $markerName  = shift;
  my $markerValue = shift;

  # Markers look like this:  ${ NAME }
	
  $$strRef =~ s/\$\{\s*$markerName\s*\}/$markerValue/g;
}


sub sort_reports ( $ $ )
{
  my $allReports               = shift;
  my $userFriendlyNameAtTheTop = shift;

  my $comparator = sub ( $ $ )  #  "local *comparator" is allegedly better as "my $comparator",
  {                             #  especially for recursive nested routines, but you get a compilation warning.
    my $left  = shift;
    my $right = shift;

    if ( $left ->{ "UserFriendlyName" } eq $userFriendlyNameAtTheTop )
    {
        return -1;
    }

    if ( $right ->{ "UserFriendlyName" } eq $userFriendlyNameAtTheTop )
    {
        return +1;
    }

    my $leftExitCodeSuccess  =  0 == $left ->{ "ExitCode" };
    my $rightExitCodeSuccess =  0 == $right->{ "ExitCode" };


    # Failed tasks have priority.

    if ( $leftExitCodeSuccess )
    {
      if ( $rightExitCodeSuccess )
      {
        # Nothing to do here, drop below.
      }
      else
      {
        return +1;
      }
    }
    else
    {
      if ( $rightExitCodeSuccess )
      {
        return -1;
      }
      else
      {
        # Nothing to do here, drop below.
      }
    }

    # We could sort all failed tasks by their timestamp, as it's roughly
    # the dependency order, that is, the order in which they were executed.
    # However, I'm not certain that sorting by name is not actually better,
    # as it allows the user to skip at once groups of uninteresting failures.

    return $left->{ "UserFriendlyName" }  cmp  $right->{ "UserFriendlyName" };
  };


  my @sortedReports = sort $comparator @$allReports;

  return @sortedReports;
}


1;  # The module returns a true value to indicate it compiled successfully.

