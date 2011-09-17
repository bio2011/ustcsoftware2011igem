package Observable;

use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use BNGUtils;
use BNGModel;
use SpeciesGraph;


# Members
struct Observable =>
{
    Name      => '$',		   
    Patterns  => '@',
    Weights   => '@',
    Type      => '$',
    Output    => '$',           # If false, suppress output.  (Feature not yet implemented)
};



###
###
###



sub copy
{
    my $obs = shift;
    
    my $obs_copy = Observable::new();
    $obs_copy->Name( $obs->Name );
    $obs_copy->Type( $obs->Type );
    $obs_copy->Output( $obs->Output );
    
    foreach my $patt ( @{$obs->Patterns} )
    {
        my $patt_copy = $patt->copy();
        push @{$obs_copy->Patterns}, $patt_copy;
    }
    
    if ( defined $obs->Weights )
    {
        $obs_copy->Weights( [ @{$obs->Weights} ] );
    }

    return $obs_copy;
}


###
###
###



# call this method to link Compartments to a new CompartmentList
sub relinkCompartments
{
    my $obs = shift;
    my $clist = shift;
    
    my $err = undef;
    unless ( ref $clist eq 'CompartmentList' )
    {   return "Observable->relinkCompartments: Error!! Method called without CompartmentList object";   }
    
    foreach my $patt ( @{$obs->Patterns} )
    {
        $err = $patt->relinkCompartments( $clist );
        if (defined $err) {  return $err;  }
    }
    
    return undef;
}



###
###
###



sub clearWeights
{
    my $obs = shift;
    @{$obs->Weights} = ();
}



###
###
###



sub evaluate
{
    my $obs = shift;
    my $args  = (@_) ? shift : [];        
    my $plist = (@_) ? shift : undef;
    my $level = (@_) ? shift : 0;
    
    # evaluate all the remaining arguments
    my $eval_args = [];
    my $ii=1;
    while ( $ii < @$args )
    {
        push @$eval_args, $args->[$ii]->evaluate( $plist, $level+1 );
        ++$ii;
    }             
    
    # first argument is reactant pointer
    my $species_idx = $eval_args->[0];
    unless ( $species_idx =~ /^\d+$/  and  $species_idx >= 0 )
    {  die "Observable->evaluate(): Error! Observable argument was not a species Index!";  }
    
    # evaluate this observable on the species
    $val = (defined $obs->Weights->[$species_idx]) ? $obs->Weights->[$species_idx] : 0;
}


###
###
###



