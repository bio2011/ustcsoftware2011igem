package Species;

use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use SpeciesGraph;
use strict;

struct Species =>
{
    SpeciesGraph        => 'SpeciesGraph',
    Concentration       => '$',
    Index               => '$',		  
    RulesApplied        => '$',
    ObservablesApplied  => '$',
    CVodeRef            => '$',  # a reference to this species within a CVode Vector
};



###
###
###


sub toXML
{
    my $spec= shift;
    my $indent= shift;
    my $id= (@_) ? shift : "S".$spec->Index;

    my $type="Species";
    my $attributes="";

    # Attributes
    # concentration
    $attributes.= " concentration=\"".$spec->Concentration."\"";
    # name
    $attributes.= " name=\"".$spec->SpeciesGraph->toString()."\"";

    # Objects contained
    my $string= $spec->SpeciesGraph->toXML($indent,$type,$id,$attributes);

    return($string);
}


###
###
###


sub getCVodeName
{
    my $species = shift;
    my $offset = -1;
    return 'NV_Ith_S(species,' . ($species->Index + $offset). ')';
}


###
###
###


sub getCVodeDerivName
{
    my $species = shift;
    my $offset = -1;
    return 'NV_Ith_S(Dspecies,' . ($species->Index + $offset). ')';
}


###
###
###


sub getMatlabName
{
    my $species = shift;
    my $offset  = 0;
    return 'species(' . ($species->Index + $offset). ')';
}


###
###
###


sub getMatlabDerivName
{
    my $species = shift;
    my $offset  = 0;
    return 'Dspecies(' . ($species->Index + $offset). ')';
}


###
###
###

1;
