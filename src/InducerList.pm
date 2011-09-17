package InducerList;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use SpeciesGraph;
use Inducer;
use Utils;

{
	struct InducerList =>
	{
		Hash	=>	'%',	#	name	=>	(index group)
		Array	=>	'@'	#	inducer objs
	};

	sub readSarray {
		my $ilist=shift;
		my $species=shift;
		my $table_out=shift;
		my $table_in=shift;
		my $rate_out=shift;
		my $rate_in=shift;

		my ($graph,$graphErr)=SpeciesGraph->newSpeciesGraph($species,0);
		if ($graphErr) { return $graphErr; }
		if ($table_out !~ /^[A-Za-z]\w*$/) {
			return "Invalid table name in $table_out";
		}
		if ($table_in !~ /^[A-Za-z]\w*$/) {
			return "Invalid table name in $table_in";
		}
		unless (isReal($rate_out)) {
			return "InducerList->readSarray: Invalid transportation-out rate $rate_out, should be real";
		}
		unless ($rate_out > 0) {
			return "InducerList->readSarray: Invalid transportation-out rate $rate_out, should be above zero";
		}
		unless (isReal($rate_in)) {
			return "InducerList->readSarray: Invalid transportation-in rate $rate_in, should be real";
		}
		unless ($rate_in > 0) {
			return "InducerList->readSarray: Invalid transportation-in rate $rate_in, should be above zero";
		}
		my $index = $#{$ilist->Array}+1;
		my $inducer=Inducer->new(
			SpeciesGraph=>$graph,
			Index=>$index,
			RuleTableNameOut=>$table_out,
			RuleTableNameIn=>$table_in,
			TransportRateOut=>$rate_out,
			TransportRateIn=>$rate_in
		);

		return $ilist->add($inducer);
	}

	sub add
	{
		my $ilist = shift;  # inducer list
		my $inducer = shift;
		ref $inducer eq 'Inducer' || return 
			"InducerList: Attempt to add non-inducer object $inducer to InducerList.";   
		my $specGrfStr=$inducer->SpeciesGraph->String;
		my $indexGrp=$ilist->Hash->{$specGrfStr}; 
		if ( $indexGrp ) { 
			push (@$indexGrp, $inducer->Index);
		}
		else{ # add new inducer
			my @newIndexGrp=($inducer->Index);
			$ilist->Hash->{$specGrfStr} = \@newIndexGrp;
		}
		push @{$ilist->Array}, $inducer;

		# continue adding inducerss (recursive)
		if ( @_ )
		{  return $ilist->add(@_);  }
		else
		{  return '';  }
	}
}

1;
__END__
