# $Id: Expression.pm,v 1.7 2007/02/20 17:39:38 faeder Exp $

# updated by msneddon, 2009/11/04
#   -added if statement as built in function
#   -added binary logical operators, <,>.<=,>=,==,!=,~=,&&,||
#    to the basic functional parser, the toString function, and 
#    to the evaluate function

#   -todo: add binary operators to method toMathMLString function
#   -todo: add the unary operator not: '!' (this is implemented, but not tested. --JSH)

package Expression;

use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use Param;
use ParamList;

# safer to use 'floor' and 'ceil' instead of 'int'
use POSIX qw/floor ceil/;


struct Expression =>
{
    Type    => '$',    # Valid types are 'NUM', 'VAR', 'FUN', '+', '-', '*', '/', '^', '**',
                       # '>','<','>=','<=','==','!=','~=','&&','||','!','~'
    Arglist => '@',
    Err     => '$',
};


# NOTE: it's weird that some built-in functions with names (like exp, cos, etc) are handled
#  differently thant built-ins with operator symbols (like +, -, etc).  We could really simplify this.
#  --Justin
%functions =
(
  "exp"  => { FPTR => sub { exp( $_[0] ) },   NARGS => 1 },
  "cos"  => { FPTR => sub { cos( $_[0] ) },   NARGS => 1 },
  "sin"  => { FPTR => sub { sin( $_[0] ) },   NARGS => 1 },
  "log"  => { FPTR => sub { log( $_[0] ) },   NARGS => 1 },
  "abs"  => { FPTR => sub { abs( $_[0] ) },   NARGS => 1 },
  "int"  => { FPTR => sub { int( $_[0] ) },   NARGS => 1 },  # deprecated!
  "floor"=> { FPTR => sub { floor( $_[0] ) }, NARGS => 1 },
  "ceil" => { FPTR => sub { ceil( $_[0] ) },  NARGS => 1 },
  "sqrt" => { FPTR => sub { sqrt( $_[0] ) },  NARGS => 1 },
  "if"   => { FPTR => sub { if($_[0]) { $_[1] } else { $_[2] } }, NARGS => 3 }, #added line, msneddon
);


my $MAX_LEVEL = 500;    # Prevent infinite loop due to dependency loops


# this hash maps operators to the min and max number of arguments
my %NARGS = ( '+'  => { 'min'=>2           },
              '-'  => { 'min'=>1           },
              '*'  => { 'min'=>2           },
              '/'  => { 'min'=>2           },
              '^'  => { 'min'=>2, 'max'=>2 },
              '**' => { 'min'=>2, 'max'=>2 },
              '&&' => { 'min'=>2           },
              '||' => { 'min'=>2           }, 
              '<'  => { 'min'=>2, 'max'=>2 },
              '>'  => { 'min'=>2, 'max'=>2 },
              '<=' => { 'min'=>2, 'max'=>2 },
              '>=' => { 'min'=>2, 'max'=>2 },
              '!=' => { 'min'=>2, 'max'=>2 },
              '~=' => { 'min'=>2, 'max'=>2 },              
              '==' => { 'min'=>2, 'max'=>2 },
              '!'  => { 'min'=>1, 'max'=>1 },
              '~'  => { 'min'=>1, 'max'=>1 }
            );


# this regex matches numbers (regular and scientific notation
#my $NUMBER_REGEX = '^[\+\-]?(\d+\.?\d*|\.\d+)(|[Ee][\+\-]?\d+|\*10\^\d+)$';
my $NUMBER_REGEX = '^[\+\-]?(\d+\.?\d*|\.\d+)(|[Ee][\+\-]?\d+|\*10\^[\+\-]?\d+)$';
# this regex matches param names (letter followed optional by word characters)
my $PARAM_REGEX  = '^[A-Za-z]\w*$';


###
###
###


# get a recursive copy of an expression.
#   Note that the recursion does not descend past VAR and FUN type expressions.
#   Returns a refence to the clone and any error messages.
sub clone
{
    my $expr = shift;
    my $plist = (@_) ? shift : undef;
    my $level = (@_) ? shift : 0;
    
    if ( $level > $MAX_LEVEL ) {  die "Max recursion depth $MAX_LEVEL exceeded.";  }
    
    my $err = '';

    # create a new array for cloned argument    
    my $clone_args = [];
    # create clone
    my $clone = Expression->new();
    $clone->Type( $expr->Type );
    $clone->Arglist( $clone_args );
    $clone->Err( '' );

    # clone argument expressions
    #print STDERR "  expr type: ", $clone->Type, "\n";
    foreach my $arg (  @{$expr->Arglist} )
    {
        my $clone_arg;
        if ( ref $arg eq 'Expression' )
        {
            # recursively expand expressions
            my $clone_arg;
            ($clone_arg, $err) = $arg->clone($plist,$level+1);
            push @$clone_args, $clone_arg;   
        }
        else
        {
            push @$clone_args, $arg;
        }      
    }      
 
    return ($clone, $err);
}


# TODO: simplify method
# eliminate 1's from mulitplications and divisions
# eliminate 0's from additions and subtractions.
# cancel terms in basic arthimetic operations.


###
###
###


# create a new expression from a number or a param name
sub newNumOrVar
{
    my $value = shift;
    my $plist = (@_) ? shift : undef;
    
    my $expr = undef;
    my $err  = undef;
    
    # is this a number?
    if ( $value =~ /$NUMBER_REGEX/ )
    {
        # create a new number expression
        $expr = Expression->new();
        $expr->Type('NUM');
        $expr->Arglist( [$value] );
        $expr->Err( undef );
    }
    # or possibly a parameter name?
    elsif ( $value =~ /$PARAM_REGEX/ )
    {
        # we need a paramllist to continue
        if ( ref $plist  eq  'ParamList' )
        {
            # check that parameter exists
            (my $param, $err) = $plist->lookup( $value );
            # if we found the parameter, then..
            unless ($err)
            {
                # create a new number expression
                $expr = Expression->new();
                $expr->Type('VAR');
                $expr->Arglist( [$value] );
                $expr->Err( undef );            
            }
        }
    }

    # return expression or undefined
    return $expr;
}


###
###
###


