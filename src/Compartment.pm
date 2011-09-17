package Compartment;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use Expression;

{
	my ($hostname, $username, $password);

	struct Compartment =>
	{
		Name	=>	'$',	#	name of the compartment
		Volume	=>	'Expression',	#	
		Population	=>	'Expression',	#	Number of cells
		Outside	=>	'Compartment',	#	outside compartment
		RuleTableName	=>	'$'	#	name of SQL rule table
	};

}

1;
