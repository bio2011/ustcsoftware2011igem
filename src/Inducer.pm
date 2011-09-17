package Inducer;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use SpeciesGraph;

{
	struct Inducer =>
	{
		SpeciesGraph	=>	'SpeciesGraph',		
		Index			=>	'$',	#	Array index
		RuleTableNameOut	=>	'$',	#	compartment out assigned with table out
		RuleTableNameIn		=>	'$',	#	compartment in assigned with table in
		TransportRateOut	=>	'$',		#	transportation rate out
		TransportRateIn		=>	'$'			#	transportation rate in
	};
}

1;
