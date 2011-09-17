# Objects for typing and checking Molecules
package MoleculeType;

use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use Molecule;
use ComponentType;


struct MoleculeType =>
{
    Name       => '$',
    Components => '@',     # Array of ComponentTypes
    PopulationType => '$', # Is this a population type molecule?
};


###
###
###


# read a molecule type from the Molecle Types block
sub readString
{
    my $mtype  = shift;
    my $strptr = shift;

    my $string_left = $$strptr;

    # Get molecule name
    # NOTE: for now we allow molecule type to be any alpha-numeric string (possibly numeric)
    #  but in the future we will disallow numeric identifiers.  The 0 symbol will be reserved
    #  for the null species (useful in 0 order synthesis reactions and unimolecular deletions)
    if ( $string_left =~ s/^(\w+)// )
    #if ( $string_left=~ s/^(\w*[A-Za-z]\w*)// )
    {
        my $name= $1;
        $mtype->Name($1);
    }
    else
    {
        return ("Invalid MoleculeType name in $string_left" );
    }

    # By default, set population tag false
    $mtype->PopulationType(0);

    # Get molecule state (marked by ~) edges (marked by !) and label (marked by
    # %) and components (enclosed in ())
    my @elabels=();
    my @components=();
    while($string_left)
    {
        # Read components in parentheses
        if ( $string_left =~ s/^[(]// )
        {
            if ( @components )
            {
	            return("Multiple component definitions");
            }
            
            while ( $string_left )
            {
	            # Continue characters
	            if ( $string_left =~ s/^[,.]// )
	            {
	                next;
	            }
	            # Stop characters
	            elsif ( $string_left =~ s/^[)]\s*// )
	            {
	                last;
	            }
                # Read
	            else
	            {
	                my $comp = ComponentType->new;
	                my $err  = $comp->readString(\$string_left);
	                if ($err) {  return ($err);  }
	                push @components, $comp;
	            }
            }
        }
        # Strip white space
        # (NOTE: this used to be a stop character.  Will removing this cause problems?  --Justin, 7mar2011)
        elsif ( $string_left =~ s/^\s+// )
        {   
            # nothing to do here
        }
        # Stop characters
        elsif ( $string_left =~ /^[,.]|[<]?-[>]/ )
        {
            last;
        }
        # Look for population tag
        elsif ( $string_left =~ s/^population\s*//i ) 
        {
            $mtype->PopulationType(1);
        }
        else
        {
            return ("Invalid MoleculeType specification $$strptr");
        }
    }

    if (@components)
    {
        $mtype->Components([@components]);
    }
    $$strptr = $string_left;

    return ('');
}


###
###
###

sub copy
{
    my $mt = shift;
    
    my $mt_copy = MoleculeType::new();
    $mt_copy->Name( $mt->Name );    
    foreach my $comp ( @{$mt->Components} )
    {
        push @{$mt_copy->Components}, $comp->copy();
    }    
    $mt_copy->PopulationType( $mt->PopulationType );
    
    return $mt_copy;
}


###
###
###


sub add {
  my $mtype=shift;
  my $mol= shift;

  #print "Adding ", $mol->toString(),"\n";
  $mtype->Name($mol->Name);
  my @ctarray;
  @ctarray=();
  for my $comp (@{$mol->Components}){
    my $ctype=ComponentType->new;
    $ctype->Name($comp->Name);
    # The first entry in the States array becomes the default state value
    my $state= $comp->State;
    if ($state ne ""){
      $ctype->States(0,$state);
    }
    push @ctarray, $ctype;
  }
  $mtype->Components([@ctarray]);
  return("");
}


###
###
###


sub check
{
  my $mtype= shift;
  my $mol = shift;
  my $params= shift;

  my $IsSpecies= (defined($params->{IsSpecies})) ? $params->{IsSpecies} : 1;
  my $AllowNewStates= (defined($params->{AllowNewStates})) ? $params->{AllowNewStates} : 1;
  my $AllowPartial= !($IsSpecies);
  my $AllowWildcard= !($IsSpecies);
  my $AllowUndefinedStates= (defined($params->{AllowUndefinedStates})) ? $params->{AllowUndefinedStates} : !($IsSpecies);
  my $InheritList= (defined($params->{InheritList})) ? $params->{InheritList} : 0;

  #print "Checking ", $mol->toString(),"\n";

  @ctypes= @{$mtype->Components};
  for my $comp (@{$mol->Components}){
    my $found=0;
    my $index=0;
    # Check for match for each component
    for my $comp_type (@ctypes){
      if ($comp->Name eq $comp_type->Name){
	my $state= $comp->State;
	if ($state eq ""){
	  # If component state is undefined, check whether component states have been declared, meaning this 
	  # component should not be stateless, unless AllowUndefinedStates is true
	  my $InheritState = ($InheritList) ? $InheritList->[$index] : 0;
	  #print "IS= $InheritState\n";
	  if (@{$comp_type->States} && !$InheritState && !$AllowUndefinedStates){
	    my $err= sprintf "State of component %s of molecule %s must be set", 
	      $comp->Name, $mol->toString(); 
	    return($err);
	  }
	} 
	elsif($state=~/^[*?+]$/){
	  if (!$AllowWildcard){
	    my $err="May not use wildcard for component state in species.";
	    return($err);
	  }
	}
	else {
	  # If component state is defined, check whether no component states have been declared, meaning this
	  # component should be stateless
	  if (!@{$comp_type->States}){
	    my $err= sprintf "Component %s of molecule %s does not accept states", 
	      $comp->Name, $mol->toString(); 
	    return($err);
	  }
	  
	  # Check that $state matches allowed states for this component
	  my $sfound=0;
	  for my $comp_state (@{$comp_type->States}){
	    if ($state eq $comp_state){
	      $sfound=1;
	      last;
	    }
	  }
	  if (!$sfound){
	    if ($AllowNewStates){
	      printf "Adding %s as allowed state of component %s of molecule %s\n", 
		$comp->State, $comp->Name, $mol->Name; 
	      push @{$comp_type->States}, $comp->State;
	    } else {
	      my $err= sprintf "Component state %s of component %s of molecule %s not defined in molecule declaration", 
		$comp->State, $comp->Name, $mol->toString(); 
	      return($err);
	    }
	  } 
	}
	# Delete component type from search array
	splice @ctypes, $index, 1;
	$found=1;
	last;
      } 
      ++$index;
    }
    if (!$found){
      my $err= sprintf "Component %s of molecule %s not found in molecule declaration", $comp->Name, $mol->toString();
      return($err);
    }
  }

  # Incomplete specification of molecule components
  if (!$AllowPartial && @ctypes){
    $names="";
    for my $ct (@ctypes){
      $names.= " ".$ct->Name;
    }
    my $err= sprintf "Component(s)${names} missing from molecule %s", $mol->toString();
    return($err);
  }

  return("");
}


###
###
###


sub toString
{
    my $mtype  = shift;
    my $max_length = (@_) ? shift : 0;

    # get name
    my $string = $mtype->Name; 
    # get components
    my @cstrings = ();
    foreach my $comp ( @{$mtype->Components} )
    {
        push @cstrings, $comp->toString();
    }
    $string .= '(' . join(',', @cstrings) . ')';
    
    if ( $max_length )
    {   # pad with extra spaces so things line up
        my $string_len = length $string;
        if ( $string_len <= $max_length )
        {
            $string .= ' ' x ($max_length - $string_len);
        }
    }

    # write population tag is not written to output!
    if ( $mtype->PopulationType )
    {   $string .= "  population";   }

    return $string;
}


###
###
###


sub toStringSSC{
  my $mtype= shift;
  my $string="";

  $string.= $mtype->Name;

  my @cstrings;
  @cstrings=();
  for my $comp (@{$mtype->Components}){
    push @cstrings, $comp->toStringSSC();
  }
  $string.= "(".join(",",@cstrings).")";

  # NOTE: SSC won't recognize population tag, so dont output. --Justin

  return($string);
}


###
###
###


sub toXML{
  my $mtype= shift;
  my $indent=shift;
  my $string=$indent."<MoleculeType";

  # Attributes
  # id
  $string.=" id=\"".$mtype->Name."\"";
  # population type
  if ( $mtype->PopulationType ) {  $string .= " population=\"1\"";  }

  # Objects
  my $indent2= "  ".$indent;
  my $ostring="";
  # Component list
  if (@{$mtype->Components}){
    $ostring.=$indent2."<ListOfComponentTypes>\n";
    for my $comp (@{$mtype->Components}){
      $ostring.= $comp->toXML("  ".$indent2);
    }
    
    $ostring.=$indent2."</ListOfComponentTypes>\n";
  }

  if ($ostring){
    $string.=">\n"; # terminate tag opening
    $string.= $ostring;
    $string.=$indent."</MoleculeType>\n";
  } else {
    $string.="/>\n"; # short tag termination
  }

  return($string);
}

1;
