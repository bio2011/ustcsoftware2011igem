package PartGraph;

use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use SiteGraph;

{
	#	NOTE: identical sites are not supported in version 1.1
	#	
	#	Possible Xpart Status : !+,!?,!>,!<,!\d+(>1)
	my $XPATTERN="^([A-Za-z]\\w*)(\\*)?(\\!\\+|\\!\\?|\\!\\>|\\!\\<|\\![1-9][0-9]*)?\$";

	struct PartGraph	=>
	{
		String	=>	'$',
		Name	=>	'$',	#	part name		
		isForward	=>	'$',	#	Forward=>1/Reverse=>0
		isXpart	=> '$',	#	no=>0, yes=>1
		XpartStatus	=>	'$',	#	for X part only
		SitesArray	=>	'@',	#	List of internal sites
		SitesHash	=>	'%'		#	
	};

	sub copy {
		my $part=shift;
		my $newp=PartGraph->new(
			String=>$part->String,
			Name=>$part->Name,
			isForward=>$part->isForward,
			XpartStatus=>$part->XpartStatus,
			isXpart=>$part->isXpart
		);
		foreach my $site (@{$part->SitesArray}) {
			my $news=$site->copy();
			push (@{$newp->SitesArray},$news);
			$newp->SitesHash->{$news->Name}=$news;
		}
		return $newp;
	}

	sub newPartGraph{
		my $class=shift;
		my $string=shift;
		my $ispatt=(@_)?shift: 0;

		if ($string =~ /^([A-Za-z]\w*)(\*)?\((.*)\)$/) {
			my $isforward=($2) ? 0:1;
			my $pg=PartGraph->new(String=>$string,Name=>$1,isForward=>$isforward,isXpart=>0);
			#print "string=$string,name=$name\n";

			my @sites=split(/\,/,$3) if $3;
			foreach my $site (@sites) {
				my ($siteobj,$sitename,$err)=SiteGraph->newSiteGraph($site,$ispatt);
				if ($err) { return('',$err); }
				else {
					if (exists $pg->SitesHash->{$sitename}) {
						return ('',"PartGraph->newPartGraph: Site with name $sitename has been defined previously");
					}
					else {
						$pg->SitesHash->{$sitename}=$siteobj;
						push(@{$pg->SitesArray},$siteobj);
					}
				}
			}
			return $pg;
		}
		else { 
			if ($ispatt) {
				if ($string =~ /$XPATTERN/) {
					my $isforward = ($2) ? 0:1;	#	forward part?
					my $pg=PartGraph->new(
						String=>$string, Name=>$1,isForward=>$isforward,isXpart=>1	
					);
					if ($3) {$pg->XpartStatus(substr($3,1)) if $3;}	#	remove "!"
					return $pg;
				}
				else { return('',"PartGraph->newPartGraph: Invalid part format in $string"); }
			}
			else { return('',"PartGraph->newPartGraph: Invalid part format in $string"); }
		}
	}

	sub findUnique{#	sort sites based on the alphabetic order of their names
		my $pg=shift;
		foreach my $site (@{$pg->SitesArray}) {#	make sure objs in SitesHash change consistently
			$site->findUnique ();
		}
		if (@{$pg->SitesArray}) {
			@{$pg->SitesArray}=sort {$a->String cmp $b->String} @{$pg->SitesArray};
		}
		$pg->String($pg->getString());
		return;
	}

	sub bondRename {
		my $pg=shift;
		my $newBondRef=shift;
		my $nameUsedRef=shift;
		foreach my $site (@{$pg->SitesArray}){
			if(my $err=$site->bondRename($newBondRef,$nameUsedRef))
			{ return $err; }
		}
		$pg->String($pg->getString());
		return '';
	}

	sub deleteUnpairedBonds {
		my $pg=shift;
		my $nameUsedRef=shift;
		foreach my $site (@{$pg->SitesArray}) {
			$site->deleteUnpairedBonds($nameUsedRef);
		}
		$pg->String($pg->getString());
		return;
	}

	sub reverseString {#	sites do not change
		my $pg=shift;
		if ($pg->isForward) { $pg->isForward(0); }
		else { $pg->isForward(1); }
		if ($pg->isXpart && $pg->XpartStatus) {
			if ($pg->XpartStatus eq '>') {$pg->XpartStatus('<');}
			elsif ($pg->XpartStatus eq '<') {$pg->XpartStatus('>');}
		}
		$pg->String($pg->getString());
	}

	sub getString {#	just get, do not update
		my $pg=shift;
		my @tags=(@_);
		my ($reverse,$nobond)=(0,0);
		foreach my $tag (@tags) {
			if ($tag eq 'reverse') { $reverse=1; }
			elsif ($tag eq 'nobond') { $nobond=1; }
		}
		
		my $string='';
		if ($pg->isXpart) {#	an X part
			if ($nobond) {#	normalization requires same name for all Xparts
				$string .= 'X'; 
			}
			else {
				$string .= $pg->Name;
				if ($reverse) { $string .= "*" if $pg->isForward; }
				else { $string .= "*" unless $pg->isForward; }
				$string .= "!".$pg->XpartStatus if $pg->XpartStatus;
			}
		}
		else {#	not an X part
			$string .= $pg->Name;
			if ($reverse) { $string .= "*" if $pg->isForward; }
			else { $string .= "*" unless $pg->isForward; }
			$string .= "(";
			my @sites=();
			foreach my $site (@{$pg->SitesArray}) {
				if ($nobond) {
					push (@sites, $site->getString ('nobond'));
				}
				else {
					push (@sites, $site->getString ());
				}
			}
			$string .= join(",",@sites);
			$string .= ")";
		}
		return $string;
	}

	sub bondPrefix {
		my $pg=shift;
		my $pfx=shift;
		foreach my $site (@{$pg->SitesArray}) {
			$site->bondPrefix($pfx);
		}
		$pg->String($pg->getString());
		return;
	}

	sub patternMatching {
		my $patt=shift;
		my $spec=shift;

		return '' unless $patt->Name eq $spec->Name;
		my $mres=$patt->Name;

		return '' unless $patt->isForward eq $spec->isForward;
		$mres.="*" unless $patt->isForward;

		#	whether sites of patt are subset of that of spec
		my @stcopys=();
		foreach my $pattst (@{$patt->SitesArray}) {
			if (my $specst=$spec->SitesHash->{$pattst->Name}) {
				if (my $stcopy=$pattst->patternMatching($specst)) {#
					push (@stcopys, $stcopy);
				}
				else { return ''; }
			}
			else { return ''; }
		}
		#	copy sites that are not part of patt's to @stcopys
		foreach my $specst (@{$spec->SitesArray}) {
			unless (my $pattst=$patt->SitesHash->{$specst->Name}) {
				push(@stcopys,$specst->String);
			}
		}
		return $mres.'('.join(',',@stcopys).')';
	}

	sub patternExpansion {
		my $pg=shift;
		my $allMR=shift;
		my $nameUsedRef=shift;
		if ($pg->isXpart) {
			if (my $seqArrayRef=$allMR->InstXs->{$pg->Name}) {
				my $seqobj='';
				if (my $times=$nameUsedRef->{$pg->Name}) {
					if ($times > $#{$seqArrayRef}) {
						return('',"PartGraph->patternExpansion: Array Overflow");
					}
					else { 
						$seqobj=$$seqArrayRef[$times]; 
						$nameUsedRef->{$pg->Name}++;
					}
				}
				else {
					$seqobj=$$seqArrayRef[0];
					$nameUsedRef->{$pg->Name}=1;
				}
				$seqobj->reverseString() unless $pg->isForward;
				return $seqobj->String;
			}
			else {
				return('',"PartGraph->patternExpansion: Cannot not reference Xpart $pg->Name in matching records");
			}
		}
		else {
			if (my $partArrayRef=$allMR->InstNXs->{$pg->Name}) {
				my $partobj='';
				if (my $times=$nameUsedRef->{$pg->Name}) {
					if ($times > $#{$partArrayRef}) { 
						foreach my $site (@{$pg->SitesArray}) {
							return('',"PartGraph->patternMatching: Incomplete speficied part ".
								$pg->String) unless $site->isFullySpecified();
						}
						return $pg->String; 
					}
					else {
						$partobj=$$partArrayRef[$times];
						$nameUsedRef->{$pg->Name}++;
					}
				}
				else {
					$partobj=$$partArrayRef[0];
					$nameUsedRef->{$pg->Name}=1;
					#print Dumper $partobj;
				}

				my @sitesexp=();
				my %sitesUsed=();
				foreach my $site (@{$pg->SitesArray}) {
					if (my $siteobj=$partobj->SitesHash->{$site->Name}) {
						my ($expstr,$err)=$site->patternExpansion($siteobj);
						if ($err) { return('',$err); }
						else { push(@sitesexp,$expstr); }
						$sitesUsed{$site->Name}=1;
					}
					else { push(@sitesexp,$site->String); }
				}
				foreach my $site (@{$partobj->SitesArray}) {
					unless ($sitesUsed{$site->Name}) {
						push(@sitesexp,$site->String);
					}
				}
				my $retval=$pg->Name;
				$retval.='*' unless $pg->isForward;
				return $retval.'('.join(",",@sitesexp).')';
			}
			else {
				foreach my $site (@{$pg->SitesArray}) {
					return('',"PartGraph->patternMatching: Incomplete speficied part ".
						$pg->String) unless $site->isFullySpecified();
				}
				return $pg->String; 
			}
		}
		#	return;
	}

	sub findAllBonds {
		my $pg=shift;
		my @res=();
		foreach my $site (@{$pg->SitesArray}) {
			my $bonds=$site->findAllBonds();
			if ($bonds) { push(@res,$bonds); }
		}
		if(@res) { return \@res; }
		else { return ''; }
	}
}

1;
__END__
