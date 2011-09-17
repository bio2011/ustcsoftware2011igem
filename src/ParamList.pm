package ParamList;

use File::Spec;
use LibSBML;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use Math::Expression::Evaluator;
use Utils;
use Expression;

{
	my %tempParams=();

	struct ParamList =>
	{
		#	Dynamic Parameters

		Hash	=>	'%',	#	include system variables, such as time
		Array	=>	'@',	#	include only user-define parameters (Expression Obj)
		Unchecked	=>	'@',	#	unchecked parameters
	};

	sub readString
	{
		my $plist = shift;
		my $string = shift;

		#	Read name (required)
		$string =~ s/^\s*([A-Za-z]\w*)// 
			||	return("Invalid parameter declaration $string: format is: Name[\s+]Expression");
		my $name = $1;

		#	Read expression (required)
		$string =~ s/^\s*(\S+)// 
			||	return("Invalid parameter declaration $string: format is: Name[\s+]Expression");
		my $expression = $1;

		if (exists $tempParams->{$name}) {
			my $err = "ParamList->readString: Parameter with $name has been defined previously";
			return $err;
		}
		else {
			$tempParams->{$name} = $expression;
			push (@{$plist->Unchecked},$name);
		}

		if ($string =~ /\S+/) {
			return("Unrecognized trailing syntax $string in parameter specification"); 
		}

		return '';
	}

	sub addSimpleParameter {
		my $plist=shift;
		my $name=shift;
		my $string=shift;
		if (exists $plist->Hash->{$name}){
			return "ParamList->addSimpleParameter: Parameter with $name has been defined previously";
		}
		else {
			my ($exprParam,$exprVal,$exprErr)=Expression->newExpression($string,'algebra');
			if ($exprErr) { return $exprErr; }
			else {
				$exprParam->Name($name);
				$plist->Hash->{$name}=$exprParam;
				push (@{$plist->Array},$exprParam);
				return '';
			}
		}
	}

	sub addVar_time
	{
		my $plist=shift;
		my $exprTime=Expression->new(Name=>'time');
		my $param = "<csymbol encoding=\"text\" definitionURL=\"http://www.sbml.org/sbml/symbols/time\">time</csymbol>";
		if (my $err=$exprTime->readMathMLFromString($param)) { 
			my @ret= ($err, __LINE__); 
			return \@ret; 
		}
		else {
			$plist->Hash->{"time"}=$exprTime;
			return '';	
		}	#	!!do not push into Array, keep only in Hash
	}

	sub checkParams
	{
		my $plist = shift;
		my $num_params_ndef=0;

		while (@{$plist->Unchecked})
		{
			#print Dumper $plist->Unchecked;
			my $param = shift @{$plist->Unchecked};
			my $expr = $tempParams->{$param};

			my ($exprParam,$exprVal,$exprErr)=Expression->newExpression($expr,'algebra',$plist);
			if ($exprErr) {
				my @ret_val=($exprErr, __LINE__);
				return \@ret_val;
			}

			unless ($exprVal) {#not calculable
				push (@{$plist->Unchecked},$param);
				$num_params_ndef++;
			}
			else{#calculable
				$plist->Hash->{$param}=$exprParam;
				$exprParam->Name($param);	#	assign Name 
				push (@{$plist->Array},$exprParam);
				$num_params_ndef=0;
			}

			my $num_params_unchecked=$#{$plist->Unchecked}+1;
			if ($num_params_unchecked > 0) {
				if ($num_params_ndef == $num_params_unchecked) {
					my $err = "Invalid parameter dependence on undefined variables";
					my @ret_val = ($err, __LINE__);
					return \@ret_val;
				}
			}
		}

		return;
	}

	sub writeMoDeL 
	{
		my $plist=shift;
		my $out = "";

		# find longest parameter name
		my $max_length = 0;
		foreach my $param (@{$plist->Array})
		{
			$max_length = ($max_length >= length $param->Name) ? $max_length : length $param->Name;
		}

		# now write parameter strings
		my $iparam = 1;
		my $out .= "<parameters>\n";
		foreach my $param (@{$plist->Array})
		{
			$out .= sprintf "%5d", $iparam;
			$out .= sprintf "  %-${max_length}s ", $param->Name;   
			$out .= sprintf "  %3.3e  ", $param->Value;   
			if ($param->String ne $param->Value) {
				$out .= " #	".$param->String;
			}
			$out .= "\n";   
			++$iparam; 
		}
		$out .= "</parameters>\n";

		return $out;
	}

	sub writeSBML {
		my $plist=shift;
		my $sbmlModel=shift;
		foreach my $param (@{$plist->Array}) {
			if($param->String ne $param->Value) {
				my $sbmlpara=$sbmlModel->createParameter();
				if(my $errcode=$sbmlpara->setId($param->Name)) {return $errcode;}
				if(my $errcode=$sbmlpara->setValue(0)) {return $errcode;}
				if(my $errcode=$sbmlpara->setConstant(0)) {return $errcode;}
				my $sbmlrule=$sbmlModel->createAssignmentRule();
				if(my $errcode=$sbmlrule->setVariable($param->Name)) {return $errcode;}
				if(my $errcode=$sbmlrule->setMath($param->MathML)) {return $errcode;}
			}
			else {
				my $sbmlpara=$sbmlModel->createParameter();
				if(my $errcode=$sbmlpara->setId($param->Name)) {return $errcode;}
				if(my $errcode=$sbmlpara->setValue($param->Value)){return $errcode;}
			}
		}

		#	add built-in variable "time" 
		my $sbmlpara=$sbmlModel->createParameter();
		$sbmlpara->setId('time');
		$sbmlpara->setValue(0);
		$sbmlpara->setConstant(0);
		my $sbmlrule=$sbmlModel->createAssignmentRule();
		$sbmlrule->setVariable('time');
		my $timestr = "<csymbol encoding=\"text\" definitionURL=\"http://www.sbml.org/sbml/symbols/time\">t</csymbol>";
		my $astMath = LibSBML::readMathMLFromString($timestr);
		if(my $errcode=$sbmlrule->setMath($astMath)) {return $errcode;}

		return '';
	}
}

1;
__END__
