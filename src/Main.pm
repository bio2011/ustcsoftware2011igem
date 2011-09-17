package Main;

use strict;
use warnings;
use File::Spec;
use LibSBML;
use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use Data::Dumper;
use autodie;
use DBI;
use Utils;

use ParamList;
use CompartmentList;
use SpeciesList;
use ReactionList;
use EventList;
use RuleList;
use FunctionList;
use InducerList;

struct Main =>
{
	Name				=>	'$',
	Time				=>	'$',
	ParamList			=>	'ParamList',
	CompartmentList		=>	'CompartmentList',
	SpeciesList			=>	'SpeciesList',
	ReactionList		=>	'ReactionList',
	EventList			=>	'EventList',
	RuleList			=>	'RuleList',
	InducerList			=>	'InducerList',
	FunctionList		=>	'FunctionList',
	Options				=>  '%'   # Options used to control behavior of model and associated methods
};


{
	my %conn_attrs = (
		PrintError => 0, 
		RaiseError => 1, 
		AutoCommit => 1
	);
	my ($file,$line_number,$file_dat);

	sub readFile
	{
		#print Dumper \@_;
		my $model = shift;	#	bless
		my $params = (@_) ? shift : '';
		#print Dumper $params;

		#	internal control parameters
		my $fname		= "";
		my $prefix		= "";
		my $no_exec		= 0;
		my $write_sbml	= 0;

		#	process optional parameters
		if ($params)
		{
			foreach (keys %$params)
			{
				if ($_ eq "no_exec") {
					$no_exec = $params->{no_exec};
				}
				elsif ($_ eq "file") {
					$fname = $params->{file};
				}
				elsif ($_ eq "prefix") {
					$prefix = $params->{prefix};
				}
				elsif ($_ eq "write_sbml") {
					$write_sbml = 1;
				}
			}
		}

		return ("Parameter file must be specified in readFile") if $fname eq '';
		my $err;

		# Read input file
		print "readFile::Reading from file $fname\n";
		if ( !open( FH, $fname ) ) {
			return ("Couldn't read from file $fname: $!");
		}
		$file_dat = [<FH>];
		#print Dumper $file_dat;
		close(FH);

		#	Initialize parameter list
		my $plist = ParamList->new;
		$model->ParamList($plist);

		#	Initialize Compartment list
		my $clist = CompartmentList->new;
		$model->CompartmentList($clist);

		#	Initialize Species list
		my $slist = SpeciesList->new;
		$model->SpeciesList($slist);

		#	Initialize Event list
		my $elist = EventList->new;
		$model->EventList($elist);

		#	read data from file into data hash
		READ:
		while ( $_ = get_line () )
		{

			if ( /^\s*\<(\w+)\>\s*$/)
			{
				my $name = $1;
				$name =~ s/\s*$//;
				$name =~ s/\s+/ /g;

				#	Read block data
				my $block_dat;
				( $block_dat, $err ) = read_block_array($name);
				if ($err) { last READ; }

				if ($name eq "parameters") 
				{
					#	processing multi-line block: 
					#	ParamList

					my $lno;
					my $plist = $model->ParamList;
					for my $line ( @$block_dat ) 
					{
						my ($entry, $lno) = @$line;
						if ($err = $plist->readString($entry)) {
							$err = errgen( $err, $lno );
							last READ;
						}
					}

					#	add built-in var time:
					$err=$plist->addVar_time ();
					if ($err) {
						$err = errgen(@$err);
						last READ;
					}

					if ($err = $plist->checkParams ()) {
						$file = "ParamList.pm";
						$err = errgen (@$err);
						last READ;
					}

					printf "Read %d ${name}.\n", scalar(@$block_dat);
				}

				if ($name eq "compartments")
				{
					#	processing multi-line block:
					#	CompartmentList

					my $lno;
					my $clist = $model->CompartmentList;
					for my $line ( @$block_dat ) 
					{
						my ($entry, $lno) = @$line;
						if ($err = $clist->readString ($entry, $model->ParamList)) {
							$err = errgen( $err, $lno );
							last READ;
						}
					}

					printf "Read %d ${name}.\n", scalar(@$block_dat);
				}

				if ($name eq "seedspecies")
				{
					#	processing multi-line block:
					#	SpeciesList

					my $lno;
					my $slist = $model->SpeciesList;
					for my $line ( @$block_dat ) 
					{
						my ($entry, $lno) = @$line;
						if (
							$err = $slist->readString (
								$entry,
								$model->ParamList, 
								$model->CompartmentList
							)
						) {
							$err = errgen( $err, $lno );
							last READ;
						}
					}
					$slist->print (*STDOUT);
					printf "Read %d ${name}.\n", scalar(@$block_dat);
				}

				if ($name eq "events")
				{
					#	processing multi-line block:
					#	EventList

					my $lno;
					my $elist = $model->EventList;
					for my $line ( @$block_dat ) 
					{
						my ($entry, $lno) = @$line;
						if (
							$err = $elist->readString (
								$entry,
								$model->ParamList, 
								$model->CompartmentList,
								$model->SpeciesList
							)
						) {
							$err = errgen( $err, $lno );
							last READ;
						}
					}

					$elist->print (*STDOUT);
					printf "Read %d ${name}.\n", scalar(@$block_dat);
				}
			}
		}

		#	Read Database
		DB:
		while (not $err)
		{
			#	get Database info from ENV

			my $hostname=$ENV{MYSQL_HOST};
			$hostname="localhost" unless $hostname;
			my $username=$ENV{USER};
			$username="root" unless $username;
			my $password=$ENV{MYSQL_PWD};
			$password="" unless $password;

			my $dsn="DBI:mysql:host=$hostname;database=MoDeL";
			my $dbh=DBI->connect ($dsn,$username,$password,\%conn_attrs)
				or die "Cannot connect to database: $DBI::errstr";

			#	read function.sql
			my $flist = FunctionList->new;
			$model->FunctionList($flist);

			my $sth=$dbh->prepare (
				"SELECT name, parameters, expression FROM function ".
				"WHERE expression IS NOT NULL"
			);
			$sth->execute ();
			my $num_of_functions_read=0;
			while (my @val=$sth->fetchrow_array()) {
				my $name=$val[0];$name =~ s/\s+//g if $name;
				my $params=$val[1];$params =~ s/\s+//g if $params;
				my $expression=$val[2];$expression =~ s/\s+//g if $expression;
				if ($err=$flist->readSarray(
						$name,$params,$expression
					)
				) {
					$err = errgen($err);
					last DB;
				}
				else { $num_of_functions_read++; }
			}
			$flist->print (*STDOUT);
			printf "Read %d functions.\n", $num_of_functions_read;
			$sth->finish ();

			#	read inducer.sql
			my $ilist= InducerList->new;
			$model->InducerList($ilist);

			$sth=$dbh->prepare (
				"SELECT species, rule_table_name_out, rule_table_name_in, ".
				"transport_rate_out, transport_rate_in FROM inducer"
			);
			$sth->execute ();
			my $num_of_transp_rules_read=0;
			while (my @val=$sth->fetchrow_array()) {
				my $species=$val[0];$species =~ s/\s+//g if $species;
				my $table_out=$val[1];$table_out =~ s/\s+//g if $table_out;
				my $table_in=$val[2];$table_in =~ s/\s+//g if $table_in;
				my $rate_out=$val[3];$rate_out =~ s/\s+//g if $rate_out;
				my $rate_in=$val[4];$rate_in =~ s/\s+//g if $rate_in;
				if ($err=$ilist->readSarray(
						$species,$table_out,$table_in,$rate_out,$rate_in
					)
				) { last DB; }
				else { $num_of_transp_rules_read++; }
			}
			printf "Read %d transportation rules.\n", $num_of_transp_rules_read;
			$sth->finish ();

			#	read rule tables
			my $rlist= RuleList->new;
			$model->RuleList($rlist);

			my $sarray=$clist->Array;
			my %tablesRead = ();
			my $num_of_rules_read=0;
			for my $i (0..$#{$sarray}) {
				my $comp= $sarray->[$i];
				my $rtabname=$comp->RuleTableName;
				
				if (exists $tablesRead{$rtabname}) {next;}
				else { $tablesRead{$rtabname}='1'; }
				$sth=$dbh->prepare (
					"SELECT name, reactant_patterns, product_patterns, is_reversible, ".
					"forward_rate_law, reverse_rate_law FROM $rtabname"
				);
				$sth->execute ();
				while (my @val=$sth->fetchrow_array()) {
					my $name=$val[0];$name =~ s/\s+//g if $name;
					my $lhs=$val[1];$lhs =~ s/\s+//g if $lhs;
					my $rhs=$val[2];$rhs =~ s/\s+//g if $rhs;
					my $reversible=$val[3];$reversible =~ s/\s+//g if $reversible;
					my $rate_on=$val[4];$rate_on =~ s/\s+//g if $rate_on;
					my $rate_off=$val[5];$rate_off =~ s/\s+//g if $rate_off;
					if ($err=$rlist->readSarray(
							$name,$rtabname,$lhs,$rhs,$reversible,$rate_on,$rate_off,$flist
						)
					) { last DB; }
					else {
						if (lc($reversible) eq "true") {
							$num_of_rules_read += 2; 
						}
						elsif (lc($reversible) eq "false") {
							$num_of_rules_read += 1;
						}
					}
				}
				$sth->finish ();
			}
			printf "Read %d rules.\n", $num_of_rules_read;

			last DB;
		}

		return $err;
	}

	sub applyRules 
	{
		my $model = shift;	#	bless
		my $params = (@_) ? shift : '';

		#	internal control parameters
		my $no_exec		= 0;
		my $write_sbml	= 0;
		my $fname		= '';

		#	process optional parameters
		if ($params)
		{
			foreach (keys %$params)
			{
				if ($_ eq "no_exec") {
					$no_exec = $params->{no_exec};
				}
				elsif ($_ eq "file") {
					$fname = $params->{file};
				}
				elsif ($_ eq "write_sbml") {
					$write_sbml = 1;
				}
			}
		}

		#	close exactcheck mode 
		$SiteGraph::exactcheck=0;

		if ($no_exec) { return ''; }
		else {
			my ($err,$sbmlDoc,$sbmlModel);
			if ($write_sbml) {
				$sbmlDoc= new LibSBML::SBMLDocument(2,4);
				$sbmlModel=$sbmlDoc->createModel();
			}

			#	Initialize Reaction list
			my $rxnlist = ReactionList->new;
			$model->ReactionList($rxnlist);

			#	apply transportation rules
			if (
				$err = $model->RuleList->applyTransportationRules (
					$model->ParamList,
					$model->CompartmentList,
					$model->SpeciesList,
					$model->ReactionList,
					$model->InducerList
				)
			) 
			{ return $err; }

			#	apply user-defined rules
			if (
				$err = $model->RuleList->applyUserDefinedRules (
					$model->ParamList,
					$model->CompartmentList,
					$model->SpeciesList,
					$model->ReactionList,
					$model->FunctionList,
					*STDOUT
				)
			)
			{ return $err; }
		}
		
		return $model->writeMoDeL($fname,$write_sbml);
	}

	sub writeMoDeL{
		my $model=shift;
		my $fname=shift;
		$fname =~ s/\..*//;
		my $write_sbml=shift;
		my $out = "";

		if ($write_sbml) {
			my $sbmlDoc=new LibSBML::SBMLDocument(2,4);
			my $sbmlModel=$sbmlDoc->createModel();
			$sbmlModel->setId($fname);
			if (my $err=$model->ParamList->writeSBML($sbmlModel)) { 
				return "WRITE PARAMETER: SBMLERRORCODE: $err";
			}
			if (my $err=$model->CompartmentList->writeSBML($sbmlModel)) { 
				return "WRITE COMPARTMENT: SBMLERRORCODE: $err"; 
			}
			if (my $err=$model->SpeciesList->writeSBML($sbmlModel)) { 
				return "WRITE COMPARTMENT: SBMLERRORCODE: $err"; 
			}
			if (my $err=$model->EventList->writeSBML($sbmlModel)) { 
				return "WRITE EVENT: SBMLERRORCODE: $err"; 
			}
			if (my $err=$model->ReactionList->writeSBML($sbmlModel)) { 
				return "WRITE REACTION: SBMLERRORCODE: $err"; 
			}
			my $wd=new LibSBML::SBMLWriter;
			my $sbmlfilename=$fname.".xml";
			my $result=$wd->writeSBML($sbmlDoc,$sbmlfilename);
			if ($result) {
				print "Wrote file \"$sbmlfilename\"\n";
			}
			else {
				print "Failed to write \"$sbmlfilename\"\n";
			}
		}

		#	Header
		my $version = '1.1';
		$out .= "# Created by MoDeL $version\n";
		$out .= $model->ParamList->writeMoDeL();	#	parameters
		$out .= $model->CompartmentList->writeMoDeL();	#	compartments
		$out .= $model->SpeciesList->writeMoDeL($model->CompartmentList);	#	species
		#	$out .= $model->FunctionList->writeMoDeL();	#	functions
		$out .= $model->EventList->writeMoDeL();	#	events
		$out .= $model->RuleList->writeMoDeL($model->SpeciesList);	#	rules
		$out .= $model->ReactionList->writeMoDeL($model->SpeciesList);	#	reactions

		my $outfile;
		$fname.=".net";
		open( $outfile, ">$fname" ) || return ("Couldn't write to $fname: $!\n");
		print $outfile $out;
		close( $outfile );
		print "Wrote network to $fname.\n";

		return '';
	}


	sub get_line
	{
		my $line = "";

		while ( $line = shift(@$file_dat) )
		{
			++$line_number;
			chomp($line);
			$line =~ s/\#.*$//;    # remove comments 
			next unless $line =~ /\S+/;    # skip blank lines
			while ( $line =~ s/\\\s*$// )
			{
				++$line_number;
				my $nline = shift(@$file_dat);
				chomp($nline);
				$nline =~ s/\#.*$//;       # remove comments
				$line .= $nline;
				next unless ( !@$file_dat );
			}
			last;
		}
		return ($line);
	}

	sub read_block_array
	{
		my $name  = shift;
		my @array = ();

		my $got_end = 0;
		while ( $_ = get_line() )
		{
			#	 Look for end of block or errors
			if ( /^\s*\<\/(\w+)\>\s*$/ )
			{
				my $ename = $1;
				$ename =~ s/\s*$//;
				$ename =~ s/\s+/ /g;
				if ( $ename ne $name )
				{
					return ( [], errgen("end $ename does not match begin $name"));
				}
				else
				{
					$got_end = 1;
					#print "end at $line_number\n";
					last;
				}
			}
			elsif ( /^\s*\<(\w+)\>\s*$/ )
			{
				return ( [], errgen("begin block before end of previous block $name") );
			}

			# Add declarations from current line
			push @array, [ ( $_, $line_number ) ];

			#print "$_ $line_number\n";
		}

		if ( !$got_end )
		{
			return ( [], errgen("begin $name has no matching end $name") );
		}

		return ( [@array] );
	}

	sub errgen
	{
		my $err = shift;
		my $lno = (@_) ? shift : $line_number;
		$err =~ s/[*]/\*/g;
		if ($file) {
			my $reterr = sprintf "%s\n  at line $lno of file $file", $err;
			return ($reterr);
		}
		else {
			my $reterr = sprintf "%s", $err;
			return ($reterr);
		}
	}
}


1;
__END__
