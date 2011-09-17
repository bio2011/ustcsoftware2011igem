# $Id: ParamList.pm,v 1.11 2007/08/24 15:10:13 faeder Exp $

package ParamList;

use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use Param;
use Expression;
use BNGUtils("isReal","send_warning");



# Members
struct ParamList =>
{
    Parent    => 'ParamList',
    Array     => '@',
    Hash      => '%',
    Unchecked => '@'	     
};


###
###
###



sub copyConstant
{
    my $plist = shift;
 
    my $plist_copy = ParamList::new();
    foreach my $param ( @{$plist->Array} )
    {
        next unless ($param->Type eq 'Constant'  or  $param->Type eq 'ConstantExpression' );
        my $param_copy = $param->copyConstant( $plist );
        $plist_copy->set( $param->Name, $param->Expr, 1, $param->Type, undef ); 
    }
    
    # check and sort paramlist
	if ( my $err = $plist_copy->check() ) {  print "complain about parameter check\n";  return undef;  }
	if ( my $err = $plist_copy->sort()  ) {  print "complain about parameter sort\n";   return undef;  }    
    
    return $plist_copy;
}



# Lookup a parameter by name.
#  Returns referenc to parameter, if found.
#  Otherwise returns undefined.
sub lookup
{
    my $plist = shift;
    my $name  = shift;

    my $param;  
    if ( exists $plist->Hash->{$name} )
    {
        return $plist->Hash->{$name}, '';
    }
    elsif ( defined $plist->Parent )
    {
        return $plist->Parent->lookup($name);
    }
    else
    {
        return undef, "Parameter $name not defined";
    }
}


###
###
###


sub getChildList
{
    my $plist = shift;
    
    my $child = ParamList::new();
    $child->Parent( $plist );
    
    return $child;
}


###
###
###




# Find an un-used name in the parameter list
#  that begins with "basename".
# Don't put the name in the list yet!
sub getName
{
    my $plist    = shift;
    my $basename = (@_) ? shift : "k";
  
    my $name;
    # Find unused name
    my $index = 1;
    while (1)
    {
        my ( $param, $err ) = $plist->lookup( "${basename}_${index}" );
        last unless $param;
        ++$index;
    }
    $name = "${basename}_${index}";
    return ($name);
}



###
###
###



sub evaluate
{
    my $plist  = shift;
    my $name   = shift;
    my $args   = (@_) ? shift : [];
    my $level  = (@_) ? shift : 0;  

    my ($param,$err) = $plist->lookup($name);
    if (defined $param)
    {
        return $param->evaluate($args, $plist, $level + 1);
    }
    elsif ( isReal($name) )
    {   
        # in a few cases, a simple number may appear where a parameter name is expected
        # (e.g. Concentration). In these cases, just return the value.
        return $name;
    }
    else
    {
        print "$name is not a valid number or parameter.";
        return undef;
    }
}



###
###
###



# parse parameter from a BNGL string
sub readString
{
    my $plist  = shift;
    my $string = shift;
    my $allow_undefined = (@_) ? shift : 0;

    my $sptr = \$string;
    my ($name, $val);

    # Remove leading index and whitespace
    $$sptr =~ s/^\s*\d+\s+//;

    # Convert non assignment format to assignment
    unless ( $$sptr =~ /^\s*\S+\s*=/ )
    {
        unless ( $$sptr =~ s/^\s*(\S+)\s+/$1=/ )
        {
            return "Invalid parameter declaration $$sptr: format is [index] name[=]Expression";
        }
    }

    # Read expression
    my $expr = Expression->new();
    $expr->setAllowForward(1);
    if ( my $err = $expr->readString($sptr,$plist) ) {  return $err;  }
    # string should be empty now.
    if ($$sptr) {  return "Syntax error at $$sptr";  }
    $expr->setAllowForward(0);

    return '';
}



###
###
###



