# $Id: Molecule.pm,v 1.9 2007/07/06 04:48:21 faeder Exp $

package Molecule;

use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use Component;
use BNGUtils;


struct Molecule =>
{
    Name        => '$',
    State       => '$',
    Edges       => '@',
    Label       => '$',
    Compartment => 'Compartment',
    Components  => '@',
    Context     => '$'
};


###
###
###


sub newMolecule 
{
	my $string = shift;
	my $clist  = shift;

	my $mol = Molecule->new();
	my $err = $mol->readString( $string, $clist );
	return ( $mol, $err );
}


###
###
###


sub readString
{
	my $mol    = shift;
	my $strptr = shift;
	my $clist  = shift;

	my $string_left = $$strptr;

	# Get molecule name
    # NOTE: for now we allow molecule type to be any alpha-numeric string (possibly numeric)
    #  but in the future we will disallow numeric identifiers.  The 0 symbol will be reserved
    #  for the null species (useful in 0 order synthesis reactions and unimolecular deletions)	
	if ( $string_left =~ s/^(\w+)// )
	#if ( $string_left =~ s/^([A-z]\w*)// )
	{
		$mol->Name($1);
	}
	#elsif ( $string_left =~ s/^(['"][^'"]+['"])// )
	#{   # TODO: is this supported anymore?  deprecate.  --Justin
	#	# read a quoted string, preserving the quotes
	#	$mol->Name($1);
	#}
	else
	{
		return undef, "Invalid molecule name in $string_left";
	}

	# Get molecule state (marked by ~) edges (marked by !) and label (marked by
	# %) and components (enclosed in ())
	my $edge_wildcard = 0;
	while ($string_left)
    {
		# Read components in parentheses
		if ( $string_left =~ s/^[(]// )
        {
			if (@{$mol->Components}) 
            {
				return undef, "Multiple component definitions";
			}
			while ($string_left)
            {
				# Continue characters
				next if ( $string_left =~ s/^,// );
				# Stop characters
				last if ( $string_left =~ s/^\)// );

				# Read component
				my ( $comp, $err ) = Component::newComponent( \$string_left );
				if ($err) {  return undef, $err;  }
			
                # Save components	
                push @{$mol->Components}, $comp;
			}
		}

		# Read attributes in braces
		elsif ( $string_left =~ s/^[{]// )
		{
			while ( !( $string_left =~ s/^\}// ) )
			{
				my $attr  = '';
				my $value = '';

				# Get attribute name
				if ( $string_left =~ s/^([^,=\}]+)// )
                {
					$attr = $1;
				}
				else
                {
					return undef, "Null attribute for Molecule at $string_left";
				}

				# Get (optional) attribute value
				if ( $string_left =~ s/^=([^,\}]+)// )
                {
					$value = $1;
				}

				# Remove trailing comma
				$string_left =~ s/^,//;

				if ( $attr eq "Context" )
                {
					my $val = booleanToInt($value);
					if ( $val == -1 )
                    {
						return undef, "Invalid value $value assigned to Boolean attribute $attr";
					}
					$mol->Context($val);
				}
				else
                {
					return undef, "Invalid attribute $attr for Molecule";
				}
			}
		}

		# Read state, edge, label, or compartment
		elsif ( $string_left =~ s/^([~%!@])(\w+|\+|\?)// )
		{
			my $type = $1;
			my $arg  = $2;
			if ( $type eq '~' )
            {   # State label
				if ( defined $mol->State )
                {
					return undef, "Multiple state definitions";
				}
				if ( $arg =~ /(\w+|\?)/ ) {  $mol->State($arg);  }
                else
                {
                    return undef, "Invalid state label in molecule";
                }
			}
			elsif ( $type eq '!' )
            {   # Bond label or wildcard
				if ( $arg =~ /^[+?]$/ )
                {
					if ($edge_wildcard)
                    {
						return undef, "Multiple edge wildcards in molecule";
					}
					$edge_wildcard = 1;
					push @{$mol->Edges}, $arg;
				}
			}
			elsif ( $type eq '%' )
            {   # Tag label
				if ( defined $mol->Label )
                {
					return undef, "Multiple label definitions";
				}
				$mol->Label($arg);
			}
			elsif ( $type eq '@' )
            {   # Compartment label
				if ( defined $mol->Compartment )
                {
					return undef, "Multiple compartment definitions";
				}

				if ( my $comp = $clist->lookup($arg) )
                {
					$mol->Compartment($comp);
				}
				else
                {
					return undef, "Undefined compartment $arg";
				}
			}
		}
		# Stop characters
		elsif ( $string_left =~ /^(\.|\+|\s+|<?->)/ )
		{
			last;
		}
		# Stop at unrecognized syntax
		else
		{
            last;
		}
	}
	
    $$strptr = $string_left;
	return '';
}


###
###
###


sub toString
{
	my $mol                 = shift;
	my $suppress_edge_names = (@_) ? shift : 0;
	my $speciesCompartment  = (@_) ? shift : '';
	my $suppress_attributes = (@_) ? shift : 0;

	my $string .= $mol->Name;

	$string .= sprintf("~%s", $mol->State)  if (defined $mol->State);

    unless ($suppress_attributes)
    {
	    $string .= sprintf("%%%s", $mol->Label)  if (defined $mol->Label);
	}
	
	if ( defined $mol->Edges )
	{
		if ($suppress_edge_names)
		{
			$string .= "!" x scalar( @{ $mol->Edges } );
		}
		else
		{
			my $wildcard = "";
			foreach my $edge ( @{ $mol->Edges } ) {
				if ( $edge =~ /^\d+$/ ) {
					$string .= sprintf "!%d", $edge + 1;
				}
				else {
					$wildcard = "!$edge";
				}
				$string .= $wildcard;
			}
		}
	}

	if ( defined $mol->Components )
	{
		my $icomp = 0;
		$string .= "(";
		foreach my $comp ( @{$mol->Components} )
		{
			if ($icomp)
			{   $string .= ',';   }
			$string .= $comp->toString($suppress_edge_names, $suppress_attributes);
			++$icomp;
		}
		$string .= ")";
	}
	else {
		$string .= "()";
	}
	if ( defined $mol->Compartment )
	{
		if ( $mol->Compartment != $speciesCompartment )
		{
			$string .= sprintf "@%s", $mol->Compartment->Name;
		}
	}

	# attributes
	my @attr = ();
	if ( $mol->Context ) {
		push @attr, "Context";
	}
	if (@attr) {
		$string .= '{' . join( ',', @attr ) . '}';
	}

	return ($string);
}

sub toStringSSC {
	my $mol = shift;
	my $mname = $mol->Name;
	my $string .= $mol->Name;
	my $icomp = 0;
	my %checkComp;    #A hash to check same component names
	my $sameCompExists = 0;
	if ( defined( $mol->Components ) ) {
		my $comp_index = 0;
		for my $comp ( @{ $mol->Components } ) {
			if ($icomp) {
				$string .= ',';
			}
			if ( defined( $comp->Name ) ) {
				my $cname = $comp->Name;
				if ( exists( $checkComp{$cname} ) ) {
					$temp = $checkComp{$cname};
					$checkComp{$cname} = ++$temp;

					print "\n same component exists for $mname \n";
					print "   SSC rules do not handle components with same name \n";
					print"    In this preliminary version of BNG-SSC translator we do not handle this case";
					# remove this for same comp to work - ++$sameCompExists;
				}
				else {
					$checkComp{$cname} = 0;
				}
				if ( $icomp == 0 )          { $string .= "("; }
				if ( $sameCompExists == 0 ) { $string .= $comp->toStringSSC(); }

               # this is where same components are checked for each molecule, and if sameCompExists != 0, toStringSSC
               # of component.pm adds index to that component
				if ( $sameCompExists != 0 ) {
					#remove this for same comp to work - $string .= $comp->toStringSSC( ( $checkComp{$cname} ) );
				}
			}
			++$icomp;
		}

		if ( $icomp != 0 ) { $string .= ")"; }
	}

	if ( $icomp == 0 ) { $string .= "()"; }
	if ( $sameCompExists != 0 ) {

	# to debug
	# foreach $key ( keys(%checkComp) ){ print "\n $key = $checkComp{$key} \n";}
		# remove this for same component to work - return ( $string, $sameCompExists );
		return ($string, 0);
	}
	return ( $string, 0 );
}

# a subroutine which fetches the number of same components in a molecule.
# returns a hash. key = name of teh component; value = no. of same components
sub getCompHash {
	my $mol = shift;
	my $string .= $mol->Name;
	my %checkComp;    #A hash to check same component names

	if ( defined( $mol->Components ) ) {
		for my $comp ( @{ $mol->Components } ) {
			if ( defined( $comp->Name ) ) {
				my $cname = $comp->Name;
				if ( exists( $checkComp{$cname} ) ) {
					$temp = $checkComp{$cname};
					$checkComp{$cname} = ++$temp;
				}
				else {
					$checkComp{$cname} = 0;
				}
			}
		}
	}
	return (%checkComp);
}

# this toString is just used in corresponding seed species block.
# As in SSC one only specifies molecules, molecules if they hava a defined states
# Or molecules with bonds.

sub toStringSSCMol {
	my $mol                 = shift;
	my $suppress_edge_names = (@_) ? shift : 0;
	my $string              = "";
	my $icomp               = 0;
	my $test                = 0;
	for my $comp ( @{ $mol->Components } ) {
		if ( defined( $comp->Edges ) ) {
			$test = 0;
			for my $edge ( @{ $comp->Edges } ) {
				if ( $edge =~ /^\d+$/ ) {
					++$test;
					if ( $icomp != 0 ) { $string .= ","; }
					if ( defined( $comp->State ) ) {
						if ( $icomp == 0 ) { $string .= "("; }
						$string .= $comp->toStringSSC();
						++$icomp;
					}    #Dont do anything if state has a bond
					     #Changes already in toString of Component.pm
					if ( ( !defined( $comp->State ) ) ) {
						if ( $icomp == 0 ) { $string .= "("; }
						$string .= $comp->Name . "#" . ( $edge + 1 );
						++$icomp;
					}
				}
			}
		}
		if ( $test == 0 ) {
			if ( defined( $comp->State ) ) {
				if ( $icomp == 0 ) { $string .= "("; }
				if ( $icomp != 0 ) { $string .= ","; }
				$string .= $comp->Name . "=\"" . $comp->State . "\"";
				++$icomp;
			}
		}

	}

	if ( $icomp != 0 ) { $string .= ")"; }
	if ( $icomp == 0 ) { $string .= "()"; }
	return ($string);
}

sub toStringMCell {
	my $mol                 = shift;
	my $suppress_edge_names = (@_) ? shift : 0;
	my $speciesCompartment  = (@_) ? shift : "";

	my $string .= $mol->Name;

	if ( defined( $mol->State ) ) {
	#do something	$string .= sprintf "~%s", $mol->State;
	}

	if ( defined( $mol->Label ) ) {
		#$string .= sprintf "%%%s", $mol->Label;
	}

	if ( defined( $mol->Edges ) ) {
		# do something
	}

	if ( defined( $mol->Components ) ) {
		#do something
	}
	
	if ( defined( $mol->Compartment ) ) {
	#do something
	}

	return ($string);
}
sub toXML {
	my $mol    = shift;
	my $indent = shift;
	my $id     = shift;
	my $index  = (@_) ? shift : "";

	my $string = $indent . "<Molecule";

	# Attributes
	# id
	my $mid = sprintf "${id}_M%d", $index;
	$string .= " id=\"" . $mid . "\"";

	# type
	$string .= " name=\"" . $mol->Name . "\"";
	if ( defined( $mol->Label ) ) {
		$string .= " label=\"" . $mol->Label . "\"";
	}
	if ( $mol->Compartment ) {
		$string .= " compartment=\"" . $mol->Compartment->Name . "\"";
	}

	# Objects contained
	my $indent2 = "  " . $indent;
	my $ostring = "";

	# Molecules
	if ( @{ $mol->Components } ) {
		$ostring .= $indent2 . "<ListOfComponents>\n";
		my $cindex = 1;
		for my $comp ( @{ $mol->Components } ) {
			$ostring .= $comp->toXML( "  " . $indent2, $mid, $cindex );
			++$cindex;
		}
		$ostring .= $indent2 . "</ListOfComponents>\n";
	}

	# Termination
	if ($ostring) {
		$string .= ">\n";                       # terminate tag opening
		$string .= $ostring;
		$string .= $indent . "</Molecule>\n";
	}
	else {
		$string .= "/>\n";                      # short tag termination
	}
}



###
###
###



# make exact copy of molecule
sub copy
{
    # get molecule that we want to copy
	my $mol = shift;
    # should we copy labels?
    my $copy_labels = (@_) ? shift : 1;
    # add prefix to edges
    my $prefix = (@_) ? shift : '';

    # create new molecule
	my $mol_copy = Molecule->new();
    
	# copy scalar attributes
	$mol_copy->Name( $mol->Name );
    $mol_copy->State( $mol->State );
    $mol_copy->Label( $mol->Label ) if ($copy_labels);
    $mol_copy->Context( $mol->Context );
    $mol_copy->Compartment( $mol->Compartment ) if (defined $mol->Compartment);

    # copy edges
	if ( @{$mol->Edges} )
	{
	    # add prefix to edge label, unless its a wildcard
	    $mol_copy->Edges( [map {$_=~/^[*+?]$/ ? $_ : $prefix.$_} @{$mol->Edges}] );
	}
	# copy components
	if ( @{$mol->Components} )
	{
		$mol_copy->Components( [map {$_->copy($copy_labels,$prefix)} @{$mol->Components} ] );
	}

    # return molecule copy
	return $mol_copy;
}


###
###
###


# call this method to link Compartments to a new CompartmentList
sub relinkCompartments
{
    my $mol = shift;
    my $clist = shift;
    
    my $err;
    unless ( ref $clist eq 'CompartmentList' )
    {   return "Molecule->relinkCompartments: Error!! Method called without CompartmentList object";   }
    
    if ( defined $mol->Compartment )
    {
        my $new_comp = $clist->lookup( $mol->Compartment->Name );
        unless ($new_comp)
        {   return "Molecule->relinkCompartments: Error!! could not find compartment name in list";   }
        $mol->Compartment( $new_comp );
    }
    
    foreach my $comp ( @{$mol->Components} )
    {
        $err = $comp->relinkCompartments( $clist );
        if (defined $err) {  return $err;  }
    }
    
    return undef;
}



###
###
###



# Molecule comparison for isomorphism
sub compare_local
{
	my $a = shift;
	my $b = shift;

	my $cmp;

	# Molecule name
	if ( $cmp = ( $a->Name cmp $b->Name ) ) {
		return ($cmp);
	}

	# Molecule state
	if ( $cmp = ( $a->State cmp $b->State ) ) {
		return ($cmp);
	}

	# Molecule compartment
	if ( $cmp = ( $a->Compartment->Name cmp $b->Compartment->Name ) ) {
		return ($cmp);
	}

	# Number of edges
	if ( $cmp = ( $#{ $a->Edges } <=> $#{ $b->Edges } ) ) {
		return ($cmp);
	}

	# Number of Components
	*comp_a = $a->Components;
	*comp_b = $b->Components;
	if ( $cmp = ( $#comp_a <=> $#comp_b ) ) {
		return $cmp;
	}

	# Components
	for my $i ( 0 .. $#comp_a ) {
		if ( $cmp = $comp_a[$i]->compare( $comp_b[$i] ) ) {
			return ($cmp);
		}
	}

	return (0);
}

1;
