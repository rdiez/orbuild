#!/usr/bin/perl

=head1 OVERVIEW

Generates an HTML report of the last orbuild run.

=head1 USAGE

perl GenerateBuildReport.pl <internal reports dir> <public reports base path> <public reports subdir (without path)> <html output filename (without path)>

=head1 OPTIONS

-h, --help, --version, --license

--title <some text>

--topLevelReportFilename <myfile.report>

--componentGroupsFilename <ComponentGroups.lst>

--subprojectsFilename <Subprojects.lst>

--startTimeUtc <time string to display in the report>  (if not present, the start time of the the top-level report is taken)

--elapsedTime <elapsed time string to display in the report>

--failedCountFilename <filename>

=head1 EXIT CODE

Exit code: 0 on success, some other value on error.

=head1 FEEDBACK

Please send feedback to rdiezmail-openrisc at yahoo.de

=head1 LICENSE

Copyright (C) 2011 R. Diez

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
use integer;  # There is no reason to resort to floating point in this script.

use Getopt::Long;
use HTML::Entities;
use URI::Escape;
use FindBin;
use File::Glob;

use constant THIS_SCRIPT_DIR => $FindBin::Bin;

use lib THIS_SCRIPT_DIR . "/../PerlModules";
use MiscUtils;
use FileUtils;
use StringUtils;
use ReportUtils;
use ProcessUtils;
use AGPL3;

use constant SCRIPT_NAME => $0;

use constant APP_NAME    => "GenerateReport.pl";
use constant APP_VERSION => "0.20";  # If you update the version number, update also the perldoc text above if needed.

use constant REPORT_EXTENSION => ".report";
use constant LOG_EXTENSION    => ".txt";

use constant SUBPROJECTS_REPORTS_DIR => "Subprojects";


# ----------- main routine, the script entry point is at the bottom -----------