# By default, allows previously defined variable to be overwritten.  Use $no_overwrite=1 to stop.
sub set
{
    my $plist = shift;
    my $name  = shift;
    my $rhs   = (@_) ? shift : '';     # this is the expression!
    my $no_overwrite = (@_) ? shift : 0;
    my $type   = (@_) ? shift : ''; # Overrides derived type of rhs
    my $ref    = (@_) ? shift : ''; # Reference to Function or Observable
    my $global = (@_) ? shift : 0;  # add parameter to top plist

    
    if ($global)
    {   # find top plist
        while (defined $plist->Parent)
        {
            $plist = $plist->Parent;
        }
    }

    # Find existing parameter
    my ($param,$err)= $plist->lookup($name);
    # or add new parameter to array
    unless (defined $param)
    {
        #print "Adding parameter $name\n";
        $param = Param->new( Name=>$name );
        # add to array, unless Local or RRef
        unless ( $type eq 'Local'  or  $type eq 'RRef' )
        {   push @{$plist->Array}, $param;   }
        # add to hash
        $plist->Hash->{$name} = $param;
        # Add parameter to list of parameters to be checked
        unless ( $type eq 'Local'  or  $type eq 'RRef' )
        {   push @{$plist->Unchecked}, $param;   }
        # Return leaving param unset if no rhs
        if ($rhs eq '')
        {   return ('');   }
    }
  
    # check if we're overwriting a parameter
    if ($param->Expr ne '')
    {
        if ($no_overwrite)
        {   return "Changing value of previously defined variable $name is not allowed";   }
        else
        {   send_warning( "Changing value of previously defined variable $name" );   }
    }

    # Handle scalar (string) argument (probably from setParameter)
    if ( ref \$rhs eq 'SCALAR' )
    {
        my $expr = Expression->new( Type=>'NUM', Arglist=>[$rhs] );
        $rhs = $expr;
    } 

    # Set Param->Expression
    $param->Expr($rhs);
    
    # Set Param->Type
    if ($type ne '')
    {
        $param->setType($type);
        # Set reference
        if ($ref)
        {   $param->Ref($ref);   }
        elsif ( $type eq 'Function' )
        {
            # create a function out of the RHS expression
            my $fun = Function->new();   
            $fun->Name($param->Name);
            $fun->Expr($param->Expr);
            # look for variables with expression
            my $vhash = $param->Expr->getVariables($plist);       
            #  find local variables and assign as function arguments
            my @args = keys %{$vhash->{Local}};
            $fun->Args([@args]);           
            # finally, point param Ref field to this function
            $param->Ref($fun);                
        }
    }
    elsif ($rhs->Type eq 'NUM')
    {
        $param->setType('Constant');
    }
    else
    {
        # Get hash of variables reference in Expr
        my $vhash = $param->Expr->getVariables($plist);
        if ( $vhash->{Observable} || $vhash->{Function} )
        {
            $param->setType('Function');
            my $fun= Function->new();
            $fun->Name($param->Name);
            $fun->Expr($param->Expr);
            my @args = keys %{$vhash->{Local}};
            $fun->Args([@args]);
            $param->Ref($fun);
        }
        elsif ( $vhash->{Constant} or $vhash->{ConstantExpression} )
        {
            $param->setType('ConstantExpression');
        }
        else
        {
            # Expression contains only number arguments
            $param->setType('Constant');
        }
    }

    return '';
}



###
###
###



sub toString
{
    my $plist = shift;

    my $out = '';
    foreach my $param ( @{$plist->Array} )
    {
        $out .= sprintf "Parameter %s=%s\n", $param->Name, $param->toString($plist);
    }
    return $out;
}



###
###
###



# This serves an input file in SSC which contains information corresponding to our parameters block in BNG
sub writeSSCcfg
{
    my $plist= shift;   
    #my $NETfile= shift;

    my $out = "# begin parameters\n";
    my $iparam = 1;
    foreach my $param ( @{$plist->Array} )
    {
        my $type = $param->Type;
        next unless ( $type =~ /^Constant/ );
        $out .= " " . $param->Name . " = ";
        $out .= $param->evaluate([],$plist) . "\n";
        ++$iparam;
    }
    $out .= "# end parameters\n";

    return $out;
}



###
###
###



