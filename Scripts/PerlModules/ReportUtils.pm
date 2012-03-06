
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

package ReportUtils;

use strict;
use warnings;

use XML::Parser;
use HTML::Entities;
use File::Spec;
use I18N::Langinfo;
use Encode;

use StringUtils;
use FileUtils;
use ConfigFile;


sub collect_all_reports ( $ $ $ $ $ )
{
  my $dirname            = shift;
  my $reportExtension    = shift;
  my $optionalEntries    = shift;  # Reference to an array.
  my $allReportsArrayRef = shift;
  my $failedCount        = shift;

  my $globPattern = FileUtils::cat_path( $dirname, "*" . $reportExtension );

  my @matchedFiles = File::Glob::bsd_glob( $globPattern, &File::Glob::GLOB_ERR | &File::Glob::GLOB_NOSORT );

  if ( &File::Glob::GLOB_ERROR )
  {
    die "Error listing existing directories: $!\n";
  }

  $$failedCount = 0;

  foreach my $filename ( @matchedFiles )
  {
    # print "File found: $filename\n";

    if ( not -f $filename )
    {
      die "File \"$filename\" is not a regular file.\n" 
    }

    my %allEntries;

    load_report( $filename, $optionalEntries, \%allEntries );

    if ( $allEntries{ "ExitCode" } != 0 )
    {
        ++$$failedCount;
    }

    push @$allReportsArrayRef, \%allEntries;
  }
}


sub load_report ( $ $ $ )
{
  my $filename          = shift;
  my $optionalEntries   = shift;  # Reference to an array.
  my $allEntriesHashRef = shift;

  ConfigFile::read_config_file( $filename, $allEntriesHashRef );

  my @mandatoryEntries = qw( UserFriendlyName
                             ExitCode        
                             LogFile         
                             StartTimeLocal  
                             StartTimeUTC    
                             FinishTimeLocal 
                             FinishTimeUTC   
                             ElapsedSeconds  );

  ConfigFile::check_config_file_contents( $allEntriesHashRef,
                                          \@mandatoryEntries,
                                          $optionalEntries,
                                          $filename );
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


    # Failed components have priority.

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

    # We could sort all failed components by their timestamp, as it's roughly
    # the dependency order, that is, the order in which they were executed.
    # However, I'm not certain that sorting by name is not actually better,
    # as it allows the user to skip at once groups of uninteresting failures.

    return $left->{ "UserFriendlyName" }  cmp  $right->{ "UserFriendlyName" };
  };


  my @sortedReports = sort $comparator @$allReports;

  return @sortedReports;
}


