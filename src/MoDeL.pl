#!/usr/bin/perl

use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Main;
use Utils;
use strict;

my $logging     = 0;
my %params		= ();	

while ($ARGV[0] =~ /^-/) 
{
	$_ = shift;
	if (/^-log$/) {$logging = 1;}
	elsif (/^-check$/) {$params{no_exec} = 1;}
	elsif (/^-v$/)
	{
		printf "MoDeL version 1.1, written by Chen Liao, USTC\n";
		exit();    
	}
	elsif (/^-sbml$/) {$params{write_sbml} = 1;}
	else {exit_error("Unrecognized command line option $_");}
}

#	output sbml file as default
$params{write_sbml}=1;

for my $file (@ARGV)
{
	# create BNGMOdel object
	my $model = Main->new();

	my $t_start= cpu_time(0);
	$params{file} = $file;

	# Open logfile, if specified
	if ($logging) 
	{
		# Default logfile name is base name of first bngl file plus .log suffix
		my $lbase = $file;
		$lbase =~ s/[.]([^.]+)$//;
		open OUTPUT, '>', "${lbase}.log" or die $!;
		STDOUT->fdopen(\*OUTPUT, 'w') or die $!;
	}
	# turn off output buffering on STDOUT
	( select(*STDOUT), $| = 1 )[0];

	printf "MoDeL version 1.1, written by Chen Liao, USTC\n";

	if ( my $err = $model->readFile( \%params ) ) {exit_error($err);}
	if ( my $err = $model->applyRules( \%params ) ) {exit_error($err);}
	printf "CPU TIME: total %.1f s.\n", cpu_time(0) - $t_start;
}