sub writeBNGL
{
    my $plist   = shift;
    my $NETfile = shift;

    # find longest parameter name
    my $max_length = 0;
    foreach my $param (@{$plist->Array})
    {
        $max_length = ($max_length >= length $param->Name) ? $max_length : length $param->Name;
    }

    # now write parameter strings
    my $iparam = 1;
    my $out .= "begin parameters\n";
    $out .= "\n"  unless ($NETfile);
    foreach my $param (@{$plist->Array})
    {
        next unless ( $param->Type =~ /^Constant/ ); 

        if ($NETfile)
        {
            $out .= sprintf "%5d ", $iparam;
            $out .= sprintf "%-${max_length}s  ", $param->Name;    
     	    $out .= $param->evaluate([], $plist);
            $out .= "  # " . $param->Type . "\n";    
        }
        else
        {
            $out .= sprintf "  %-${max_length}s ", $param->Name;   
            $out .= $param->toString($plist) . "\n";   
        }
        ++$iparam; 
    }
    $out .= "\n"  unless ($NETfile);    
    $out .= "end parameters\n";
    
    return $out;
}



###
###
###



sub writeFunctions
{
    my $plist = shift;
    my $vars  = (@_) ? shift : {NETfile=>0};


    my $max_length = 0;
    unless ( $vars->{NETfile} )
    {
        # find longest function name
        foreach my $param ( @{$plist->Array} )
        {
		    my $type= $param->Type;
            next unless ( $param->Type eq 'Function' );
        
            my $string = $param->Ref->toString( $plist, 1);
            $string =~ /\=/g;
            $max_length = ( pos $string > $max_length ) ? pos $string : $max_length;
        }
    }

    my $out = "begin functions\n\n";
    my $iparam=1;
    foreach my $param ( @{$plist->Array} )
    {
		my $type= $param->Type;
        next unless ( $param->Type eq 'Function' );
        
        if ( $vars->{NETfile} )
        {
            next if ( $param->Ref->checkLocalDependency($plist) );
            $out .= sprintf "%5d", $iparam;
            $out .= ' ' . $param->Ref->toString( $plist, 0) . "\n";
        }
        else
        {
            # nice formatting for BNGL output
            $out .= '  ' . $param->Ref->toString( $plist, 1, $max_length) . "\n";
        }
        ++$iparam;
    }
    $out.="\nend functions\n";
	
	# Don't output null block
    if ( $iparam==1 ){  $out = '';  }
 
    return $out;
}



###
###
###



sub copyFunctions
{
    my $plist = shift;
    
    my $fcn_copies = [];
    foreach my $param ( @{$plist->Array} )
    {
        if ( $param->Type eq 'Function' )
        {
            # arguments are: parameter list, level, same_name
            my ($fcn_copy,$err) = $param->Ref->clone( $plist, 0, 1 );
            push @$fcn_copies, $fcn_copy;
        }
    }
    
    return $fcn_copies;
}



###
###
###



# Delete a parameter from the ParamList by name
sub deleteLocal
{
    my $plist = shift;
    my $pname = shift;
    
    # Find parameter
    my ($param,$err) = $plist->lookup($pname);
    if ($err) {  return($err);  }
    
    # check that this is a local type
    if ($param->Type ne 'Local') {  return "Parameter $pname is not a local parameter";  }
    
    # remove param from lookup hash
    delete $plist->Hash->{$pname};
    
    # undefine parameter object
    %{$param} = ();
    $param = undef;

    return '';
}



###
###
###



# Delete a parameter from the ParamList by name
sub deleteParam
{
    my $plist = shift;
    my $pname = shift;
    
    # Find parameter
    my ($param,$err) = $plist->lookup($pname);
    if ($err) {  return($err);  }
    
    # remove param from lookup hash
    delete $plist->Hash->{$pname};
    
    # remove param from array (expensive)
    my $index = @{$plist->Array};
    while ($index > 1)
    {
        --$index;
        if ( $param == $plist->Array->[$index] )
        {
            splice( @{$plist->Array}, $index, 1);
            last;
        }
    }
  
    # remove param from unchecked (expensive)
    my $index = @{$plist->Unchecked};
    while ($index > 1)
    {
        --$index;
        if ( $param == $plist->Unchecked->[$index] )
        {
            splice( @{$plist->Unchecked}, $index, 1);
        }
    }

    # undefine parameter object
    undef %{$param};
    $param = undef;

    return '';
}



###
###
###



