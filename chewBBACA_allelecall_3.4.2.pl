#!/usr/bin/env perl
## A wrapper script to call chewBBACA.py and collect its output
use strict;
use warnings;
use Cwd;
use English;
use File::Copy;
use File::Basename;

# Parse arguments
my ($input1,
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

# Run chewBBACA
sub runChewBBACA {
    my $abs_path = Cwd::abs_path($PROGRAM_NAME);
    my $scriptdir = dirname($abs_path);
    my $utilsdir = "$scriptdir/utils";
    my $newpath = "PATH=$ENV{PATH}:$scriptdir/allelecall:$utilsdir";
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
          my $name = $inputs_names[$i] . ".fasta";
          $name =~ s/ /_/g;
          $name =~ s/\//_/g;
          $name =~ s/\(/_/g;
          $name =~ s/\)/_/g;
          $name =~ s/\[/_/g;
          $name =~ s/\]/_/g;
          $name =~ s/\{/_/g;
          $name =~ s/\}/_/g;
          $name =~ s/\}/_/g;
          $name =~ s/.fasta.fasta/.fasta/g;
          $name =~ s/.fna.fasta/.fna/g;
          $name =~ s/.ffn.fasta/.ffn/g;
          $name =~ s/.fa.fasta/.fa/g;
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
    # AlleleCall
    my @outputs = split(',', $output);
    my @statistics = glob "output_dir/results_statistics.tsv";
    if (@statistics == 1) {
      move($statistics[0], $outputs[0])
    }
    my @contigsinfo = glob "output_dir/results_contigsInfo.tsv";
    if (@contigsinfo == 1) {
      move($contigsinfo[0], $outputs[1])
    }
    my @alleles = glob "output_dir/results_alleles.tsv";
    if (@alleles == 1) {
      move($alleles[0], $outputs[2])
    }
    my @alleleshashed = glob "output_dir/results_alleles_hashed.tsv";
    if (@alleleshashed == 1) {
      move($alleleshashed[0], $outputs[3])
    }
    my @logginginfo = glob "output_dir/logging_info.txt";
    if (@logginginfo == 1) {
      move($logginginfo[0], $outputs[4])
    }
    my @repeatedloci = glob "output_dir/paralogous_loci.tsv";
    if (@repeatedloci == 1) {
      move($repeatedloci[0], $outputs[5])
    }
    return 0;
}

