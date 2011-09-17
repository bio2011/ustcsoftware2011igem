# $Id: SpeciesList.pm,v 1.14 2007/02/20 17:37:01 faeder Exp $

package SpeciesList;

use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use Species;
use SpeciesGraph;
use MoleculeTypesList;
use BNGUtils;
use ParamList;



# Members
struct SpeciesList =>
{
    Array      => '@',
    Hash       => '%',
    Hash_exact => '%'
};



###
###
###



sub sort
{
    my $slist = shift;

    print "Sorting species list\n";
    my @newarr = sort {$a->SpeciesGraph->StringExact cmp $b->SpeciesGraph->StringExact} @{$slist->Array};
    $slist->Array(\@newarr);
    my $ispec = 1;
    foreach my $spec ( @{$slist->Array} )
    {
        $spec->Index($ispec);
        ++$ispec;
    }

    return $slist;
}



###
###
###



# Returns pointer to matching species in $slist or null if no match found
sub lookup
{
    my $slist = shift;
    my $sg = shift;
    my $check_iso = (@_) ? shift : 1;

    if( $sg->IsCanonical ) {  $check_iso = 0;  }

    my $spec = undef;
    my $sstring = $sg->StringID;
    if ( exists $slist->Hash->{$sstring} )
    {
        # Since string is not completely canonical, need to check isomorphism with other list members
        # Determine whether the graph is isomorphic to any on the current list
        if ($check_iso)
        {
            my $found_iso=0;
            foreach my $spec2 ( @{$slist->Hash->{$sstring}} )
            {
	            if ($sg->isomorphicTo($spec2->SpeciesGraph))
	            {
                    $spec = $spec2;
                    $found_iso=1;
                    last;
                }
            }
        }
        else
        {
            #print "Not checking isomorphism\n";
            $spec = $slist->Hash->{$sstring}->[0];
        }
    }
    return $spec;
}



###
###
###



sub lookup_bystring {
  my $slist=shift;
  my $sstring=shift;

  return($slist->Hash_exact->{$sstring});
}

