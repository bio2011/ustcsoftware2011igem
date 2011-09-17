package Reaction;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use Expression;
use Utils;

struct Reaction =>
{
	Name	=>	'$',
	RuleIndex	=>	'$',	#	rule index
	Lhs		=>	'@',	#	reactants name
	Mds		=>	'@',	#	modifiers name
	Rhs		=>	'@',	#	products  name
	Rate	=>	'Expression',
	Prefac	=>	'$',		#	prefactor for one reaction
	sbmlVolumeFactor	=>	'$'
};


1;
