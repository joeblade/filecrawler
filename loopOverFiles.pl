#!/usr/bin/perl
use strict;

my $inputFolder = "/var/projects/filecrawler_data/";
my $outputFolder = "/var/projects/filecrawler_output/";
unlink($outputFolder);

recurseFolders($inputFolder, $outputFolder);

sub recurseFolders {
  my ($folderName, $outputFolder) = @_;
  my @foldersToHandle = ();

  mkdir $outputFolder;

  opendir(DIR, $folderName) || die "Can't open directory: $!\n";
  while (my $file = readdir(DIR)) {
    next if $file =~ /^\./;

    my $fileName = "$folderName/$file";
    my $outputFileName = "$outputFolder/$file";

    if (-f $fileName) {
      #process file
      processFile($fileName, $outputFileName);
    } else {
      push @foldersToHandle, "$file";
    }
  }
  closedir(DIR);

  foreach my $nextFolder (@foldersToHandle) {
    recurseFolders("$folderName/$nextFolder", "$outputFolder/$nextFolder");
  }

}

sub processFile {
  my ($inputFile, $outputFile) = @_;
  print "$inputFile\n";

  local $/ = undef;
  open CUR, '<', $inputFile or die "can't open $inputFile: $!";
  my $fileContents = <CUR>;
  close CUR;

  $fileContents = findAndReplaceBadUrls($fileContents);

  open (OUTFILE, ">$outputFile") or die "Error opening file $outputFile for output\n $!";
  print OUTFILE $fileContents;
  close OUTFILE;
}

sub findAndReplaceBadUrls {
  my ($data) = @_;

  # 1: urls are enclosed in href=" or href=' and do not contain ' or " internally.
  # 2: urls that end without a / or .extension should have a / placed at the end

  # instead of doing this in one regex, split into parts, with the content of <text> blocks kept separate for replacement.
  my $output = "";
  my ($pre, $match, $rest);
  my $remainder = $data;

  while (
      ($pre, $match, $rest) = $data =~ m/(.*?href=[\'\"])([^\'\"]*)([\'\"].*)/gs
    ) {
    $data = $rest;
    $remainder = $rest;

    $output .= $pre;

    $match = fixHref($match);
    $output .= $match;
  }

  $output .= $remainder;

  return $output;
}

sub fixHref {
  my ($href) = @_;
      # check match. if it does not end in / , and has no . after last /   then add a /
      # example:
      # /some/path/file.ext   is good
      # /some/path/path/      is good
      # /some/some.path/file  is wrong (no / at and and no . after last /)
  my $anchor = "";
  ($href, $anchor) = split (/#/, $href);

  if (length $anchor > 0) {
    $anchor = "#" . $anchor;
  }

  # get the last path segment (a/b/  --> b/ )
  my $lastSeg = (split /(?<=\/)/, $href)[-1];

  # if segment contains /
  # or if segment contains . with 3 characters
  # or if segment is listed in the known file extensions

  # if ends with / no need to do anything
  if ($lastSeg =~ m/\/$/) {
    return $href . $anchor;
  }

  # if ends with 3 characters, assume .gif and suchlike.
  if ($lastSeg =~ m/\.\w{3}$/) {
    return $href . $anchor;
  }

  my @extensions = ( "html", "jpeg", "mpga", "mp4a", "mxml", "sgml", "xhtml" );

  # if ends with 4 or more characters, look the extension up in the allow list.
  if (my ($ext) = $lastSeg =~ m/\.(\w{4,})$/) {
    if (grep { $_ eq $ext } @extensions) {
      return $href . $anchor;
    }
  }

  return $href . "/" . $anchor;
}