# Returns reference to Species object either newly created or found in $slist
# Should check if species already exists in list before adding
sub add {
  my $slist= shift;
  my $sg= shift;
  my $conc= (@_) ? shift : 0;

  *hash= $slist->Hash;
  *hash_exact= $slist->Hash_exact;
  *array= $slist->Array;

  # Create new species from SpeciesGraph
  $spec=Species->new;
  push @array, $spec;
  push @{$hash{$sg->StringID}}, $spec;
  $hash_exact{$sg->StringExact}= $spec; # Can only be one entry
  $spec->SpeciesGraph($sg);
  $spec->Concentration($conc);
  $spec->Index($#array+1);
  $spec->RulesApplied(0);
  # Put ref to species in SpeciesGraph to bind it
  $sg->Species($spec);

  return($spec);
}

sub remove{
  my $slist=shift;
  my $spec= shift;

  #print "Removing species ", $spec->Index," ",$spec->SpeciesGraph->toString(),"\n";

  # Remove from Array
  splice(@{$slist->Array}, $spec->Index-1,1);
  
  # Remove from Hash 
  *harray= $slist->Hash->{$spec->SpeciesGraph->StringID};
  for my $i (0..$#harray){
    if ($spec==$harray[$i]){
      splice(@harray,$i,1);
      if (!@harray){
	undef $slist->Hash->{$spec->SpeciesGraph->StringID};
      }
      last;
    }
  }

  # Remove from Hash_exact
  undef $slist->Hash_exact->{$spec->SpeciesGraph->StringExact};

  return;
}


# Read entry from input species block

sub readString
{
  my $slist=shift;
  my $string= shift;
  my $plist= shift;
  my $clist= shift;
  my $mtlist= (@_) ? shift : "";
  my $AllowNewTypes= (@_) ? shift : 0;

  my $conc, $sg, $err;

  my $name='';
#  if ($string=~ s/^\s*([^:].*)[:]\s*//){
#    # Check if first token is a name for the species (first occurence of a ':')
#    $name= $1;
#    #print "(user) name=$name\n";
#  }
#  # Check if token is an index (ignored)
#  elsif ($string=~ s/^\s*(\d+)\s+//){
#  }

  if ( $string =~ s/^\s*(\d+)\s+// ) {}

  # Read species string
  $sg = SpeciesGraph->new;
  $string =~ s/^\s+//;
  $err = $sg->readString( \$string, $clist, 1, '^\s+', $mtlist, $AllowNewTypes );
  if ($err) { return ($err); }

  # Check if isomorphic to existing species
  my $existing= $slist->lookup($sg);
  if ($existing)
  {
      my $sstring = $sg->StringExact;
      my $index = $existing->Index;
      return ( "Species $sstring isomorphic to previously defined species index $index" );
  }

  # Read species concentration as math expression (set to 0 if not present)
  # Set species concentration to number or variable name
  if ( $string=~ /\S+/ )
  {
    # Read expression
    my $expr= Expression->new();
    if ( my $err = $expr->readString( \$string, $plist ) ) { return ('', $err) }
    if ( $expr->Type eq 'NUM' )
    {
        $conc = $expr->evaluate();
    }
    else
    {
        $conc = $expr->getName( $plist, 'InitialConc' );
    }
  }
  else
  {
      $conc = 0;
  }

  # Create new Species entry in SpeciesList
  $slist->add($sg, $conc);
  
  return ('');
}



###
###
###



sub writeBNGL
{
    my $slist = shift;
    my $conc  = (@_) ? shift : undef;
    my $plist = (@_) ? shift : '';
    my $print_names = (@_) ? shift : 0;
    my $vars  = (@_) ? shift : {NETfile=>0};

    # Determine length of longest species string
    my $maxlen = 0;
    foreach my $spec ( @{$slist->Array} )
    {
        my $len = length($spec->SpeciesGraph->Name.$spec->SpeciesGraph->StringExact) + 1;
        $maxlen = ($len > $maxlen) ? $len : $maxlen;
    }

    my $out .= "begin species\n";
    #$out .= "\n"  unless ( $vars->{NETfile} );
    foreach my $spec ( @{$slist->Array} )
    {
        if ( $vars->{NETfile} )
        {   $out .= sprintf "%5d ", $spec->Index;   }
        else
        {   $out .= '  ';   }

        my $sname;
        my $sexact = $spec->SpeciesGraph->toString(0);
        if ( my $name = $spec->SpeciesGraph->Name )
        {
            if ( $sexact =~ /[:]/ )
            {   $sname .= $name.$sexact;   }
            else
            {   $sname .= $name . ':' . $sexact;   }	
        }
        else
        {
            $sname=$sexact;
        }
        $out .= sprintf "%-${maxlen}s", $sname;
        
        my $c;
        if ( defined $conc  and  @$conc )
        {
            $c = $conc->[$spec->Index - 1];
        }
        else
        {
            $c = $spec->Concentration;
        }
        $out .= sprintf " %s\n", $c;
    }
    #$out .= "\n"  unless ( $vars->{NETfile} );    
    $out .= "end species\n";
    
    return $out;
}



###
###
###



sub writeSSC{
  my $slist= shift;
  my $conc= (@_) ? shift: "";
  my $plist= (@_) ? shift : "";
  my $print_names= (@_) ? shift : 0;
  my $string="";

  # Determine length of longest species string. Not sure, what it does
  my $maxlen=0;
  for my $spec (@{$slist->Array}){
          my $len= length($spec->SpeciesGraph->Name.$spec->SpeciesGraph->StringExact)+1;
          $maxlen= ($len> $maxlen) ? $len : $maxlen;
  }

  for my $spec (@{$slist->Array}){
          my $sname;
          my $sexact= $spec->SpeciesGraph->toStringSSCMol();
          $sname=$sexact;
          $string .= "new $sname at ";
          my $c;
          $c= $spec->Concentration;
          $string .= $c;
          $string.= "\n";
  }

  return($string);
}


sub print{
  my $slist= shift;
  my $fh= shift;
  my $i_start= (@_) ? shift : 0;

  print $fh "begin species\n";
  *sarray= $slist->Array;
  for my $i ($i_start..$#sarray){
    my $spec= $sarray[$i];
    printf $fh "%5d %s %s\n", $i-$i_start+1, $spec->SpeciesGraph->StringExact, $spec->Concentration;
  }
  print $fh "end species\n";
  return("");
}

sub toXML{
  my $slist= shift;
  my $indent=shift;
  # Use concentration array if provided
  my $conc= (@_) ? shift : "";

  my $string=$indent."<ListOfSpecies>\n";

  my $i=0;
  for my $spec (@{$slist->Array}){
    my $saved_conc;
    if ($conc){
        $saved_conc= $spec->Concentration;
        $spec->Concentration($conc->[$i])
    }
    $string.= $spec->toXML("  ".$indent);
    if ($conc){
        $spec->Concentration($saved_conc)
    }
    ++$i;
  }

  $string.= $indent."</ListOfSpecies>\n";
  return($string);
}


# assign CVode references to each species in the list
#sub updateCVodeRefs
#{
#    my $slist = shift;
#    my $plist = (@_) ? shift : undef;
#    
#    my $err;
#    
#    my $n_species = 0;
#    foreach my $species ( @{$slist->Array} )
#    {
#        $species->CVodeRef( "NV_Ith_S(species,$n_species)" );
#        ++$n_species;
#    }

#    return ($err);
#}


###
###
###


sub toCVodeString
{
    my $slist       = shift;
    my $rlist       = shift;
    my $stoich_hash = shift;
    my $plist       = (@_) ? shift : undef;

    my $deriv_defs = '';
    my $indent = '    ';
    my $err;

    # construct derivative definition for each species
    foreach my $species ( @{ $slist->Array } )
    {
        # get species vector in stoich hash
        my $species_vector = $stoich_hash->{ $species->Index };
        my $species_deriv = '';
        
        if ( $species->SpeciesGraph->Fixed )
        {   # handle species with fixed population
            $species_deriv = 0.0;
        }
        else
        {   # handle all other species...
            # add rates and stoich for each reaction that influences this speices
            foreach my $i_rxn ( keys %$species_vector )
            {
                # get species stoichiometry under this reaction
                my $stoich = $species_vector->{$i_rxn};
                
                # look up reaction object
                my $i_rxn0 = $i_rxn - 1;
                my $rxn = $rlist->Array->[$i_rxn0];
                
                # add this reaction flux to the species derivative
                if    ( $stoich == 1 )
                {   $species_deriv .= " +" . $rxn->getCVodeName();             }
                elsif ( $stoich == 0 )
                {                                                              }
                elsif ( $stoich == -1 )
                {   $species_deriv .= " -" . $rxn->getCVodeName();             }
                elsif ( $stoich > 0 )
                {   $species_deriv .= " +$stoich.0*" . $rxn->getCVodeName();   }
                elsif ( $stoich < 0 )
                {   $species_deriv .= " $stoich.0*" . $rxn->getCVodeName();    } 
            } 

            # trim leading " +"
            $species_deriv =~ s/^ \+?//;
        
            # replace empty string with a zero rate
            if ($species_deriv eq '')
            {   $species_deriv = '0.0';   }
        }
            
        # add derivative to list of definitions
        $deriv_defs .= $indent . $species->getCVodeDerivName() . " = $species_deriv;\n"; 
    }

    return ( $deriv_defs, $err );
}


###
###
###


sub toMatlabString
{
    my $slist       = shift;
    my $rlist       = shift;
    my $stoich_hash = shift;
    my $plist       = (@_) ? shift : undef;

    my $deriv_defs = '';
    my $indent = '    ';
    my $err;

    # construct derivative definition for each species
    foreach my $species ( @{ $slist->Array } )
    {
        # get species vector in stoich hash
        my $species_vector = $stoich_hash->{ $species->Index };
        my $species_deriv = '';
        
        if ( $species->SpeciesGraph->Fixed )
        {   # handle species with fixed population
            $species_deriv = '0.0';
        }
        else
        {   # handle all other species...
            # add rates and stoich for each reaction that influences this speices
            foreach my $i_rxn ( keys %$species_vector )
            {
                # get species stoichiometry under this reaction
                my $stoich = $species_vector->{$i_rxn};
                
                # look up reaction object
                my $i_rxn0 = $i_rxn - 1;
                my $rxn = $rlist->Array->[$i_rxn0];
                
                # add this reaction flux to the species derivative
                if    ( $stoich == 1 )
                {   $species_deriv .= " +" . $rxn->getMatlabName();             }
                elsif ( $stoich == 0 )
                {                                                               }
                elsif ( $stoich == -1 )
                {   $species_deriv .= " -" . $rxn->getMatlabName();             }
                elsif ( $stoich > 0 )
                {   $species_deriv .= " +$stoich.0*" . $rxn->getMatlabName();   }
                elsif ( $stoich < 0 )
                {   $species_deriv .= " $stoich.0*" . $rxn->getMatlabName();    } 
            } 

            # trim leading " +"
            $species_deriv =~ s/^ \+?//;
        
            # replace empty string with a zero rate
            if ($species_deriv eq '')
            {   $species_deriv = '0.0';   }
        }
            
        # add derivative to list of definitions
        $deriv_defs .= $indent . $species->getMatlabDerivName() . " = $species_deriv;\n"; 
    }

    return ( $deriv_defs, $err );
}


###
###
###


# get names of species and formulas for initial concentrations for matlab
sub getMatlabSpeciesNames
{
    my $slist = shift;
    my $plist = (@_) ? shift : undef;
    
    my $err;
    my $species_names = '';
    my $species_init = '';
    my $indent = '    ';
    
    # TODO: this matlab output is a hack.  improve this.  --justin

    # generate a map from param names to matlab references
    my $ref_map = {};
    my $m_idx = 1;
    foreach my $param ( @{ $plist->Array } )
    {
        if ( $param->Type eq 'Constant' )
        {
            $ref_map->{ $param->Name } = "params($m_idx)";
            ++$m_idx;
        }
    }
    
    # gather names and init expressions for all species
    $m_idx = 1;
    my @species_names = ();    
    foreach my $species ( @{ $slist->Array } )
    {
        push @species_names, "'" . $species->SpeciesGraph->StringExact . "'";    
        (my $param) = $plist->lookup( $species->Concentration );    
    
        if ( $param )
        {   # initial concentration is given by a Parameter
            # expand the expression (recursively past parameters!)
            $species_init .= $indent . "species_init($m_idx) = " . $param->toString( $plist, 0, 2 ) . ";\n";          
        }
        else
        {   # initial concentration is a number
            $species_init .= $indent . "species_init($m_idx) = " . $species->Concentration . ";\n";
        }  
        ++$m_idx;
    }
    
    # replace param names with Matlab references   
    foreach my $pname ( keys %$ref_map )
    {
        my $matlab_ref = $ref_map->{$pname};
        my $regex = 
        $species_init =~ s/(^|\W)$pname(\W|$)/$1$matlab_ref$2/g;
    }
    
    return (  join(', ', @species_names), $species_init, $err );
}

sub getMatlabSpeciesNamesOnly
{
	my $slist = shift;
	my $err;
	my @species_names = ();    
    foreach my $species ( @{ $slist->Array } )
    	{
    		push @species_names, "'" . $species->SpeciesGraph->StringExact . "'";
    	}
    
    return (  join(', ', @species_names), $err );

}


1;
