#!/usr/bin/perl
# Simple parameter scanning script.  Creates and runs a single BNGL file that
# scans a single parameter using the setParameter command".  User provides
# a BNGL file containing the model - actions in this file are ignored.
#
# Written by Jim Faeder, Los Alamos National Laboratory, 3/6/2007 

my $BNGPATH=".";

my $log=0;
my $t_end= 20;
my $n_steps=20;
my $steady_state=0;
my $prefix;

while ($ARGV[0] =~ /^-/){
  $_ = shift;
  if (/^-log$/){
    $log=1;
  }
  elsif(/^-n_steps/){
    $n_steps= shift(@ARGV);
  }
  elsif(/^-prefix/){
    $prefix= shift(@ARGV);
  }
  elsif(/^-steady_state/){
    $steady_state=1;
  }
  elsif(/^-t_end/){
    $t_end= shift(@ARGV);
  }
  else{
    exit_error("Unrecognized command line option $_");
  }
}

if ($#ARGV != 4) {
  die "Usage $0 file.bngl varname var_min var_max n_pts";
}

my $file= shift(@ARGV);
my $var= shift(@ARGV);
my $var_min= shift(@ARGV);
my $var_max= shift(@ARGV);
my $n_pts= shift(@ARGV);

# Automatic assignment of prefix if unset
if (!$prefix){
  $prefix=$file;
  # strip suffix
  $prefix=~ s/[.][^.]*$//;
  $prefix.="_${var}";
}

if ($log){
  $var_min= log($var_min);
  $var_max= log($var_max);
}

my $delta= ($var_max-$var_min)/($n_pts-1);

# Read file 
open(IN,$file) || die "Couldn't open file $file: $?\n";
my $script="";
while(<IN>){
  $script.=$_;
  # Skip actions
  last if (/^\s*end\s*model\s*$/);
}

if (-d $prefix){
  system("rm -r $prefix");
#  die "Directory $prefix exists.  Remove before running this script.";
}

mkdir $prefix;
chdir $prefix;

# Create input file scanning variable
$fname= sprintf "${prefix}.bngl", $run;
open(BNGL,">$fname") || die "Couldn't write to $fname";
print BNGL $script;
print BNGL "generate_network({overwrite=>1});\n";
my $val= $var_min;
for my $run (1..$n_pts){
  my $srun= sprintf "%05d", $run;
  if ($run>1){
    print BNGL "resetConcentrations()\n";
  }
  my $x= $val;
  if ($log){ $x= exp($val);}
  printf BNGL "setParameter($var,$x);\n";
  
  my $opt= "suffix=>\"$srun\",t_end=>$t_end,n_steps=>$n_steps";
  if ($steady_state){
    $opt.=",steady_state=>1";
  }
  printf BNGL "simulate_ode({$opt});\n";
  $val+=$delta;
}  
close(BNGL);

# Run BioNetGen on file
print "Running BioNetGen on $fname\n";
my $exec= "${BNGPATH}/Perl2/BNG2.pl";
system("$exec $fname > $prefix.log");

# Process output
$ofile="../$prefix.scan";
open(OUT,">$ofile") || die "Couldn't open $ofile";
my $val= $var_min;
for my $run (1..$n_pts){
  # Get data from gdat file
  $file= sprintf "${prefix}_%05d.gdat", $run;
  print "Extracting data from $file\n";
  open(IN,"$file") || die "Couldn't open $file";
  if ($run==1){
     my $head= <IN>;
     $head=~ s/^\s*\#//;
     my @heads= split(' ',$head);
     shift(@heads);
     printf OUT "# %+14s", $var;
     for my $head (@heads){
       printf OUT " %+14s", $head;
     }
     print OUT "\n";
  }
  while(<IN>){$last=$_};
  my @dat= split(' ',$last);
  my $time= shift(@dat);
  my $x= ($log)? exp($val) : $val;
  printf OUT "%16.8e %s\n", $x, join(' ',@dat);
  close(IN);
  $val+=$delta;
}  
close(OUT);
