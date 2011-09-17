package RuleList;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use Data::Dumper;
use Utils;
use Rule;
use SpeciesGraph;

{
	struct RuleList =>
	{
		Array	=>	'@',	#	rule objs
		RulesUsed	=>	'%'	#	rule index => 1/0
	};
	
	sub readSarray {
		my $rlist=shift;
		my $name=shift;
		my $rtabname=shift;
		my $lhsstr=shift;
		my $rhsstr=shift;
		my $isrev=shift;
		my $fwdratelaw=shift;
		my $revratelaw=shift;
		my $funclist=shift;
	
		if ($name !~ /^[A-Za-z]\w*$/) {
			return("Rule->readSarray: Invalid rule name in $name");
		}
		if ($rtabname !~ /^[A-Za-z]\w*$/) {
			return("Rule->readSarray: Invalid rule table name in $rtabname");
		}

		#	lhsstr and rhsstr could not be empty simultaneously
		my @lhspatts=();
		my @rhspatts=();
		if ($lhsstr || $rhsstr) {
			@lhspatts=split (/\;/,$lhsstr) if $lhsstr;
			@rhspatts=split (/\;/,$rhsstr) if $rhsstr;
		}
		else { return("Invalid reaction $name (no Reactant patterns and Product patterns)"); }
		#print Dumper \@lhspatts;
		#print Dumper \@rhspatts;

		if (boolean2int($isrev) == -1) {
			return("Invalid boolean value $isrev (should be true or false, case-insentive)");
		}
		else 
		{
			my @reactantpatts=();
			my @modifierpatts=();
			my @productpatts=();
			my $rindex=$#{$rlist->Array}+1;
			my $ratelaw_expansion='';
			my $localparams='';

			#	forward 
			foreach my $patt (@lhspatts) {
				if ($patt =~ s/^@//) {#	modifier patterns
					my ($mpatt_obj,$err)=SpeciesGraph->newSpeciesGraph($patt,1);
					if ($err) { return $err; }
					else { push (@modifierpatts, $mpatt_obj); }
				}
				else {#	reactant patterns
					my ($rpatt_obj,$err)=SpeciesGraph->newSpeciesGraph($patt,1);
					if ($err) { return $err; }
					else { push (@reactantpatts, $rpatt_obj); }
				}
			}

			foreach my $patt (@rhspatts) {
				$patt =~ s/^@//;
				my ($ppatt_obj,$err)=SpeciesGraph->newSpeciesGraph($patt,1);
				if ($err) { return $err; }
				else { push(@productpatts, $ppatt_obj); }
			}
			
			if ($fwdratelaw =~ /^([A-Za-z]\w*)\((.*)\)$/) {
				my $funcname=$1;
				$funclist->Hash->{$funcname} 
					|| return("Cannot reference undefined funciton $funcname");
				my @params=split(/\,/,$2) if $2;
				(my $func_exp,$localparams,my $err)=
					$funclist->Hash->{$funcname}->functionExpansion ($rindex+1,@params);
				if ($err) { return $err; }
				else { $ratelaw_expansion=$func_exp; }
			}
			else {return("Invalid forward rate law $fwdratelaw");}

			#	create rule object
			#print "name=$name, rindex=$rindex\n";
			my $ruleobj=Rule->new(
				Name=>$name,
				Index=>$rindex,
				TableName=>$rtabname,
				RateLaw=>$ratelaw_expansion
			);
			foreach (@reactantpatts) { push(@{$ruleobj->ReactantPatterns}, $_); }
			foreach (@modifierpatts) { push(@{$ruleobj->ModifierPatterns}, $_); }
			foreach (@productpatts)  { push(@{$ruleobj->ProductPatterns},  $_); }
			if($localparams ne '') {
				foreach (keys %{$localparams}) { 
					$ruleobj->LocalParams->{$_}=$localparams->{$_}; 
				}
			}

			#	add rule to list
			if (my $err=$rlist->add($ruleobj)) {return $err;}

			if (boolean2int($isrev)) 
			{	#	bi-direction 

				@reactantpatts=();
				@modifierpatts=();
				@productpatts=();
				$rindex=$#{$rlist->Array}+1;
				$ratelaw_expansion='';
				$localparams='';

				#	reverse
				foreach my $patt (@rhspatts) {
					if ($patt =~ s/^@//) {#	modifier patterns
						my ($mpatt_obj,$err)=SpeciesGraph->newSpeciesGraph($patt,1);
						if ($err) { return $err; }
						else { push (@modifierpatts, $mpatt_obj); }
					}
					else {#	reactant patterns
						my ($rpatt_obj,$err)=SpeciesGraph->newSpeciesGraph($patt,1);
						if ($err) { return $err; }
						else { push (@reactantpatts, $rpatt_obj); }
					}
				}

				foreach my $patt (@lhspatts) {
					$patt =~ s/^@//;
					my ($ppatt_obj,$err)=SpeciesGraph->newSpeciesGraph($patt,1);
					if ($err) { return $err; }
					else { push (@productpatts, $ppatt_obj); }
				}

				if ($revratelaw =~ /^([A-Za-z]\w*)\((.*)\)$/) {
					my $funcname=$1;
					my @params=split(/\,/,$2) if $2;
					$funclist->Hash->{$funcname} 
					|| return("Cannot reference undefined funciton $funcname");
					(my $func_exp,$localparams,my $err)=
						$funclist->Hash->{$funcname}->functionExpansion($rindex+1,@params);
					if ($err) { return $err; }
					else { $ratelaw_expansion=$func_exp; }
				}
				else {return("Invalid reverse rate law $revratelaw");}

				#	create rule object
				$ruleobj=Rule->new(
					Name=>$name."_rev",
					Index=>$rindex,
					TableName=>$rtabname,
					RateLaw=>$ratelaw_expansion
				);
				foreach (@reactantpatts) { push(@{$ruleobj->ReactantPatterns}, $_); }
				foreach (@modifierpatts) { push(@{$ruleobj->ModifierPatterns}, $_); }
				foreach (@productpatts)  { push(@{$ruleobj->ProductPatterns},  $_); }
				if($localparams ne '') {
					foreach (keys %$localparams) { 
						$ruleobj->LocalParams->{$_}=$localparams->{$_}; 
					}
				}

				if (my $err=$rlist->add($ruleobj)) {return $err;}
			}
		}
	}

	sub add
	{
		my $rlist=shift;  
		my $rule=shift;
		ref $rule eq 'Rule'
		|| return "RuleList: Attempt to add non-rule object $rule to RuleList.";   

		#	primary key (name) in rule table
		#	add new rule
		push @{$rlist->Array}, $rule;

		# continue adding rules (recursive)
		if ( @_ )
		{  return $rlist->add(@_);  }
		else
	{  return '';  }
	}

	sub applyTransportationRules 
	{
		my $rlist=shift;
		my $plist=shift;
		my $clist=shift;
		my $slist=shift;
		my $rxnlist=shift;
		my $ilist=shift;
		my @transpUsed=();
		my %inducerRuleUsed=();

		foreach my $spec (@{$slist->Array}){
			#	info of species $spec
			my $comp0=$clist->Hash->{$spec->Compartment};
			my $cname0=$comp0->Name;
			my $rtname0=$comp0->RuleTableName;
			my $specString=$spec->SpeciesGraph->String;
			my $index0=$slist->getSpeciesIndex($specString,$cname0);
			my $ngbCompsInfo=$clist->getNeighbors($cname0);

			#	inducer rules with regard to $specString
			my $indexGrp=$ilist->Hash->{$specString};
			next unless $indexGrp;

			foreach my $idx (@$indexGrp) {
				my $inducer=$ilist->Array($idx);
				foreach my $cname (keys %$ngbCompsInfo) {
					my $rtname=$ngbCompsInfo->{$cname};
					#	whether transportation happens between two comps
					my $case1=($rtname0 eq $inducer->RuleTableNameOut &&
						$rtname  eq $inducer->RuleTableNameIn);
					my $case2=($rtname0 eq $inducer->RuleTableNameIn &&
						$rtname  eq $inducer->RuleTableNameOut);
					if ($case1 || $case2) {
						my $index=$slist->getSpeciesIndex($specString,$cname);
						#	print "index=$index,index0=$index0\n";
						if (defined $index) {
							#	check if transportation reaction considered
							my $addNewTransp=1;
							my @record=($index0,$index);
							@record=sort @record;
							foreach my $rxn (@transpUsed) {
								if (diff_array($rxn,\@record)) { 
									$addNewTransp=0;last; 
								}
							}
							if ($addNewTransp) { push (@transpUsed,\@record); }
							else { next; }
						}
						else {#	transport species to new compartment and add a new reaction
							my ($newIndex,$err)=$slist->addNewGenSpecies ($specString,$cname);
							if ($err) { return $err; }
							else { $index=$newIndex; }
							my @record=($index0,$index);
							@record=sort @record;
							push (@transpUsed,\@record);
						}

						#	inducer rule used
						my $poutName='transp'.$inducer->Index.'_pout';
						my $pinName ='transp'.$inducer->Index.'_pin';
						unless (exists $inducerRuleUsed{$inducer->Index}){
							$inducerRuleUsed{$inducer->Index}=1;
							$plist->addSimpleParameter($poutName,$inducer->TransportRateOut);
							$plist->addSimpleParameter($pinName,$inducer->TransportRateIn);
						}

						#print "index=$index,index0=$index0\n";
						my $transporter1=$slist->Array($index0);
						my $transporter2=$slist->Array($index);
						if ($case1) {
							#print "cname=$cname cname0=$cname0\n";
							$rxnlist->addTransportationRxns (
								$transporter1->Name,
								$transporter2->Name,
								$cname0,$cname,
								$poutName,$pinName,
								$clist->Hash->{$cname}->Population->Name
							);
						}
						elsif ($case2) {
							#print "cname=$cname cname0=$cname0\n";
							$rxnlist->addTransportationRxns (
								$transporter2->Name,
								$transporter1->Name,
								$cname,$cname0,
								$poutName,$pinName,
								$clist->Hash->{$cname0}->Population->Name
							);
						}
					}
				}
			}
		}

		return '';
	}

	sub findRulesByTable{#	table name given
		my $rlist=shift;
		my $tableName=shift;
		my @rulesFound=();
		foreach my $rule (@{$rlist->Array}) {
			if ($rule->TableName eq $tableName) {
				push (@rulesFound, $rule);
			}
		}
		return \@rulesFound;
	}

	sub applyUserDefinedRules {
		my $rlist=shift;
		my $plist=shift;
		my $clist=shift;
		my $slist=shift;
		my $rxnlist=shift;
		my $flist=shift;
		my $fh=shift; #filehandle

		printf $fh "Iteration%5d: %5d species%5d rxns\n", 
			0, scalar(@{$slist->Array}), scalar(@{$rxnlist->Array});

		my $ispec=0;
		foreach my $spec (@{$slist->Array}) {
			#print $spec->SpeciesGraph->String,"\n";
			my $comp=$clist->Hash->{$spec->Compartment};
			my $tabname=$comp->RuleTableName;
			my $rulesRef=$rlist->findRulesByTable($tabname);
			foreach my $rule (@$rulesRef) {
				my $numRxns1=scalar(@{$rxnlist->Array});
				#print "rule name = ",$rule->Name,"\n";
				if (my $err=$rule->transformation($plist,$rxnlist,$flist,$slist,$spec)) { return $err; }
				my $numRxns2=scalar(@{$rxnlist->Array});
				if ($numRxns2>$numRxns1) {
					unless($rlist->RulesUsed->{$rule->Index}) {
						$rlist->RulesUsed->{$rule->Index}=1;
						foreach my $param (keys %{$rule->LocalParams}) {
							$plist->addSimpleParameter($param,$rule->LocalParams->{$param});
						}
					}
				}
			}
			printf $fh "Iteration%5d: %5d species%5d rxns\n", 
				++$ispec, scalar(@{$slist->Array}), scalar(@{$rxnlist->Array});
		}

		return '';
	}

	sub writeMoDeL 
	{
		my $rlist=shift;
		my $out = "";

		# find longest rule name
		my $max_length = 0;
		foreach my $rule (@{$rlist->Array})
		{
			$max_length = ($max_length >= length $rule->Name) ? $max_length : length $rule->Name;
		}

		#	get Used Tables
		my %TableUsed=();
		foreach my $rule (@{$rlist->Array}) {
			if($rlist->RulesUsed->{$rule->Index}) {
				$TableUsed{$rule->TableName}=1;
			}
		}

		$out .= "<rules>\n";
		foreach my $tab (keys %TableUsed)
		{
			$out .= "  #  ".$tab."\n";
			foreach my $rule (@{$rlist->Array}) {
				next unless $rlist->RulesUsed->{$rule->Index};
				$out .= sprintf "%5d", ($rule->Index+1);

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

				$out .= sprintf "  %s  ->  %-s  ", join('+',@lhspatts), join('+',@rhspatts);
				$out .= sprintf "  %-s  ", $rule->RateLaw;
				$out .= sprintf "  #  %-${max_length}s \n", $rule->Name;   
			}
		}
		$out .= "</rules>\n";

		return $out;
	}
}

1;
