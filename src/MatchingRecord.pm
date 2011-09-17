package MatchingRecord;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use Data::Dumper;
use IO::Handle;
use Class::Struct;

{
	struct MatchingRecord => {
		Index	=>	'$',	#	
		Residue =>  '$',	#	Species matching only
		Concat	=>  '$',	#	Sequence matching only
		InstXs	=>	'%',	#	Xpart name => array of objects of Class::Sequence
		InstNXs =>  '%'     #	Non-Xpart name => array of objects of Class::Part
	};

	sub print {
		my $MR=shift;
		print "\n\nindex=",$MR->Index,"\n" if $MR->Index;
		print "residue=",$MR->Residue,"\n" if $MR->Residue;
		print "concat=",$MR->Concat,"\n" if $MR->Concat;
		my (%hashx,%hashnx)=((),());
		foreach my $xarray (keys %{$MR->InstXs}) {
			my $array=$MR->InstXs->{$xarray};
			my @strings=();
			foreach my $seq (@$array) {
				push (@strings,$seq->String);
			}
			$hashx{$xarray}=\@strings;
		}
		foreach my $nxarray (keys %{$MR->InstNXs}) {
			my $array=$MR->InstNXs->{$nxarray};
			my @strings=();
			foreach my $part (@$array) {
				push (@strings,$part->String);
			}
			$hashnx{$nxarray}=\@strings;
		}
		print "InstXs:\n";
		print Dumper \%hashx;
		print "InstNXs:\n";
		print Dumper \%hashnx;

		return;
	}

	sub merge {#	merge Residue, InstXs, InstNXs
		my $MR0=shift;
		my $MR=shift;
		my $Xonly=(@_)?shift:'';	#	if true, only merge InstXs
		
		foreach my $name (keys %{$MR->InstXs}) {#	Merge InstXs
			if ($MR0->InstXs->{$name}) {
				my $sarray0=$MR0->InstXs->{$name};
				my $sarray=$MR->InstXs->{$name};
				foreach my $seq (@$sarray) {
					push(@$sarray0,$seq->copy());
				}
			}
			else {
				my $sarray=$MR->InstXs->{$name};
				my @newseq=();
				foreach my $seq (@$sarray) {
					push(@newseq,$seq->copy());
				}
				$MR0->InstXs->{$name}=\@newseq;
			}
		}

		return if $Xonly && $Xonly eq 'Xonly';

		if ($MR0->Residue) {#	merge Residue
			$MR0->Residue($MR0->Residue.".".$MR->Residue) if $MR->Residue;
		}
		else { $MR0->Residue($MR->Residue) if $MR->Residue; }

		foreach my $name (keys %{$MR->InstNXs}) {#	Merge InstNXs
			if ($MR0->InstNXs->{$name}) {
				my $parray0=$MR0->InstNXs->{$name};
				my $parray=$MR->InstNXs->{$name};
				foreach my $part (@$parray) {
					push(@$parray0,$part->copy());
				}
			}
			else {
				my $parray=$MR->InstNXs->{$name};
				my @newp=();
				foreach my $part (@$parray) {
					push(@newp,$part->copy());
				}
				$MR0->InstNXs->{$name}=\@newp;
			}
		}
		return;
	}
}

1;
__END__