# check the parameter list undefined or cyclic dependency
sub check
{
    my $plist = shift;
    my $err  = '';
  
    foreach my $param (@{$plist->Unchecked})
    {
        # Check that variable has defined value
        #printf "Checking if parameter %s is defined.\n", $param->Name;
        unless ( $param->Type )
        {
            $err= sprintf "Parameter %s is referenced but not defined", $param->Name;
            last;
        }
    }
    if ($err) { return ($err) };

    foreach my $param ( @{$plist->Unchecked} )
    {
        #printf "Checking parameter %s for cycles.\n", $param->Name;
        # Check that variable doesn't have cylic dependency
        (my $dep, $err) = ($param->Expr->depends( $plist, $param->Name ));
        if ($dep)
        {
            $err= sprintf "Parameter %s has a dependency cycle %s", $param->Name, $param->Name.'->'.$dep;
            last;
        }
    }
  
    # Reset list of Unchecked parameters if all parameters passed checks.
    unless ( $err )
    {
        undef @{$plist->Unchecked};
        #printf "Unchecked=%d\n", scalar(@{$plist->Unchecked});
    }
    return ($err);
}



###
###
###



# sort the Array of parameters by dependency
{
    my $plist;
    my $err;
    sub sort
    {
        $plist = shift;
        $err   = '';
    
        $plist->Array( [sort by_depends @{$plist->Array}] );
        return($err);
    }

    sub by_depends
    {
        (my $dep_a, $err) = $a->Expr->depends( $plist, $b->Name );
        if ($err)
        {   #printf "$err %s %s\n", $a->Name, $b->Name;
            return(0);
        }

        if ($dep_a)
        {   #printf "%s depends on %s\n", $a->Name, $b->Name;
            return(1);
        }

        (my $dep_b, $err) = $b->Expr->depends( $plist, $a->Name );
        if ($err)
        {
            return(0);
        }
    
        if ($dep_b)
        {   #printf "%s depends on %s\n", $b->Name, $a->Name;
            return(-1);
        }

        #printf "%s and %s are independent\n", $a->Name, $b->Name;
        return(0);
    }
}



###
###
###



# Assign indices to Parameters. BNG doesn't use this, but it's helpful
#  for writing network models in vector form.
#  NOTE:  Constant and ConstantExpression types are indexed separately
#   from Observable types.  Function and Local types not indexed.
sub indexParams
{
    my $plist = shift;
    my $err;  
    
    # check parameter list for undefined and cyclic dependency
    ($err) = $plist->check();
    if ( $err ) { return ( undef, $err) };
    
    # sort paramlist by dependency!
    ($err) = $plist->sort();
    if ( $err ) { return ( undef, $err) };    

    # index parameter types
    my $n_expressions = 0;
    my $n_observables = 0;
        
    # loop through parameters and generate
    foreach my $param ( @{ $plist->Array } )
    {
        my $type = $param->Type;
        my $expr = $param->Expr;
        if    ( $type eq 'Constant')
        {
            $param->Index( $n_expressions );
            $param->CVodeRef( "NV_Ith_S(expressions,$n_expressions)" );
            ++$n_expressions;
        }
        elsif ( $type eq 'ConstantExpression' )
        {        
            $param->Index( $n_expressions );
            $param->CVodeRef( "NV_Ith_S(expressions,$n_expressions)" );
            ++$n_expressions;    
        }
        elsif ( $type eq 'Observable' )
        {
            $param->Index( $n_observables );
            $param->CVodeRef( "NV_Ith_S(observables,$n_observables)" );
            ++$n_observables;
        }
        else
        {
            $param->Index( undef );
            $param->CVodeRef( '' );
        }
    }

    return ($err);
}



###
###
###



# return a string with CVode expression defintions.
#  Call "indexParams" before this!
sub getCVodeExpressionDefs
{
    my $plist = shift;
    
    # !!! Assume that parameter list is checked and sorted by dependency !!!

    # expression definition string
    my $expr_defs = '';
    # to hold errors..
    my $err;  
    # count constants
    my $n_constants   = 0;   
    # size of the indent
    my $indent = '    ';
    
    # loop through parameters and generate
    foreach my $param ( @{ $plist->Array } )
    {
        # get type
        my $type = $param->Type;
        if    ( $type eq 'Constant')
        {
            # constants are defined in terms of the input parameters
            $expr_defs .= $indent . $param->getCVodeName() . " = parameters[$n_constants];\n";
            ++$n_constants;
        }
        elsif ( $type eq 'ConstantExpression' )
        {   
            # constant expressions are defined in terms of other expressions
            $expr_defs .= $indent . $param->getCVodeName() . " = " .  $param->Expr->toCVodeString( $plist ) . ";\n";    
        }
    }

    return ($expr_defs, $err);
}