sub main ()
{
  my $arg_help             = 0;
  my $arg_h                = 0;
  my $arg_version          = 0;
  my $arg_license          = 0;
  my $arg_startTimeUtc     = "";
  my $arg_elapsedTime      = "";
  my $arg_title            = "orbuild report";
  my $arg_topLevelReportFilename  = "";
  my $arg_componentGroupsFilename = "";
  my $arg_subprojectsFilename     = "";
  my $arg_failedCountFilename     = "";

  my $result = GetOptions(
                 'help'                =>  \$arg_help,
                 'h'                   =>  \$arg_h,
                 'version'             =>  \$arg_version,
                 'license'             =>  \$arg_license,
                 'startTimeUtc=s'      =>  \$arg_startTimeUtc,
                 'elapsedTime=s'       =>  \$arg_elapsedTime,
                 'title=s'             =>  \$arg_title,
                 'topLevelReportFilename=s'  => \$arg_topLevelReportFilename,
                 'componentGroupsFilename=s' => \$arg_componentGroupsFilename,
                 'subprojectsFilename=s'     => \$arg_subprojectsFilename,
                 'failedCountFilename=s'     => \$arg_failedCountFilename
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

  if ( $arg_version )
  {
    write_stdout( "@{[APP_NAME]} version @{[APP_VERSION]}\n" );
    return MiscUtils::EXIT_CODE_SUCCESS;
  }

  if ( $arg_license )
  {
    write_stdout( AGPL3::get_agpl3_license_text() );
    return MiscUtils::EXIT_CODE_SUCCESS;
  }

  if ( scalar( @ARGV ) != 4 )
  {
    die "Invalid number of arguments. Run this program with the --help option for usage information.\n";
  }

  my $reportsDir              = shift @ARGV;
  my $outputBaseDir           = shift @ARGV;
  my $outputSubDir            = shift @ARGV;
  my $htmlOutputFilename      = shift @ARGV;

  my $subprojectsReportsDir = FileUtils::cat_path( $outputBaseDir, SUBPROJECTS_REPORTS_DIR );

  FileUtils::create_folder_if_does_not_exist( $subprojectsReportsDir );

  write_stdout( "Collecting reports...\n" );

  my %componentToGroupLookup;  # Key: programmatic component name, Value: group name.

  if ( $arg_componentGroupsFilename ne "" )
  {
    my %componentGroupsFileContents;
    ConfigFile::read_config_file( $arg_componentGroupsFilename, \%componentGroupsFileContents );

    foreach my $grpName ( keys %componentGroupsFileContents )
    {
      my $componentStr = $componentGroupsFileContents{ $grpName };
      # write_stdout( "Grp: $grpName, components: $componentStr\n" );

      my @allComponentNames = split( "\\s+", $componentStr );

      foreach my $programmaticComponentName ( @allComponentNames )
      {
        if ( exists $componentToGroupLookup{ $programmaticComponentName } )
        {
          die "Duplicate programmatic component name \"$programmaticComponentName\" found in the component group definitions.\n";
        }

        $componentToGroupLookup{ $programmaticComponentName } = $grpName;
      }
    }
  }

  my %subprojectsFileContents;

  if ( $arg_subprojectsFilename ne "" )
  {
    ConfigFile::read_config_file( $arg_subprojectsFilename, \%subprojectsFileContents );

    if ( 0 )  # For debugging purposes only.
    {
      foreach my $subprojectName ( keys %subprojectsFileContents )
      {
        my $subprojectReportFilename = $subprojectsFileContents{ $subprojectName };
        write_stdout( "Subproject: $subprojectName, report path: $subprojectReportFilename\n" );
      }
    }
  }

  my $makefileUserFriendlyName = "";

  if ( $arg_topLevelReportFilename eq "" )
  {
    if ( $arg_startTimeUtc eq "" )
    {
      die "If there is no top-level report, you need to specify the --startTimeUtc argument.\n";
    }
  }
  else
  {
    my %makefileReportEntries;

    ReportUtils::load_report( $arg_topLevelReportFilename, undef, \%makefileReportEntries );
    $makefileUserFriendlyName = $makefileReportEntries{ "UserFriendlyName" };

    if ( $arg_startTimeUtc eq "" )
    {
      $arg_startTimeUtc = $makefileReportEntries{ "StartTimeUTC" };
    }
  }

  write_stdout( "Generating HTML report...\n" );

  my @allReports;
  # At the moment, the makefile report is in the same directory as all others,
  # so it will be found again later.
  #   push @allReports, \%makefileReportEntries;

  my $failedCount;
  ReportUtils::collect_all_reports( $reportsDir, REPORT_EXTENSION, undef, \@allReports, \$failedCount );
  my $componentCount = scalar @allReports;


  # This loop performs 2 separate tasks:
  #   1) Mark all the subproject reports, copy the subproject reports to the main report subdirectory.
  #   2) Classify the reports into groups.

  my @topLevelReports;
  my %groupToReports;  # Key: group name, Value: referece to an array of reports.

  foreach my $report( @allReports )
  {
    my $programmaticComponentName = $report->{ "ProgrammaticName" };

    my $subprojectReportFilename = $subprojectsFileContents{ $programmaticComponentName };

    if ( defined $subprojectReportFilename )
    {
      set_report_setting( $report, "ReportType", ReportUtils::RT_SUBPROJECT );

      my ( $volume, $directories, $filename ) = File::Spec->splitpath( $subprojectReportFilename );
      my $subprojectReportDir = FileUtils::cat_path( $volume, $directories );
      $subprojectReportDir = StringUtils::str_remove_optional_suffix( $subprojectReportDir, "/" );
      my $destDir = FileUtils::cat_path( $subprojectsReportsDir, $programmaticComponentName );

      FileUtils::recreate_dir( $destDir );

      # Copy all files and directories recursively.
      # Alternatively, see http://stackoverflow.com/questions/227613/how-can-i-copy-a-directory-recursively-and-filter-filenames-in-perl

      if ( -d $subprojectReportDir )
      {
        my $copyCmd = qq< cp -r -t "$destDir" "$subprojectReportDir" >;
        # write_stdout( "Copy command: $copyCmd\n" );
        ProcessUtils::run_process_exit_code_0( $copyCmd );
      }

      my ( $volume2, $directories2, $dirname2 ) = File::Spec->splitpath( $subprojectReportDir );
      my $drillDownLink = FileUtils::cat_path( SUBPROJECTS_REPORTS_DIR, $programmaticComponentName, $dirname2, $filename );
      set_report_setting( $report, "DrillDownLink", $drillDownLink );
    }


    # write_stdout( "Processing report for component $programmaticComponentName ...\n" );
    my $groupName = $componentToGroupLookup{ $programmaticComponentName };

    if ( defined $groupName )
    {
      my $existing = $groupToReports{ $groupName };

      if ( defined $existing )
      {
        push @$existing, $report;
      }
      else
      {
        my @new_elem;
        push @new_elem, $report;
        $groupToReports{ $groupName } = \@new_elem;
      }
    }
    else
    {
      push @topLevelReports, $report;
    }
  }


  # Add one fake report per group.

  foreach my $groupName ( keys %groupToReports )
  {
    my %fakeReport;

    $fakeReport{ "UserFriendlyName" } = $groupName;

    my $allGroupReports = $groupToReports{ $groupName };

    my $allOk = MiscUtils::TRUE;

    foreach my $report ( @$allGroupReports )
    {
      if ( $report->{ "ExitCode" } != 0 )
      {
        $allOk = MiscUtils::FALSE;
        last;
      }
    }

    # Fake an exit code.
    $fakeReport{ "ExitCode" } = $allOk ? 0 : 1;

    set_report_setting( \%fakeReport, "ReportType", ReportUtils::RT_GROUP );

    push @topLevelReports, \%fakeReport;
  }


  my $defaultEncoding = ReportUtils::get_default_encoding();
  my $injectedHtml = "";


  # Generate the top-level table.

  $injectedHtml .= generate_table_header();
  $injectedHtml .= generate_report_table_entries( \@topLevelReports, $makefileUserFriendlyName, $outputSubDir, $defaultEncoding );
  $injectedHtml .= generate_table_footer();


  # Generate one table per group.

  # Sort the groups by name.
  my @sortedGroupNames = sort keys %groupToReports;

  if ( 0 != scalar @sortedGroupNames )
  {
    $injectedHtml .= "<br/> <hr/> \n";
    $injectedHtml .= "<h1>Group report breakdown</h1>\n";

    # Alternative text:
    #   "Anything else below is a break-down of the overall build results above."
    #   "In order to find out if anything failed at all, you only need to look at the top-level results."
    $injectedHtml .= "<p>Please note that any build errors beyond this point are also reflected in aggregated form in the summary table above.</p>\n";
  }

  foreach my $groupName ( @sortedGroupNames )
  {
    # write_stdout( "Processing group $groupName...\n" );

    my $allGroupReports = $groupToReports{ $groupName };

    my $anchorName = sanitize_name_for_id_purposes( $groupName );

    $injectedHtml .= qq{ <a name="$anchorName"></a>  <h2> $groupName </h2> \n };

    $injectedHtml .= generate_table_header();
    $injectedHtml .= generate_report_table_entries( $allGroupReports, "", $outputSubDir, $defaultEncoding );
    $injectedHtml .= generate_table_footer();
  }


  # Load the HTML template file.

  my $htmlTemplateFilename = FileUtils::cat_path( THIS_SCRIPT_DIR, "BuildReportTemplate.html" );

  my $htmlText = FileUtils::read_whole_binary_file( $htmlTemplateFilename );

  ReportUtils::check_valid_html( $htmlText );


  # Fill out the HTML template.

  my $timeMsg = "Build started at UTC $arg_startTimeUtc";
  if ( $arg_elapsedTime ne "" )
  {
    $timeMsg .= ", elapsed time: $arg_elapsedTime";
  }
  $timeMsg .= ".";

  ReportUtils::replace_marker( \$htmlText, "REPORT_START_AND_ELAPSED_TIME", $timeMsg );

  ReportUtils::replace_marker( \$htmlText, "REPORT_BODY"      , $injectedHtml );

  my $statusMsg;

  if ( $componentCount == 0 )
  {
    $statusMsg = "ERROR: The top-level makefile did not build any components.";
  }
  elsif ( $failedCount == 0 )
  {
    $statusMsg = "All $componentCount components were built successfully.";
  }
  else
  {
    $statusMsg = "$failedCount components of the $componentCount attempted failed to build. Note that some components may have been skipped, as any which depend on the failed ones would also fail.";
    $statusMsg .= " "; # "<br/>";
    $statusMsg .= "Failed components are always displayed at the top.";
  }

  ReportUtils::replace_marker( \$htmlText, "TITLE", $arg_title );
  ReportUtils::replace_marker( \$htmlText, "REPORT_STATUS_MESSAGE", $statusMsg );

  my $tarballFilename = "OrbuildReport.tgz";
  ReportUtils::replace_marker( \$htmlText, "TARBALL_FILENAME", $tarballFilename );


  # Write the HTML report file.

  FileUtils::write_string_to_new_file( FileUtils::cat_path( $outputBaseDir, $htmlOutputFilename ), $htmlText );

  eval
  {
    ReportUtils::check_valid_html( $htmlText );
  };

  my $errorMessage = $@;

  if ( $errorMessage )
  {
    die "Error validating the generated HTML file \"$htmlOutputFilename\": $errorMessage\n";
  }

  if ( $arg_failedCountFilename ne "" )
  {
    FileUtils::write_string_to_new_file( $arg_failedCountFilename, "$failedCount" );
  }

  # Generate the tarball file.

  my $cmd = qq[cd $outputBaseDir && set -o pipefail && tar --create * --exclude="$tarballFilename" | gzip -1 - >"$tarballFilename"];
  # write_stdout( "Compressed archive cmd: $cmd\n" );
  my $escapedCmd = escape_for_bash_c( $cmd );
  my $cmdToRun = qq[bash -c "$escapedCmd"];
  ProcessUtils::run_process_exit_code_0( $cmdToRun );

  write_stdout( "HTML report finished.\n" );

  return MiscUtils::EXIT_CODE_SUCCESS;
}


sub escape_for_bash_c ( $ )
{
  my $str = shift;

  $str =~ s/(")/\\$1/go;

  return $str;
}


sub set_report_setting ( $ $ $ )
{
  my $report  = shift;
  my $setting = shift;
  my $value    = shift;

  if ( exists $report->{ $setting } )
  {
    die "Internal error: the report has already a setting called '$setting'.\n";
  }

  $report->{ $setting } = $value;
}


sub sanitize_name_for_id_purposes ( $ )
{
  my $str = shift;

  $str =~ s/[^[:alnum:]]/-/og;

  return $str
}


sub generate_table_header ()
{
  my $injectedHtml = "";

  $injectedHtml .= qq{ <table summary="Report table" \n };
  $injectedHtml .= qq{        border="1" \n };
  $injectedHtml .= qq{        CELLSPACING="0"> \n };

  $injectedHtml .= qq{ <thead> \n };
  $injectedHtml .= qq{ <tr> \n };

  $injectedHtml .= qq{ <th>Component</th> \n };
  $injectedHtml .= qq{ <th>Status</th> \n };
  $injectedHtml .= qq{ <th>Drill down</th> \n };
  
  $injectedHtml .= qq{ </tr> \n };
  $injectedHtml .= qq{ </thead> \n };
          
  $injectedHtml .= qq{ <tbody> \n };

  return $injectedHtml;
}


sub generate_table_footer ()
{
  my $injectedHtml = "";

  $injectedHtml .= qq{ </tbody> \n };
  $injectedHtml .= qq{ </table> \n };

  return $injectedHtml;
}


sub generate_report_table_entries ( $ $ $ $ )
{
  my $allReports               = shift;
  my $makefileUserFriendlyName = shift;
  my $outputSubDir             = shift;
  my $defaultEncoding          = shift;

  my @sortedReports = ReportUtils::sort_reports( $allReports, $makefileUserFriendlyName );

  my $injectedHtml = "";

  foreach my $report ( @sortedReports )
  {
    $injectedHtml .= process_report( $report, $makefileUserFriendlyName, $outputSubDir, $defaultEncoding );
  }

  return $injectedHtml;
}


sub process_report ( $ $ $ $ )
{
  my $report                   = shift;
  my $makefileUserFriendlyName = shift;
  my $outputSubDir             = shift;
  my $defaultEncoding          = shift;

  my $logFilename      = $report->{ "LogFile" };
  my $userFriendlyName = $report->{ "UserFriendlyName" };

  my $html = "<tr>\n";

  $html .= text_cell( $userFriendlyName );

  $html .= ReportUtils::generate_status_cell( $report->{ "ExitCode" } == 0 );

  my $type = ReportUtils::get_report_type( $report );

  if ( $type == ReportUtils::RT_GROUP )
  {
    my $anchorName = sanitize_name_for_id_purposes( $userFriendlyName );

    $html .= "<td>";
    $html .= "<a href=\"#$anchorName\">Group report below</a>";
    $html .= "</td>\n";
  }
  else
  {
    my $drillDownTarget = $report->{ "DrillDownLink" };
    $html .= ReportUtils::generate_html_log_file_and_cell_links( $logFilename, $outputSubDir, $defaultEncoding, $drillDownTarget );
  }

  $html .= "</tr>\n";
  $html .= "\n";

  return $html;
}


sub text_cell ( $ )
{
  my $contents = shift;
  return "<td>" . encode_entities( $contents ) . "</td>\n";
}


#------------------------------------------------------------------------

MiscUtils::entry_point( \&main, SCRIPT_NAME );
