package Function;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Data::Dumper;
use Class::Struct;
use Expression;
use Utils;

{
	struct Function =>
	{
		Name	=>	'$',
		Parameters	=>	'@',
		Expression	=>	'Expression'
	};

	sub functionExpansion {
		my $func=shift;
		my $ruleindex=shift;
		my @params_new=(@_);

		#	param in @params_new should either be a number or a specieal pattern $\d+
		foreach my $param (@params_new) {
			unless (isReal($param)) {
				unless ($param =~ /^#\d+$/){
					return('','',"Invalid parameter $param (should be a real number of number proceeds #");
				}
			}
		}

		my $num_of_params_new=scalar(@params_new);
		if ($num_of_params_new) {
			my @params_old=@{$func->Parameters};
			#	replace params_old with params_new
			if (scalar(@params_old) != $num_of_params_new) {
				return('','',"Invalid number of parameters (maybe due to wrong usage in rule tables)");
			}
			else {
				my %hash_params=();
				my %local_params=();
				for my $i (0..$#params_new) {
					if(isReal($params_new[$i])) {
						my $newname="rule$ruleindex\_$params_old[$i]";
						$hash_params{$params_old[$i]}=$newname;
						$local_params{$newname}=$params_new[$i];
					}
					else { $hash_params{$params_old[$i]}=$params_new[$i]; }
				}

				my $expression_new=$func->Expression->String;
				#	print "expression_new=$expression_new\n";
				#	print Dumper \%hash_params;
=cut
				my @sorted_old=reverse sort {length($a) <=> length($b)} @params_old;
				foreach (@sorted_old) {$expression_new =~ s/$_/$hash_params{$_}/g;}
				return $expression_new;
=cut
				my $res='';
				while($expression_new =~ /([A-Za-z]\w*)/) {
					$res .= $`.$hash_params{$1};
					$expression_new = $';
				}
				$res.=$expression_new if $expression_new;
				#	print "res=$res\n";
				return ($res,\%local_params);
			}
		}
		else { return $func->Expression->String; }
	}
}

1;
__END__
