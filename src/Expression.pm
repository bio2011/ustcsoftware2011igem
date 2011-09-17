package Expression;

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use Math::Expression::Evaluator;
use Parse::BooleanLogic;
use Data::Dumper;
use Utils;

{
	my %logicalOperators = 
	(
		'<'		=>		'lt',
		'>'		=>		'gt',
		'<='	=>		'le',
		'>='	=>		'ge',
		'=='	=>		'eq',
		'!='	=>		'ne',
		'&&'	=>		'and',
		'||'	=>		'or'
	);
	
	my %algebraOperators =
	(
		'+'		=>		'plus',
		'-'		=>		'minus',
		'*'		=>		'times',
		'/'		=>		'divide',
		'^'		=>		'power'
	);

	#	For parameters with "String" is not real, write AssignmentRules for each
	struct Expression =>
	{
		Name	=>	'$',
		String	=>	'$',	
		MathML	=>	'$',	#	AST
		Type	=>	'$',	#	logic or algebra
		Value	=>	'$'	#	value if calculable
	};

	sub newExpression {
		my $class=shift;
		my $string = shift;
		my $type=shift; #	logic or algebra
		my $plist=(@_)? shift: "";
		my $clist=(@_)? shift: "";
		my $slist=(@_)? shift: "";

		$string =~ s/\s+//g;	#	remove white spaces
		#print "string=$string,type=$type\n";

		my ($value,$mathml,$err);
		if ($type eq 'algebra') {
			($value,$mathml,$err)=AlgebraicEvaluation($string,$plist,$clist,$slist);
			if ($err) { return('','',$err); }
		}
		elsif ($type eq 'logic') {
			($value,$mathml,$err)=BooleanLogicEvaluation($string,$plist,$clist,$slist);
			if ($err) { return('','',$err); }
		}

		my $expr= Expression->new (String=>$string,MathML=>$mathml,Type=>$type,Value=>$value);
		return ($expr,$value);
	}

	sub AlgebraicEvaluation {
		my $string=shift;
		my $plist= (@_)? shift : "";
		my $clist= (@_)? shift : "";
		my $slist= (@_)? shift : "";

		my $mathml=LibSBML::parseFormula($string);
		return ('','',"Cannot parse formula $string by LibSBML") unless $mathml;
		ref $mathml eq 'LibSBML::ASTNode' || return (
			'','',"Expression: Attempt to assign non-ASTNode_t object $mathml to MathML"
		);

		my $value;
		if (isReal($string)) { $value=$string; }
		else {	#	complex expression
			
			#	do not check valid reference
			if ($plist eq "" && $clist eq "" && $slist eq "") { return('',$mathml); }

			my $m = Math::Expression::Evaluator->new;
			my @vars = $m->parse($string)->variables();

			my $parsef='';
			my $undefined=undef;
			my $num_plist_vars_found=0;

			foreach (@vars) {
				my $unfound=1;
				if ($plist && exists $plist->Hash->{$_}) { 
					$unfound=0;
					if (my $val=$plist->Hash->{$_}->Value) {
						$num_plist_vars_found++;
						$parsef.="$_=$val\;";
					}
				}
				elsif ($clist && exists $clist->Hash->{$_}) {$unfound=0;}
				elsif ($slist && exists $slist->Hash->{$_}) {$unfound=0;}
				if ($unfound) {$undefined=$_;last;}
			}
			if ($undefined) {
				return ('','',"Cannot reference undefined parameter $undefined");
			}

			#print "num_plist_vars_found=$num_plist_vars_found\n";
			#print "length_vars=@vars\n";

			if ($num_plist_vars_found == scalar(@vars)) {
				$parsef.=$string;
				#print "parsef:	$parsef\n";
				$value=$m->parse($parsef)->val();
			}
		}

		return ($value,$mathml);
	}

	sub BooleanLogicEvaluation{#3 tasks, check, calculation, conversion to valid MathML format
		my $string=shift;
		my @list=@_;	#plist, clist, slist	

		my $parser=Parse::BooleanLogic->new( operators => ['&&','||']);
		my $tree= $parser->as_array($string);
		#print Dumper $tree;

		my ($string_new,$value,$err)=parseBooleanLogicArray($tree,@list);
		if ($err) {return ('','',$err." in string $string");}
		else {
			#print "string:	$string\nstring_new:	$string_new\n";
			my $mathml=LibSBML::parseFormula($string_new);
			return ('','',"Cannot parse formula $string by LibSBML") unless $mathml;
			ref $mathml eq 'LibSBML::ASTNode' || return (
				'','',"Expression: Attempt to assign non-ASTNode_t object $mathml to MathML"
			);
			return ($value,$mathml); 
		}
	}

	sub parseBooleanLogicArray {
		my $tree=shift;
		my @list=@_;	#plist, clist, slist

		my @as_array=@$tree;
		#print Dumper $tree;
		return ('','',"Incomplete expression") unless @as_array;

		my ($LHSexpr,$LHSval,$RHSexpr,$RHSval,$err);

		my $left_operand=shift @as_array;
		if (ref $left_operand eq 'HASH') {
			($LHSexpr,$LHSval,$err)=
				parseBooleanLogicHash(
					$left_operand,
					@list
				);
			if ($err) {return ('','',$err);}

			#	return if only one Hash left
			return ($LHSexpr,$LHSval) unless @as_array;
		}
		elsif (ref $left_operand eq 'ARRAY') {
			($LHSexpr,$LHSval,$err)=
				parseBooleanLogicArray(
					$left_operand,
					@list
				);
			if ($err) {return ('','',$err);}

			#	return if only one Array left
			return ($LHSexpr,$LHSval) unless @as_array;
		}
		else {return ('','',"Invalid object $left_operand (should be an ARRAY or a HASH)");}

		#	the second element must be && or ||
		my $op = shift @as_array;
		#print "op:	$op\n";
		if ($op ne "&&" && $op ne "||") {
			return ('','',"Invalid operator $op (should be && or ||)");
		}
		
		($RHSexpr,$RHSval,$err)=parseBooleanLogicArray(\@as_array,@list);
		if ($err) {return ('','',$err);}

		#	calculate
		my $ret_val;	#	undef
		if ($LHSval && $RHSval) {#calculate sub-expression
			if ($op eq '&&') {
				if ($LHSval && $RHSval) { $ret_val=1; }
				else { $ret_val=0; }
			}
			elsif ($op eq '||') {
				if (not $LHSval && not $RHSval) { $ret_val=0; }
				else { $ret_val=1;}
			}
		}

		return ("$logicalOperators{$op}($LHSexpr,$RHSexpr)",$ret_val);
	}

	sub parseBooleanLogicHash {
		my $hash=shift;
		my $plist=(@_)? shift: "";
		my $clist=(@_)? shift: "";
		my $slist=(@_)? shift: "";

		my $string = $hash->{operand};
		#print "string:	$string\n";
		return('','',"Incomplete expression") unless $string; 

		#	operand is a number
		return($string,$string) if isReal($string);

		#	binary logic operators
		my $RegExp='(\S+)(>=|<=|<|>|==|!=)(\S+)';
		if ($string =~ /$RegExp/) {
			my ($left_operand,$op,$right_operand)=($1,$2,$3);
			if (exists $logicalOperators{$op}) {
				$op=$logicalOperators{$op};
			}
			else {
				return ('','',"Unrecognized logic operator $op");
			}

			#	check left operand
			my ($LHSval,undef,$LHSerr)=AlgebraicEvaluation(
				$left_operand,$plist,$clist,$slist
			);
			if ($LHSerr) {return('','',$LHSerr);}

			#	check right operand
			my ($RHSval,undef,$RHSerr)=AlgebraicEvaluation(
				$right_operand,$plist,$clist,$slist
			);
			if ($RHSerr) {return('','',$RHSerr);}

			my $ret_val;
			if ($LHSval && $RHSval) {
				if ($op eq 'lt') {$ret_val=$LHSval<$RHSval?1:0;}
				elsif ($op eq 'gt') {$ret_val=$LHSval>$RHSval?1:0;}
				elsif ($op eq 'le') {$ret_val=$LHSval<=$RHSval?1:0;}
				elsif ($op eq 'ge') {$ret_val=$LHSval>=$RHSval?1:0;}
				elsif ($op eq 'eq') {$ret_val=$LHSval==$RHSval?1:0;}
				elsif ($op eq 'ne') {$ret_val=$LHSval!=$RHSval?1:0;}
			}

			my $substr="$op($left_operand,$right_operand)";
			#print "substr:	$substr\n";
			return ($substr,$ret_val);
		}
		else {
			return ('','',"Cannot parse boolean logic unit $string");
		}
	}

	sub	readMathMLFromString {
		my $expr=shift;
		my $string=shift;

		my $mathml=LibSBML::readMathMLFromString($string);
		return ('','',"Cannot parse formula $string by LibSBML") unless $mathml;
		ref $mathml eq 'LibSBML::ASTNode' || return (
			'','',"Expression: Attempt to assign non-ASTNode_t object $mathml to MathML"
		);
		$expr->{MathML}=$mathml;
		
		return '';
	}

}


1;