###
###
###



# return a string with Matlab expression defintions.
#  Call "indexParams" before this!
sub getMatlabExpressionDefs
{
    my $plist = shift;
    
    # !!! Assume that parameter list is checked and sorted by dependency !!!

    # expression definition string
    my $expr_defs = '';
    # to hold errors..
    my $err;  
    # count constants
    my $n_constants = 0;   
    # size of the indent
    my $indent = '    ';
    # matlab array index offset
    my $offset = 1;
    
    # loop through parameters and generate
    foreach my $param ( @{ $plist->Array } )
    {
        # get type
        my $type = $param->Type;
        if    ( $type eq 'Constant')
        {
            # constants are defined in terms of the input parameters
            $expr_defs .= $indent . $param->getMatlabName() . " = parameters(" . ($n_constants + $offset) . ");\n";
            ++$n_constants;
        }
        elsif ( $type eq 'ConstantExpression' )
        {   
            # constant expressions are defined in terms of other expressions
            $expr_defs .= $indent . $param->getMatlabName() . " = " .  $param->Expr->toMatlabString( $plist ) . ";\n";    
        }
    }

    return ($expr_defs, $err);
}



###
###
###



# return a string with CVode observable defintions.
sub getCVodeObservableDefs
{
    my $plist = shift;

    # expression definition string
    my $obsrv_defs = '';
    # to hold errors..
    my $err;   
    # size of the indent
    my $indent = '    ';
    
    # loop through parameters and generate observable definitions
    foreach my $param ( @{ $plist->Array } )
    {
        if ( $param->Type eq 'Observable')
        {
            my $obsrv = $param->Ref;
            # constants are defined in terms of the input parameters
            $obsrv_defs .= $indent . $param->getCVodeName() . " = " . $obsrv->toCVodeString($plist) . ";\n";
        }
    }

    return ($obsrv_defs, $err);
}



###
###
###



# return a string with Matlab observable defintions.
sub getMatlabObservableDefs
{
    my $plist = shift;

    # expression definition string
    my $obsrv_defs = '';
    # to hold errors..
    my $err;   
    # size of the indent
    my $indent = '    ';
    
    # loop through parameters and generate observable definitions
    foreach my $param ( @{ $plist->Array } )
    {
        if ( $param->Type eq 'Observable')
        {
            my $obsrv = $param->Ref;
            # constants are defined in terms of the input parameters
            $obsrv_defs .= $indent . $param->getMatlabName() . " = " . $obsrv->toMatlabString($plist) . ";\n";
        }
    }

    return ($obsrv_defs, $err);
}



###
###
###



# get names of constnat parameters and default values in a string that define
# matlab arrays
sub getMatlabConstantNames
{
    my $plist = shift;
    
    my $err;
    
    my @default_values = ();
    my @constant_names = ();  

    # loop through parameters and generate names and values for constants
    foreach my $param ( @{ $plist->Array } )
    {
        if ( $param->Type eq 'Constant')
        {
  		    push @default_values, $param->evaluate([], $plist); 
            my $constant_name = $param->Name;
            $constant_name =~ s/\_/\\\_/g;
  		    push @constant_names, "'" . $constant_name . "'";
        }    
    }
    
    return (  join(', ', @constant_names), join(', ', @default_values), $err );
}



###
###
###



# get names of observables for matlab
sub getMatlabObservableNames
{
    my $plist = shift;
    
    my $err;
    
    my @observable_names = ();  
    # loop through params and find observables
    foreach my $param ( @{ $plist->Array } )
    {
        if    ( $param->Type eq 'Observable')
        {
	        my $observable_name = $param->Name;
	        $observable_name =~ s/\_/\\\_/g;
	        push @observable_names, "'" . $observable_name . "'";
        }    
    }
    
    return (  join(', ', @observable_names), $err );
}



###
###
###


 
# count the number of parameters with a type
sub countType
{
    my $plist = shift;
    my $type  = shift;
    
    my $count = 0;
    foreach my $param ( @{$plist->Array} )
    {
        ++$count  if ( $param->Type  eq $type );
    }
    return $count;
}



###
###
###

1;
