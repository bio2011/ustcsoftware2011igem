package Species;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use SpeciesGraph;
use Expression;
use Utils;

{
	struct Species =>
	{
		Name	=>	'$',	#	name of the species
		Index	=>	'$',	#	index in species array
		Compartment	=>	'$',	#	compartment it locates in
		InitConcentration	=>	'Expression',	#	init concentration
		isConst	=>	'$',	#	has const concentration? 1/0
		isSeedSpecies	=>	'$',		#	is seed species? 1/0
		SpeciesGraph	=>	'SpeciesGraph'	#	species components
	};

	sub equal {#	same compartment and same species
		my $spec0=shift;
		my $spec1graph=shift;
		my $spec1cname=shift;
		return $spec0->Compartment eq $spec1cname && 
			$spec0->SpeciesGraph->String eq $spec1graph->String;
	}
	
}


1;
