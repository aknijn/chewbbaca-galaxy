#!/usr/bin/env perl
## A wrapper script to call chewBBACA.py and collect its output
use strict;
use warnings;
use Cwd;
use English;
use File::Copy;
use File::Basename;

# Parse arguments
my ($myFunction,
    $input1,
    $input1_names,
    $output,
    $python) = @ARGV;

# Run program
my $abs_path = Cwd::abs_path($PROGRAM_NAME);
my $scriptdir = dirname($abs_path);

prepareEnvironment($input1,$input1_names,"input_dir");
runChewBBACA();
collectOutput();
exit(0);

# Run INNUca
sub runChewBBACA {
    my $abs_path = Cwd::abs_path($PROGRAM_NAME);
    my $scriptdir = dirname($abs_path);
    my $createschemadir = "$scriptdir/createschema";
    my $allelecalldir = "$scriptdir/allelecall";
    my $SchemaEvaluatordir = "$scriptdir/SchemaEvaluator";
    my $utilsdir = "$scriptdir/utils";
    my $newpath = "PATH=$ENV{PATH}:$createschemadir:$allelecalldir:$SchemaEvaluatordir:$utilsdir";
    my $result = system("$newpath; $python");
    return 0;
}

# Run prepareEnvironment, create the directory $indir with symlinks to the files listed in $inlist
sub prepareEnvironment {
    my ($inlist, $inlist_names, $indir) = @_;
    if ($inlist ne "NULL") {
      mkdir($indir);
      my @inputs = split(',', $inlist);
      if ($inlist_names ne "NULL") {
        my @inputs_names = split(',', $inlist_names);
        for my $i ( 0 .. $#inputs ){
          my $name = $inputs_names[$i];
          $name =~ s/ /_/g;
          $name =~ s/\//_/g;
          $name =~ s/\(/_/g;
          $name =~ s/\)/_/g;
          $name =~ s/\[/_/g;
          $name =~ s/\]/_/g;
          $name =~ s/\{/_/g;
          $name =~ s/\}/_/g;
          symlink($inputs[$i], $indir . "/" . $name);
        }
      }
      else {
        foreach my $i (@inputs){
          symlink($i, $indir . "/" . basename($i));
        }
      }
    }
    return 0;
}

# Collect output
sub collectOutput{
    # CreateSchema
    if ($myFunction eq "CreateSchema") {
      my($dataname, $datadir, $datasuffix) = fileparse($output,qr/\.[^.]*/);
      my @fasta_files = glob "output_dir/*.fasta";
      my $dest_dir = $datadir . $dataname . "/";
      mkdir($dest_dir);
      open(my $fh1, '>', $output) or die "Could not open file '$output' $!";
      my $new_fasta_file = "";
      foreach my $fasta_file (@fasta_files) {
         $new_fasta_file = $dest_dir . basename($fasta_file);
         print $fh1 "$new_fasta_file\n";
         move($fasta_file, $new_fasta_file) or die "Could not move $fasta_file: $!\n";
      }
      close $fh1;
      my @short_fasta_files = glob "output_dir/short/*.fasta";
      my $short_dest_dir = $datadir . $dataname . "/short/";
      mkdir($short_dest_dir);
      foreach my $short_fasta_file (@short_fasta_files) {
         move($short_fasta_file, $short_dest_dir) or die "Could not move $short_fasta_file: $!\n";
      }
    }
    # AlleleCall
    if ($myFunction eq "AlleleCall") {
      my @outputs = split(',', $output);
      my @statistics = glob "output_dir/results_*/results_statistics.tsv";
      if (@statistics == 1) {
        move($statistics[0], $outputs[0])
      }
      my @contigsinfo = glob "output_dir/results_*/results_contigsInfo.tsv";
      if (@contigsinfo == 1) {
        move($contigsinfo[0], $outputs[1])
      }
      my @alleles = glob "output_dir/results_*/results_alleles.tsv";
      if (@alleles == 1) {
        move($alleles[0], $outputs[2])
      }
      my @logginginfo = glob "output_dir/results_*/logging_info.txt";
      if (@logginginfo == 1) {
        move($logginginfo[0], $outputs[3])
      }
      my @repeatedloci = glob "output_dir/results_*/RepeatedLoci.txt";
      if (@repeatedloci == 1) {
        move($repeatedloci[0], $outputs[4])
      }
    }
    # SchemaEvaluator
    if ($myFunction eq "SchemaEvaluator") {
      my($dataname, $datadir, $datasuffix) = fileparse($output,qr/\.[^.]*/);
      my @output_files = glob "output_rms/*.*";
      my $dest_dir = $datadir . $dataname . "/";
      mkdir($dest_dir);
      my $new_output_file = "";
      foreach my $output_file (@output_files) {
         $new_output_file = $dest_dir . basename($output_file);
         move($output_file, $new_output_file) or die "Could not move $output_file: $!\n";
      }
      open(my $fh2, '<', $dest_dir . "SchemaEvaluator.html") || die "File not found";
      my @lines = <$fh2>;
      close($fh2);
      my @newlines;
      foreach(@lines) {
         $_ =~ s/\.\.\/\.\.\/\.\.\/.*?\/database\/files\/...\/dataset/dataset/g;
         push(@newlines,$_);
      }
      # write the html to the Galaxy output file
      open($fh2, '>', $output) || die "File not found";
      print $fh2 @newlines;
      close($fh2);
      my @html_output_files = glob "output_rms/genes_html/*.*";
      my $html_dest_dir = $dest_dir . "genes_html/";
      mkdir($html_dest_dir);
      foreach my $html_output_file (@html_output_files) {
         move($html_output_file, $html_dest_dir) or die "Could not move $html_output_file: $!\n";
      }
    }
    return 0;
}

