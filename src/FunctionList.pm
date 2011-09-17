package FunctionList;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use Utils;
use Function;
use Expression;

{
	my $print_on=0;	#	print switch

	struct FunctionList =>
	{
		Hash =>	'%',	#	name => expression	
		Array	=>	'@',	#	list of functions
		FunctionUsed	=>	'%'	#	function name => 1/0
	};

	sub readSarray {
		my $flist=shift;
		my $name=shift;
		my $params=shift;
		my $express=shift;

		if ($name !~ /^[A-Za-z]\w*$/) {
			return "Invalid function name in $name";
		}

		#	params should have pattern /[A-Za-z]\w*/
		my @params_array=split(/\,/,$params);
		foreach my $param (@params_array) {
			if ($param !~ /^[A-Za-z]\w*$/) {
				return "Invalid parameter name in $param";
			}
		}

		#	expression obj
		my ($expr,undef,$err)=Expression->newExpression($express,'algebra');
		if ($err) {	return $err; }

		#	function obj
		my $func=Function->new(Name=>$name,Expression=>$expr);
		foreach my $param (@params_array) {
			push (@{$func->Parameters}, $param);
		}

		return $flist->add($func);
	}

	sub add
	{
		my $flist = shift;  # function list

		my $func = shift;
		ref $func eq 'Function' || return 
			"FunctionList: Attempt to add non-function object $func to FunctionList.";   

		if ( exists $flist->Hash->{ $func->Name } ) { 
			# function with same name is already in list
			return "FunctionList: function $func->Name has been defined previously";
		}
		else{ # add new function
			$flist->Hash->{ $func->Name } = $func;
			$flist->FunctionUsed->{ $func->Name } = 0;
			push @{$flist->Array}, $func;
		}

		# continue adding functions (recursive)
		if ( @_ )
		{  return $flist->add(@_);  }
		else
		{  return '';  }
	}

	sub print{
		
		if ($print_on) {
			my $flist= shift;
			my $fh= shift;	#filehandle
			my $i_start= (@_) ? shift : 0;

			print $fh "begin functions\n";
			my $sarray= $flist->Array;
			for my $i ($i_start..$#{$sarray}){
				my $func= $sarray->[$i];

				printf $fh "%5d	", $i-$i_start+1;

				my @vars = (
					$func->Name,
					$func->Expression->String
				);
				my $prt=join("  ",@vars);
				printf $fh "$prt\n";
			}
			print $fh "end functions\n";
			return("");
		}
	}

	sub writeMoDeL 
	{
		my $flist=shift;
		my $out = "";

		# find longest function name
		my $max_length = 0;
		foreach my $name (@{$flist->FunctionUsed})
		{
			$max_length = ($max_length >= length $name) ? $max_length : length $name;
		}

		# now write function strings
		my $ifunc = 1;
		$out .= "<functions>\n";
		foreach my $name (keys %{$flist->FunctionUsed})
		{
			if ($flist->FunctionUsed->{$name}) {
				my $func = $flist->Hash->{$name};
				$out .= sprintf "%5d", $ifunc;
				$out .= sprintf "  %-${max_length}s ", $name;   
				$out .= sprintf " %s ", $func->Expression->String;
				$out .= "\n";   
				++$ifunc; 
			}
		}
		$out .= "</functions>\n";

		return $out;
	}
}

1;
__END__
