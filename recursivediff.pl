#!/usr/bin/perl
use strict;
use Text::Diff;


my $sourceFolder = "/var/projects/filecrawler_data";
my $compareFolder = "/var/projects/filecrawler_output";
my $outputFolder = "/var/projects/filecrawler_diff";

unlink $outputFolder;
recurseFolders($sourceFolder, $compareFolder, $outputFolder);

sub recurseFolders {
  my ($folderName, $compareFolder, $outputFolder) = @_;
  my @foldersToHandle = ();

  mkdir $outputFolder;

  opendir(DIR, $folderName) || die "Can't open directory: $!\n";
  while (my $file = readdir(DIR)) {
    next if $file =~ /^\./;

    my $fileName = "$folderName/$file";
    my $compareFileName = "$compareFolder/$file";
    my $outputFileName = "$outputFolder/$file";

    if (-f $fileName) {
      #process file
      processFile($fileName, $compareFileName, $outputFileName);
    } else {
      push @foldersToHandle, "$file";
    }
  }
  closedir(DIR);

  foreach my $nextFolder (@foldersToHandle) {
    recurseFolders("$folderName/$nextFolder", "$compareFolder/$nextFolder", "$outputFolder/$nextFolder");
  }

}

sub processFile {
  my ($inputFile, $compareFile, $outputFile) = @_;

  my $diff = diff $inputFile => $compareFile;
  return unless length $diff > 0;
  my $length = length $diff;

  print "writing $length bytes to $outputFile\n";

  open (OUTFILE, ">$outputFile") or die "Error opening file $outputFile for output\n $!";
  print OUTFILE $diff;
  close OUTFILE;
}
