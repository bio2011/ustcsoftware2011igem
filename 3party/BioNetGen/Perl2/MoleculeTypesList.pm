# $Id: MoleculeTypesList.pm,v 1.4 2006/09/13 03:44:06 faeder Exp $

# List of MoleculeType objects
package MoleculeTypesList;

use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use MoleculeType;
use SpeciesGraph;
use Molecule;

struct MoleculeTypesList =>
{
    MolTypes     => '%',
    StrictTyping => '$'
};

sub readString{
  my $mtl= shift;
  my $entry= shift;

  # Check if token is an index
  if ($entry=~ s/^\s*(\d+)\s+//){
    my $index= $1; # This index will be ignored
  }
  
  # Next token is string for species graph
  $entry=~ s/^\s*//;
  my $mt= MoleculeType->new;
  $err= $mt->readString(\$entry,1,"",$mtlist);
  if ($err){return($err);}
  if ($entry=~ /\S+/){
    return("Syntax error in MoleculeType declaration");
  }
  
  # Check if type previously defined
  if ($mtl->MolTypes->{$mt->Name}){
    $err= sprintf "Molecule type %s previously defined.", $mt->Name;
    return($err);
  }

  # Create new MoleculeType entry
  $mtl->MolTypes->{$mt->Name}= $mt;

  return("");
}


# get a copy of a moleculeTypesList, along with copies of all the moleculeTypes
sub copy
{
    my $mtlist = shift;
    
    my $mtlist_copy = MoleculeTypesList::new();
    while ( my ($name,$mt) = each %{$mtlist->MolTypes} )
    {
        my $mt_copy = $mt->copy();
        $mtlist_copy->MolTypes->{$mt_copy->Name} = $mt_copy;
    }
    $mtlist_copy->StrictTyping( $mtlist->StrictTyping );
    
    return $mtlist_copy;
}


# add a moleculeType to the list
sub add
{
    my $mtlist = shift;
    my $mt = shift;
 
    if ( exists $mtlist->MolTypes->{$mt->Name} )
    {   # molecule type is already in list
        return 0;
    }
    else
    {   # add molecule type to list
        $mtlist->MolTypes->{$mt->Name} = $mt;
        return 1;
    }
}

# Check whether Molecules in SpeciesGraph match declared types
# Set $params->{IsSpecies} to 1 to force all components to be 
# declared with defined states (if states are defined for the component)

sub checkSpeciesGraph{
  my $mtl= shift;
  my $sg= shift;
  my $params= (@_) ? shift : "";

  #printf "Checking %s\n", $sg->toString();

  my $IsSpecies= (defined($params->{IsSpecies})) ? $params->{IsSpecies} : 1;
  my $AllowNewTypes= (defined($params->{AllowNewTypes})) ? $params->{AllowNewTypes} : 0;

  *moltypes= $mtl->MolTypes;
  for my $mol (@{$sg->Molecules}){
    my $mtype;
    if ($mol->Name =~ /[*]/){
      my $found_match=0;
      # Handle mol names containing wildcards
      for $mtype (keys %moltypes){
	next unless ($mol->Name =~ $mtype);
	if ($mtype->check($mol,$params) eq ""){
	  ++$found_match;
	}
	if (!$found_match){
	  my $err= sprintf "Molecule string %s does not match any declared molecule types", $mol->toString();
	  return($err);
	}
      }
    } elsif ($mtype= $moltypes{$mol->Name}){
      # Validate against declared type
      if (my $err=$mtype->check($mol,$params)){
	return($err);
      }
    } else {
      # Type not found.  
      if ($AllowNewTypes){
	#Define a new type
	my $mtype= MoleculeType->new;
	$mtype->add($mol);
	$moltypes{$mol->Name}= $mtype;
      }
      else {
	my $err= sprintf "Molecule %s does not match any declared molecule types", $mol->toString();
	#$err.= "\n".$mtl->writeBNGL();
	return($err);
      }
    }
  }

  return("");
}

sub checkMolecule{
  my $mtl= shift;
  my $mol= shift;
  my $params= (@_) ? shift : "";

  my $IsSpecies= (defined($params->{IsSpecies})) ? $params->{IsSpecies} : 1;
  my $AllowNewTypes= $IsSpecies;

  *moltypes= $mtl->MolTypes;
  my $mtype;
  if ($mtype= $moltypes{$mol->Name}){
    #printf "Checking %s against %s\n", $mol->toString(), $mtype->toString();
    # Validate against declared type
    if (my $err=$mtype->check($mol,$params)){
      return($err);
    }
  } else {
    # Type not found.  
    if ($AllowNewTypes){
      #Define a new type
      my $mtype= MoleculeType->new;
      $mtype->add($mol);
      $moltypes{$mol->Name}= $mtype;
    } else {
      my $err= sprintf "Molecule %s does not match any declared molecule types", $mol->toString();
      return($err);
    }
  }
  
  return("");
}



###
###
###



sub writeBNGL
{
    my $mtlist = shift;
    my $vars   = (@_) ? shift : {NETfile=>0};

    # find longest molecule type
    my $max_length = 0;
    unless ( $vars->{NETfile} ) 
    {
        while ( my ($name, $mt) = each %{$mtlist->MolTypes} )
        {    
            my $string = $mt->toString();
            $max_length = ( length $string > $max_length ) ? length $string : $max_length;
        }
    }

    my $out = "begin molecule types\n";
    $out .= "\n"  unless ( $vars->{NETfile} );
    my $index = 1;
    while ( my ($name, $mt) = each %{$mtlist->MolTypes} )
    {
        if ( $vars->{NETfile} )
        {
            $out .= sprintf "%5d %s\n", $index, $mt->toString();
        }
        else
        {
            $out .= '  ' . $mt->toString($max_length) . "\n";
        }
        ++$index;
    }
    $out .= "\n"  unless ( $vars->{NETfile} );    
    $out .= "end molecule types\n";
    
    return $out;
}



###
###
###



sub toXML{
  my $mtlist= shift;
  my $indent=shift;
  my $string=$indent."<ListOfMoleculeTypes>\n";
  # loop over molecule types
  for my $mname (sort keys %{$mtlist->MolTypes}){
    my $mt= $mtlist->MolTypes->{$mname};
    $string.= $mt->toXML("  ".$indent);
  }
  $string.=$indent."</ListOfMoleculeTypes>\n";
  return($string);
}



1;
