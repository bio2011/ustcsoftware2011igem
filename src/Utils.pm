package Utils;

use strict;
use warnings;
use Data::Dumper;
use base qw(Exporter);
our @EXPORT = qw ($warnings_on diff_array cpu_time exit_error send_warning isReal boolean2int generate_permutation find_combinatorial_coefficient get_rate_formula_by_replacement);

our $warnings_on=1;	#	switch to print warnings

sub diff_array {
	my $arrRefA = shift;
	my $arrRefB = shift;
	my @arrA = @$arrRefA;
	my @arrB = @$arrRefB;
	foreach my $a (@arrA) {
		if (@arrB) { 
			my $b=shift @arrB;
			if ($a ne $b) { return 0; }
		}
		else { return 0; }
	}
	return 0 if @arrB;
	return 1;
}

sub cpu_time
{
	my ($t_tot, $utime, $stime, $cutime, $cstime);
	my $t_ret;

	my $t_last= shift if (@_);
	($utime, $stime, $cutime, $cstime)= times;
	$t_tot= $utime + $stime +$cutime + $cstime;
	$t_ret= $t_tot - $t_last;
	$t_last= $t_tot;
	return($t_ret);
}

sub exit_error
{
    my @msgs= @_;
    print STDERR "ABORT: ";
    for my $msg (@msgs){print STDERR $msg,"\n";}
    exit(1);
}

sub send_warning{
	if ($warnings_on) {
		my @msgs= @_;
		print STDOUT "WARNING: ";
		for my $msg (@msgs){
			print STDOUT $msg,"\n";
		}
		# Could have $STRICT flag to force exit
		return(0);
	}
}


sub isReal{
	my $string=shift;
	my $isdec=0;
	
	if ($string=~ s/^[+-]?\d+[.]?\d*//){
		$isdec=1;
	}
	elsif ($string=~ s/^[+-]?[.]\d+//){
		$isdec=1;
	} else {
		return(0);
	}
	if ($string eq ""){return(1);}

	if ($string=~ s/^[DEFGdefg][+-]?\d+$//){
		return(1);
	}
	return(0);
}

# Convert boolean to integer False=0 True=1 notBoolean=-1
sub boolean2int {
	my $string=shift;
	my $intval;
	
	#	/i means case-insensitive
	if ($string =~ /^true$/i) {$intval=1;}
	elsif ($string =~ /^false$/i) {$intval=0;}
	elsif ($string eq "") {# Boolean that is not a assigned a value is True by default
		$intval=1;
	}
	else {$intval=-1;}
	return $intval;
}

sub generate_permutation {# $en >= $sn, both positive numbers required (sign free)
	my $sn=(@_)? shift: -1;
	my $en=(@_)? shift: -1;
	if ($sn !~ /^\d+$/ || $en !~ /^\d+$/) {
		return ('',"Utils->generate_permutation: Positive number required for both $sn and $en");
	}
	if ($sn > $en) {#	swap
		my $an = $en;
		$en = $sn;
		$sn = $an;
	}
    my $arrNum = $en-$sn+1;
    my $numPerms = $arrNum**$arrNum;

    my @arrPtrs = ();
    for (my $i=0; $i<$arrNum; $i++) {push (@arrPtrs, 0);}

    my @subPerm = ();
    my $i_ptr = 0;
    while ($i_ptr < $numPerms) {
        my @eachPerm = ();
        my %hash = (); # used to record the number occurence

        my $insertOK = 1;
        foreach (@arrPtrs) {
            if (exists $hash{$_}) { $insertOK = 0; last; }
            else {
                push (@eachPerm, $sn+$_);
                $hash{$_} = 1;
            }
        }
        push (@subPerm, \@eachPerm) if $insertOK;

        for (my $i=0; $i < $arrNum; $i++) {
            last unless ++$arrPtrs[$i] == $arrNum;
            $arrPtrs[$i] = 0;
        }
        $i_ptr++;
    }

    return \@subPerm;
}

sub find_combinatorial_coefficient
{
	my (@reactant) = @_;
	my %hash_rp = ();
	foreach (@reactant)
	{
		if (exists $hash_rp{$_}) {$hash_rp{$_}++;}
		else {$hash_rp{$_} = 1;}
	}
	my $coef = 1;
	foreach (keys %hash_rp) {
		$coef *= factorial($hash_rp{$_});
	}
	return 1/$coef;
}

sub factorial {#	num should be >= 1
	my $num=shift;
	my $res = 1;
	$res *= $_ foreach 1..$num;
	return $res;
}

sub get_rate_formula_by_replacement {
	my $string=shift;
	my $jointArray=(@_)?shift:'';
	while ($string =~ /#(\d+)/) {
		my $index=$1-1;
		my $repstr=$$jointArray[$index];
		if ($repstr) {	$string =~ s/#\d+/$repstr/; }
		else { 
			print "string=$string\n";
			print Dumper $jointArray if $jointArray;
			return('',"Utils->get_rate_formula_by_replacement: Cannot find the $index"."th element"); 
		}
	}
	return $string;
}

1;
__END__



1;
