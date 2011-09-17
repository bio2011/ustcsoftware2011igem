package SiteGraph;

use strict;
use warnings;
use FindBin;
use Data::Dumper;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;

$SiteGraph::exactcheck=1;

{
	struct SiteGraph	=>
	{
		String	=>	'$',
		Name	=>	'$',	#	site name		
		BondStatus	=>	'$',	#	free('')/occupied(!+,!\d+)/not known(!?)
		Labels	=>	'@'	#	list of labels
	};

	sub copy {
		my $site=shift;
		my $news=SiteGraph->new(
			String=>$site->String,
			Name=>$site->Name,
			BondStatus=>$site->BondStatus
		);
		foreach my $label (@{$site->Labels}) {
			push (@{$news->Labels},$label);
		}
		return $news;
	}

	sub newSiteGraph {
		my $class=shift;
		my $string=shift;
		my $ispatt=(@_)?shift:0;
		my $sg=SiteGraph->new(String=>$string);

		my $name="";
		if ($string =~ s/^([A-Za-z]\w*)//) { $name=$1;$sg->Name($name); }
		else { return('','',"SiteGraph->newSiteGraph: Invalid site format in $string"); }

		#	bondstatus
		if ($string =~ /^\!/) {
			if ($string =~ s/^\!([0-9]+)//) {#	the first letter should not be 0 in exact checking mode
				my $firstdigit=substr($1,0,1);
				if ($SiteGraph::exactcheck && $firstdigit == 0) {
					return('','',"SiteGraph->newSiteGraph: First digit of bond name $1 should not be 0");
				}
				else { $sg->BondStatus($1); }
			}
			elsif ($string =~ s/^\!\+//) {
				if ($ispatt) { $sg->BondStatus('+'); }
				else { return('','',"SiteGraph->newSiteGraph: Invalid bond status in ".$sg->String); }
			}
			elsif ($string =~ s/^\!\?//) {
				if ($ispatt) { $sg->BondStatus('?'); }
				else { return('','',"SiteGraph->newSiteGraph: Invalid bond status in ".$sg->String); }
			}
			else {
				return('','',"SiteGraph->newSiteGraph: Invalid bond status in ".$sg->String);
			}
		}

		#	labels
		if ($string =~ s/^\~//) {
			return('','',"SiteGraph->newSiteGraph: Invalid bond lable in ".$sg->String) unless $string;

			my @labels=split (/\~/,$string);
			foreach my $label (@labels) {
				if ($label =~ /^[A-Za-z]\w*$/) {
					push(@{$sg->Labels}, $label);
				}
				else { return('','',"SiteGraph->newSiteGraph: Invalid label in ".$sg->String); }
			}
			return ($sg,$name);
		}
		else {
			if ($string) {
				return('','',"SiteGraph->newSiteGraph: Invalid label in ".$sg->String); 
			}
			else { return ($sg,$name); }
		}
	}

	sub findUnique {#	sort labels based on their alphabetic order
		my $sg=shift;
		my $labelsArray=$sg->Labels;
		if (@{$labelsArray}) {#sort labels
			@{$labelsArray}=sort(@{$labelsArray});
			$sg->String($sg->getString());
		}
		return;
	}

	sub deleteUnpairedBonds {
		my $sg=shift;
		my $nameUsedRef=shift;
		if ($sg->BondStatus =~ /\d+/) {
			if ($nameUsedRef->{$sg->BondStatus}) {
				$sg->BondStatus(undef);
			}
		}
		$sg->String($sg->getString());
		return;
	}

	sub bondRename {#
		my $sg=shift;
		my $newBondRef=shift;
		my $nameUsedRef=shift;

		if ($sg->BondStatus) {	#	only for non-patterns
			if ($sg->BondStatus =~ /\d+/) {
				my $oldBondName = $nameUsedRef->{$sg->BondStatus};
				if (defined $oldBondName) {
					if ($oldBondName eq '0') {
						return 'SiteGraph->bondRename: Multiple ends for one bond in ';
					}
					else {
						$nameUsedRef->{$sg->BondStatus}=0;
						$sg->BondStatus($oldBondName);
					}
				}
				else {
					$nameUsedRef->{$sg->BondStatus}=$$newBondRef;
					$sg->BondStatus($$newBondRef++);
				}
				$sg->String($sg->getString());
			}
		}
		return '';
	}

	sub getString {#
		my $sg=shift;
		my @tags=(@_);
		my $nobond=0;
		foreach my $tag (@tags) {
			if ($tag eq 'nobond') { $nobond=1; }
		}

		my $string=$sg->Name;
		if ($sg->BondStatus) {
			$string .= "!";
			if ($nobond && $sg->BondStatus =~ /\d+/) {}
			else { $string .= $sg->BondStatus;}
		}
		foreach my $label (@{$sg->Labels}) { $string .= "~$label"; }
		return $string;
	}

	sub bondPrefix {	#	add prefix to each unambiguous bond name
		my $sg=shift;
		my $pfx=shift;
		if($sg->BondStatus) {
			if($sg->BondStatus =~ /\d+/) {
				$sg->BondStatus($pfx.$sg->BondStatus);
				$sg->String($sg->getString());
			}
		}
		return;
	}

	sub patternMatching {
		my $patt=shift;
		my $spec=shift;

		return '' unless $patt->Name eq $spec->Name;
		my $mres=$patt->Name;

		my $pattbs=$patt->BondStatus;
		my $specbs=$spec->BondStatus;
		if ($specbs) { return '' unless $pattbs; }
		else { return '' if $pattbs && ($pattbs ne '?'); }
		if ($pattbs) {
			if ($pattbs =~ /\d+/) { $mres.="!$pattbs"; }
			elsif ($pattbs eq '?' && $specbs) { $mres.="!$specbs"; }
			elsif ($pattbs eq '+') { $mres.="!$specbs"; }
		}

		if (@{$spec->Labels}){
			#	whether labels of patt is subset of that of spec
			if (@{$patt->Labels}) {
				my $target=join('-',@{$spec->Labels});
				foreach my $label (@{$patt->Labels}) {
					return '' unless ("-$label-" =~ /\-$target\-/);
				}
			}
			#	inherit labels from species
			$mres.="~$_" foreach @{$spec->Labels};
		}
		else { $mres.="~$_" foreach @{$patt->Labels}; }

		return $mres;
	}

	sub patternExpansion {
		my $patt=shift;	#	pattern
		my $spec=shift;	#	species
		if ($patt->Name ne $spec->Name) {
			return('',"SiteGraph->patternExpansion: Inconsistent names between $patt->Name and $spec->Name");
		}
		my $retval=$patt->Name;
		if ($patt->BondStatus) { #	bonds
			if ($patt->BondStatus eq '+') {
				if ($spec->BondStatus) {
					$retval.="!".$spec->BondStatus;
				}
				else {
					return('',"SiteGraph->patternExpansion: Cannot inheriting bond names from LHS patterns");
				}
			}
			elsif ($patt->BondStatus eq '?') {
				$retval.="!".$spec->BondStatus if $spec->BondStatus;
			}
			else { $retval.="!".$patt->BondStatus; }
		}
		if (@{$patt->Labels}) {	#	labels
			return "$retval~".join("~",@{$patt->Labels});
		}
		else { return $retval; }
	}

	sub isFullySpecified {
		my $sg=shift;
		if ($sg->BondStatus) {
			if ($sg->BondStatus eq '+' || $sg->BondStatus eq '?') { return 0; }
			else { return 1; }
		}
		else { return 1; }
	}

	sub findAllBonds {
		my $sg=shift;
		if ($sg->BondStatus) {
			if ($sg->BondStatus =~ /\d+/) {
				return $sg->BondStatus;
			}
		}
		return '';
	}
}


1;