sub readString
{
    my $obs    = shift;
    my $string = shift;
    my $model  = shift;
    my $AllowNewTypes = (@_) ? shift : 0;
    
    my $err;

    my $plist= $model->ParamList;
    my $clist= $model->CompartmentList;
    my $mtlist= $model->MoleculeTypesList;

    # set output true (by default)
    $obs->Output(1);

    # Check if first token is an index
    if ( $string =~ s/^\s*\d+\s+// )
    {
        # This index will be ignored
    }

    # Check if next token is observable type
    #  Adding Counter and Population types  --Justin, 5nov2010
    #  Function observable is undocumenterd, but its here to include function
    #    evaluations among the output observables --Justin
    if ( $string =~ s/^\s*(Molecules|Species|Counter|Population|Function)\s*// )
    {
        # record observable type
        $obs->Type($1);
    }
    else
    {

        # Justin thinks defaults like this are dangerous and prone to unpredictable behavior
        #  when future changes are made to the language or code.  Return error instead
        #return "Observable type is not valid";
        
        # this is the old default behavior.  leave in tact for now.
        $obs->Type('Molecules');

    }

    # Next token is observable Name
    if ( $string =~ s/^\s*([A-z]\w*)\s+// )
    {
        my $name=$1;
        $obs->Name($name);
    }
    else
    {
        my ($name) = split(' ', $string);
        return "Invalid observable name $name: may contain only alphnumeric and underscore";
    }

    if ( $obs->Type ne 'Function' )
    {
        # Define parameter with name of the Observable
        if ( $plist->set( $obs->Name, "0", 1, "Observable", $obs) )
        {
      	    my $name= $obs->Name;
            return "Observable name $name matches previously defined Observable or Parameter";
        }

        # Remaining entries are patterns
        my $sep = '^\s+|^\s*,\s*';
        *patterns = $obs->Patterns;
        while ($string)
        {
            my $g = SpeciesGraph->new();

            #Passing values to the following parameters in readString of SpeciesGraph.pm:
            #      $AllowNewTypes         = 0
            #      $AllowNewStates        = 0
            #      $AllowUndefinedStates  = 1
            #To resolve the bug to allow addition of new states in Observables, if not mentioned in /
            #Molecule types block or otherwise.  Arshi Dec7'2010

            my $count_autos = $obs->Type eq 'Molecules' ? 1 : 0;
            $err = $g->readString( \$string, $clist, 0, $sep, $mtlist,
                                   $AllowNewTypes, $AllowNewTypes, 1, $count_autos );

            if ($err) {  return "While reading observable " . $obs->Name . ": $err";  }

            $string=~ s/$sep//;
            if ( ($obs->Type eq 'Species') and ($g->Quantifier eq ''))
            { 
                $g->MatchOnce(1);
            }
            push @patterns, $g;
        }
    }
    else
    {
        # This is a Function observable (this undocumented'feature' might be dropped --Justin)
        # remainder of string is expression..
        my $expr = Expression::new();
        $expr->setAllowForward(1);
        if ( my $err = $expr->readString( \$string, $plist ) )
        {  return ($err);  }
      
        # check for remaining string
        if ( $string )
        {  return ( "Syntax error at $string" );  }
        
        $expr->setAllowForward(0);
   
        # Define parameter with name of the Observable
        if ( $plist->set( $obs->Name, $expr, 1, 'Observable', $obs ) )
        {
      	    my $name= $obs->Name;
            return "Observable name $name matches previously defined Observable or Parameter";
        }
    }
    
    return $err;
}



###
###
###



#sub toString
#{
#    my $obs = shift;
#    # used to align columns nicely
#    my $max_length = (@_) ? shift : 0;
#
#    # write name
#    my $string .= sprintf "%-10s ", $obs->Type;
#    $string    .= $obs->Name . ' ';
#    if ($max_length)
#    {
#        my $name_length = length $obs->Name;
#        if ( $max_length >= $name_length )
#        {   $string .= ' ' x ($max_length - $name_length);   } 
#    }
#    # write patterns
#    foreach my $patt ( @{$obs->Patterns} )
#    {
#        $string .= '  ' . $patt->toString();
#    }
#
#    return $string;
#}

sub toString{
  my $obs=shift;
  my $string="";

  $string.= $obs->Type.' '.$obs->Name;
  for my $patt (@{$obs->Patterns}){
    $string.= " ".$patt->toString();
  }

  return($string);
}

###
###
###


sub toStringSSC
{
  my $obs=shift;
  my $string="";

  for my $patt (@{$obs->Patterns}){
    ( my $tempstring, my $trash) = $patt->toStringSSC();
    $string.= " ".$tempstring;
  }

  return($string);
}


###
###
###


# replaced with new method (see below)  --Justin
#sub toMatlabString
#{
#    my $obs = shift;
#   
#    # create linear sum of terms that contribute to the observable
#    my @terms = ();
#    for ( my $idx=1; $idx < @{$obs->Weights}; $idx++ )
#    {  
#        if ( defined $obs->Weights->[$idx] )
#        {
#            my $term;
#            if ( $obs->Weights->[$idx] == 1 )
#            {  $term = "x($idx)";  }
#            else
#            {  $term = $obs->Weights->[$idx] . "*x($idx)";  }
#            push @terms, $term;
#        }
#    }   
#    return '(' . join('+', @terms) . ')';
#}


###
###
###


sub toCVodeString
{
    my $obs = shift;
    my $plist = (@_) ? shift : undef;
   
    if ( $obs->Type ne 'Function' )
    {
        # create linear sum of terms that contribute to the observable
        # BE CAREFUL: species indexed starting from 1.
        my @terms = ();
        for ( my $idx1=1; $idx1 < @{$obs->Weights}; $idx1++ )
        {  
            my $idx0 = $idx1 - 1;
            if ( defined $obs->Weights->[$idx1] )
            {
                my $term;
                if ( $obs->Weights->[$idx1] == 1 )
                {  $term = "NV_Ith_S(species,$idx0)";  }
                else
                {  $term = $obs->Weights->[$idx1] . "*NV_Ith_S(species,$idx0)";  }
                push @terms, $term;
            }
        }
        if ( @terms )
        {   return join( ' +', @terms );   }
        else
        {   return "0.0";  }
    }
    else
    {
        # handle function type observable!
        ( my $param, my $err ) = $plist->lookup( $obs->Name );
        return $param->Expr->toCVodeString( $plist );
    }    
}


###
###
###


sub toMatlabString
{
    my $obs = shift;
    my $plist = (@_) ? shift : undef;
   
    if ( $obs->Type ne 'Function' )
    {
        # create linear sum of terms that contribute to the observable
        # BE CAREFUL: species indexed starting from 1.        
        my @terms = ();
        for ( my $idx1=1; $idx1 < @{$obs->Weights}; $idx1++ )
        {  
            if ( defined $obs->Weights->[$idx1] )
            {
                my $term;
                if ( $obs->Weights->[$idx1] == 1 )
                {  $term = "species($idx1)";  }
                else
                {  $term = $obs->Weights->[$idx1] . "*species($idx1)";  }
                push @terms, $term;
            }
        }
        if ( @terms )
        {   return join( ' +', @terms );   }
        else
        {   return "0.0";  }
    }
    else
    {
        # handle function type observable!
        ( my $param, my $err ) = $plist->lookup( $obs->Name );
        return $param->Expr->toMatlabString( $plist );
    }    
}


###
###
###


sub toXML
{
  my $obs= shift;
  my $indent= shift;
  my $index= shift;

  my $id= "O".$index;

  my $string=$indent."<Observable";

  # Attributes
  # id
  $string.= " id=\"".$id."\"";
  # name
  if ($obs->Name){
    $string.= " name=\"".$obs->Name."\"";
  }
  # type
  if ($obs->Type){
    $string.= " type=\"".$obs->Type."\"";
  }

  # Objects contained
  my $indent2= "  ".$indent;
  my $ostring=$indent2."<ListOfPatterns>\n";
  my $ipatt=1;
  for my $patt (@{$obs->Patterns}){
    my $indent3= "  ".$indent2;
    my $pid= $id."_P".$ipatt;
    $ostring.= $patt->toXML($indent3,"Pattern",$pid,"");
    ++$ipatt;
  }
  $ostring.=$indent2."</ListOfPatterns>\n";

  # Termination
  if ($ostring){
    $string.=">\n"; # terminate tag opening
    $string.= $ostring;
    $string.=$indent."</Observable>\n";
  } else {
    $string.="/>\n"; # short tag termination
  }
}


###
###
###


# try to match observable to a speciesGraph and return the number of matches
sub match
{
    my $obs  = shift;
    my $sg   = shift;

    # Loop over patterns and find matches
    my $total_matches = 0;    
    foreach my $patt (@{$obs->Patterns})
    {
        # find matches of this pattern in species graph
        my @matches = $patt->isomorphicToSubgraph($sg);
            
        # add correction for symmetry!
        my $n_match = scalar @matches;
        # SYMMETRY CORRECTION is disabled for the time being!
        #  Uncommend the following block to enable the correction.  --Justin 15mar2010
        #if ( $obs->Type eq 'Molecules' )
        #{
        #    $n_match /= $patt->Automorphisms;
        #}
            
        # add these matches, if found
        next unless $n_match;
        # check quantitifer
        if ($patt->Quantifier)
        {
	        my $test = $n_match.$patt->Quantifier;
	        my $result = eval $test;
	        next unless $result;
        }
        # check the species observable
        if ($obs->Type eq 'Species') {  $n_match = 1;  }
        # add matches
        $total_matches += $n_match;
    }

    return $total_matches;
}


###
###
###


sub update
{
    my $obs = shift;
    my $species = shift;
    my $idx_start = (@_) ? shift : 0;

    my $err = '';
  
    # This appears to be a little speed tweak..
    #   Make sure full size of array is allocated, but don't risk overwritting the last element.
    unless ($#$species < 0)
    {
        $obs->Weights->[$#$species] = $obs->Weights->[$#$species];
    }

    # Loop over patterns to generate matches; update weight at index of each match.
    foreach my $patt (@{$obs->Patterns})
    {
        for ( my $ii = $idx_start; $ii < @$species; ++$ii )
        {
            my $sp = $species->[$ii];
            next if ( $sp->ObservablesApplied );

            # find matches of this pattern in species graph
            my @matches = $patt->isomorphicToSubgraph( $sp->SpeciesGraph );
            
            # add correction for symmetry!
            my $n_match = (scalar @matches);
            # SYMMETRY CORRECTION is disabled for the time being!
            #  Uncommend the following block to enable the correction.  --Justin 15mar2010
            #if ( $obs->Type eq 'Molecules' )
            #{
            #    $n_match /= $patt->Automorphisms;
            #}
            
            # add these matches, if found
            next unless $n_match;
            if ($patt->Quantifier)
            {
	            my $test = $n_match.$patt->Quantifier;
	            my $result = eval $test;
	            #print "($test) $result\n";
	            next unless $result;
            }

            if ($obs->Type eq 'Species') {  $n_match = 1;  }
            $obs->Weights->[$sp->Index] += $n_match;
        }
    }

    return $err;
}


###
###
###

my $print_match=0;

###
###
###


sub getWeightVector
{
  my $obs=shift;
  my @wv=();

  foreach my $i ( 1..$#{$obs->Weights} )
  {
    my $w= $obs->Weights->[$i];
    if ($w){
      push @wv, $w;
    } else {
      push @wv, 0;
    }
  }
  return (@wv);
}


###
###
###


sub toGroupString
{
  my $obs=shift;
  my $slist=shift;
  my $out= sprintf "%-20s ", $obs->Name;

  my $i=-1;
  my $first=1;
  my $n_elt=0;
  for my $w (@{$obs->Weights}){
    ++$i;
    next unless $w;
    ++$n_elt;
    if ($first){
      $first=0;
    } else {
      $out.=",";
    }
    if ($w==1){
      $out.= "$i";
    } else {
      $out.= "$w*$i";
    }
  }
  
  if ($print_match){
    print $obs->Patterns->[0]->toString(),": ";
    my $i=-1;
    for my $w (@{$obs->Weights}){
      ++$i;
      next unless $w;
      my $sstring= $slist->Array->[$i-1]->SpeciesGraph->toString();
      for my $nw (1..$w){
	print "$sstring, ";
      }
    }
    print "\n";
  }

  #printf "Group %s contains %d elements.\n", $obs->Name, $n_elt;
  return $out;
}


###
###
###


# Returns number of nonzero elements in the Group
sub sizeOfGroup
{
  my $obs= shift;

  my $n_elt=0;
  for my $w (@{$obs->Weights}){
    next unless $w;
    ++$n_elt;
  }
  return($n_elt);
}


###
###
###


sub printGroup
{
    my $obs     = shift;
    my $fh      = shift;
    my $species = shift;
    my $idx_start = (@_) ? shift : 0;

    printf $fh "%s ", $obs->Name;
  
    my $first=1;
    for ( my $ii = $idx_start;  $ii < @$species;  ++$ii )
    {
        $spec = $species->[$ii];

        my $sp_idx = $spec->Index;
        my $weight = $obs->Weights->[$sp_idx];
        next unless $weight;

        if ($first) {   $first = 0;   }
        else {   print $fh ",";   }
        
        if ( $weight==1 ) {   print $fh $sp_idx;   }
        else {   print $fh "$weight*$sp_idx";   }
    }
    print $fh "\n";
    return '';
}


###
###
###


sub toMathMLString
{
  my $obs=shift;
  my $string="";

  $string.= "<math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n";
  my $n_elt= $obs->sizeOfGroup();

  $string.= "  <apply>\n";
  $string.= "    <plus/>\n";
  if ($n_elt==1){
    $string.=   sprintf "      <cn> 0 </cn>\n";
  }

  my $i=-1;
  for my $w (@{$obs->Weights}){
    ++$i;
    next unless $w;
    if ($w==1){
      $string.=   sprintf "    <ci> S%d </ci>\n", $i;
    } else {
      $string.=   "    <apply>\n";
      $string.=   "      <times/>\n";
      $string.=   sprintf "      <cn> %s </cn>\n", $w;
      $string.=   sprintf "      <ci> S%d </ci>\n", $i;
      $string.=   "    </apply>\n";
    }
  }
  # Include zero entry if no nonzero weights
  if ($n_elt==0){
    $string.= "    <cn> 0 </cn>\n";
  }

  $string.= "  </apply>\n";
  $string.= "</math>\n";

  return ($string,"");
}


###
###
###

1;
