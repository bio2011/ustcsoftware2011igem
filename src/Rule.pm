package Rule;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Data::Dumper;
use Class::Struct;
use Utils;

{
	struct Rule =>
	{
		Name	=>	'$',
		Index	=>	'$',
		TableName	=>	'$',	#	which rule table
		ReactantPatterns		=>	'@',
		ModifierPatterns		=>	'@',
		ProductPatterns		=>	'@',
		RateLaw	=>	'$',	#	just a formula is ok
		LocalParams	=>	'%'		#	[rule][$index]_[$paraname]
	};

	sub transformation {
		my $rule=shift;
		my $plist=shift;
		my $rxnlist=shift;
		my $flist=shift;
		my $slist=shift;
		my $spec0=shift;
		my $comp0name=$spec0->Compartment;
		my $index=$spec0->Index;
		my $reArrayNum=scalar(@{$rule->ReactantPatterns});

		#	pattern	matching of species with given index
		my $isMatchSpec0=0;
		my @jointPatterns=(@{$rule->ReactantPatterns},@{$rule->ModifierPatterns});
		foreach my $patt (@jointPatterns) {
			my $validRes=$patt->patternMatching(
				$spec0->SpeciesGraph,
				$spec0->SpeciesGraph->String,
				'check'
			);
			if ($validRes) {$isMatchSpec0=1;last;}
		}
		return '' unless $isMatchSpec0;

		#	find pattern matching of all species with index < $index
		my ($ipatt,$numCombs)=(-1,1);
		my @allRes=();
		foreach my $patt (@jointPatterns) {
			$ipatt ++;#print "$ipatt,\n";
			my @partRes=();
			for my $ispec (0..$index) {
				my $spec=$slist->Array($ispec);
				if ($spec->Compartment eq $spec0->Compartment) {
					my $stanstr=$spec->SpeciesGraph->String;
					$spec->SpeciesGraph->bondPrefix("0".($ipatt+1)."0"); #	rebond name 
					my $res=$patt->patternMatching($spec->SpeciesGraph,$stanstr);
					$spec->SpeciesGraph->bondRenameCore();	#	restore bond name
					unless($res) { next; }
					else {
						foreach my $mr (@$res) { 
							$mr->Index($ispec); 
							push(@partRes,$mr);
						}
					}
				}
			}
			return '' unless @partRes;
			push (@allRes,\@partRes);
			$numCombs *= scalar(@partRes);
		}

		#	print "\nRule: number of combinations = $numCombs\n";
		#	for my $i (0..$#allRes) {
		#		my $partres=$allRes[$i];
		#		print "pattern $i, ", $jointPatterns[$i]->String,"\n";
		#		foreach my $mr (@$partres) {
		#			$mr->print();
		#		}
		#	}

		my $iptr=-1;
		my @ptrs=();
		for my $i (0..$#jointPatterns) { push(@ptrs,0); }
		while(++$iptr < $numCombs) {	#print Dumper \@ptrs;
			my ($ipatt,$found)=(0,0);
			foreach my $ptr (@ptrs) {
				my $mrArray=$allRes[$ipatt++];
				my $ispec=$$mrArray[$ptr]->Index;
				#print "ispec=$ispec,index=$index\n";
				if ($ispec == $index) { $found=1; last; }
			}
			if($found) {
				my ($correctorder,$ipatt2)=(1,0);
				my (%hashReOrder,%hashMoOrder)=((),());	#	take care of modifiers
				foreach my $ptr (@ptrs) {
					my $mrArray=$allRes[$ipatt2];
					my $ispec=$$mrArray[$ptr]->Index;
					my $pattstr=$jointPatterns[$ipatt2]->String;
					if ($ipatt2<$reArrayNum) {	#	reactant patterns
						if(my $maxnum=$hashReOrder{$pattstr}) {
							if ($ispec<$maxnum) { 
								$correctorder=0; 
								last; 
							}
						}
						else { $hashReOrder{$pattstr}=$ispec; }
					}
					else {	#	modifier patterns
						if(my $maxnum=$hashMoOrder{$pattstr}) {
							if ($ispec<$maxnum) { 
								$correctorder=0; 
								last; 
							}
						}
						else { $hashMoOrder{$pattstr}=$ispec; }
					}
					$ipatt2++;
				}
				if($correctorder) {	#	start a reaction
					$ipatt=-1;
					my $allMR=MatchingRecord->new();
					my (@reArray,@moArray,@prArray)=((),(),());
					foreach my $ptr (@ptrs) {
						my $mrArray=$allRes[++$ipatt];
						my $ispec=$$mrArray[$ptr]->Index;
						my $specName=$slist->Array($ispec)->Name;
						if ($ipatt < $reArrayNum) {#	reactants
							push(@reArray,$specName);
							$allMR->merge($$mrArray[$ptr]);
						}
						else {	#	modifiers
							push(@moArray,$specName);
							$allMR->merge($$mrArray[$ptr],'Xonly');
						}
					}
					my @jointArray=(@reArray,@moArray);
					my $coef=find_combinatorial_coefficient(@jointArray);

					#print Dumper $allMR->InstNXs;
					#print $allMR->Residue,"\n";

					#	mixture-split procudure
					my ($mixture,$err)=$rule->mix($allMR);
					if ($err) { return $err; }
					#print "mixture=$mixture\n";
					(my $splits,$err)=SpeciesGraph->trim($mixture);
					if ($err) { return $err; }
					if ($splits) {
						foreach my $split (@$splits) {
							my $specindex=$slist->findSpecies(
								$split,$spec0->Compartment	#	split is of class SpeciesGraph
							);
							if ($specindex > -1){
								push(@prArray,$slist->Array($specindex)->Name);
							}
							else {
								my $index = $#{$slist->Array}+1;
								my $sname="s".($index+1);
								my ($expr)=Expression->newExpression(0.0,'algebra');
								my $species = Species->new(
									Name=>$sname,
									Index=>$index,
									Compartment=>$spec0->Compartment,
									InitConcentration=>$expr,
									Constant=>0,
									isSeedSpecies=>0,
									SpeciesGraph=>$split
								);
								$slist->add($species);
								push(@prArray,$sname);
							}
						}
					}

					#	kinetic law
					(my $formula,$err)=get_rate_formula_by_replacement($rule->RateLaw,\@jointArray);
					if ($err) {return $err;}

					#	add new reaction
					@prArray=sort @prArray;	#	att!	only sort product array
					$err=$rxnlist->addGeneralRxns(
						$rule->Index,$comp0name,\@reArray,\@moArray,\@prArray,$formula,$coef
					);
					if ($err) { return $err; }
				}
			}

			#	update pointers
			for my $i (0..$#jointPatterns) { 
				if (++$ptrs[$i] != scalar(@{$allRes[$i]})) { last; }
				else { $ptrs[$i] = 0; }
			}
		}
		 
		return '';
	}

	sub mix {
		my $rule=shift;
		my $allMR=shift;
		my ($ipatt,@mixture)=(-1,());
		my %nameUsed=();
		foreach my $patt (@{$rule->ProductPatterns}) {
			$patt->bondPrefix("00".(++$ipatt+1)."0");
			my ($expansion,$err)=$patt->patternExpansion($allMR,\%nameUsed);
			$patt->bondRenameCore();
			#print "expansion=$expansion\n";
			if ($err) { return('',$err); }
			if ($expansion) { push(@mixture,$expansion); }
		}
		if ($allMR->Residue) { push(@mixture,$allMR->Residue); }
		if (@mixture) { return join(".",@mixture); }
		else { return ''; }
	}

	sub print {
		my $rule=shift;
		my @lhspatts=();
		foreach my $rpatt (@{$rule->ReactantPatterns}) {
			push (@lhspatts, "  ".$rpatt->String."  ");
		}
		foreach my $mpatt (@{$rule->ModifierPatterns}) {
			push (@lhspatts, "  (".$mpatt->String.")  ");
		}
		my @rhspatts=();
		foreach my $ppatt (@{$rule->ProductPatterns}) {
			push (@rhspatts, "  ".$ppatt->String."  ");
		}
		my $out='';
		$out .= sprintf "  %s  ", $rule->Name;   
		$out .= sprintf "  %s  ->  %-s  ", join('+',@lhspatts), join('+',@rhspatts);
		$out .= sprintf "  %-s \n", $rule->RateLaw;
		print $out;
	}


}

1;
