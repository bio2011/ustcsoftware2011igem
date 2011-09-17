package CompartmentList;

use strict;
use warnings;
use File::Spec;
use LibSBML;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Data::Dumper;
use Class::Struct;
use Compartment;
use Utils;

{
	my $RootCompartmentDefined = 0;

	struct CompartmentList =>
	{
		Array		=>	'@',	#	list of compartments
		Hash		=>	'%',	#	map compartment name to its object
		Unchecked	=>	'@'		#	
	};	

	sub readString
	{
		my $clist  = shift;  #	CompartmentList
		my $string = shift;  #	Compartment string to parse
		my $plist  = shift;	 #	ParameterList

		#	Read name (required)
		$string =~ s/^\s*([A-Za-z]\w*)//   or return("Invalid compartment name in $string");
		my $name = $1;

		#	Read outside compartment (required)
		$string =~ s/^\s*([A-Za-z]\w*)//   or return( "Invalid outside compartment name for Compartment in $string" ); 
		my $cname = $1;

		my $outside = undef;
		if ($cname eq 'ROOT') {#root compartment
			if ($RootCompartmentDefined) {
				return("Root compartment has been defined previously");
			}
			else { $RootCompartmentDefined=1; }
		}
		else {
			$outside = $clist->Hash->{$cname} ||  
			return(
				"Outside compartment $cname is not in CompartmentList.\n".
				"Please make sure $cname is defined earlier than $name." 
			);
		}

		#	Read rule table (required)
		#	It seems not necessary to restrict the first character to be alphabetics
		#	$string =~ s/^\s*([A-Za-z]\w*)//	or return( "Invalid rule table name for Compartment in $string" );
		$string =~ s/^\s*(\w+)//	or return( "Invalid rule table name for Compartment in $string" );
		my $rtname = $1;

		#	Read volume (optional)
		my ($exprVOL,$exprVal,$exprErr);
		if ($string =~ s/^\s*([A-Za-z]\w*)\s*//) {
			my $volume=$1;
			($exprVOL,$exprVal,$exprErr)=Expression->newExpression($volume,'algebra',$plist);
			if ($exprErr) {return $exprErr};
			unless ($exprVal) {
				return("Cannot calculate value of volume $volume of compartment $name");
			}
		}
		else {($exprVOL)=Expression->newExpression(1,'algebra');}

		#	Read population (optional)
		my $exprPopu;
		if ($string =~ s/^\s*([A-Za-z]\w*)\s*//) {
			my $population = $1;
			($exprPopu,$exprVal,$exprErr)=Expression->newExpression($population,'algebra',$plist);
			if ($exprErr) { return $exprErr; }
			else { $exprPopu->Name($population); }
			#print Dumper $exprPopu;
			unless ($exprVal) {
				return("CompartmentList->readString: Cannot calculate value of population $population of compartment $name");
			}
		}
		else {($exprPopu)=Expression->newExpression(1,'algebra');}

		if ($string =~ /\S+/) {
			return "Unrecognized trailing syntax $string in compartment specification"; 
		}

		# create compartment
		my $comp = Compartment->new(
			Name=>$name, 
			Outside=>$outside,
			RuleTableName=>$rtname, 
			Volume=>$exprVOL,
			Population=>$exprPopu
		);
		#print "name=$name\n";
		#print Dumper $exprPopu;

		# add compartment to list
		return $clist->add($comp);
	}

	sub add
	{
		my $clist = shift;  # CompartmentList ref

		my $comp = shift;
		ref $comp eq 'Compartment'
		|| return "CompartmentList: Attempt to add non-compartment object $comp to CompartmentList.";   

		if ( exists $clist->Hash->{ $comp->Name } ) { # compartment with same name is already in list
			return "CompartmentList: compartment $comp->Name has been defined previously";
		}
		else{ # add new compartment
			$clist->Hash->{ $comp->Name } = $comp;
			push @{$clist->Array}, $comp;
		}

		# continue adding compartments (recursive)
		if ( @_ )
		{  return $clist->add(@_);  }
		else
		{  return '';  }
	}

	sub getNeighbors {#	get neighbor compartments
		my $clist=shift;
		my $cname=shift;
		my %neighbors=();
		foreach my $comp (@{$clist->Array}) {
			if ($comp->Outside) {#	ROOT
				if ($comp->Name eq $cname) {
					$neighbors{$comp->Outside->Name}=$comp->Outside->RuleTableName;
				}
				elsif ($comp->Outside->Name eq $cname) {
					$neighbors{$comp->Name}=$comp->RuleTableName;
				}
			}
		}
		return \%neighbors;
	}

	sub writeMoDeL 
	{
		my $clist=shift;
		my $out = "";

		# find longest compartment name
		my $max_length = 0;
		my $max_length_1 = 0;
		foreach my $comp (@{$clist->Array})
		{
			$max_length = ($max_length >= length $comp->Name) ? $max_length : length $comp->Name;
			$max_length_1 = ($max_length_1 >= length $comp->RuleTableName) ? $max_length_1 : length $comp->RuleTableName;
		}

		# now write compartment strings
		my $icomp = 1;
		$out .= "<compartments>\n";
		foreach my $comp (@{$clist->Array})
		{
			$out .= sprintf "%5d", $icomp;
			$out .= sprintf "  %-${max_length}s ", $comp->Name;   
			if ($comp->Outside) {
				$out .= sprintf "  %-${max_length}s ", $comp->Outside->Name;
			}
			else { 
				$out .= sprintf "  %-${max_length}s ", '(R)';
			}
			$out .= sprintf " %3.3f ", $comp->Volume->Value;
			$out .= sprintf " %d ", $comp->Population->Value;
			$out .= sprintf "  #  %-${max_length_1}s ", $comp->RuleTableName;
			$out .= "\n";   
			++$icomp; 
		}
		$out .= "</compartments>\n";

		return $out;
	}

	sub writeSBML {
		my $clist=shift;
		my $sbmlModel=shift;
		foreach my $comp (@{$clist->Array}) {
			my $sbmlcomp=$sbmlModel->createCompartment();
			if (my $errcode=$sbmlcomp->setId($comp->Name)) {return $errcode;}
			if (my $errcode=$sbmlcomp->setConstant(0)) {return $errcode;}
			if (my $errcode=$sbmlcomp->setSize($comp->Volume->Value)) {return $errcode;}
			if ($comp->Outside) {
				if (my $errcode=$sbmlcomp->setOutside($comp->Outside->Name)) {return $errcode;}
			}
		}
		return '';
	}
}

1;
