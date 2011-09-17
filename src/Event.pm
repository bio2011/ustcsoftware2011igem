package Event;

use FindBin;
use lib $FindBin::Bin;
use IO::Handle;
use Class::Struct;
use Expression;
use Utils;

{
	struct Event =>
	{
		Name	=>	'$',	#	identifier of the event
		Trig	=>	'Expression',	#	a logic expression
		Hash	=>	'%'		#	event assignments
	};

	sub newEvent {
		my $class=shift;
		my $name=shift;
		my $trig=shift;
		my $ref_assi=shift;
		my $plist=(@_)? shift: "";
		my $clist=(@_)? shift: "";
		my $slist=(@_)? shift: "";

		my ($exprTrig,$exprVal,$exprErr)=Expression->newExpression($trig,'logic',$plist,$clist,$slist);
		if ($exprErr) {	return ('',$exprErr); }
		my $event = Event->new(Name=>$name,Trig=>$exprTrig);

		my $exprAssi;
		foreach (@$ref_assi) {#add to Event->Hash
			my ($var,$expr) = split (/\=/,$_);

			($exprAssi,$exprVal,$exprErr)=Expression->newExpression($expr,'algebra',$plist,$clist,$slist);
			if ($exprErr) {	return ('',$exprErr); }
			else {$event->Hash->{$var} = $exprAssi;}
		}

		return $event;
	}
}



1;