# Creates a new expression from a list of existing expressions.
# The type argument indicates the operation used to combine the expressions.
#   E.g. '+', '-', 'FUN'.
# If the type is 'FUN', then the first argument should be the name of
#   a built-in or user-defined function.
sub operate
{
    my $type  = shift;
    my $args  = shift;
    my $plist = shift;
   
    # can't do anything without arguments!
    unless ( @$args )
    {   return undef;   }   
    
    # operate is unhappy without a paramlist!
    unless ( ref $plist eq 'ParamList' )
    {   return undef;   }   
    
    my $err;
    my $expr;
    my $args_copy;
    
    # copy the arguments
    @$args_copy = @$args;
        
    # Check for the right number of arguments..
   
    # is this a function?
    if ( $type eq 'FUN' )
    {
        # get function name (first argument)
        my $fcn_name = $args_copy->[0];

        # is this a built-in function?
        if ( exists $functions{ $fcn_name } )
        {      
            # correct number of arguments?
            return undef  unless (  $functions{ $fcn_name }->{NARGS} == (@$args_copy - 1)  );
        }
   
        # or is this custom?
        else
        {
            # lookup function in parameter list
            (my $fcn_param, $err) = $plist->lookup( $fcn_name );
            if ( $err  or  !defined($fcn_param) ) {   return undef;   }

            if ( ref $fcn_param  ne 'Param'  or  $fcn_param->Type ne 'Function' )
            {   return undef;  }

            # correct number of arguments?
            unless (  @{$fcn_param->Ref->Args} == (@$args_copy - 1)  )
            {   return undef;   }
        }
        
        # clone arguments (not first argument, which is the fcn name)
        foreach my $arg ( @$args_copy[1..$#$args_copy] )
        {
            # clone argument, if it's an expression
            if ( ref $arg eq 'Expression' ) 
            {   ($arg, $err) = $arg->clone($plist);   }
        
            # if arg isn't an expression, try to create one  
            else      
            {   $arg = Expression::newNumOrVar( $arg );   }
    
            # check that are is still defined
            unless ( defined $arg )
            {   return undef;   }  
        }        
    }
    
    # or an operator?
    else
    {
        # check that the operator exists and has the right number of arguments      
        unless ( exists $NARGS{$type} )
        {   return undef;   }
        if (  (exists $NARGS{$type}->{min})  and  (($NARGS{$type}->{min}) > (@$args_copy))  )
        {   return undef;   } 
        if (  (exists $NARGS{$type}->{max})  and  (($NARGS{$type}->{max}) < (@$args_copy))  )
        {   return undef;   }
        
        # clone arguments
        foreach my $arg ( @$args_copy )
        {
            # clone argument, if it's an expression
            if ( ref $arg eq 'Expression' ) 
            {   ($arg, $err) = $arg->clone($plist);     }
        
            # if arg isn't an expression, try to create one  
            else      
            {   $arg = Expression::newNumOrVar( $arg );   }
    
            # check that are is still defined
            unless ( defined $arg )
            {   return undef;   }  
        }             
    }
            
    # return undefined if there were any errors
    if ($err) {   return undef;   }
   
    # create the new expression
    my $expr = Expression->new();
    $expr->Type( $type );
    $expr->Arglist( $args_copy );
    $expr->Err( undef );
    
    # return reference to expression!
    return $expr;
}


###
###
###


# load an expression by parsing a string
{
    my $string_sav;
    my %variables;
    my $allowForward = 0;


    sub setAllowForward
    {
        my $expr = shift;
        $allowForward = shift;
        #print "allowForward=$allowForward\n";
    }


    sub readString
    {
        # get arguments
        my $expr      = shift;
        my $sptr      = shift;
        my $plist     = (@_) ? shift : '';
        my $end_chars = (@_) ? shift : '';
        my $level     = (@_) ? shift : 0;
        
        my $err       = '';
        my $ops_bi    = '\*\*|[+\-*/^]|>=|<=|[<>]|==|!=|~=|&&|\|\|';  #edited, msneddon
        my $ops_un    = '[+\-!~]';

        if ( !$level )
        {
            $string_sav = $$sptr;
            %variables  = ();
        }

        # parse string into form expr op expr op ...
        # a+b*(c+d)
        # -5.0e+3/4
        my $last_read       = '';
        my $expr_new        = '';
        my @list            = ();
        my $expect_op       = 0;
        my $assign_var_name = '';
        while ( $$sptr ne '' )
        {
            #print "string=$$sptr\n";
            if ( $expect_op == 1 )
            {
                # OPERATOR
                if ( $$sptr =~ s/^\s*($ops_bi)// )
                {
                    my $express = Expression->new();
                    $express->Type($1);
                    push @list, $express;
                    $expect_op = 0;
                    next;
                }
    
                # Assignment using '='.  Valid syntax is VAR = EXPRSSION
                elsif ( $$sptr =~ s/^\s*=// )
                {
                    # Check that only preceding argument is variable
                    my $var             = $list[$#list];
                    my $vname           = $var->Arglist->[0];
                    my $var_count_start = $variables{$vname};
                    if ( $#list > 0 ) {
                        return ( "Invalid assignment syntax (VAR = EXPRESSION) in $string_sav at $$sptr" );
                    }
    
                    if ( $var->Type ne 'VAR' ) {
                        return ( "Attempted assignment to non-variable type in $string_sav at $$sptr." );
                    }
    
                    # Read remainder as expression
                    my $rhs = Expression->new();
                    $err = $rhs->readString( $sptr, $plist, $end_chars, $level + 1 );
                    $err && return ($err);
    
                    # Perform assignment of expression to variable
                    # Evaluate rhs if lhs VAR occurs on rhs
                    if ( $variables{$vname} > $var_count_start ) {
                        $plist->set( $vname, $rhs->evaluate($plist) );
                    }
                    # otherwise, set variable to rhs.
                    else {
                        $plist->set( $vname, $rhs );
                    }
    
                    #print "Evaluates to ", $expr->evaluate($plist),"\n";
                    #print "Prints    to ", $expr->toString($plist),"\n";
                    last;
                }
    
                # Look for end characters
                elsif ( $end_chars && ( $$sptr =~ /^\s*${end_chars}/ ) )
                {
                    last;
                }
                else
                {
                    $$sptr =~ s/^\s*//;
    
                    #last unless ($$sptr);
                    last;
                    return ("Expecting operator in expression $string_sav at $$sptr");
                }
            }
    
            # Chop leading whitespace
            $$sptr =~ s/^\s*//;
    
            # NUMBER
            if ( my $express = getNumber($sptr) )
            {
                #printf "Read NUM %s\n", $express->evaluate();
                push @list, $express;
                $expect_op = 1;
                next;
                0;
            }
    
            # FUNCTION
            if ( $$sptr =~ s/^($ops_un)?\s*(\w+)\s*\(// )
            {
                if ( my $op = $1 )
                {
                    # (optional) UNARY OP at start of expression, as in -a + b, or -a^2
                    my $express_u = Expression->new();
                    $express_u->Type($1);
                    push @list, $express_u;
                }
                my $name  = $2;
                my @fargs = ();
                my $type  = '';
                my $nargs;
                my ($param, $err);
                if ($plist)
                { 
                    ($param, $err) = $plist->lookup($name); 
                }
                if ( exists $functions{$name} )
                {
                    $type  = "B";
                    $nargs = $functions{$name}->{NARGS};
                }
                elsif ( $param  and  ($param->Type eq 'Observable') )
                {
                    $type = "O";
                    # number of args may be zero or one.
                }
                elsif ( $param  and  ($param->Type eq 'Function') )
                {
                    $type  = "F";
                    $nargs = scalar( @{ $param->Ref->Args } );
                }
                else
                {
                    if ($allowForward)
                    {
                        $plist->set($name);
                    }
                    else
                    {
                        return ( "Function $name is not a built-in function, Observable, or defined Function" );
                    }
                }
    
                # Read arguments to function
                while (1)
                {
                    my $express = Expression->new();
                    $err = $express->readString( $sptr, $plist, ',\)', $level + 1 );
                    if ($err) {   return ($err);   }
                    if ($express->Type) {   push @fargs, $express;   }
                    
                    if ( $$sptr =~ s/^\)// )
                    {   last;   }
                    elsif ( $$sptr =~ s/^,// )
                    {   next;   }
                }
    
                # Check Argument list for consistency with function
                if ( $type eq "O" )
                {
                    my $nargs= scalar(@fargs);
                    if  ($nargs>1){
                        return ("Observables $name is called with too many arguments");
                    }
                    elsif ($nargs==1)
                    {
                        # Arugument must be VAR
                        if ($fargs[0]->Type ne "VAR"){
                            return("Argument to observable must be a variable");
                        }
                        # Argument to Observable must be Local type
                        (my $lv) = $plist->lookup($fargs[0]->Arglist->[0]);
                        if ($lv->Type ne "Local"){
                            return( "Argument to observable must be a local variable" );
                        }
                    }
                }
                else
                {
                
                    if ( $param  and  ($nargs != @fargs) )
                    {
                        return ( "Incorrect number of arguments to function $name" );
                    }
                }
                my $express = Expression->new();
                $express->Type('FUN');
                $express->Arglist( [ $name, @fargs ] );
                push @list, $express;
                $expect_op = 1;
                next;
            }
    
            # VARIABLE
            elsif ( $$sptr =~ s/^($ops_un)?\s*([A-Za-z0-9_]+)// )
            {
                if ( my $op = $1 )
                {
                    # (optional) UNARY OP at start of expression, as in -a + b, or -a^2
                    my $express_u = Expression->new();
                    $express_u->Type($1);
                    push @list, $express_u;
                }
                my $name = $2;
    
                # Validate against ParamList, if present
                if ($plist)
                {
                    # Create and set variable if next token is '='
                    # otherwise create referenced variable but leave its Expr unset
                    unless ( $$sptr =~ /^\s*=/ )
                    {
                        my ( $param, $err ) = $plist->lookup($name);
                        if ( !$param )
                        {
                            if ($allowForward)
                            {
                                $plist->set($name);
                            }
                            else
                            {
                                return ("Can't reference undefined parameter $name");
                            }
                        }
                    }
                }
                else
                {
                    return ("No parameter list provided");
                }
                my $express = Expression->new();
                $express->Type('VAR');
                $express->Arglist( [$name] );
                ++$variables{$name};
                push @list, $express;
                $expect_op = 1;
                next;
            }

            # Get expression enclosed in parenthesis
            elsif ( $$sptr =~ s/^($ops_un)?\s*\(// )
            {
                if ( my $op = $1 )
                {
                    # (optional) UNARY OP at start of expression, as in -a + b, or -a^2
                    my $express_u = Expression->new();
                    $express_u->Type($1);
                    push @list, $express_u;
                }
                my $express = Expression->new();
                $err = $express->readString( $sptr, $plist, '\)', $level + 1 );
                if ($err) {  return ($err);  }
                unless ( $$sptr =~ s/^\s*\)// )
                {
                    return ("Missing end parenthesis in $string_sav at $$sptr");
                }
    
                #printf "express=%s %s\n", $express->toString($plist), $$sptr;
                push @list, $express;
                $expect_op = 1;
                next;
            }
            elsif ( $end_chars  and  ($$sptr =~ /^\s*[${end_chars}]/) )
            {
                last;
            }
          
            # ERROR
            else
            {
                return ("Expecting operator argument in $string_sav at $$sptr");
            }
        }

        # Transform list into expression preserving operator precedence
        if (@list) {  $expr->copy( arrayToExpression(@list) );  }

        return ($err);
    }
}


###
###
###


{
  sub depends
  {
    my $expr    = shift;
    my $plist   = shift;
    my $varname = shift;
    my $level   = (@_) ? shift : 0;
    my $dep     = (@_) ? shift : {};

    my $retval = "";
    my $err    = "";

    my $type = $expr->Type;
    if ( $type eq 'NUM' ) {
    }
    elsif ( $type eq 'VAR' ) {

      #printf "type=$type %s\n", $expr->toString($plist);
      my $vname = $expr->Arglist->[0];

      #print "$varname $vname\n";
      if ( $$dep{$vname} ) {
        $err = sprintf "Cycle in parameter $vname looking for dep in %s",
          $varname;
        print "$err\n";
        $retval = $vname;
      }
      else {

        #++$$dep{$vname};
        if ( $varname eq $vname ) {
          $retval = $vname;
        }
        elsif ($plist) {
          my $param;
          ( $param, $err ) = $plist->lookup($vname);
          my %newdep = %{$dep};
          $newdep{$nvame} = 1;
          ( my $ret, $err ) = ($param ne "") ?
            ( $param->Expr->depends( $plist, $varname, $level + 1, \%newdep ) ) :
            ("","");
          if ($ret) {
            $retval = $param->Name . '->' . $ret;
          }
        }
      }
    }
    else {
      my @arglist = @{ $expr->Arglist };

      # Skip function name if this is a function
      if ( $type eq 'FUN' ) { shift(@arglist); }
      for my $e (@arglist) {
        ( $retval, $err ) =
          ( $e->depends( $plist, $varname, $level + 1, $dep ) );
        last if $retval;
      }
    }

    #print "level=$level $retval $err\n";
    return ( $retval, $err );
  }
}


###
###
###



# copy the contents of this expression into a second expression.
#  NOTE: this is not recursive!!  use the clone method to get a recursive copy
sub copy
{
    my $edest   = shift;
    my $esource = shift;

    $edest->Type( $esource->Type );
    $edest->Arglist( [ @{ $esource->Arglist } ] );
    return ($edest);
}



###
###
###


# evaluate an expression and return a numerical value
sub evaluate
{
    my $expr  = shift;
    my $plist = (@_) ? shift : undef;
    my $level = (@_) ? shift : 0;

    if ( $level > $MAX_LEVEL ) {  die "Max recursion depth $MAX_LEVEL exceeded.";  }

    my $val = undef;
    if ( $expr->Type eq 'NUM' )
    {
        $val = $expr->Arglist->[0];
    }
    elsif ( $expr->Type eq 'VAR' )
    {        
        unless (defined $plist)
        {  die "Expression->evaluate: Error! Cannot evaluate VAR type without ParamList.";  }
    
        my $name = $expr->Arglist->[0];
        $val = $plist->evaluate( $name, [], $level+1 );
    }
    elsif ( $expr->Type eq 'FUN' )
    {
        # first argument is function name
        my $name  = $expr->Arglist->[0];
        
        # handle built-in functions
        if ( exists $functions{$name} )
        {
            my $f = $functions{$name}->{FPTR};
            # evaluate all the remaining arguments
            my $eval_args = [];
            my $ii=1;
            while ( $ii < @{$expr->Arglist} )
            {
                push @$eval_args, $expr->Arglist->[$ii]->evaluate($plist, $level+1);
                ++$ii;
            }             
            $val = $f->(@$eval_args);
        }
        # handle user-defined functions
        else
        {
            unless (defined $plist)
            {  die "Expression->evaluate: Error! Cannot evaluate user Function without ParamList.";  }
        
            $val = $plist->evaluate( $name, $expr->Arglist, $level+1 );
        }
    }
    else
    {
        my $eval_string;
        my $operator = $expr->Type;

        # replace non-perl operators with the perl equivalents
        if    ( $operator eq '~=' ) {  $operator = '!=';  }
        elsif ( $operator eq '^'  ) {  $operator = '**';  }
        elsif ( $operator eq '~'  ) {  $operator = '!';   } 
        
        if ( @{$expr->Arglist} == 1 )
        {   # handle unary operators
            if ( $operator eq "/" )
            {
                $eval_string = "1.0/(\$expr->Arglist->[0]->evaluate(\$plist,\$level+1))";
            }
            else
            {
                $eval_string = "$operator(\$expr->Arglist->[0]->evaluate(\$plist,\$level+1))";
            }
        
        }
        else
        {
            my $last = @{$expr->Arglist} - 1;
            $eval_string = join "$operator", map {"(\$expr->Arglist->[$_]->evaluate(\$plist,\$level+1))"} (0..$last);
        }
        
        # check if this is boolean type
        if ( $operator =~ /[<>|&!=]/ )
        {
            # evaluate the expression
            $val = eval "$eval_string" ? 1 : 0;
            warn $@ if $@;             
        }
        else
        {
            # evaluate the expression        
            $val = eval "$eval_string";
            if ($@)
            {  die "Expression->evalute: Error!  Some problem evaluating expression: $@.";  }
        }
    }

    return $val;
}



###
###
###



# Call this method to clone an expression and then descend into the expression
#  and evaluate any local observables.  The method returns the cloned variable
#  with local observables evaluated as numbers.  NOTE: this method will not
#  work correctly if observables haven't been computed prior to the call.
sub evaluate_local
{
    my $expr  = shift;
    my $plist = (@_) ? shift : undef;
    my $level = (@_) ? shift : 0;
    
    if ( $level > $MAX_LEVEL ) {  return (undef, "Max recursion depth $MAX_LEVEL exceeded.");  }
    unless (defined $plist)    {  die "Expression->evaluate_local: Error! Function called without required ParamList.";  }    
    
    # local variables
    my $local_expr = undef;
    my $err = '';

    # clone expression
    ($local_expr, $err) = $expr->clone( $plist, $level+1 );   

    # evaluate local dependencies in arguments
    foreach my $arg ( @{$local_expr->Arglist} )
    {
        # only need to do this for expression arguments
        if ( ref $arg eq 'Expression' )
        {   $arg = $arg->evaluate_local( $plist, $level+1 );   }
    } 
   
    # some additional handling for Function expressions!
    if ( $expr->Type eq 'FUN' )
    {
        # if local arguments are passed to this function, then we
        #  must go into the function and evaluate the local bits.  Then
        #  we need to create a clone of the function that has the local bits evaluated.
        #  Yuck!
        
        # First argument is the function name
        my $name = $expr->Arglist->[0];
        # Handle user-defined functions only (non-built-ins)
        unless( exists $functions{$name} )
        {
            # lookup function parameter:
            (my $fcn_param) = $plist->lookup( $name );
            
            # Is this a true function or an observable??
            if ( $fcn_param->Type eq 'Function' )
            {                    
                # get locally evaluated function
                my $local_fcn = $fcn_param->Ref->evaluate_local( $local_expr->Arglist, $plist, $level+1 );

                # add local_fcn to the parameter list
                #  (so we can lookup the local function in the future!
                $plist->set( $local_fcn->Name, $local_fcn->Expr, 1, 'Function', $local_fcn, 1 );

                # get parameter name for local function
                $local_expr->Arglist->[0] = $local_fcn->Name;
            }
            # This function is Really an Observable!!    
            elsif ( $fcn_param->Type eq 'Observable' )
            {         
                if ( @{$expr->Arglist} > 1 )
                {
                    # get locally evaluated function
                    my $val = $fcn_param->Ref->evaluate( $local_expr->Arglist, $plist, $level+1 );      
           
                    # replace local expression with the evaluation
                    my $args = [ $val ];
                    $local_expr->Type('NUM');
                    $local_expr->Arglist($args);
                    $local_expr->Err(undef);
                }
            }
            # The reference type is not known, abort with error!
            else
            {   $err = "ERROR in Expression->evaluate_local(): expression is a function, but ref type is unknown!";   }   
        }
    }

    return $local_expr;
}



###
###
###


# check for local observable dependency, return true if found
sub checkLocalDependency
{
    my $expr  = shift;
    my $plist = shift;
    my $level = (@_) ? shift : 0;

    unless ( defined $plist )
    {   die "Expression->checkLocalDependency: Error! Missing argument ParamList!";   }
    

    # check dependence of arguments
    foreach my $arg ( @{$expr->Arglist} )
    {
        if ( ref $arg eq 'Expression' )
        {
            return 1  if ( $arg->checkLocalDependency( $plist, $level+1 ) );
        }
    }    
       
    if ( $expr->Type eq 'FUN' )
    {    
        # only need to handle custom functions
        unless ( exists $functions{ $expr->Arglist->[0] } )
        {    
            # get fcn parameter
            my ($fcn_param) = $plist->lookup( $expr->Arglist->[0] );
            # is this a true function or an observable?
            if ( $fcn_param->Type eq 'Function' ) 
            {   
                my $fcn = $fcn_param->Ref;            
                return 1  if ( $fcn->checkLocalDependency( $plist, $level+1 ) );
            }
            elsif ( $fcn_param->Type eq 'Observable' )
            {
                # function observables are locally dependent!!
                return (@{$expr->Arglist} > 1 ? 1 : 0);
            }
        }
    }
    
    return 0;
}


###
###
###


# check if two expressions are equivalent
sub equivalent
{
    my $expr1 = shift;
    my $expr2 = shift;
    my $plist = (@_) ? shift : undef;
    my $level = (@_) ? shift : 0;
  
    # make sure we have defined expressions!
    return 0  unless ( defined $expr1  and  ref $expr1 eq 'Expression' );
    return 0  unless ( defined $expr2  and  ref $expr2 eq 'Expression' );

    # shortcut: first check if we're looking at the same object
    return 1  if ( $expr1 == $expr2 );
    
    # check type equivalence
    return 0  unless ( $expr1->Type  eq  $expr2->Type );
    
    # check for equal number of arguments
    return 0  unless ( @{$expr1->Arglist} == @{$expr2->Arglist} );
    
    # now we have to look deeper into the arguments
    if    ( $expr1->Type eq 'NUM' )
    {
        # compare numbers
        return ( $expr1->Arglist->[0]  ==  $expr2->Arglist->[0] );
    }
    elsif ( $expr2->Type eq 'VAR' )
    {
        # compare var names
        return ( $expr1->Arglist->[0]  eq  $expr2->Arglist->[0] );
    }
    elsif ( $expr2->Type eq 'FUN' )
    {
        # compare function names
        return 0  unless ( $expr1->Arglist->[0] eq $expr2->Arglist->[0] );
    
        # check argument equivalence
        for ( my $i = 1;  $i < @{$expr1->Arglist};  ++$i )
        {   
            return 0
                unless ( Expression::equivalent($expr1->Arglist->[$i], $expr2->Arglist->[$i], $plist, $level+1) );
        }
    }
    else
    {
        # check argument equivalence
        for ( my $i = 0;  $i < @{$expr1->Arglist};  ++$i )
        {   
            return 0
                unless ( Expression::equivalent($expr1->Arglist->[$i], $expr2->Arglist->[$i], $plist, $level+1) );
        }
    }
    
    # return true if no differences have been found   
    return 1;
}




# write this expression as a string.
#  The expression is expanded up to the named Parameters and Functions.
sub toString
{
    my $expr   = shift;
    my $plist  = (@_) ? shift : undef;
    my $level  = (@_) ? shift : 0;
    my $expand = (@_) ? shift : 0;

    # simple error checking
    if ( $level > $MAX_LEVEL ) { die "Max recursion depth $MAX_LEVEL exceeded."; }
    if ( $expand  and  !$plist ) { die "Can't expand expression past parameters without a parameter list."; }

    # local variables
    my $err;
    my $string;
    
    # different handling depending on the type
    my $type = $expr->Type;
    if ( $type eq 'NUM' )
    {
        # if number, print the numerical value!
        $string = $expr->Arglist->[0];
        #print "NUM=$string\n";
    }
    elsif ( $type eq 'VAR' )
    {
        if ( $expand )
        {
            # descend recursively into parameter!
            ( my $param, $err ) = $plist->lookup( $expr->Arglist->[0] );
             $string = $param->toString( $plist, $level+1, $expand );
        }
        else
        {
            # just write the parameter name
            $string = $expr->Arglist->[0];
        }
        #$string= $expr->evaluate($plist);
        #print "VAR=$string\n";
    }
    elsif ( $type eq 'FUN' )
    {
        if ( $expand )
        {
            # TODO
            my @sarr = ();
            foreach my $i ( 1 .. $#{ $expr->Arglist } ) {
                push @sarr, $expr->Arglist->[$i]->toString( $plist, $level + 1 );
            }
            $string = $expr->Arglist->[0] . '(' . join( ',', @sarr ) . ')';
        }
        else
        {
            my @sarr = ();
            foreach my $i ( 1 .. $#{ $expr->Arglist } ) {
                push @sarr, $expr->Arglist->[$i]->toString( $plist, $level + 1 );
            }
            $string = $expr->Arglist->[0] . '(' . join( ',', @sarr ) . ')';
        }
    }
    else
    {
        if ( $expand )
        {
            my @sarr = ();
            foreach my $e ( @{ $expr->Arglist } ) {
                push @sarr, $e->toString( $plist, $level+1, $expand );
            }
            if ( $#sarr > 0 )
            {   $string = join( $type, @sarr );   }
            else
            {   $string = $type . $sarr[0];       }

            # enclose in brackets if not at top level
            #    print "level=$level\n";
            if ($level)
            {   $string = '(' . $string . ')';    }          
        }
        else
        {
            my @sarr = ();
            foreach my $e ( @{ $expr->Arglist } ) {
                push @sarr, $e->toString( $plist, $level + 1 );
            }
            if ( $#sarr > 0 )
            {
                $string = join( $type, @sarr );
            }
            else {
                $string = $type . $sarr[0];
            }

            # enclose in brackets if not at top level
            #    print "level=$level\n";
            if ($level) {
                $string = '(' . $string . ')';
            }
            #printf "%s=$string\n", $expr->Type;
        }
    }

    return ($string);
}



# write this expression as an XML string.
#  Same as toString, except a few operators are replaced to avoid clashes with XML
sub toXML
{
    my $expr   = shift;
    my $plist  = (@_) ? shift : undef;
    my $level  = (@_) ? shift : 0;
    my $expand = (@_) ? shift : 0;

    # simple error checking
    if ( $level > $MAX_LEVEL ) { die "Max recursion depth $MAX_LEVEL exceeded."; }
    if ( $expand  and  !$plist ) { die "Can't expand expression past parameters without a parameter list."; }

    # local variables
    my $err;
    my $string;
    
    # different handling depending on the type
    my $type = $expr->Type;
    if ( $type eq 'NUM' )
    {
        # if number, print the numerical value!
        $string = $expr->Arglist->[0];
    }
    elsif ( $type eq 'VAR' )
    {
        if ( $expand )
        {
            # descend recursively into parameter!
            ( my $param, $err ) = $plist->lookup( $expr->Arglist->[0] );
             $string = $param->toXML( $plist, $level+1, $expand );
        }
        else
        {
            # just write the parameter name
            $string = $expr->Arglist->[0];
        }
    }
    elsif ( $type eq 'FUN' )
    {
        if ( $expand )
        {
            # TODO
            my @sarr = ();
            foreach my $i ( 1 .. $#{$expr->Arglist} )
            {
                push @sarr, $expr->Arglist->[$i]->toXML( $plist, $level + 1 );
            }
            $string = $expr->Arglist->[0] . '(' . join( ',', @sarr ) . ')';
        }
        else
        {
            my @sarr = ();
            foreach my $i ( 1 .. $#{$expr->Arglist} )
            {
                push @sarr, $expr->Arglist->[$i]->toXML( $plist, $level + 1 );
            }
            $string = $expr->Arglist->[0] . '(' . join( ',', @sarr ) . ')';
        }
    }
    else
    {
        if ( $expand )
        {
            my @sarr = ();
            foreach my $e ( @{$expr->Arglist} )
            {
                push @sarr, $e->toXML( $plist, $level+1, $expand );
            }
            if ( $#sarr > 0 )
            {   $string = join( $type, @sarr );   }
            else
            {   $string = $type . $sarr[0];       }

            # enclose in brackets if not at top level
            #    print "level=$level\n";
            if ($level)
            {   $string = '(' . $string . ')';    }          
        }
        else
        {
            my @sarr = ();
            foreach my $e ( @{ $expr->Arglist } ) {
                push @sarr, $e->toXML( $plist, $level + 1 );
            }
            if ( $#sarr > 0 )
            {
                $string = join( $type, @sarr );
            }
            else {
                $string = $type . $sarr[0];
            }

            # enclose in brackets if not at top level
            #    print "level=$level\n";
            if ($level) {
                $string = '(' . $string . ')';
            }
            #printf "%s=$string\n", $expr->Type;
        }
    }

    # TODO: special handling for XML output should be handled by a special option
    #  or a toXML sub.  --Justin
    
    #BEGIN edit, msneddon
    # for outputting to XML, we need to make sure we put in some special
    # characters and operators to match the muParser library and to allow
    # the XML parser to work.<" with "&lt;", ">" with "&gt;", and
    #"&" with "&amp
    #print "before XML replacement: $string\n";
    $string =~ s/</&lt\;/;
    $string =~ s/>/&gt\;/;
    $string =~ s/&&/and/;
    $string =~ s/\|\|/or/;
    #print "after XML replacement: $string\n";
    #END edit, msneddon

    return ($string);
}




# write expression as a string suitable for
#  export to CVode.  This is the same as toString,
#  except variable names are replaced with pointers into
#  arrays.
sub toCVodeString
{
    my $expr   = shift;
    my $plist  = (@_) ? shift : '';
    my $level  = (@_) ? shift : 0;
    my $expand = (@_) ? shift : 0;

    if ( $level > $MAX_LEVEL ) {  die "Max recursion depth $MAX_LEVEL exceeded.";  }

    my $string;
    my $err;
    
    my $type   = $expr->Type;
    
    if ( $type eq 'NUM' )
    {
        $string = $expr->Arglist->[0];
        # if this is a pure integer,
        #  add a decimal place to make sure C knows this has type double
        $string =~ s/^(\d+)$/$1.0/;
    }
    elsif ( $type eq 'VAR' )
    {   
        # lookup corresponding parameter ...
        (my $param, $err) = $plist->lookup( $expr->Arglist->[0] );
        if ($param)
        {   # return cvode ref
            $string = $param->getCVodeName();   
        }
        else
        {   # parameter not defined, assume it's a local argument and write its name
            $string = $expr->Arglist->[0];
        }        
    }
    elsif ( $type eq 'FUN' )
    {
        # the first argument is the function name
        my $fcn_name = $expr->Arglist->[0];
        
        # first see if this is a built-in function (e.g. sin, cos, exp..)
        if ( exists $functions{ $expr->Arglist->[0] } )
        {
            # handle built-ins with 1 argument that have the same name in the C library
            if ( $fcn_name =~ /^(sin|cos|exp|log|abs|sqrt|floor|ceil)$/ )
            {
                my @sarr = ( map {$_->toCVodeString($plist, $level+1, $expand)} @{$expr->Arglist}[1..$#{$expr->Arglist}] );
                $string = $fcn_name .'('. join( ',', @sarr ) .')';
            }
            # handle the 'if' built-in with 3 arguments
            elsif ( $fcn_name eq 'if' )
            {   
                # substitute the "?" operator for the if function
                my @sarr = ( map {$_->toCVodeString($plist, $level+1)} @{$expr->Arglist}[1..$#{$expr->Arglist}] );

                if ( @sarr == 3)
                {   $string = '('. $sarr[0] .' ? '. $sarr[1] .' : '. $sarr[2] .')';   }
                else
                {   die "Error in Expression->toCVodeString():  built-in function 'if' must have three arguments!";   }    
            }
            # fatal error if the built-in is not handled above
            else
            {   die "Error in Expression->toCVodeString():  don't know how to handle built-in function $builtin!";   }
        }
        
        # otherwise, this is a user-defined function or observable
        else
        {             
            # lookup parameter
            # lookup function parameter:
            (my $fcn_param) = $plist->lookup( $fcn_name );
            unless ($fcn_param)
            {   die "Error in Expression->toCVodeString: could not find function parameter!";   }
            
            # Is this a true function or an observable??
            if ( $fcn_param->Type eq 'Function' )
            {   # Handling a true Function!                            
                # expand argument expressions up until named entities
                my @sarr = ( map {$_->toCVodeString($plist, $level+1, $expand)} @{$expr->Arglist}[1..$#{$expr->Arglist}] );
                # pass arguments pointing to the expressions array and observables array
                push @sarr, 'expressions', 'observables';
                $string = $fcn_name . '(' . join( ',', @sarr ) . ')';
            }
            elsif ( $fcn_param->Type eq 'Observable' )
            {
                # TODO: if there are arguments, then we should warn the user that we can't evaluate a local
                # observables in a CVode function!!
                $string = $fcn_param->getCVodeName();
            }
            else
            {   die "Error in Expression->toCVodeString(): don't know how to process function expression of non-function type!";   }
            
        }
        
    }
    elsif ( ($type eq '**') or ($type eq '^') )
    {  
        # substitute the "pow" function for the exponentiation operator
        my @sarr = ( map {$_->toCVodeString($plist, $level+1)} @{$expr->Arglist} );
    
        if ( @sarr == 2 )
        {   $string = 'pow(' . $sarr[0] . ',' . $sarr[1] . ')';  }
        else
        {   die "Error in Expression->toCVodeString(): Exponentiation must have exactly two arguments!";   }
    }
    else
    {   
        # handling some other operator (+,-,*,/)
        # enclose in brackets (always. just to be safe)        
        my @sarr = ( map {$_->toCVodeString($plist, $level+1, $expand)} @{$expr->Arglist} );
        if ( @sarr > 1 )
        {   # binary or higher order
            $string = '(' . join( $type, @sarr ) . ')';
        }
        else
        {   # unary operator
            $string = '(' . $type . $sarr[0] . ')';
        }
    }

    return ($string);
}




# write expression as a string suitable for
#  export to a Matlab M-file.
sub toMatlabString
{
    my $expr   = shift;
    my $plist  = (@_) ? shift : '';
    my $level  = (@_) ? shift : 0;
    my $expand = (@_) ? shift : 0;

    if ( $level > $MAX_LEVEL ) {  die "Max recursion depth $MAX_LEVEL exceeded.";  }

    my $string;
    my $err;
    
    my $type   = $expr->Type;
    
    if ( $type eq 'NUM' )
    {
        $string = $expr->Arglist->[0];
    }
    elsif ( $type eq 'VAR' )
    {   
        # lookup corresponding parameter ...
        (my $param, $err) = $plist->lookup( $expr->Arglist->[0] );
        if ($param)
        {   # return matlab ref
            $string = $param->getMatlabName();   
        }
        else
        {   # parameter not defined, assume it's a local argument and write its name
            $string = $expr->Arglist->[0];
        }        
    }
    elsif ( $type eq 'FUN' )
    {
        # the first argument is the function name
        my $fcn_name = $expr->Arglist->[0];
        
        # first see if this is a built-in function (e.g. sin, cos, exp..)
        if ( exists $functions{ $expr->Arglist->[0] } )
        {
            # handle built-ins with 1 argument that have the same name in Matlab
            if ( $fcn_name =~ /^(sin|cos|exp|log|abs|sqrt|floor|ceil)$/ )
            {
                my @sarr = ( map {$_->toMatlabString($plist, $level+1, $expand)} @{$expr->Arglist}[1..$#{$expr->Arglist}] );
                $string = $fcn_name .'('. join( ',', @sarr ) .')';
            }
            # handle the 'if' built-in with 3 arguments
            elsif ( $fcn_name eq 'if' )
            {   
                # substitute the "?" operator for the if function
                my @sarr = ( map {$_->toMatlabString($plist, $level+1)} @{$expr->Arglist}[1..$#{$expr->Arglist}] );

                if ( @sarr == 3)
                {   $string = 'if('. $sarr[0] . ',' . $sarr[1] . ',' . $sarr[2] . ')';   }
                else
                {   die "Error in Expression->toMatlabString():  built-in function 'if' must have three arguments!";   }    
            }
            # fatal error if the built-in is not handled above
            else
            {   die "Error in Expression->toMatlabString():  don't know how to handle built-in function $builtin!";   }
        }
        
        # otherwise, this is a user-defined function or observable
        else
        {             
            # lookup parameter
            # lookup function parameter:
            (my $fcn_param) = $plist->lookup( $fcn_name );
            unless ($fcn_param)
            {   die "Error in Expression->toMatlabString: could not find function parameter!";   }
            
            # Is this a true function or an observable??
            if ( $fcn_param->Type eq 'Function' )
            {   # Handling a true Function!                            
                # expand argument expressions up until named entities
                my @sarr = ( map {$_->toMatlabString($plist, $level+1, $expand)} @{$expr->Arglist}[1..$#{$expr->Arglist}] );
                # pass arguments pointing to the expressions array and observables array
                push @sarr, 'expressions', 'observables';
                $string = $fcn_name . '(' . join( ',', @sarr ) . ')';
            }
            elsif ( $fcn_param->Type eq 'Observable' )
            {
                # TODO: if there are arguments, then we should warn the user that we can't evaluate a local
                # observables in a CVode function!!
                $string = $fcn_param->getMatlabName();
            }
            else
            {   die "Error in Expression->toMatlabString(): don't know how to process function expression of non-function type!";   }
            
        }
        
    }
    else
    {   
        # handling some other operator (+,-,*,/)
        # enclose in brackets (always. just to be safe)        
        my @sarr = ( map {$_->toMatlabString($plist, $level+1, $expand)} @{$expr->Arglist} );
        if ( @sarr > 1 )
        {   # binary or higher order
            $string = '(' . join( $type, @sarr ) . ')';
        }
        else
        {   # unary operator
            $string = '(' . $type . $sarr[0] . ')';
        }
    }

    return ($string);
}


###
###
###


{
  my %ophash = (
    '+'  => 'plus',
    '-'  => 'minus',
    '*'  => 'times',
    '/'  => 'divide',
    '**' => 'power',
    '^'  => 'power',
  );

  sub toMathMLString {
    my $expr   = shift;
    my $plist  = (@_) ? shift : "";
    my $indent = (@_) ? shift : "";
    my $level  = (@_) ? shift : 0;

    ( $level > $MAX_LEVEL ) && die "Max recursion depth $MAX_LEVEL exceeded.";

    my $string  = "";
    my $indentp = $indent;
    if ( $level == 0 ) {
      $string .=
        $indent . "<math xmlns=\"http://www.w3.org/1998/Math/MathML\">\n";
      $indentp .= "  ";
    }

    my $type = $expr->Type;
    if ( $type eq 'NUM' ) {
      $string .= sprintf "%s<cn> %s </cn>\n", $indentp, $expr->Arglist->[0];
    }
    elsif ( $type eq 'VAR' ) {
      $string .= sprintf "%s<ci> %s </ci>\n", $indentp, $expr->Arglist->[0];
    }
    elsif ( $type eq 'FUN' ) {
      $string .= $indentp . "<apply>\n";
      my $indentpp = $indentp . "  ";
      my @arglist  = @{ $expr->Arglist };
      $string .= sprintf "%s<%s/>\n", $indentpp, shift(@arglist);
      for my $e (@arglist) {
        $string .= $e->toMathMLString( $plist, $indentpp, $level + 1 );
      }
      $string .= $indentp . "</apply>\n";
    }
    else {
      $string .= $indentp . "<apply>\n";
      my $indentpp = $indentp . "  ";
      $string .= sprintf "%s<%s/>\n", $indentpp, $ophash{ $expr->Type };
      for my $e ( @{ $expr->Arglist } ) {
        $string .= $e->toMathMLString( $plist, $indentpp, $level + 1 );
      }
      $string .= $indentp . "</apply>\n";
    }

    if ( $level == 0 ) {
      $string .= $indent . "</math>\n";
    }
    return ($string);
  }
}

# Convert an array of type EXPR OP EXPR OP ... to a single Expression.
sub arrayToExpression {
  my @earr = @_;

  # list of optypes in order of precedence
  my @operators = ( '\*\*|\^', '[*/]', '[+-]','[<>]|==|!=|~=|>=|<=','&&|\|\|'); #edited, msneddon
  my $optype = shift @operators;
  while ($optype) {
    my $i = 0;

    # Consolidate EXPR OP EXPR into EXPR
    while ( $i < $#earr ) {
      my $expr = $earr[$i];
      if ( $expr->Type =~ /$optype/ && !( @{ $expr->Arglist } ) ) {
        if ( $i > 0 ) {
          $expr->Arglist->[0] = $earr[ $i - 1 ];
          $expr->Arglist->[1] = $earr[ $i + 1 ];
          splice @earr, $i - 1, 3, $expr;
          next;
        }
        else {

          # Handle leading unary op, as in -a + b
          $expr->Arglist->[0] = $earr[ $i + 1 ];
          splice @earr, $i, 2, $expr;
          ++$i;
          next;
        }
      }
      ++$i;
    }

    #print "expression after $optype= ";
    #foreach $expr (@earr){
    # printf " %s", $expr->toString();
    #}
    #print "\n";
    # Finished with current optype
    $optype = shift @operators;
  }

  #printf "final expression= %s\n", $earr[0]->toString();

  return ( $earr[0] );
}



# extract a number expression from a BNG string.
# NOTE: the method newNumOrVar is appropriate when
#  the string ONLY contains a number of param name.  This
#  method, however, is suitable for cases where the string 
#  contains additional content.
sub getNumber
{
  my $string = shift;
  my $number = "";

  # Decimal part
  if ( $$string =~ s/^([+-]?\d+)([.]?\d*)// ) {
    $number = $1;
    if ($2 eq '.'){
      # pad number ending in decimal point
      $number .= ".0";
    } else {
      $number .= $2;
    }
  }
  elsif ( $$string =~ s/^([+-]?[.]\d+)// ) {
    $number = $1;
  }
  else {
    return ('');
  }

  # Exponent part
  if ( $$string =~ s/^([DEFGdefg][+-]?\d+)// ) {
    $number .= $1;
  }
  elsif ( $$string =~ /^[A-Za-z_]/ ) {

    # String is non a number; restore value of string
    $$string = $number . $$string;
    return ('');
  }
  
  # create number expression and return
  my $express = Expression->new();
  $express->Type('NUM');
  $express->Arglist( [$number] );
  return ($express);
}



# Returns name of VAR if expression is an existing VAR or
# creates a new VAR with name derived from $basename and 
# returns name of new VAR containing expression.
sub getName
{
    my $expr       = shift;
    my $plist      = shift;
    my $basename   = (@_) ? shift : "k";
    my $force_fcn = (@_) ? shift : 0; 

    my $name;
  
    if ( $expr->Type eq 'VAR'  and  !$force_fcn )
    {
        $name = $expr->Arglist->[0];
        #printf "Found existing parameter %s\n", $name;
    }
    else 
    {
        # Find unused name
        my $index = 1;
        while (1)
        {
            my ( $param, $err ) = $plist->lookup( $basename . $index );
            last unless $param;
            ++$index;
        }
        $name = $basename . $index;
                
        # set parameter in list (with type Function, if force)
        $plist->set( $name, $expr, 0, ($force_fcn ? 'Function' : '') );

        #printf "Creating new parameter %s\n", $name;
    }

    return ($name);
}



# Return a hash of all the variable names referenced in the current expression.
 sub getVariables {
  my $expr    = shift;
  my $plist   = shift;
  my $level   = (@_) ? shift : 0;
  my $rethash = (@_) ? shift : "";
#  use Data::Dumper;

  ( $level > $MAX_LEVEL ) && die "Max recursion depth $MAX_LEVEL exceeded.";

  if ( $level == 0 ) {
    $rethash = {};
  }

  my $type = $expr->Type;
  if ( $type eq 'NUM' ) {
  }
  elsif ( $type eq 'VAR' ) {
    my ( $param, $err ) = $plist->lookup( $expr->Arglist->[0] );
    if ($err) { die $err }
    ;    # Shouldn't be an undefined variable name here
    $rethash->{ $param->Type }->{ $param->Name }= $param;
  }
  elsif ( $type eq 'FUN' ) {
    my ( $param, $err ) = $plist->lookup( $expr->Arglist->[0] );
    if ($err){
      # function is a built-in      
    }
    else {
      $rethash->{$param->Type}->{ $param->Name }= $param;
    }
    for my $i ( 1 .. $#{ $expr->Arglist } ) {
      $expr->Arglist->[$i]->getVariables( $plist, $level + 1, $rethash );
    }
  }
  else {
    for my $e ( @{ $expr->Arglist } ) {
      $e->getVariables( $plist, $level + 1, $rethash );
    }
  }

  ( $level > 0 ) && return ();

  #  print Dumper($rethash);
  return ($rethash);
}

1;