sub convert_text_file_to_html ( $ $ )
{
  my $srcFilename  = shift;
  my $destFilename = shift;

  open( my $srcFile, "<$srcFilename" )
    or die "Cannot open file \"$srcFilename\": $!\n";

  # The build log outputs are redirected to files, which are normally encoded in UTF-8,
  # but could be encoded in some other system default encoding.
  # If we don't specify anything here, the UTF-8 characters are garbled in the resulting HTML page.
  # Here we are attempting to find out the system's default text encoding.
  # Alternatively, we could use module Encode::Locale and then binmode( ':encoding(locale)' ),
  # but that module is not usually installed.
  my $defaultCodeset = I18N::Langinfo::langinfo( I18N::Langinfo::CODESET() );
  my $defaultEncoding = Encode::find_encoding( $defaultCodeset )->name;
  # print "---> defaultEncoding: $defaultEncoding\n";
  binmode( $srcFile, ":encoding($defaultEncoding)" );  # Also avoids CRLF conversion.

  open( my $destFile, ">$destFilename" )
    or die "Cannot open for writing file \"$destFilename\": $!\n";

  binmode( $destFile );  # Avoids CRLF conversion.

  # Alternative with HTML::FromText
  #   my $logFilenameContents = FileUtils::read_whole_binary_file( $logFilename );
  #   my $t2h  = HTML::FromText->new( { lines => 1 } );
  #   my $logContentsAsHtml = $t2h->parse( $logFilenameContents );

  my $header = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\"\n" .
               "\"http://www.w3.org/TR/html4/strict.dtd\">\n" .
               "<html>\n" .
               "<head>\n" .
               "<title>Log file</title>\n" .
               "<style type=\"text/css\">\n" .

               "td.linenumber {\n" .
               "text-align:right;\n" .
               "font-family: monospace;\n" .
               "vertical-align: top;\n" .
               "padding-right: 10px;\n" .
               "border-style: solid;\n" .
               "border-width: 1px;\n" .
               "border-color: #B0B0B0;\n" .
               "}\n" .

               "td.logline {\n" .
               "text-align:left;\n" .
               "font-family: monospace;\n" .
               "padding-left:  10px;\n" .
               "padding-right: 10px;\n" .
               "border-style: solid;\n" .
               "border-width: 0px;\n" .
               "word-break: break-all;\n" .  # CSS3, only supported by Microsoft Internet Explorer (tested with version 9) and
                                             # Chromium (tested with version 17), but not by Firefox 10.
                                             # Without it, very long lines will cause horizontal scroll-bars to appear at bottom of the page.
                                             # The alternative 'break-word' works well with Chromium, chopping at word boundaries except when the word is too long,
                                             # but unfortunately it does not well with IE 9 (scroll-bars appear again).
               "}\n" .

               "</style>\n" .
               "</head>\n" .
               "<body>\n" .
               "<table summary=\"Log file\" border=\"1\" CELLSPACING=\"0\">\n" .
               "<thead>\n" .
               "<tr>\n" .
               "<th>No</th>\n" .
               "<th>Log line text</th>\n" .
               "</tr>\n" .
               "</thead>\n" .
               "<tbody>\n";

  (print $destFile $header) or
      die "Cannot write to file \"$destFilename\": $!\n";

  my $htmlBr = "<br/>";

  for ( my $lineNumber = 1; ; ++$lineNumber )
  {
    my $line = readline( $srcFile );

    last if not defined $line;

    # Strip trailing new-line characters.
    $line =~ s/[\n\r]*$//o;

    if ( 0 != length( $line ) )
    {
      # $line = "<code>" . encode_entities( $line ) . "</code>";
      $line = encode_entities( $line );

      # Git shows and updates every second or so a progress message like this:
      #    Checking out files:   0% (2/38541)
      # These messages end with a Carriage Return (\r, 0x0D) only, without a Line Feed (\n, 0x0A) at the end,
      # and that's not displayed well in the HTML report. Therefore,
      # convert all embedded Carriage Return codes into HTML line breaks here.
      $line =~ s/\r/$htmlBr/og;
    }

    $line = "<tr>" .
            "<td class=\"linenumber\">$lineNumber</td>" .
            "<td class=\"logline\">$line</td>" .
            "</tr>\n";

    (print $destFile $line) or
        die "Cannot write to file \"$destFilename\": $!\n";
  }

  my $footer = "</tbody>\n" .
               "</table>\n" .
               "</body>\n" .
               "</html>\n";

  (print $destFile $footer) or
      die "Cannot write to file \"$destFilename\": $!\n";

  FileUtils::close_or_die( $destFile );
  FileUtils::close_or_die( $srcFile  );
}


sub generate_html_log_file_and_cell_links ( $ )
{
  my $logFilename = shift;

  my ( $volume, $directories, $logFilenameOnly ) = File::Spec->splitpath( $logFilename );

  use constant SUFFIX_TO_REMOVE => ".txt";

  my $htmlLogFilenameOnly = $logFilenameOnly;

  if ( StringUtils::str_ends_with( $htmlLogFilenameOnly, SUFFIX_TO_REMOVE ) )
  {
    $htmlLogFilenameOnly = substr( $htmlLogFilenameOnly, 0, length( $htmlLogFilenameOnly ) - length( SUFFIX_TO_REMOVE ) );
  }

  $htmlLogFilenameOnly .= ".html";

  my $htmlLogFilename = FileUtils::cat_path( $volume, $directories, $htmlLogFilenameOnly );

  ReportUtils::convert_text_file_to_html( $logFilename, $htmlLogFilename );


  my $html = "";

  my $link1 = encode_entities( $htmlLogFilenameOnly );  # Absolute link: "file://" . encode_entities( $htmlLogFilenameOnly );
  my $link2 = encode_entities( $logFilenameOnly );
  $html .= "<td>";
  $html .= html_link( $link1, "HTML" );
  $html .= " or ";
  $html .= html_link( $link2, "plain txt"  );
  $html .= "</td>\n";

  return $html;
}


sub generate_status_cell ( $ )
{
  my $exitCode = shift;

  my $styleClass;
  my $text;

  if ( $exitCode == 0 )
  {
    $styleClass = "StatusOk";
    $text = "OK";
  }
  else
  {
    $styleClass = "StatusFailed";
    $text = "FAILED";
  }

  my $html = "";

  $html .= "<td class=\"$styleClass\">";
  $html .= $text;
  $html .= "</td>\n";
}


sub html_link ( $ $ )
{
  my $link = shift;
  my $text = shift;

  return "<a href=\"$link\">$text</a>";
}


1;  # The module returns a true value to indicate it compiled successfully.

