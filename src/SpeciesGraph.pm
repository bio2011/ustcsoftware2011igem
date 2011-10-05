package SpeciesGraph;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Data::Dumper;
use Class::Struct;
use SequenceGraph;
use Utils;

{
	struct SpeciesGraph	=>
	{
		String	=>	'$',
		isPattern	=>	'$',	#	pattern or not
		Sequences	=>	'@',
		EquivSeqGroups	=>  '@',	#	groups of equivalent sequences
		isNorm	=>	'$'
	};

	sub newSpeciesGraph{
		my $class=shift;
		my $string=shift;
		my $ispatt=(@_)?shift: 0;

		#print "read species $string\n";
		
		if (not $string) {
			return('',"SpeciesGraph->newSpeciesGraph: Empty string");
		}
		else {
			my $sg=SpeciesGraph->new(String=>$string,isPattern=>$ispatt,isNorm=>0);
			#	print "string=$string\n";
			my @seqs=split(/\./,$string);
			foreach my $seq (@seqs) {
				my ($seqobj,$err)=SequenceGraph->newSequenceGraph($seq,$ispatt);
				if ($err) { return('',$err); }
				else {
					push (@{$sg->Sequences},$seqobj);
				}
			}
			if (my $err=$sg->findUnique ()) { return('',$err); }
			else { return $sg; }
		}
	}

	sub findUnique {
		my $sg=shift; 
		foreach my $seq (@{$sg->Sequences}) { 
			$seq->findUnique (); #print $seq->String;
		}
		@{$sg->Sequences}=sort {$a->getString('nobond') cmp $b->getString ('nobond')} @{$sg->Sequences};
		$sg->String($sg->getString());

		my $equivList=$sg->findEquivNoBondSeqs ();
		my $perms=$sg->findSeqPerms ($equivList);
		my ($minstrArray, $err)=$sg->findminstrArray ($perms);
		if ($err) { return $err; }
		else { $sg->bondRename($$minstrArray[0],'update'); }
		my $equivGroups=$sg->findEquivSeqs ($minstrArray);
		foreach my $gref (@{$equivGroups}) {
			push (@{$sg->EquivSeqGroups},$gref);
		}
		$sg->isNorm(1);

		return;
	}

	sub bondRename {#	optional to update
		my $sg=shift;
		my $permRef=(@_)? shift: '';
		my $update=(@_)? shift: '';

		my @SequencesCopy=();
		my $lastIndex=$#{$sg->Sequences};
		if (@$permRef) {
			foreach my $i (@$permRef) {
				push (@{$sg->Sequences}, $sg->Sequences($i)->copy());
			}
			for my $i (0..$lastIndex) { #	make a copy
				push (@SequencesCopy, shift @{$sg->Sequences}); 
			}
		}

		if (my $err=$sg->bondRenameCore()) { return('',$err); }
		my $stringAfterRebond=$sg->String;

		if (@$permRef) {
			unless ($update eq 'update') {	#	restore to original copy
				for my $i (0..$lastIndex) { 
					$sg->Sequences($i,$SequencesCopy[$i]);
				}
				$sg->String($sg->getString());
			}
		}
		return $stringAfterRebond;
	}

	sub bondRenameCore {
		my $sg=shift;
		my $delubs=(@_)? shift: '';

		#	rename bonds
		my $newBond=1;
		my %nameUsed=();
		foreach my $seq (@{$sg->Sequences}){
			if (my $err=$seq->bondRename(\$newBond,\%nameUsed)) 
			{ return('',$err.$sg->String); }
		}

		if ($delubs eq 'yes') {#  delete unpair bonds
			$sg->deleteUnpairedBonds(\%nameUsed);
		}
		elsif ($delubs eq 'no') {#	do nothing
			$sg->String($sg->getString());	#	update
			return '';
		}
		else {#	send errors
			foreach my $key (%nameUsed) {
				if ($nameUsed{$key}) {
					return('','SpeciesGraph->bondRenameCore: Unpaired bonds in '.$sg->String);
				}
			}
			$sg->String($sg->getString());	#	update
			return '';
		}
	}

	sub deleteUnpairedBonds {
		my $sg=shift;
		my $nameUsedRef=shift;
		foreach my $seq (@{$sg->Sequences}) {
			$seq->deleteUnpairedBonds($nameUsedRef);
		}
		$sg->String($sg->getString());
		return;
	}

	sub bondPrefix {
		my $sg=shift;
		my $pfx=shift;
		foreach my $seq (@{$sg->Sequences}) {
			$seq->bondPrefix($pfx);
		}
		$sg->String($sg->getString());	#	update
		return;
	}

	sub getString {#	connect sequences using .
		my $sg=shift;
		my @seqsArray=();
		foreach my $seq (@{$sg->Sequences}) {
			push (@seqsArray, $seq->getString());
		}
		return join(".",@seqsArray);
	}

	sub findEquivNoBondSeqs {
		my $sg=shift;
		my %start_end=();
		my ($prev_seq,$ptr1,$ptr2)=('',0,0);
		foreach my $seq (@{$sg->Sequences}) {
			unless ($ptr2) {
				$prev_seq=$seq->getString('nobond');
				$start_end{0}=0;
				$ptr2++;
				next;
			}
			if ($seq->getString('nobond') eq $prev_seq) {
				$start_end{$ptr1}=$ptr2;
			}
			else { 
				$ptr1=$ptr2;
				$start_end{$ptr1}=$ptr2;
			}
			$prev_seq=$seq->getString('nobond');
			$ptr2++;
		}
		#	print Dumper \%start_end;
		return \%start_end;
	}

	sub findSeqPerms {#
		my $sg=shift;
		my $blockRef=shift;
		#	print "blockRef\n"; print Dumper $blockRef;

		my @subPerms=();
		my $numPerms=1;
		foreach my $startNum (sort keys %$blockRef) {
			my $endNum = $blockRef->{$startNum};
			my $subPerm = generate_permutation ($startNum, $endNum);
			$numPerms *= @$subPerm;
			push (@subPerms, $subPerm);
		}
		#	print Dumper \@subPerms;

		my @arrPtrs=();
		my @perms=();
		for my $i (0..$#subPerms) { push (@arrPtrs, 0); }

		my $i_ptr=0;
		while ($i_ptr < $numPerms) {
			my @eachPerm = ();
			for my $i (0..$#subPerms) {
				my $subPermRef_1 = $subPerms[$i];
				my $subPermRef_2 = $$subPermRef_1[$arrPtrs[$i]];
				push (@eachPerm, @$subPermRef_2);
			}
			push (@perms, \@eachPerm);

			#   update arr_ptr
			for my $i (0..$#subPerms) {
				my $subPermRef = $subPerms[$i];
				last unless ++$arrPtrs[$i] == @$subPermRef;
				$arrPtrs[$i] = 0;
			}
			$i_ptr ++;
		}

		#	print Dumper \@perms;
		return \@perms;
	}

	sub findminstrArray {#
		my $sg=shift;
		my $perms_ref=shift;

		#	find minimal string set from all permutations of sequences
		my $minstr = "";
		my @minstrArray=();
		foreach my $perm (@$perms_ref) {
			my ($newstr,$err)=$sg->bondRename($perm);
			if ($err) { return('',$err); }

			#print Dumper $perm;
			#print "newstr=$newstr\n";
			unless (@minstrArray) {
				push (@minstrArray, $perm);
				$minstr = $newstr;
				next;
			}

			if ($minstr eq $newstr) {
				push (@minstrArray, $perm);
			}
			elsif ($minstr gt $newstr) {
				@minstrArray = ();
				push (@minstrArray, $perm);
				$minstr = $newstr;
			}
		}
		
		return \@minstrArray;
	}
		
	sub findEquivSeqs {
		my $sg=shift;
		my $minstrArrayRef=shift;
		#print Dumper $minstrArrayRef;
		
		my @groups=();
		my $perm_2="";
		foreach my $perm_1 (@$minstrArrayRef) {
			unless ($perm_2) {$perm_2=$perm_1; next;}
			for my $i (0..$#{$perm_1}) {
				my ($index1, $index2) = ($$perm_2[$i], $$perm_1[$i]);
				if ($index1 != $index2) {
					my $exist = 0;
					foreach my $gref (@groups)
					{
						#   find $index1 and $index2
						my ($find1, $find2) = (0,0);
						foreach my $index (@$gref)
						{
							if ($index == $index1) {$find1 = 1;}
							if ($index == $index2) {$find2 = 1;}
							last if $find1 && $find2;
						}

						$exist = 1 if ($find1 || $find2);  
						last if ($find1 && $find2);
						push (@$gref, $index2) if ($find1 && !$find2);
						push (@$gref, $index1) if ($find2 && !$find1);
					}

					#   create a new group
					unless ($exist) {
						my @newg = ($index1, $index2);
						push (@groups, \@newg);
					}
				}
			}
		}

		return \@groups;
	}

	sub EquivSeqGroups2String {
		my $sg=shift;
		my $string='';
		foreach my $gref (@{$sg->EquivSeqGroups}) {
			$string .= '('.join (',', sort @$gref).')	';
		}
		return $string;
	}

	sub patternMatching {	#	check whether species share the same key features with pattern
		my $patt=shift;	#	pattern
		my $spec=shift;	#	species
		my $specStanString=shift;
		my $check=(@_)?shift:'';
		#print "patt=",$patt->String,"\nspec=",$spec->String,"\n";

		my $numCombs=1;
		my (@allRes,@validRes)=((),());
		foreach my $pattSeq (@{$patt->Sequences}) {
			#print "pattSeq=",$pattSeq->String,"\n";
			my @seqRes=();
			my $ispec=-1;
			foreach my $specSeq (@{$spec->Sequences}) {
				#print "specSeq=",$specSeq->String,"\n";
				$ispec++;
				next unless ($pattSeq->Type eq $specSeq->Type);
				@seqRes=(@seqRes,@{$pattSeq->patternMatching($specSeq,$ispec)});
				#print Dumper \@seqRes;
				if ($specSeq->Type eq 'd') {#	reverse
					$specSeq->reverseString();
					@seqRes=(@seqRes,@{$pattSeq->patternMatching($specSeq,$ispec)});
					$specSeq->reverseString();	#	reverse back
					#print Dumper \@seqRes;
				}
			}
			return '' unless @seqRes;
			$numCombs *= scalar(@seqRes);
			push (@allRes,\@seqRes);
		}

		#print "check = $check\n";
		return $numCombs if $check eq 'check';

		#print "SpeciesGraph: number of combinations = $numCombs\n";

		my ($iptr,@ptrs,@symm,%used)=(0,(),(),());
		for my $i (0..$#{$patt->Sequences}) { push(@ptrs,0); }
		while ($iptr < $numCombs) {
			my @symm0=();
			my $found=0;
			my $equivgrps=$patt->EquivSeqGroups;
			if (@{$equivgrps}) {
				foreach my $grp (@{$equivgrps}) {
					my @subsymm=();
					foreach my $index (@$grp) {
						push (@subsymm,$ptrs[$index]);
					}
					@subsymm=sort(@subsymm);
					push(@symm0,@subsymm);
				}
				foreach my $rec (@symm) {
					if (diff_array($rec,\@symm0)) { $found=1; last; }
				}
			}
			#print "found=$found\n";

			FOUND:
			while (not $found) {#	
				my @newpattscore=();
				my %specSeqUsed=();	#	spec seq index => patt seq index
				my $ipatt=0;
				foreach my $ptr (@ptrs) {
					my $mrArray=$allRes[$ipatt];
					my $ispec=$$mrArray[$ptr]->Index;
					push (@newpattscore,$$mrArray[$ptr]->Concat);
					my $found1=$specSeqUsed{$ispec};
					if ($found1) { last FOUND; }
					else { $specSeqUsed{$ispec}=1; }
					$ipatt++;
				}
				
				my @residues=();
				for my $i (0..$#{$spec->Sequences}) {
					unless ($specSeqUsed{$i}) {
						push(@residues,$spec->Sequences($i)->String);
						push(@newpattscore,$spec->Sequences($i)->String);
					}
				}

				my ($newpatt,$err)=SpeciesGraph->newSpeciesGraph(join(".",@newpattscore));
				#print Dumper \@newpattscore;

				unless ($err) {	#print "species1=",$newpatt->String,"\nspecies2=",$specStanString,"\n";
					if ($newpatt->String eq $specStanString) {#	merge
						my $MR=MatchingRecord->new();
						$ipatt=0;	#	reset to 0
						foreach my $ptr (@ptrs) {
							my $mrArray=$allRes[$ipatt++];
							$MR->merge($$mrArray[$ptr]);
						}
						$MR->Residue(join(".",@residues)) if @residues;
						push(@validRes,$MR);
						push(@symm,\@symm0) if $equivgrps;
					}	
				}
				last FOUND;
			}

			for my $i (0..$#{$patt->Sequences}) { 
				if (++$ptrs[$i] != scalar(@{$allRes[$i]})) { last; }
				else { $ptrs[$i] = 0; }
			}
			
			$iptr++;
		}

		return \@validRes;
	}

	sub patternExpansion {
		my $sg=shift;
		my $allMR=shift;
		my $nameUsedRef=shift;
		unless ($sg->isPattern) {
			return('','SpeciesGraph->patternExpansion: NOT A PATTERN');
		}
		my @seqs=();
		foreach my $seq (@{$sg->Sequences}) {
			my ($expansion,$err)=$seq->patternExpansion($allMR,$nameUsedRef);
			if ($err) { return('',$err); }
			if ($expansion) { push(@seqs,$expansion); }
		}
		if (@seqs) { return join(".",@seqs); }
		else { return ''; }
	}

	sub trim {
		my $class=shift;
		my $mixture=shift;
		return '' unless $mixture;
		my @seqobjs=();
		my @seqstrs = split (/\./, $mixture);
		foreach my $str (@seqstrs) {
			my ($seq,$err)=SequenceGraph->newSequenceGraph($str);
			if ($err) { return('',$err); }
			else { push(@seqobjs,$seq); }
		}
		my %hashbs=();
		my $iseq=-1;
		foreach my $seq (@seqobjs) {
			$iseq++;
			if(my $allbonds=$seq->findAllBonds()) {
				foreach my $bond (@$allbonds) {
					if( my $seqArray=$hashbs{$bond}) {
						push(@$seqArray,$iseq);
					}
					else {
						my @tmparr=($iseq);
						$hashbs{$bond}=\@tmparr;
					}
				}
			}
		}
		my @groups = ();
		foreach my $bond (keys %hashbs) {
			my $seqArray = $hashbs{$bond};
			if (scalar(@$seqArray) == 1) {	#   remove dangling bonds
				my $seqno = $$seqArray[0];
				my ($reg1, $reg2) = ("\\!$bond", "");
				$seqstrs[$seqno] =~ s/$reg1/$reg2/;
			}
			elsif (scalar(@$seqArray) > 2) {
				return('',"SpeciesGraph->trim: Multiple ends for one bond in $mixture");
			}
			else {
				my ($seqno1,$seqno2)=($$seqArray[0],$$seqArray[1]);
				my ($igrp,$grpno1,$grpno2)=(0,-1,-1);
				foreach my $grp (@groups) {#
					foreach my $seqno (@$grp) {
						if ("$seqno" eq "$seqno1") {$grpno1 = $igrp;} 
						if ("$seqno" eq "$seqno2") {$grpno2 = $igrp;} 
					}
					$igrp++;
				}
				if ($grpno1==-1 && $grpno2==-1) {
					my @tmparr=();
					if ("$seqno1" eq "$seqno2") {
						push(@tmparr,$seqno1); 
					}
					else {
						push(@tmparr,$seqno1); 
						push(@tmparr,$seqno2);
					}
					push (@groups, \@tmparr);
				}
				elsif ($grpno1>-1 && $grpno2==-1) {
					push (@{$groups[$grpno1]}, $seqno2);
				}
				elsif ($grpno2>-1 && $grpno1==-1) {
					push (@{$groups[$grpno2]}, $seqno1);
				}
				else {
					if ($grpno1 != $grpno2) {
						push(@{$groups[$grpno1]}, @{$groups[$grpno2]});
						delete $groups[$grpno2];
					}
				}
			}
		}

		my @resplits=();
		foreach my $gref (@groups) {
			next unless $gref;
			my @newseqs = ();
			foreach my $seqno (@$gref) {
				push (@newseqs, $seqstrs[$seqno]);
				delete $seqstrs[$seqno];
			}
			if (@newseqs) {
				my ($spec,$err)=SpeciesGraph->newSpeciesGraph(join(".", @newseqs));
				if ($err) { return('',$err); }
				else { push(@resplits,$spec); }
			}
		}
		foreach my $str (@seqstrs) {
			next unless $str;
			my ($spec,$err)=SpeciesGraph->newSpeciesGraph($str);
			if ($err) { return('',$err); }
			else { push(@resplits,$spec); }
		}
		if (@resplits) { return \@resplits; }
		else { return ''; }
	}

}

1;
__END__
