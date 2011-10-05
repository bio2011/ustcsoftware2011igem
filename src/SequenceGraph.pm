package SequenceGraph;

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use Data::Dumper;
use IO::Handle;
use Class::Struct;
use PartGraph;
use MatchingRecord;
use Utils;

{
	struct SequenceGraph	=>
	{
		String	=>	'$',
		Type	=>	'$',	#	(d)na,(r)na,(p)rotein,(m)olecule
		Parts	=>	'@'
	};

	sub newSequenceGraph{
		my $class=shift;
		my $string=shift;
		my $ispatt=(@_)?shift: 0;
		my $notype=(@_)?shift: '';

		my $type='';
		my $sg=SequenceGraph->new(String=>$string);
		if ($string =~ s/^(d|r|p|nb)\://) {
			$type=$1;
			$sg->Type($type);
		}
		else {
			unless ($notype eq 'notype') {
				return('',"SequenceGraph->newSequenceGraph: Invalid sequence format in $string"); 
			}
		}

		my @parts=split(/\-/,$string);
		foreach my $part (@parts) {
			my ($partobj,$err)=PartGraph->newPartGraph($part,$ispatt);
			if ($err) { return('',$err); }
			else { push (@{$sg->Parts},$partobj); }
		}

		return $sg;
	}

	sub copy {
		my $sg=shift;
		my $newseq=SequenceGraph->new(
			String=>$sg->String,
			Type=>$sg->Type
		);
		foreach my $part (@{$sg->Parts}) {
			my $newp=$part->copy();
			push(@{$newseq->Parts},$newp);
		}
		return $newseq;
	}

	sub findUnique {#	reverse string if it has lower weight
		my $sg=shift;
		foreach my $part (@{$sg->Parts}) { $part->findUnique (); }

		#	forward or reverse?
		if ($sg->Type eq 'd') {
			my $fwdString=$sg->getString ('nobond');
			my $revString=$sg->getString ('reverse','nobond');
			#print "fwdstring=$fwdString\nrevstring=$revString\n";
			if ($revString lt $fwdString) { $sg->reverseString (); }
			elsif ($revString eq $fwdString) {
				send_warning ("SequenceGraph->findUnique: Panlidrome string $fwdString FOUND");
			}
		}
		return;
	}
	
	sub bondRename {#	
		my $sg=shift;
		my $newBondRef=shift;
		my $nameUsedRef=shift;
		foreach my $part (@{$sg->Parts}){
			if(my $err=$part->bondRename($newBondRef,$nameUsedRef))
			{ return $err; }
		}
		$sg->String($sg->getString ());
		return '';
	}

	sub deleteUnpairedBonds {
		my $sg=shift;
		my $nameUsedRef=shift;
		foreach my $part (@{$sg->Parts}) {
			$part->deleteUnpairedBonds($nameUsedRef);
		}
		$sg->String($sg->getString());
		return;
	}

	sub reverseString {
		my $sg=shift;
		@{$sg->Parts}=reverse(@{$sg->Parts});
		foreach my $part (@{$sg->Parts}) {
			$part->reverseString ();
		}
		$sg->String ($sg->getString ());
	}

	sub getString {#	just get, do not update
		my $sg=shift;
		my @tags=(@_);
		my ($reverse,$nobond)=(0,0);
		foreach my $tag (@tags) {
			if ($tag eq 'reverse') { $reverse=1; }
			elsif ($tag eq 'nobond') { $nobond=1; }
		}

		my @partsArray=();
		if ($reverse) {
			if ($sg->Type ne 'd') {
				send_warning ("SequenceGraph->getString: Try to reverse a non-DNA sequence ".$sg->Stirng);
			}

			for my $i (0..$#{$sg->Parts}) {
				my $part = $sg->Parts(-($i+1));
				if ($nobond) {
					push (@partsArray, $part->getString ('reverse','nobond'));
				}
				else {
					push (@partsArray, $part->getString ('reverse'));
				}
			}
		}
		else {
			for my $i (0..$#{$sg->Parts}) {
				my $part = $sg->Parts($i); #print $part->{String};
				if ($nobond) {
					push (@partsArray, $part->getString ('nobond'));
				}
				else {
					push (@partsArray, $part->getString ());
				}
			}
		}

		if ($sg->Type) {
			return $sg->Type.":".join("-",@partsArray);
		}
		else { return join("-",@partsArray); }
	}

	sub bondPrefix {
		my $sg=shift;
		my $pfx=shift;
		foreach my $part (@{$sg->Parts}) {
			$part->bondPrefix($pfx);
		}
		$sg->String($sg->getString());
		return;
	}

	sub getXpartIndices {
		my $patt=shift;
		my $xnum=0;
		my $ipart=-1;
		my @indices=();
		foreach my $part (@{$patt->Parts}) {
			$ipart++;
			if ($part->isXpart) { 
				push (@indices,$ipart); 
				$xnum ++; 
			}
		}
		return ($xnum,@indices);
	}

	sub validateXpartMatchings {
		my $patt=shift;
		my $mrsRef=shift;	#	@F, matching strings for each X part
		my $idxRef=shift;	#	Indices of X part in $patt
		for my $ixp (0..$#{$mrsRef}) {#
			my $part=$patt->Parts($$idxRef[$ixp]);
			if ($part->XpartStatus) {
				my $numPartsMatched=0;
				if ($$mrsRef[$ixp]) {
					my @splits=split(/-/,$$mrsRef[$ixp]);
					$numPartsMatched=scalar(@splits);
				}
				if ($part->XpartStatus eq '+') {
					return 0 if	$numPartsMatched == 0;
				}
				elsif ($part->XpartStatus eq '?') {
					return 0 if $numPartsMatched > 1;
				}
				elsif ($part->XpartStatus =~ /\d+/) {
					return 0 unless $numPartsMatched == $part->XpartStatus;
				}
				else {#	> or <
					my $delta=$part->XpartStatus eq '>'? 1:-1;
					my $npidx=$$idxRef[$ixp]+$delta;
					my $nextpart=$patt->Parts($npidx);
					if ($nextpart) {
						my $substr='';
						if ($nextpart->isXpart) { 
							$substr=$$mrsRef[$ixp+$delta]; 
						}
						else { $substr=$nextpart->String; }
						return 0 if index($$mrsRef[$ixp],$substr) > -1;
					}
				}
			}
		}
		return 1;
	}

	sub patternMatching {
		my $patt=shift;
		my $spec=shift;
		my $ispec=shift;
		my @pattXind=$patt->getXpartIndices();
		my $pattXnum=shift @pattXind;
		my @pattXname=();
		foreach my $idx (@pattXind) {
			push(@pattXname,$patt->Parts($idx)->Name);
		}

		my @pmResults=();	#	@{Matching Records}
		my $initMismatch=0;
		my $ptrErr=1;
		my @ptrs=();
		for (my $i=0; $i < $pattXnum; $i++) { push(@ptrs,0); }
		#print Dumper \@ptrs;

		my $regexp=$patt->genRegExp(\@ptrs);

		#print "pattern=",$patt->String,"\n";
		#print "\nregexp0=$regexp\nstring=",$spec->String,"\n";
		#print "match!\n" if $spec->String =~ /$regexp/;

		my @FF=();
		while (1) {
			#print "regexp=$regexp\n";
			my @F = ($spec->String =~ /$regexp/);
			if (@F) {		#print Dumper \@F;
				if ($pattXnum > 0) {
					if ($patt->validateXpartMatchings(\@F,\@pattXind)) {
						my $MR = MatchingRecord->new();
						my $ixmatch=0;
						foreach my $xmatch (@F) {
							my $xname=$pattXname[$ixmatch++];
							if (exists $MR->InstXs->{$xname}) {
								push (@{$MR->InstXs->{$xname}},$xmatch);
							}
							else {
								my @newArray=($xmatch);
								$MR->InstXs->{$xname}=\@newArray; 
							}
						}
						push (@pmResults,$MR);
					}
				}
				else {
					push(@pmResults,MatchingRecord->new());
					last;
				}

				#	update pointers
				$ptrs[-1] += length($F[-1]) +3; #3 is at least
				#print Dumper \@ptrs;
				$regexp=$patt->genRegExp(\@ptrs);
				$ptrErr=1;
				$initMismatch++;
				@FF=@F;	#	keep last valid regular expression matching
			}
			else {
				unless ($initMismatch++) { last; }	#	no matchings at all
				if(++$ptrErr>$pattXnum) { last; }
				for (my $i=1; $i < $ptrErr; $i++) { $ptrs[-$i] = 0; }
				
				#	---------------------------------------------
				#	$ptrs[-$ptrErr] += length ($FF[-$ptrErr]) +3;
				#	Chen Liao Modified On Oct.5
					$ptrs[-$ptrErr] = length ($FF[-$ptrErr]) +3;
				#	---------------------------------------------
				
				$regexp = $patt->genRegExp(\@ptrs);
			}
		}
		#print Dumper \@pmResults;

		my $numRes=scalar(@pmResults);
		for (my $i=0; $i<$numRes; $i++) {
			my $MR = shift @pmResults;
			my @concat=();
			my ($pass,$ipart)=(1,0);
			foreach my $part (@{$patt->Parts}) {
				#print "part=",$part->String,"\n";
				if ($part->isXpart) {
					my $xmatch=$MR->InstXs->{$part->Name};
					my $pmstr=shift @{$xmatch};
					if ($pmstr) {
						my ($seq,$err)=$patt->newSequenceGraph($pmstr,0,'notype');
						if ($err) {exit_error ("$err\nIMPORTANT BUG!");}
						push (@concat,$seq->String);
						unless ($part->isForward) { $seq->reverseString(); }
						push(@{$xmatch},$seq);
						$ipart += scalar(@{$seq->Parts});
					}
					else { push(@{$xmatch},SequenceGraph->new()); }
				}
				else {#	non-X-part
					#print "patt=",$part->String," spec=",$spec->Parts($ipart)->String,"\n";
					if (my $mres=$part->patternMatching($spec->Parts($ipart))) {
						#print "mres=$mres\n";
						if (exists $MR->InstNXs->{$part->Name}) {
							push (@{$MR->InstNXs->{$part->Name}},$spec->Parts($ipart)->copy());
						}
						else {
							my @newArray=($spec->Parts($ipart)->copy());
							$MR->InstNXs->{$part->Name}=\@newArray;
						}
						push (@concat,$mres);
						$ipart++;
					}
					else { $pass=0; last; }
				}
				#print Dumper \@concat;
			}
			if ($pass) { 
				$MR->Index($ispec);
				$MR->Concat($patt->Type.":".join('-',@concat));
				push(@pmResults,$MR); 
			}
		}
		#print "number of pattern matchign results=",scalar(@pmResults),"\n";

		return \@pmResults;
	}

	sub genRegExp {
		my $patt=shift;
		my $ptrsRef=shift;
		my $numpart=scalar(@{$patt->Parts});

		#	special case
		if ($numpart == 1 && $patt->Parts(0)->isXpart) { 
		#	=======================================
		#	-----	Chen Liao Mofied On 10.5  -----
		#	return $patt->Type.":(.*)"; 
		#	=======================================
			return $patt->Type.":(.{$$ptrsRef[-1],})"; 
		}

		#	create regular expression
		my $regexp='^'.$patt->Type.":";
		my ($index,$dash) = (0,0);
		foreach my $part (@{$patt->Parts}) {
			if ($part->isXpart) {
				my $min_len = $$ptrsRef[$index];
				if ($min_len == 0) {$regexp .= "\-?(.{0,}?)\-?";}
				else {$regexp .= "\-?(.{$min_len,}?\\))\-?";}
				$index++;
				$dash = 0;
			}
			else {
				$regexp .= "\-" if ($dash);
				$dash = 1;
				$regexp .= $part->Name;
				$regexp .= "\\*" unless $part->isForward;
				$regexp .= "\\(.*?\\)";
			}
        }
		$regexp .= "\$";	#	important
		return $regexp;
	}

	sub patternExpansion {
		my $sg=shift;
		my $allMR=shift;
		my $nameUsedRef=shift;
		my @parts=();
		foreach my $part (@{$sg->Parts}) {
			my ($expansion,$err)=$part->patternExpansion($allMR,$nameUsedRef);
			if ($err) { return('',$err); }
			if ($expansion) { push(@parts,$expansion); }
		}
		if (@parts) { return $sg->Type.":".join('-',@parts); }
		else { return ''; }
	}

	sub findAllBonds {
		my $sg=shift;
		my @res=();
		foreach my $part (@{$sg->Parts}) {
			my $bonds=$part->findAllBonds();
			if ($bonds) { @res=(@res,@$bonds); }
		}
		if(@res) { return \@res; }
		else { return ''; }
	}

}

1;
__END__
