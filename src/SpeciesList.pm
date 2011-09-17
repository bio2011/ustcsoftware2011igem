package SpeciesList;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use Species;
use SpeciesGraph;
use Utils;
use Expression;

{
	my $print_on=1;	#	switch on/off print

	struct SpeciesList =>
	{
		Array	=>	'@',	#	array of species
		Hash	=>	'%'		#	hash of species
	};

	sub readString
	{
		my $slist =shift;
		my $string= shift;
		my $plist = shift;
		my $clist = shift;
		
		#	Read compartment (required)
		$string =~ s/^\s*([A-Za-z]\w*)// or return("Invalid compartment name in $string");
		my $cname = $1;
		$clist->Hash->{$1} || return("Compartment name $cname is not in CompartmentList");

		#	Read name (required)
		$string =~ s/^\s*([A-Za-z]\w*)// or return("Invalid species name in $string");
		my $sname = $1;
		return("SpeciesList->readString: Seed species with name ".
			"$sname has been defined previously") if $slist->Hash->{$1};

		#	Read structure (required)
		$string =~ s/^\s*(\S+)// or return("Invalid species structure in $string");
		my $structure = $1;
		my ($graph,$graphErr) = SpeciesGraph->newSpeciesGraph ($structure,0);
		if ($graphErr) { return $graphErr; }

		#	Read initial concentration (required)
		$string =~ s/^\s*([A-Za-z]\w*)// or return("Invalid species initial concentration in $string");
		my $init_c = $1;
		my ($exprInitConc,$exprVal,$exprErr)=Expression->newExpression($init_c,'algebra',$plist);
		if ($exprErr) {return $exprErr;}
		unless ($exprVal) {
			return("Cannot calculate value of initial concentration $init_c of species $sname");
		}

		#	Read const	(optional)
		my $const = 1;
		if ($string =~ s/^\s*([A-Za-z]+)//) {
			$const = boolean2int ($1);
			if ($const == -1) { return("Unrecognized boolean value $1"); }
		}

		if ($string =~ /\S+/) {
			return ("Unrecognized trailing syntax in seedspecies specification");
		}

		my $index = $#{$slist->Array}+1;
		my $species = Species->new(
			Name=>$sname,
			Index=>$index,
			Compartment=>$cname,
			InitConcentration=>$exprInitConc,
			Constant=>$const,
			isSeedSpecies=>1,
			SpeciesGraph=>$graph
		);

		# Create new Species entry in SpeciesList
		$slist->add($species);

		return '';
	}

	sub addNewGenSpecies {#	init concentraion=0, const=0
		my $slist=shift;
		my $string=shift; #	structure
		my $cname=shift;	# compartment name
		my ($graph,$graphErr) = SpeciesGraph->newSpeciesGraph ($string,0);
		if ($graphErr) { return ('', $graphErr); }
		my ($exprInitConc,undef,undef)=Expression->newExpression(0.0,'algebra');
		my $index = $#{$slist->Array}+1;
		my $species = Species->new(
			Name=>"s".($index+1),
			Index=>$index,
			Compartment=>$cname,
			InitConcentration=>$exprInitConc,
			Constant=>0,
			isSeedSpecies=>0,
			SpeciesGraph=>$graph
		);
		$slist->add($species);
		return $index;
	}

	sub add
	{
		my $slist = shift;  # CompartmentList ref

		my $spec = shift;
		ref $spec eq 'Species'
		|| return "SpeciesList: Attempt to add non-species object $spec to SpeciesList.";   

		if ( exists $slist->Hash->{ $spec->Name } ) { # species with same name is already in list
			return "SpeciesList: species $spec->Name has been defined previously";
		}
		else{ # add new species
			$slist->Hash->{ $spec->Name } = $spec;
			push @{$slist->Array}, $spec;
		}

		# continue adding species (recursive)
		if ( @_ )
		{  return $slist->add(@_);  }
		else
		{ return '';}
	}

	sub print{
		
		if ($print_on) {
			my $slist= shift;
			my $fh= shift;	#filehandle
			my $i_start= (@_) ? shift : 0;

			print $fh "begin species\n";
			my $sarray= $slist->Array;
			for my $i ($i_start..$#{$sarray}){
				my $spec= $sarray->[$i];
				printf $fh "%5d	%s %s \n", $i-$i_start+1, 
					$spec->SpeciesGraph->String, 
					$spec->SpeciesGraph->EquivSeqGroups2String();
			}
			print $fh "end species\n";
			return("");
		}
	}

	sub getSpeciesIndex {
		my $slist=shift;
		my $string=shift;	#	structure
		my $cname=shift;	#	compartment name
		
		for my $i (0..$#{$slist->Array}) {
			my $spec=$slist->Array($i);
			if ($spec->Compartment eq $cname) {
				if ($spec->SpeciesGraph->String eq $string) {
					return $i;
				}
			}
		}
		return undef;
	}

	sub findSpecies {
		my $slist=shift;
		my $spec0graph=shift;
		my $spec0cname=shift;
		foreach my $spec (@{$slist->Array}) {
			return $spec->Index if $spec->equal($spec0graph,$spec0cname);
		}
		return -1;
	}

	sub writeMoDeL 
	{
		my $slist=shift;
		my $clist=shift;
		my $out = "";

		my $max_length = 0;
		foreach my $spec (@{$slist->Array}) {
			$max_length = ($max_length >= length $spec->Name) ? $max_length : length $spec->Name;
		}

		my $ispec = 1;
		$out .= "<species>\n";
		foreach my $comp (@{$clist->Array}) {
			$out .= "  #  ".$comp->Name."\n";
			foreach my $spec (@{$slist->Array}) {
				if ($spec->Compartment eq $comp->Name) {
					$out .= sprintf "%5d", $ispec;
					$out .= sprintf "  %-${max_length}s ", $spec->Name;   
					$out .= sprintf "  %3.3e  ", $spec->InitConcentration->Value;
					$out .= sprintf "  %s  ", $spec->SpeciesGraph->String;
					$out .= "  #  Seed  " if $spec->isSeedSpecies;
					$out .= "\n";   
					++$ispec; 
				}
			}
		}
		$out .= "</species>\n";
		return $out;
	}

	sub writeSBML {
		my $slist=shift;
		my $sbmlModel=shift;
		foreach my $spec (@{$slist->Array}) {
			my $sbmlspec=$sbmlModel->createSpecies();
			if(my $errcode=$sbmlspec->setCompartment($spec->Compartment)) {return $errcode;}
			if(my $errcode=$sbmlspec->setId($spec->Name)) {return $errcode;}
			if(my $errcode=$sbmlspec->setName($spec->SpeciesGraph->String)) {return $errcode;}
			if(my $errcode=$sbmlspec->setInitialConcentration($spec->InitConcentration->Value)) {return $errcode;}
			if ($spec->isConst) {
				if(my $errcode=$sbmlspec->setConstant($spec->isConst)) {return $errcode;}
			}
			#if(my $errcode=$sbmlspec->setHasOnlySubstanceUnits(0)) {return $errcode;}
			#if(my $errcode=$sbmlspec->setBoundaryCondition(0)) {return $errcode;}
		}
		return '';
	}
}

1;
