package EventList;

use strict;
use warnings;
use File::Spec;
use LibSBML;
use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use Event;

{
	my $print_on=0;	#	switch on/off print

	struct EventList =>
	{
		Hash	=>	'%',	#	hash 
		Array	=>	'@'		#	array
	};

	sub readString
	{
		my $elist  = shift;  #	EventList
		my $string = shift;  #	Event string to parse
		my $plist  = shift;	 #	ParameterList
		my $clist  = shift;	 #  CompartmentList
		my $slist  = shift;	 #	SpeciesList

		#	Read name (required)
		$string =~ s/^\s*([A-Za-z]\w*)//   or return("Invalid event name in $string");
		my $name = $1;

		#	Read triggering condition (required)
		$string =~ s/^\s*(\S+)//   or return( "Invalid trigger condition for Event in $string" ); 
		my $trig = $1;
		#print "trig=$trig\n";

		#	Read event assignments
		my @assignments = ();
		while ($string =~ s/^\s*([A-Za-z]\w*)\=([A-Za-z]\w*)//) {
			$slist->Hash->{$1}
				||	return("Cannot reference undefined species $1");
			push (@assignments, $1."=".$2);
		}

		return unless @assignments;	#	do nothing if no event assignments

		if ($string =~ /\S+/) {
			return "Unrecognized trailing syntax $string in compartment specification"; 
		}

		#	create event
		my ($event,$err) = Event->newEvent($name,$trig,\@assignments,$plist,$clist,$slist);

		if ($err) { return $err; }
		else { return $elist->add($event); }
	}

	sub add
	{
		my $elist = shift;  # EventList ref

		my $event = shift;
		ref $event eq 'Event'
		|| return "EventList: Attempt to add non-event object $event to EventList.";   

		if ( exists $elist->Hash->{ $event->Name } ) { # event with same name is already in list
			return "EventList: event $event->Name has been defined previously";
		}
		else{ # add new event
			$elist->Hash->{ $event->Name } = $event;
			push @{$elist->Array}, $event;
		}

		# continue adding events (recursive)
		if ( @_ )
		{  return $elist->add(@_);  }
		else
		{  return '';  }
	}

	sub print{
		
		if ($print_on) {
			my $elist= shift;
			my $fh= shift;	#filehandle
			my $i_start= (@_) ? shift : 0;

			print $fh "begin events\n";
			my $sarray= $elist->Array;
			for my $i ($i_start..$#{$sarray}){
				my $event= $sarray->[$i];
				
				printf $fh "%5d	",	$i-$i_start+1;

				my @vars = (
					$event->Name,
					$event->Trig->String
				);
				foreach (keys %{$event->Hash}) {
					push (@vars,$_."=".$event->Hash->{$_}->String);
				}
				my $prt=join("  ",@vars);
				printf $fh "$prt\n";
			}
			print $fh "end events\n";
			return("");
		}
	}

	sub writeMoDeL 
	{
		my $elist=shift;
		my $out = "";

		# find longest event name
		my $max_length = 0;
		foreach my $event (@{$elist->Array})
		{
			$max_length = ($max_length >= length $event->Name) ? $max_length : length $event->Name;
		}

		# now write event strings
		my $ievent = 1;
		$out .= "<events>\n";
		foreach my $event (@{$elist->Array})
		{
			$out .= sprintf "%5d", $ievent;
			$out .= sprintf "  %-${max_length}s ", $event->Name;   
			$out .= sprintf "  %s  ", $event->Trig->String;
			foreach my $ass (keys %{$event->Hash}) {
				$out .= sprintf "  %s  ", $ass."=".$event->Hash->{$ass}->String;
			}
			$out .= "\n";   
			++$ievent; 
		}
		$out .= "</events>\n";

		return $out;
	}

	sub writeSBML {
		my $elist=shift;
		my $sbmlModel=shift;
		foreach my $event (@{$elist->Array}) {
			my $sbmlevent=$sbmlModel->createEvent();
			if(my $errcode=$sbmlevent->setId($event->Name)) {return $errcode;}
			my $sbmltrig=$sbmlevent->createTrigger();
			if(my $errcode=$sbmltrig->setMath($event->Trig->MathML)) {return $errcode;}
			foreach my $ass (keys %{$event->Hash}) {
				my $sbmlass=$sbmlevent->createEventAssignment();
				if(my $errcode=$sbmlass->setVariable($ass)) {return $errcode;}
				if(my $errcode=$sbmlass->setMath($event->Hash->{$ass}->MathML)) {return $errcode;}
			}
		}
		return '';
	}
}

1;
__END__
