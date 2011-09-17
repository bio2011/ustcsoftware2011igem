package BNGModel;

use Class::Struct;
use FindBin;
use lib $FindBin::Bin;
use MoleculeTypesList;
use ParamList;
use Function;
use Compartment;
use CompartmentList;
use SpeciesList;
use RxnRule;
use EnergyPattern;
use Observable;
use PopulationList;
use BNGUtils;

#use strict;

my $NO_EXEC = 0; # Prevents execution of functions to allow file syntax checking
my $HAVE_PS = 0
  ; # Set to 0 for MS Windows systems with no ps command - disables reporting of
    # memory usage at each iteration of network generation


# Structure containing all BioNetGen model data
struct BNGModel =>
{
	Name                => '$',
	Time                => '$',
	Concentrations      => '@',
	MoleculeTypesList   => 'MoleculeTypesList',
	SpeciesList         => 'SpeciesList',
	SeedSpeciesList     => 'SpeciesList',
	RxnList             => 'RxnList',
	RxnRules            => '@',
	ParamList           => 'ParamList',
	Observables         => '@',
	EnergyPatterns      => '@',  # energyBNG: Holds a list of energy patterns  --Justin
	CompartmentList     => 'CompartmentList',
	PopulationTypesList => 'MoleculeTypesList',  # list of population molecule types
	PopulationList      => 'PopulationList',     # list of population species
	SubstanceUnits      => '$',
	UpdateNet           => '$',  # This variable is set to force update of NET file before simulation.
	Version             => '@',  # Indicates set of version requirements- output to BNGL and NET files
	Options             => '%'   # Options used to control behavior of model and associated methods
};


###
###
###


# Read bionetgen data in blocks enclosed by begin param end param
# lines.  Prevents overwriting of variables possible with eval.

# To do:

# 1.  Receive a valid list of parameter names to be read
# 2.  Check syntax of lines- this is currently done when parameter is
#     handled.  Some basic checks could be done here.

# Lines between begin and end commands are put into arrays with the name given by the
# block name


{
	my $file, $line_number, $file_dat;
	my $level = 0, @files, @lnos, @fdats;
	my $MAX_LEVEL = 5;    # Sets maximum level of allowed recursion
	my %bngdata;

	sub readFile
	{
		my $model = shift;
		my $params = (@_) ? shift : '';

		# Internal control parameters
		my $fname            = "";
		my $prefix           = "";
		my $write_xml        = 0;
		my $write_mfile      = 0;
		my $write_sbml       = 0;
		my $generate_network = 0;
		my $allow_actions    = 1;
		my $action_skip_warn = 0;

		# Process optional parameters
		if ($params) {
			for my $param ( keys %$params ) {
				if ( $param eq "no_exec" ) {
					$NO_EXEC = $params->{no_exec};
				}
				elsif ( $param eq "file" ) {
					$fname = $params->{file};
				}
				elsif ( $param eq "prefix" ) {
					$prefix = $params->{prefix};
				}
				elsif ( $param eq "write_xml" ) {
					$write_xml     = 1;
					$allow_actions = 0;
				}
				elsif ( $param eq "write_mfile" ) {
					$write_mfile      = 1;
					$allow_actions    = 0;
					$generate_network = 1;
				}
				elsif ( $param eq "write_sbml" ) {
					$write_sbml       = 1;
					$allow_actions    = 0;
					$generate_network = 1;
				}
				else {
					send_warning("Parameter $param ignored");
				}
			}
		}

		if ( $fname eq '' ) {
			return ("Parameter file must be specified in readFile");
		}

		my $err;

	  READ:
		while (1) {

			# Read BNG model data
			print "readFile::Reading from file $fname\n";
			if ( !open( FH, $fname ) ) {
				return ("Couldn't read from file $fname: $!");
			}
			$file_dat = [<FH>];
			close(FH);

			$file = $fname;
			push @files, $file;
			$level = $#files;
			if ( $level == 0 ) {
				%bngdata     = ();
				$line_number = 0;
			}
			else {
				push @lnos, $line_number;
			}
			push @fdats, $file_dat;

			#print "level=$level lno=$line_number file=$file\n";
			if ( $level > $MAX_LEVEL ) {
				$err = "Recursion level exceeds maximum of $MAX_LEVEL";
				last READ;
			}

			$line_number = 0;
			if ( $prefix ne "" ) {
				print "Setting model name to $prefix\n";
				$model->Name($prefix);
				$model->UpdateNet(1);
			}
			else {

				# Set name of model based on file name
				my $name = $file;

				# Strip suffix
				$name =~ s/[.]([^.]+)$//;
				my $type = $1;
				$model->Name($name);
			}

			# Initialize parameter list
			my $plist = ParamList->new;
			$model->ParamList($plist);

			# Initialize MoleculeTypesList
			my $mtlist = MoleculeTypesList->new( StrictTyping=>0 );
			$model->MoleculeTypesList($mtlist);

			# Initialize PopulationTypesList
			$model->PopulationTypesList( MoleculeTypesList->new() );
			
			# Initialize PopulationList
			$model->PopulationList( PopulationList->new() );

			# Initialize CompartmentList
			my $clist = CompartmentList->new();
			$model->CompartmentList($clist);

			# Initialize SubstanceUnits
			$model->SubstanceUnits("Number");


			# Read data from file into data hash
			my $begin_model = 0;
			my $in_model    = 1;
			while ( $_ = get_line() ) {
				if (/^\s*begin\s+model\s*$/) {
					++$begin_model;
					if ( $begin_model > 1 ) {
						$err = errgen("Only one model definition allowed per file");
						last READ;
					}
					$in_model = 1;
					next;
				}
				elsif (/^\s*end\s+model\s*$/) {
					if ( !$in_model ) {
						$err = errgen("end model encountered without enclosing begin model");
						last READ;
					}
					$in_model = 0;
					next;
				}

				# Process multi-line block
				if (s/^\s*begin\s*//) {
					$name = $_;

					# Remove trailing white space
					$name =~ s/\s*$//;

					# Remove repeated white space
					$name =~ s/\s+/ /g;

					# Read block data
					my $block_dat;
					( $block_dat, $err ) = read_block_array($name);
					if ($err) { last READ; }
					$bngdata{$name} = 1;


					# Read Parameters Block
					if ( ( $name eq "parameters" ) ) {
						my $plast = $#{ $plist->Array };
						if ( !$in_model ) {
							$err = errgen(
								"$name cannot be defined outside of a model");
							last READ;
						}

						# Model parameters
						my $lno;
						my $plist = $model->ParamList;
						for my $line ( @{$block_dat} ) {
							( my $entry, $lno ) = @{$line};
							if ( $err = $plist->readString($entry) ) {
								$err = errgen( $err, $lno );
								last READ;
							}
						}
						if ( $err = $plist->check() ) {
							$err = errgen( $err, $lno );
							last READ;
						}
						if ( $err = $plist->sort() ) {
							$err = errgen( $err, $lno );
							last READ;
						}
						printf "Read %d ${name}.\n",
						  $#{ $plist->Array } - $plast;
					}
					
					# Read Functions Block
					elsif ( ( $name eq "functions" ) )
					{
						my $nread = 0;
						if ( !$in_model ) {
							$err = errgen(
								"$name cannot be defined outside of a model");
							last READ;
						}

						# Model functions
						my $lno;
						my $plist = $model->ParamList;
						for my $line ( @{$block_dat} ) {
							( my $entry, $lno ) = @{$line};
							my $fun = Function->new();
							if ( $err = $fun->readString( $entry, $model ) ) {
								$err = errgen( $err, $lno );
								last READ;
							}
							++$nread;
						}
						
					    # check paramlist for unresolved dependency, etc
					    #   GIVE warning here, don't terminate!
						if ( $err = $plist->check() )
						{
							$err = errgen( $err, $lno );
							print "Warning: $err\n"
							     ."  (if parameter is defined in a subsequent block,\n"
							     ."  then this warning can be safely ignored.)\n";
						}							
						
						printf "Read %d ${name}.\n", $nread;
					}
					
					# Read Molecule Types block
					elsif ( $name =~ /^molecule[_ ]types$/ )
					{
						if ( !$in_model ) {
							$err = errgen(
								"$name cannot be defined outside of a model");
							last READ;
						}

						# read MoleculeTypes
						$model->MoleculeTypesList->StrictTyping(1);  # enable strict typing
						foreach my $line ( @{$block_dat} )
						{
							my ( $entry, $lno ) = @{$line};
							if ( $err = $model->MoleculeTypesList->readString($entry) )
							{
								$err = errgen( $err, $lno );
								last READ;
							}
						}
						printf "Read %d molecule types.\n",
						    scalar keys %{$model->MoleculeTypesList->MolTypes};
					}


					# Read Population Types block
					elsif ( $name =~ /^[Pp]opulation[_ ][Tt]ypes$/ )
					{
						unless ($in_model)
						{
							$err = errgen("$name cannot be defined outside of a model");
							last READ;
						}

						# MoleculeTypes
						foreach my $line ( @{$block_dat} )
						{
							my ( $entry, $lno ) = @{$line};
							if ( $err = $model->PopulationTypesList->readString($entry) )
							{
								$err = errgen( $err, $lno );
								last READ;
							}
						}
						printf "Read %d population types.\n", scalar( keys %{$model->PopulationTypesList->MolTypes} );
					}


					# Read Population Maps block
					elsif ( $name =~ /^[Pp]opulation[_ ][Mm]aps$/ )
					{
						unless ($in_model)
						{
							$err = errgen("$name cannot be defined outside of a model");
							last READ;
						}

						# MoleculeTypes
						foreach my $line ( @{$block_dat} )
						{
							my ( $entry, $lno ) = @{$line};
							if ( $err = $model->PopulationList->readString($entry,$model) )
							{
								$err = errgen( $err, $lno );
								last READ;
							}
						}
						printf "Read %d population maps.\n", scalar @{$model->PopulationList->List};
					}
					
					
					# Read Compartments Block
					elsif ( $name eq "compartments" )
					{
                        # changes to implement:  if compartment block is defined, then we should require
                        # explicit declaration of species compartments.  if not defined, then
                        # we can skip a lot of extra processing in RxnRule
                        # --justin 23feb2009

						for my $line ( @{$block_dat} ) {
							my ( $entry, $lno ) = @{$line};
							if ( $err =
								$clist->readString( $entry, $model->ParamList )
							  )
							{
								$err = errgen( $err, $lno );
								last READ;
							}
						}
						if ( $err = $clist->validate() ) {
							$err = errgen( $err, $lno );
							last READ;
						}

						#print $clist->toString($plist);
						printf "Read %d compartments.\n",
						    scalar( @{ $clist->Array } );
					}
					
					
					# Read Species/Seed Species Block
					elsif (    ( $name eq "species" )
						    or ( $name =~ /^seed[ _]species$/ ) )
					{
						if ( !$in_model ) {
							$err = errgen("$name cannot be defined outside of a model");
							last READ;
						}

						# Species
						my $slist = SpeciesList->new;

				        # Allow new types?
						my $AllowNewTypes = $model->MoleculeTypesList->StrictTyping ? 0 : 1;

						#print "AllowNewTypes=$AllowNewTypes\n";
						foreach my $line ( @{$block_dat} )
						{
							my ( $entry, $lno ) = @{$line};
							if ( $err = $slist->readString( $entry, $model->ParamList,
									                        $model->CompartmentList,
									                        $model->MoleculeTypesList,
									                        $AllowNewTypes  		   ) )
							{
								$err = errgen( $err, $lno );
								last READ;
							}							
						}
						printf "Read %d species.\n",
						  scalar( @{ $slist->Array } );
						$model->SpeciesList($slist);
					}
					
					# Read Reaction Rules Block
					elsif ( $name =~ /^reaction[_ ]rules$/ )
					{
						if ( !$in_model ) {
							$err = errgen("$name cannot be defined outside of a model");
							last READ;
						}
						my $nerr = 0;

						# Reaction rules
						my @rrules = ();
						foreach my $line ( @{$block_dat} )
                        {
							my ( $entry, $lno ) = @{$line};

							# Error handled internally in RxnRule
							my $rrs;
							( $rrs, $err ) = RxnRule::newRxnRule( $entry, $model );
							if ( $err ne "" ) {

								#last READ;
								$err = errgen( $err, $lno );
								printf STDERR "ERROR: $err\n";
								++$nerr;
							}
							else {
								push @rrules, $rrs;

				                #printf "n_rules=%d n_new=%d\n", scalar(@rrules),scalar(@$rrs);
								if ( !$rrs->[0]->Name ) {
									$rrs->[0]->Name( "Rule" . scalar @rrules );
								}
								if ( $#$rrs == 1 ) {
									if ( !$rrs->[1]->Name ) {
										$rrs->[1]->Name( "Rule" . scalar @rrules . "r" );
									}
								}
							}
						}
						if ($nerr) {
							$err = "Reaction rule list could not be read because of errors";
							last READ;
						}
						$model->RxnRules( [@rrules] );
						printf "Read %d reaction rule(s).\n",
						  scalar( @{ $model->RxnRules } );
					}
					
					# Read Reactions Block
					elsif ( $name eq "reactions" )
					{
						if ( !$in_model ) {
							$err = errgen( "$name cannot be defined outside of a model" );
							last READ;
						}

						# Reactions (when reading NET file)
						my $rlist = RxnList->new;
						for my $line ( @{$block_dat} ) {
							my ( $entry, $lno ) = @{$line};
							if ( $err = $rlist->readString( $entry,
								                            $model->SpeciesList,
                                                            $model->ParamList    ) )
							{
								$err = errgen( $err, $lno );
								last READ;
							}
						}
						printf "Read %d reaction(s).\n", scalar( @{$block_dat} );
						$model->RxnList($rlist);
					}
					
					# Read Groups Block
					elsif ( $name eq "groups" ) {
						if ( !$in_model ) {
							$err = errgen(
								"$name cannot be defined outside of a model");
							last READ;
						}

						# Groups (when reading NET file)
						# Must come after Observables
						if ( !$model->Observables ) {
							$err = errgen(
								"Observables must be defined before Groups",
								$lno );
							last READ;
						}
						my $iobs   = 0;
						my $maxobs = $#{ $model->Observables };
						for my $line ( @{$block_dat} ) {
							my ( $entry, $lno ) = @{$line};
							my @tokens = split( ' ', $entry );

							# Skip first entry if it's an index
							if ( $tokens[0] =~ /^\d+$/ ) { shift(@tokens) }

							if ( $iobs > $maxobs ) {
								$err = errgen( "More groups than observables",
									$lno );
								last READ;
							}
							my $obs = $model->Observables->[$iobs];

							# Check that Observable and Group names match
							if ( $tokens[0] ne $obs->Name ) {
								$err = errgen("Group named $tokens[0] is not compatible with any observable", $lno );
								last READ;
							}
							shift(@tokens);

							my @array = split( ',', $tokens[0] );
							*weights = $obs->Weights;

							# Zero the weights
							@weights = (0) x @weights;
							my $w, $ind;
							for $elt (@array) {
								if ( $elt =~ s/^([^*]*)\*// ) {
									$w = $1;
								}
								else {
									$w = 1;
								}
								if ( $elt =~ /\D+/ ) {
									$err =
									  errgen( "Non-integer group entry: $elt",
										$lno );
									last READ;
								}
								$weights[$elt] += $w;
							}
							++$iobs;
						}
						printf "Read %d group(s).\n", scalar( @{$block_dat} );
					}
					
					# Read Observables Block
					elsif ( $name eq 'observables' )
					{
						if ( !$in_model ) {
							$err = errgen(
								"$name cannot be defined outside of a model");
							last READ;
						}

                        # create model observables array, if not defined
                        #unless ( defined $model->Observables )
                        #{   $model->Observables = [];   }

				        # Allow new types?
						my $AllowNewTypes = $model->MoleculeTypesList->StrictTyping ? 0 : 1;

                        # parse each line in the observables block
                        my $lno;
						foreach my $line ( @{$block_dat} )
						{
							( my $entry, $lno ) = @{$line};
							my $obs = Observable->new();
							if ( $err = $obs->readString($entry, $model, $AllowNewTypes) )
							{
								$err = errgen( $err, $lno );
								last READ;
							}
							push @{$model->Observables}, $obs;
						}	

					    # check paramlist for unresolved dependency, etc
					    #   GIVE warning here, don't terminate!				    
						if ( $err = $model->ParamList->check() )
						{
							$err = errgen( $err, $lno );
							print "Warning: $err\n"
							     ."  (if parameter is defined in a subsequent block,\n"
							     ."  then this warning can be safely ignored.)\n";
						}					
											
						printf "Read %d observable(s).\n", scalar( @{$model->Observables} );
					}
					
					# Read Energy Patterns Block
					elsif ( $name =~ /^energy[_ ]patterns$/ )
					{
						if ( !$in_model ) {
							$err = errgen("$name cannot be defined outside of a model");
							last READ;
						}

                        # check if this is an energyBNG model!
                        unless ( $model->Options->{energyBNG}  )
                        {
                            $err = errgen( "$name cannot be defined unless the energyBNG option is true" );
                            last READ;
                        }
                    
                        # read each energy pattern
						my $elist = [];
						foreach my $line ( @{$block_dat} )
						{
							my ( $entry, $lno ) = @{$line};
							my $epatt = EnergyPattern->new();
							if ( $err = $epatt->readString( $entry, $model ) )
							{
								$err = errgen( $err, $lno );
								last READ;
							}
							push @$elist, $epatt;
						}
						$model->EnergyPatterns( $elist );
						printf "Read %d energy patterns(s).\n", scalar( @{$model->EnergyPatterns} );  
					
					}					
					
					# Read Actions Block
					elsif ( $name eq "actions" )
					{
						if ( !$allow_actions ) {
							if ( !$action_skip_warn ) {
								send_warning("Skipping actions");
								$action_skip_warn = 1;
							}
							next;
						}
						for my $line ( @{$block_dat} ) {
							my ( $entry, $lno ) = @{$line};

							# Remove (and ignore) leading index from line
							$entry =~ s/^\d+\s+//;

							my $command;
							if ( $entry =~ /^\s*([A-Za-z0-9_]+)\s*\(/ ) {
								$command = $1;
							}
							else {
								$err = "Line $entry does not appear to contain a command";
								$err = errgen( $err, $lno );
							}

	                        # Perform self-consistency checks before operations are performed on model
							if ( $err = $plist->check() ) {
								$err = errgen($err);
								last READ;
							}

							# call to methods associated with $model
							my $t_off = cpu_time(0);    # Set cpu clock offset

							$err = eval '$model->' . $entry;
							if ($err) { $err = errgen($err); last READ; }
							if ($@)   { $err = errgen($@);   last READ; }
							my $tused = cpu_time(0) - $t_off;
							if ( $tused > 0.0 ) {
								printf "CPU TIME: %s %.1f s.\n", $1, $tused;
							}
						}
					}
					
					# Try to read anyother Block type (probably an error)
					else {

						# Unrecognized block name
						$err = errgen("Could not process block type $name");
						send_warning($err);
						$err = "";

						#last READ;
					}
					
				}
				elsif ( s/^\s*(Parameter|Param)\s+//i )
				{
					if ( !$in_model ) {
						$err = errgen(
							"Parameter cannot be defined outside of a model");
						last READ;
					}
					my $plist = $model->ParamList;

					#printf "Reading $1 $_\n";
					if ( $err = $plist->readString($_) ) {
						$err = errgen($err);
						last READ;
					}
				}
				elsif ( /^\s*([A-Za-z][^(]*)/ )
				{
					if ( !$allow_actions ) {
						if ( !$action_skip_warn ) {
							send_warning("Skipping actions");
							$action_skip_warn = 1;
						}
						next;
					}

	                # Perform self-consistency checks before operations are performed on model
					if ( $err = $plist->check() ) {
						$err = errgen($err);
						last READ;
					}

					# call to methods associated with $model
					my $t_off = cpu_time(0);    # Set cpu clock offset
					                            #print "command: $_\n";
					$err = eval '$model->' . $_;
					if ($err) { $err = errgen($err); last READ; }
					if ($@)   { $err = errgen($@);   last READ; }
					my $tused = cpu_time(0) - $t_off;
					if ( $tused > 0.0 ) {
						printf "CPU TIME: %s %.1f s.\n", $1, $tused;
					}
				}
				else
				{
					if ( !$allow_actions ) {
						if ( !$action_skip_warn ) {
							send_warning("Skipping actions");
							$action_skip_warn = 1;
						}
						next;
					}

					# General Perl code
					eval $_;
					if ($@) { $err = errgen($@); last READ; }
				}
			}
			last READ;
		}    # END READ

		if ($write_xml) {
			$model->writeXML();
		}
		if ($generate_network) {
			$model->generate_network( { overwrite => 1 } );
		}
		if ($write_mfile) {
			$model->writeMfile();
		}
		if ($write_sbml) {
			$model->writeSBML();
		}

	  EXIT:
		pop @files;
		pop @fdats;
		if ($level)
		{
			$file        = $files[$#files];
			$file_dat    = $fdats[$#fdats];
			$line_number = pop @lnos;
			--$level;

			#print "returning to level $level file $file line $line_number\n";
		}
		print "Finished processing file $fname\n" unless $err;
		
        # return with any error messages	
		return ($err);
	}

    ###
    ###
    ###

	sub read_block_array
	{
		my $name  = shift;
		my @array = ();

		my $got_end = 0;
		while ( $_ = get_line() )
		{
			# Look for end of block or errors
			if ( s/^\s*end\s+// )
			{
				my $ename = $_;
				$ename =~ s/\s*$//;
				$ename =~ s/\s+/ /g;
				if ( $ename ne $name )
				{
					return ( [], errgen("end $ename does not match begin $name") );
				}
				else
				{
					$got_end = 1;
					#print "end at $line_number\n";
					last;
				}
			}
			elsif ( /^\s*begin\s*/ )
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

    ###
    ###
    ###

	sub errgen
	{
		my $err = shift;
		my $lno = (@_) ? shift : $line_number;
		$err =~ s/[*]/\*/g;
		my $reterr = sprintf "%s\n  at line $lno of file $file", $err;
		return ($reterr);
	}

    ###
    ###
    ###

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
}



###
###
###



# Syntax
#   setOption(name,value,name,value,...) Set option value pairs
# First call will cause initialization with default values.

sub setOption
{
	my $model = shift;
	my $err   = "";

	# Process options
	while (@_) {
		my $arg = shift @_;
		@_ || return ("No value specified for option $arg");
		my $val = shift @_;

		if ( $arg eq "SpeciesLabel" ) {

			# SpeciesLabel method can only be changed prior to reading species.
			# Otherwise, inconsistent behavior could arise from changing the
			# labeling method.
			if ( $model->SeedSpeciesList ) {
				return ( "SpeciesLabel attribute can only be changed prior to reading of species.");
			}
			( $err = SpeciesGraph::setSpeciesLabel($val) )  and  return ($err);
			$model->Options->{$arg} = $val;
		}
		elsif ( $arg eq "energyBNG" )
		{   # enable energy mode
		    if ( scalar @{$model->RxnRules} )
            {   return ( "energyBNG mode can only be changed prior to reading ReactionRules.");  }
		    $model->Options->{$arg} = $val;
		}
		else {
			return "Unrecognized option $arg in setOption";
		}
	}

	return ('');
}



###
###
###



sub substanceUnits
{
	my $model = shift;
	my $units = shift;

	my $ucommand = "";
	if ( $units =~ /^conc/i ) {
		$ucommand = "Concentration";
	}
	elsif ( $units =~ /^num/i ) {
		$ucommand = "Number";
	}
	else {
		return (
"Invalid argument to subtanceUnits $units: valid arguments are Number and Concentration"
		);
	}

	print "SubstanceUnits set to $ucommand.\n";
	$model->SubstanceUnits($ucommand);
	return ("");
}



###
###
###



sub setVolume
{
	my $model            = shift;
	my $compartment_name = shift;
	my $value            = shift;

	my $err = $model->CompartmentList->setVolume( $compartment_name, $value );
	return ($err);
}



###
###
###



sub writeSimpleBNGL
{
	my $model = shift;
	my $out   = "";

	return ("") if $NO_EXEC;

	# Species
	$out .=
	  $model->SpeciesList->writeBNGL( $model->Concentrations,
		$model->ParamList );

	# Reactions
	$out .= $model->RxnList->writeBNGL( "", $model->ParamList );

}



###
###
###



# write NET format to file
sub writeBNGL
{
	my $model  = shift;
	my $params = (@_) ? shift(@_) : '';
	my $out    = '';
	use strict;
    
	my %vars = (
		'prefix'       => $model->Name,
		'TextReaction' => 0,
		'NETfile'      => 0
	);
	my %vars_pass = ();

	foreach my $key ( keys %$params )
	{
		if ( defined( $vars{$key} ) )
		{
			$vars{$key} = $params->{$key};
			if ( defined $vars_pass{$key} )
			{
				$vars_pass{$key} = $params->{$key};
			}
		}
		elsif ( defined $vars_pass{$key} )
		{
			$vars_pass{$key} = $params->{$key};
		}
		else
		{
			die "Unrecognized parameter $key in writeBNGL";
		}
	}

	return ('') if $NO_EXEC;


    # !!! Begin writing file !!!


	# Header
	my $version = BNGversion();
	$out .= "# Created by BioNetGen $version\n";

	# Version requirements
	foreach my $vstring ( @{$model->Version} )
	{   $out .= "version(\"$vstring\");\n";   }

	# Options
	while ( my ($opt,$val) = each %{$model->Options} )
	{   $out .= "setOption(\"$opt\",\"$val\");\n";   }

	# Units
	$out .= sprintf "substanceUnits(\"%s\");\n", $model->SubstanceUnits;


    # Begin Model
    $out .= "\nbegin model\n"  unless ( $vars{NETfile} );


	# Parameters
	$out .= $model->ParamList->writeBNGL( $vars{NETfile} );


	# Compartments
	if ( defined $model->CompartmentList  and  @{$model->CompartmentList->Array} )
	{   $out .= $model->CompartmentList->toString( $model->ParamList );   }


	# MoleculeTypes
	$out .= $model->MoleculeTypesList->writeBNGL( {NETfile=>$vars{NETfile}} );


	# Observables	
	if ( @{$model->Observables} )
	{
	    # find max length of observable name
	    my $max_length = 0;
		foreach my $obs ( @{$model->Observables} )
		{
		    $max_length = ( length $obs->Name > $max_length ) ? length $obs->Name : $max_length;
		}
	    
	
		$out .= "begin observables\n";
#		$out .= "\n"  unless ( $vars{NETfile} );
		my $io = 1;
		foreach my $obs ( @{$model->Observables} )
		{
		    if ( $vars{NETfile} )
		    {
			    $out .= sprintf "%5d %s\n", $io, $obs->toString();
			}
			else
			{
			    $out .= sprintf "  %s\n", $obs->toString($max_length);
			}
			++$io;
		}
#		$out .= "\n"  unless ( $vars{NETfile} );		
		$out .= "end observables\n";
	}


	# Energy Patterns
	if ( @{$model->EnergyPatterns} )
	{
		$out .= "begin energy patterns\n";
		$out .= "\n"  unless ( $vars{NETfile} );		
		my $io = 1;
		foreach my $epatt ( @{ $model->EnergyPatterns } )
		{
		    if ( $vars{NETfile} )
		    {
			    $out .=  sprintf "%5d %s\n", $io, $epatt->toString($model->ParamList);
			}
			else
			{
			    $out .=  sprintf "  %s\n", $epatt->toString($model->ParamList);
			}
			++$io;
		}
		$out .= "\n"  unless ( $vars{NETfile} );		
		$out .= "end energy patterns\n";
	}


	# Functions
	$out .= $model->ParamList->writeFunctions( {NETfile=>$vars{NETfile}} );
	
	
	# Species
  	$out .= $model->SpeciesList->writeBNGL( $model->Concentrations, $model->ParamList, 0, {NETfile=>$vars{NETfile}} );


	# Reaction rules
	$out .= "begin reaction rules\n";
    $out .= "\n"  unless ( $vars{NETfile} );	
	foreach my $rset ( @{$model->RxnRules} )
	{
		my $rreverse = ( @$rset > 1 ) ? $rset->[1] : undef;

        # write BNGL rule
		$out .= sprintf "    %s\n", $rset->[0]->toString($rreverse);
		
		# write actions if this is a NETfile
		if ( $vars{NETfile} )
	    {
		    $out .= $rset->[0]->listActions();
		    if ( defined $rreverse )
		    {
			    $out .= "    # Reverse\n";
			    $out .= $rset->[1]->listActions();
		    }    
		}
        $out .= "\n"  unless ( $vars{NETfile} );
	}	
	$out .= "end reaction rules\n";


    # only write network blocks if this is a NETfile!
	if ( $vars{NETfile} )
	{
	    # Reactions	
	    if ( $vars{TextReaction} )
	    {
		    print "Writing full species names in reactions.\n";
	    }
	
	    $out .= $model->RxnList->writeBNGL( $vars{TextReaction}, $model->ParamList );


	    # Groups
	    if ( @{$model->Observables} )
	    {
		    $out .= "begin groups\n";
		    my $io = 1;
		    foreach my $obs ( @{$model->Observables} )
		    {
			    $out .= sprintf "%5d %s\n", $io, $obs->toGroupString( $model->SpeciesList );
			    ++$io;
		    }
		    $out .= "end groups\n";
	    }
	}


    # End Model
    $out .= "end model\n"  unless ( $vars{NETfile} );

	return $out;
}


###
###
###


# Write model to a MATLAB M-file
sub writeMfile
{	
	my $model = shift;
	my $params = (@_) ? shift : undef;

    # a place to hold errors
    my $err;

    # nothing to do if NO_EXEC is true
	return ('') if $NO_EXEC;

    # nothing to do if there are no reactions
	unless ( $model->RxnList )
	{
	    return ( "writeMfile() has nothing to do: no reactions in current model.\n"
	            ."  Did you remember to call generate_network() before attempting to\n"
	            ."  write network output?");
	}

    # get reference to parameter list
	my $plist = $model->ParamList;
	
	# get model name
	my $model_name = $model->Name;

    # Build output file name
	# ..strip path from model file
	$model_name =~ s/^.*\///;
	# ..use prefix if defined, otherwise use model name
	my $prefix = ( defined $params->{prefix} ) ? $params->{prefix} : $model->Name;
	# ..add suffix, if any
	my $suffix = ( defined $params->{suffix} ) ? $params->{suffix} : '';
	if ( $suffix ne '' )
	{   $prefix .= "_${suffix}";   }
	# get all caps version
	my $prefix_caps = uc $prefix;
	
	
	# define m-script files name
	my $mscript = "${prefix}.m";


    # configure options (see Matlab documentation of functions ODESET and ODE15S)
    my $odeset_abstol = 1e-8;
    if ( exists $params->{'atol'} )
    {   $odeset_abstol = $params->{'atol'};  }
    
    my $odeset_reltol = 1e-8;
    if ( exists $params->{'rtol'} )
    {   $odeset_reltol = $params->{'rtol'};  } 

    my $odeset_stats = 'off';
    if ( exists $params->{'stats'} )
    {   $odeset_stats = $params->{'stats'};  } 

    my $odeset_bdf = 'off';
    if ( exists $params->{'bdf'} )
    {   $odeset_bdf = $params->{'bdf'};  } 

    my $odeset_maxorder = 5;
    if ( exists $params->{'maxOrder'} )
    {   $odeset_maxorder = $params->{'maxOrder'};  } 

    # time options for mscript
    my $t_start = 0;
    if ( exists $params->{'t_start'} )
    {   $t_start = $params->{'t_start'};  }  

    my $t_end = 10;
    if ( exists $params->{'t_end'} )
    {   $t_end = $params->{'t_end'};  } 

    my $n_steps = 20;
    if ( exists $params->{'n_steps'} )
    {   $n_steps = $params->{'n_steps'};  } 

    # configure time step dependent options
    my $odeset_maxstep = undef;
    if ( exists $params->{'maxStep'} )
    {   $odeset_maxstep = $params->{'maxStep'};  }     
    
    # construct ODESET function call
    my $mscript_call_odeset;
    if ( defined $odeset_maxstep )
    {
        $mscript_call_odeset = "opts = odeset( 'RelTol',   $odeset_reltol,   ...\n"
                              ."               'AbsTol',   $odeset_abstol,   ...\n"
                              ."               'Stats',    '$odeset_stats',  ...\n"
                              ."               'BDF',      '$odeset_bdf',    ...\n"
                              ."               'MaxOrder', $odeset_maxorder, ...\n"
                              ."               'MaxStep',  $odeset_maxstep    );\n";
    }
    else
    {
        $mscript_call_odeset = "opts = odeset( 'RelTol',   $odeset_reltol,   ...\n"
                              ."               'AbsTol',   $odeset_abstol,   ...\n"
                              ."               'Stats',    '$odeset_stats',  ...\n"
                              ."               'BDF',      '$odeset_bdf',    ...\n"
                              ."               'MaxOrder', $odeset_maxorder   );\n";    
    }

    # Index parameters associated with Constants, ConstantExpressions and Observables
    ($err) = $plist->indexParams();
    if ($err) { return ($err) };

    # and retrieve a string of expression definitions
    my $n_parameters = $plist->countType( 'Constant' );
    my $n_expressions = $plist->countType( 'ConstantExpression' ) + $n_parameters;
    ($calc_expressions_string, $err) = $plist->getMatlabExpressionDefs();    
    if ($err) { return ($err) };

    # get list of parameter names and defintions for matlab
	my $mscript_param_names;
	my $mscript_param_values;
	($mscript_param_names, $mscript_param_values, $err) = $plist->getMatlabConstantNames();
    if ($err) { return ($err) };

    # get number of species
    my $n_species = scalar @{$model->SpeciesList->Array};
     
	# retrieve a string of observable definitions
    my $n_observables = scalar @{$model->Observables};
    my $calc_observables_string;
    ($calc_observables_string, $err) = $plist->getMatlabObservableDefs();
    if ($err) { return ($err) };    
    
    # get list of observable names for matlab
	my $mscript_observable_names;
	($mscript_observable_names, $err) = $plist->getMatlabObservableNames();
    if ($err) { return ($err) };
    
    # Construct user-defined functions
    my $user_fcn_declarations = '';
    my $user_fcn_definitions  = '';
	foreach my $param ( @{ $model->ParamList->Array } )
	{
		if ( $param->Type eq 'Function' )
		{
		    # get reference to the actual Function
		    my $fcn = $param->Ref;
		    
		    # don't write function if it depends on a local observable evaluation (this is useless
		    #   since CVode can't do local evaluations)
		    next if ( $fcn->checkLocalDependency($plist) );
		    		    
		    # get function definition			    
		    my $fcn_defn = $fcn->toMatlabString( $plist, {fcn_mode=>'define', indent=>''} );

		    # add definition to the user_fcn_definitions string
		    $user_fcn_definitions .= $fcn_defn . "\n";
        }
	}
	
    # index reactions
    ($err) = $model->RxnList->updateIndex( $plist );
    if ($err) { return ($err) };

	# retrieve a string of reaction rate definitions
	my $n_reactions = scalar @{$model->RxnList->Array};
    my $calc_ratelaws_string;
    ($calc_ratelaws_string, $err) = $model->RxnList->getMatlabRateDefs( $plist );
    if ($err) { return ($err) };
    

    # get stoichiometry matrix (sparse encoding in a hashmap)
	my $stoich_hash = {};
	($err) = $model->RxnList->calcStoichMatrix( $stoich_hash );

	# retrieve a string of species deriv definitions
    my $calc_derivs_string;
    ($calc_derivs_string, $err) = $model->SpeciesList->toMatlabString( $model->RxnList, $stoich_hash, $plist );
    if ($err) { return ($err) };   	


    # get list of species names and initial value expressions for matlab
	my $mscript_species_names;
	my $mscript_species_init;
	($mscript_species_names, $mscript_species_init, $err) = $model->SpeciesList->getMatlabSpeciesNames( $plist );
    if ($err) { return ($err) }; 


                           
    # format title for matlab figure
    my $figure_title;
    ($figure_title = $prefix) =~ s/_/\\_/g;


    # generate code snippets for plotting observables or species
    my $mscript_plot_labels;
    my $mscript_make_plot;
    if ( @{$model->Observables} )
    {
        $mscript_plot_labels = "    observable_labels = { $mscript_observable_names };\n";
        
        $mscript_make_plot = "    plot(timepoints,observables_out);      \n"
                            ."    title('$figure_title');                \n"
                            ."    axis([$t_start timepoints(end) 0 inf]);\n"
                            ."    legend(observable_labels);             \n";
    
    }
    else
    {
        $mscript_plot_labels = "    species_labels = { $mscript_species_names };\n";
    
        $mscript_make_plot = "    plot(timepoints,species_out);          \n"
                            ."    title('$figure_title');                \n"
                            ."    axis([$t_start timepoints(end) 0 inf]);\n"
                            ."    legend(species_labels);                \n";
    }
    


    # open Mexfile and begin printing...
	open( Mscript, ">$mscript" ) || die "Couldn't open $mscript: $!\n";
    print Mscript <<"EOF";
function [err, timepoints, species_out, observables_out ] = ${prefix}( timepoints, species_init, parameters, suppress_plot )
%${prefix_caps} : Integrate reaction network and plot observables.
%   Integrates the reaction network corresponding to the BioNetGen model
%   ${model_name} and then (optionally) plots the observable trajectories,
%   or species trajectories if no observables are defined. Trajectories are
%   generated using either default or user-defined parameters and initial
%   species values. Integration is performed by the MATLAB stiff solver
%   'ode15s'. ${prefix_caps} returns an error value, a vector of timepoints,
%   species trajectories, and observable trajectories.
%   
%   [err, timepoints, species_out, observables_out]
%        = $prefix( timepoints, species_init, parameters, suppress_plot )
%
%   INPUTS:
%   -------
%   species_init    : row vector of $n_species initial species populations.
%   timepoints      : column vector of time points returned by integrator.
%   parameters      : row vector of $n_parameters model parameters.
%   suppress_plot   : 0 if a plot is desired (default), 1 if plot is suppressed.
%
%   Note: to specify default value for an input argument, pass the empty array.
%
%   OUTPUTS:
%   --------
%   err             : 0 if the integrator exits without error, non-zero otherwise.
%   timepoints      : a row vector of timepoints returned by the integrator.
%   species_out     : array of species population trajectories
%                        (columns correspond to species, rows correspond to time).
%   observables_out : array of observable trajectories
%                        (columns correspond to observables, rows correspond to time).
%
%   QUESTIONS about the BNG Mfile generator?  Email justinshogg\@gmail.com



%% Process input arguments

% define any missing arguments
if ( nargin < 1 )
    timepoints = [];
end

if ( nargin < 2 )
    species_init = [];
end

if ( nargin < 3 )
    parameters = [];
end

if ( nargin < 4 )
    suppress_plot = 0;
end


% initialize outputs (to avoid error msgs if script terminates early
err = 0;
species_out     = [];
observables_out = [];


% setup default parameters, if necessary
if ( isempty(parameters) )
   parameters = [ $mscript_param_values ];
end
% check that parameters has proper dimensions
if (  size(parameters,1) ~= 1  |  size(parameters,2) ~= $n_parameters  )
    fprintf( 1, 'Error: size of parameter argument is invalid! Correct size = [1 $n_parameters].\\n' );
    err = 1;
    return;
end

% setup default initial values, if necessary
if ( isempty(species_init) )
   species_init = initialize_species( parameters );
end
% check that species_init has proper dimensions
if (  size(species_init,1) ~= 1  |  size(species_init,2) ~= $n_species  )
    fprintf( 1, 'Error: size of species_init argument is invalid! Correct size = [1 $n_species].\\n' );
    err = 1;
    return;
end

% setup default timepoints, if necessary
if ( isempty(timepoints) )
   timepoints = linspace($t_start,$t_end,$n_steps+1)';
end
% check that timepoints has proper dimensions
if (  size(timepoints,1) < 2  |  size(timepoints,2) ~= 1  )
    fprintf( 1, 'Error: size of timepoints argument is invalid! Correct size = [t 1], t>1.\\n' );
    err = 1;
    return;
end

% setup default suppress_plot, if necessary
if ( isempty(suppress_plot) )
   suppress_plot = 0;
end
% check that suppress_plot has proper dimensions
if ( size(suppress_plot,1) ~= 1  |  size(suppress_plot,2) ~= 1 )
    fprintf( 1, 'Error: suppress_plots argument should be a scalar!\\n' );
    err = 1;
    return;
end

% define parameter labels (this is for the user's reference!)
param_labels = { $mscript_param_names };



%% Integrate Network Model
 
% calculate expressions
[expressions] = calc_expressions( parameters );

% set ODE integrator options
$mscript_call_odeset

% define derivative function
rhs_fcn = @(t,y)( calc_species_deriv( t, y, expressions ) );

% simulate model system (stiff integrator)
try 
    [timepoints, species_out] = ode15s( rhs_fcn, timepoints, species_init', opts );
catch
    err = 1;
    fprintf( 1, 'Error: some problem encounteredwhile integrating ODE network!\\n' );
    return;
end

% calculate observables
observables_out = zeros( length(timepoints), $n_observables );
for t = 1 : length(timepoints)
    observables_out(t,:) = calc_observables( species_out(t,:), expressions );
end


%% Plot Output, if desired

if ( ~suppress_plot )
    
    % define plot labels
$mscript_plot_labels
    % construct figure
$mscript_make_plot
end


%~~~~~~~~~~~~~~~~~~~~~%
% END of main script! %
%~~~~~~~~~~~~~~~~~~~~~%


% initialize species function
function [species_init] = initialize_species( params )

    species_init = zeros(1,$n_species);
$mscript_species_init
end


% user-defined functions
$user_fcn_definitions


% Calculate expressions
function [ expressions ] = calc_expressions ( parameters )

    expressions = zeros(1,$n_expressions);
$calc_expressions_string   
end



% Calculate observables
function [ observables ] = calc_observables ( species, expressions )

    observables = zeros(1,$n_observables);
$calc_observables_string
end


% Calculate ratelaws
function [ ratelaws ] = calc_ratelaws ( species, expressions, observables )

    ratelaws = zeros(1,$n_observables);
$calc_ratelaws_string
end

% Calculate species derivates
function [ Dspecies ] = calc_species_deriv ( time, species, expressions )
    
    % initialize derivative vector
    Dspecies = zeros($n_species,1);
    
    % update observables
    [ observables ] = calc_observables( species, expressions );
    
    % update ratelaws
    [ ratelaws ] = calc_ratelaws( species, expressions, observables );
                        
    % calculate derivatives
$calc_derivs_string
end


end
EOF

	close(Mscript);
	print "Wrote M-file script $mscript.\n";
	return ();	
}



###
###
###



sub writeMexfile
{
	my $model = shift;
	my $params = (@_) ? shift : undef;

    # a place to hold errors
    my $err;

    # nothing to do if NO_EXEC is true
	return ('') if $NO_EXEC;

    # nothing to do if there are no reactions
	unless ( $model->RxnList )
	{
	    return ( "writeMexfile() has nothing to do: no reactions in current model.\n"
	            ."  Did you remember to call generate_network() before attempting to\n"
	            ."  write network output?");
	}

    # get reference to parameter list
	my $plist = $model->ParamList;
	
	# get model name
	my $model_name = $model->Name;

	# Strip prefixed path
	$model_name =~ s/^.*\///;
	my $prefix =
	  ( defined( $params->{prefix} ) ) ? $params->{prefix} : $model->Name;
	my $suffix = ( defined( $params->{suffix} ) ) ? $params->{suffix} : "";
	if ( $suffix ne "" )
	{   $prefix .= "_${suffix}";   }
	
	# define mexfile name
	my $mexfile = "${prefix}_cvode.c";
	# define m-script files name
	my $mscript = "${prefix}.m";


    # configure options
    my $cvode_abstol = 1e-6;
    if ( exists $params->{'atol'} )
    {   $cvode_abstol = $params->{'atol'};  }
    
    my $cvode_reltol = 1e-8;
    if ( exists $params->{'rtol'} )
    {   $cvode_reltol = $params->{'rtol'};  }    

    my $cvode_max_num_steps = 2000;
    if ( exists $params->{'max_num_steps'} )
    {   $cvode_max_num_steps = $params->{'max_num_steps'};  }  

    my $cvode_max_err_test_fails = 7;
    if ( exists $params->{'max_err_test_fails'} )
    {   $cvode_max_err_test_fails = $params->{'max_err_test_fails'};  }  

    my $cvode_max_conv_fails = 10;
    if ( exists $params->{'max_conv_fails'} )
    {   $cvode_max_conv_fails = $params->{'max_conv_fails'};  }  

    my $cvode_max_step = '0.0';
    if ( exists $params->{'max_step'} )
    {   $cvode_max_step = $params->{'max_step'};  }

    # Stiff = CV_BDF,CV_NEWTON (Default); Non-stiff = CV_ADAMS,CV_FUNCTIONAL
    my $cvode_linear_multistep = 'CV_BDF';
    my $cvode_nonlinear_solver = 'CV_NEWTON';
    if ( exists $params->{'stiff'} )
    {   
        # if stiff is FALSE, then change to CV_ADAMS and CV_FUNCTIONAL
        unless ( $params->{'stiff'} )
        {
            $cvode_linear_multistep = 'CV_ADAMS';    
            $cvode_nonlinear_solver = 'CV_FUNCTIONAL';
        }
    }

    if ( exists $params->{'nonlinear_solver'} )
    {   $cvode_nonlinear_solver = $params->{'nonlinear_solver'};  }  

    # set sparse option (only permitted with CV_NEWTON)
    my $cvode_linear_solver;
    if ( ($cvode_nonlinear_solver eq 'CV_NEWTON')  and  ($params->{'sparse'}) )
    {
        $cvode_linear_solver =     "flag = CVSpgmr(cvode_mem, PREC_NONE, 0);\n"
                              ."    if (check_flag(&flag, \"CVSpgmr\", 1))";
    }
    else
    {
        $cvode_linear_solver =     "flag = CVDense(cvode_mem, __N_SPECIES__);\n"
                              ."    if (check_flag(&flag, \"CVDense\", 1))";
    }

    # time options for mscript
    my $t_start = 0;
    if ( exists $params->{'t_start'} )
    {   $t_start = $params->{'t_start'};  }  

    my $t_end = 10;
    if ( exists $params->{'t_end'} )
    {   $t_end = $params->{'t_end'};  } 

    my $n_steps = 20;
    if ( exists $params->{'n_steps'} )
    {   $n_steps = $params->{'n_steps'};  } 

    # code snippet for cleaning up dynamic memory before exiting CVODE-MEX
    my $cvode_cleanup_memory =     "{                                  \n"
                              ."        N_VDestroy_Serial(expressions);\n"
                              ."        N_VDestroy_Serial(observables);\n"
                              ."        N_VDestroy_Serial(ratelaws);   \n"
                              ."        N_VDestroy_Serial(species);    \n"
                              ."        CVodeFree(&cvode_mem);         \n"
                              ."        return_status[0] = 1;          \n"
                              ."        return;                        \n"
                              ."    }                                  ";

    # Index parameters associated with Constants, ConstantExpressions and Observables
    ($err) = $plist->indexParams();
    if ($err) { return ($err) };

    # and retrieve a string of expression definitions
    my $n_parameters = $plist->countType( 'Constant' );
    my $n_expressions = $plist->countType( 'ConstantExpression' ) + $n_parameters;
    ($calc_expressions_string, $err) = $plist->getCVodeExpressionDefs();    
    if ($err) { return ($err) };

    # get list of parameter names and defintions for matlab
	my $mscript_param_names;
	my $mscript_param_values;
	($mscript_param_names, $mscript_param_values, $err) = $plist->getMatlabConstantNames();
    if ($err) { return ($err) };


    # generate CVode references for species
    # (Do this now, because we need species CVodeRefs for Observable definitions and Rxn Rates)
    my $n_species = scalar @{$model->SpeciesList->Array};
    
     
	# retrieve a string of observable definitions
    my $n_observables = scalar @{$model->Observables};
    my $calc_observables_string;
    ($calc_observables_string, $err) = $plist->getCVodeObservableDefs();
    if ($err) { return ($err) };    
    
    # get list of observable names for matlab
	my $mscript_observable_names;
	($mscript_observable_names, $err) = $plist->getMatlabObservableNames();
    if ($err) { return ($err) };
    
    # Construct user-defined functions
    my $user_fcn_declarations = '';
    my $user_fcn_definitions = '';
	foreach my $param ( @{ $model->ParamList->Array } )
	{
		if ( $param->Type eq 'Function' )
		{
		    # get reference to the actual Function
		    my $fcn = $param->Ref;
		    
		    # don't write function if it depends on a local observable evaluation (this is useless
		    #   since CVode can't do local evaluations)
		    next if ( $fcn->checkLocalDependency($plist) );
		    		    
		    # get function declaration, add it to the user_fcn_declarations string
		    $user_fcn_declarations .= $fcn->toCVodeString( $plist, {fcn_mode=>'declare',indent=>''} );
		    
		    # get function definition			    
		    my $fcn_defn = $fcn->toCVodeString( $plist, {fcn_mode=>'define', indent=>''} );

		    # add definition to the user_fcn_definitions string
		    $user_fcn_definitions .= $fcn_defn . "\n";
        }
	}
	
    # index reactions
    ($err) = $model->RxnList->updateIndex( $plist );
    if ($err) { return ($err) };

	# retrieve a string of reaction rate definitions
	my $n_reactions = scalar @{$model->RxnList->Array};
    my $calc_ratelaws_string;
    ($calc_ratelaws_string, $err) = $model->RxnList->getCVodeRateDefs( $plist );
    if ($err) { return ($err) };
    

    # get stoichiometry matrix (sparse encoding in a hashmap)
	my $stoich_hash = {};
	($err) = $model->RxnList->calcStoichMatrix( $stoich_hash );

	# retrieve a string of species deriv definitions
    my $calc_derivs_string;
    ($calc_derivs_string, $err) = $model->SpeciesList->toCVodeString( $model->RxnList, $stoich_hash, $plist );
    if ($err) { return ($err) };   	



    # get list of species names and initial value expressions for matlab
	my $mscript_species_names;
	my $mscript_species_init;
	($mscript_species_names, $mscript_species_init, $err) = $model->SpeciesList->getMatlabSpeciesNames( $plist );
    if ($err) { return ($err) }; 


                           
    # format title for matlab figure
    my $figure_title;
    ($figure_title = $prefix) =~ s/_/\\_/g;


    # generate code snippets for plotting observables or species
    my $mscript_plot_labels;
    my $mscript_make_plot;
    if ( @{$model->Observables} )
    {
        $mscript_plot_labels = "    observable_labels = { $mscript_observable_names };\n";
        
        $mscript_make_plot = "    plot(timepoints,observables_out);      \n"
                            ."    title('$figure_title');                \n"
                            ."    axis([$t_start timepoints(end) 0 inf]);\n"
                            ."    legend(observable_labels);             \n";
    
    }
    else
    {
        $mscript_plot_labels = "    species_labels = { $mscript_species_names };\n";
    
        $mscript_make_plot = "    plot(timepoints,species_out);          \n"
                            ."    title('$figure_title');                \n"
                            ."    axis([$t_start timepoints(end) 0 inf]);\n"
                            ."    legend(species_labels);                \n";
    }


    # open Mexfile and begin printing...
	open( Mexfile, ">$mexfile" ) || die "Couldn't open $mexfile: $!\n";
    print Mexfile <<"EOF";
/*   
**   $mexfile
**	 
**   Cvode-Mex implementation of BioNetGen model $prefix.
**
**   Code Adapted from templates provided by Mathworks and Sundials.
**   QUESTIONS about the code generator?  Email justinshogg\@gmail.com
**
**   Requires the CVODE libraries:  sundials_cvode and sundials_nvecserial.
**   https://computation.llnl.gov/casc/sundials/main.html
**
**-----------------------------------------------------------------------------
**
**   COMPILE in MATLAB:
**   mex -L<path_to_cvode_libraries> -I<path_to_cvode_includes>  ...
**          -lsundials_nvecserial -lsundials_cvode -lm $mexfile
**
**   note1: if cvode is in your library path, you can omit path specifications.
**
**   note2: if linker complains about lib stdc++, try removing "-lstdc++"
**     from the mex configuration file "gccopts.sh".  This should be in the
**     matlab bin folder.
** 
**-----------------------------------------------------------------------------
**
**   EXECUTE in MATLAB:
**   [error_status, species_out, observables_out]
**        = ${prefix}_cvode( timepoints, species_init, parameters )
**
**   timepoints      : column vector of time points returned by integrator.
**   parameters      : row vector of $n_parameters parameters.
**   species_init    : row vector of $n_species initial species populations.
**
**   error_status    : 0 if the integrator exits without error, non-zero otherwise.
**   species_out     : species population trajectories
**                        (columns correspond to states, rows correspond to time).
**   observables_out : observable trajectories
**                        (columns correspond to observables, rows correspond to time).
*/

/* Library headers */
#include "mex.h"
#include "matrix.h"
#include <stdlib.h>
#include <math.h>
#include <cvode/cvode.h>             /* prototypes for CVODE  */
#include <nvector/nvector_serial.h>  /* serial N_Vector       */
#include <cvode/cvode_dense.h>       /* prototype for CVDense */
#include <cvode/cvode_spgmr.h>       /* prototype for CVSpgmr */

/* Problem Dimensions */
#define __N_PARAMETERS__   $n_parameters
#define __N_EXPRESSIONS__  $n_expressions
#define __N_OBSERVABLES__  $n_observables
#define __N_RATELAWS__     $n_reactions
#define __N_SPECIES__      $n_species

/* core function declarations */
void  mexFunction ( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
int   check_flag  ( void *flagvalue, char *funcname, int opt );
void  calc_expressions ( N_Vector expressions, double * parameters );
void  calc_observables ( N_Vector observables, N_Vector species, N_Vector expressions );
void  calc_ratelaws    ( N_Vector ratelaws,  N_Vector species, N_Vector expressions, N_Vector observables );
int   calc_species_deriv ( realtype time, N_Vector species, N_Vector Dspecies, void * f_data );

/* user-defined function declarations */
$user_fcn_declarations

/* user-defined function definitions  */
$user_fcn_definitions

/* Calculate expressions */
void
calc_expressions ( N_Vector expressions, double * parameters )
{
$calc_expressions_string   
}

/* Calculate observables */
void
calc_observables ( N_Vector observables, N_Vector species, N_Vector expressions )
{
$calc_observables_string
}

/* Calculate ratelaws */
void
calc_ratelaws ( N_Vector ratelaws, N_Vector species, N_Vector expressions, N_Vector observables )
{  
$calc_ratelaws_string
}


/* Calculate species derivates */
int
calc_species_deriv ( realtype time, N_Vector species, N_Vector Dspecies, void * f_data )
{
    int         return_val;
    N_Vector *  temp_data;
    
    N_Vector    expressions;
    N_Vector    observables;
    N_Vector    ratelaws;

    /* cast temp_data */
    temp_data = (N_Vector*)f_data;
     
    /* sget ratelaws Vector */
    expressions = temp_data[0];
    observables = temp_data[1];
    ratelaws    = temp_data[2];
       
    /* calculate observables */
    calc_observables( observables, species, expressions );
    
    /* calculate ratelaws */
    calc_ratelaws( ratelaws, species, expressions, observables );
                        
    /* calculate derivates */
$calc_derivs_string

    return(0);
}


/*
**   ========
**   main MEX
**   ========
*/
void mexFunction( int nlhs, mxArray * plhs[], int nrhs, const mxArray * prhs[] )
{
    /* variables */
    double *  return_status;
    double *  species_out;
    double *  observables_out;    
    double *  parameters;
    double *  species_init;
    double *  timepoints; 
    size_t    n_timepoints;
    size_t    i;
    size_t    j;

    /* intermediate data vectors */
    N_Vector  expressions;
    N_Vector  observables;
    N_Vector  ratelaws;

    /* array to hold pointers to data vectors */
    N_Vector  temp_data[3];
    
    /* CVODE specific variables */
    realtype  reltol;
    realtype  abstol;
    realtype  time;
    N_Vector  species;
    void *    cvode_mem;
    int       flag;

    /* check number of input/output arguments */
    if (nlhs != 3)
    {  mexErrMsgTxt("syntax: [err_flag, species_out, obsv_out] = network_mex( timepoints, species_init, params )");  }
    if (nrhs != 3)
    {  mexErrMsgTxt("syntax: [err_flag, species_out, obsv_out] = network_mex( timepoints, species_init, params )");  }


    /* make sure timepoints has correct dimensions */
    if ( (mxGetM(prhs[0]) < 2)  ||  (mxGetN(prhs[0]) != 1) )
    {  mexErrMsgTxt("TIMEPOINTS must be a column vector with 2 or more elements.");  }

    /* make sure species_init has correct dimensions */
    if ( (mxGetM(prhs[1]) != 1)  ||  (mxGetN(prhs[1]) != __N_SPECIES__) )
    {  mexErrMsgTxt("SPECIES_INIT must be a row vector with $n_species elements.");  } 

    /* make sure params has correct dimensions */
    if ( (mxGetM(prhs[2]) != 1)  ||  (mxGetN(prhs[2]) != __N_PARAMETERS__) )
    {  mexErrMsgTxt("PARAMS must be a column vector with $n_parameters elements.");  }

    /* get pointers to input arrays */
    timepoints   = mxGetPr(prhs[0]);
    species_init = mxGetPr(prhs[1]);
    parameters   = mxGetPr(prhs[2]);

    /* get number of timepoints */
    n_timepoints = mxGetM(prhs[0]);

    /* Create an mxArray for output trajectories */
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL );
    plhs[1] = mxCreateDoubleMatrix(n_timepoints, __N_SPECIES__, mxREAL);
    plhs[2] = mxCreateDoubleMatrix(n_timepoints, __N_OBSERVABLES__, mxREAL);

    /* get pointers to output arrays */
    return_status   = mxGetPr(plhs[0]);
    species_out     = mxGetPr(plhs[1]);
    observables_out = mxGetPr(plhs[2]);    
   
    /* initialize intermediate data vectors */
    expressions  = NULL;
    expressions = N_VNew_Serial(__N_EXPRESSIONS__);
    if (check_flag((void *)expressions, "N_VNew_Serial", 0))
    {
        return_status[0] = 1;
        return;
    }

    observables = NULL;
    observables = N_VNew_Serial(__N_OBSERVABLES__);
    if (check_flag((void *)observables, "N_VNew_Serial", 0))
    {
        N_VDestroy_Serial(expressions);
        return_status[0] = 1;
        return;
    }

    ratelaws    = NULL; 
    ratelaws = N_VNew_Serial(__N_RATELAWS__);
    if (check_flag((void *)ratelaws, "N_VNew_Serial", 0))
    {   
        N_VDestroy_Serial(expressions);
        N_VDestroy_Serial(observables);        
        return_status[0] = 1;
        return;
    }
    
    /* set up pointers to intermediate data vectors */
    temp_data[0] = expressions;
    temp_data[1] = observables;
    temp_data[2] = ratelaws;

    /* calculate expressions (expressions are constant, so only do this once!) */
    calc_expressions( expressions, parameters );

        
    /* SOLVE model equations! */
    species   = NULL;
    cvode_mem = NULL;

    /* Set the scalar relative tolerance */
    reltol = $cvode_reltol;
    abstol = $cvode_abstol;

    /* Create serial vector for Species */
    species = N_VNew_Serial(__N_SPECIES__);
    if (check_flag((void *)species, "N_VNew_Serial", 0))
    {  
        N_VDestroy_Serial(expressions);
        N_VDestroy_Serial(observables);
        N_VDestroy_Serial(ratelaws);
        return_status[0] = 1;
        return;
    }
    for ( i = 0; i < __N_SPECIES__; i++ )
    {   NV_Ith_S(species,i) = species_init[i];   }
    
    /* write initial species populations into species_out */
    for ( i = 0; i < __N_SPECIES__; i++ )
    {   species_out[i*n_timepoints] = species_init[i];   }
    
    /* write initial observables populations into species_out */ 
    calc_observables( observables, species, expressions );  
    for ( i = 0; i < __N_OBSERVABLES__; i++ )
    {   observables_out[i*n_timepoints] = NV_Ith_S(observables,i);   }

    /*   Call CVodeCreate to create the solver memory:    
     *   CV_ADAMS or CV_BDF is the linear multistep method
     *   CV_FUNCTIONAL or CV_NEWTON is the nonlinear solver iteration
     *   A pointer to the integrator problem memory is returned and stored in cvode_mem.
     */
    cvode_mem = CVodeCreate($cvode_linear_multistep, $cvode_nonlinear_solver);
    if (check_flag((void *)cvode_mem, "CVodeCreate", 0))
    $cvode_cleanup_memory



    /*   Call CVodeInit to initialize the integrator memory:     
     *   cvode_mem is the pointer to the integrator memory returned by CVodeCreate
     *   rhs_func  is the user's right hand side function in y'=f(t,y)
     *   T0        is the initial time
     *   y         is the initial dependent variable vector
     */
    flag = CVodeInit(cvode_mem, calc_species_deriv, timepoints[0], species);
    if (check_flag(&flag, "CVodeInit", 1))
    $cvode_cleanup_memory
   
    /* Set scalar relative and absolute tolerances */
    flag = CVodeSStolerances(cvode_mem, reltol, abstol);
    if (check_flag(&flag, "CVodeSStolerances", 1))
    $cvode_cleanup_memory   
   
    /* pass params to rhs_func */
    flag = CVodeSetUserData(cvode_mem, &temp_data);
    if (check_flag(&flag, "CVodeSetFdata", 1))
    $cvode_cleanup_memory
    
    /* select linear solver */
    $cvode_linear_solver
    $cvode_cleanup_memory
    
    flag = CVodeSetMaxNumSteps(cvode_mem, $cvode_max_num_steps);
    if (check_flag(&flag, "CVodeSetMaxNumSteps", 1))
    $cvode_cleanup_memory

    flag = CVodeSetMaxErrTestFails(cvode_mem, $cvode_max_err_test_fails);
    if (check_flag(&flag, "CVodeSetMaxErrTestFails", 1))
    $cvode_cleanup_memory

    flag = CVodeSetMaxConvFails(cvode_mem, $cvode_max_conv_fails);
    if (check_flag(&flag, "CVodeSetMaxConvFails", 1))
    $cvode_cleanup_memory

    flag = CVodeSetMaxStep(cvode_mem, $cvode_max_step);
    if (check_flag(&flag, "CVodeSetMaxStep", 1))
    $cvode_cleanup_memory

    /* integrate to each timepoint */
    for ( i=1;  i < n_timepoints;  i++ )
    {
        flag = CVode(cvode_mem, timepoints[i], species, &time, CV_NORMAL);
        if (check_flag(&flag, "CVode", 1))
        {
            N_VDestroy_Serial(expressions);
            N_VDestroy_Serial(observables);           
            N_VDestroy_Serial(ratelaws);
            N_VDestroy_Serial(species);
            CVodeFree(&cvode_mem);
            return_status[0] = 1; 
            return;
        }

        /* copy species output from nvector to matlab array */
        for ( j = 0; j < __N_SPECIES__; j++ )
        {   species_out[j*n_timepoints + i] = NV_Ith_S(species,j);   }
        
        /* copy observables output from nvector to matlab array */
        calc_observables( observables, species, expressions );         
        for ( j = 0; j < __N_OBSERVABLES__; j++ )
        {   observables_out[j*n_timepoints + i] = NV_Ith_S(observables,j);   }      
    }
 
    /* Free vectors */
    N_VDestroy_Serial(expressions);
    N_VDestroy_Serial(observables);  
    N_VDestroy_Serial(ratelaws);        
    N_VDestroy_Serial(species);

    /* Free integrator memory */
    CVodeFree(&cvode_mem);

    return;
}


/*  Check function return value...
 *   opt == 0 means SUNDIALS function allocates memory so check if
 *            returned NULL pointer
 *   opt == 1 means SUNDIALS function returns a flag so check if
 *            flag >= 0
 *   opt == 2 means function allocates memory so check if returned
 *            NULL pointer 
 */
int check_flag(void *flagvalue, char *funcname, int opt)
{
    int *errflag;

    /* Check if SUNDIALS function returned NULL pointer - no memory allocated */
    if (opt == 0 && flagvalue == NULL)
    {
        mexPrintf( "\\nSUNDIALS_ERROR: %s() failed - returned NULL pointer\\n", funcname );    
        return(1);
    }

    /* Check if flag < 0 */
    else if (opt == 1)
    {
        errflag = (int *) flagvalue;
        if (*errflag < 0)
        {
            mexPrintf( "\\nSUNDIALS_ERROR: %s() failed with flag = %d\\n", funcname, *errflag );
            return(1);
        }
    }

    /* Check if function returned NULL pointer - no memory allocated */
    else if (opt == 2 && flagvalue == NULL)
    {
        mexPrintf( "\\nMEMORY_ERROR: %s() failed - returned NULL pointer\\n", funcname );
        return(1);
    }

    return(0);
}
EOF
	close(Mexfile);



    # open Mexfile and begin printing...
	open( Mscript, ">$mscript" ) || die "Couldn't open $mscript: $!\n";
    print Mscript <<"EOF";
function [err, timepoints, species_out, observables_out ] = ${prefix}( timepoints, species_init, parameters, suppress_plot )
%${prefix_caps} : Integrate reaction network and plot observables.
%   Integrates the reaction network corresponding to the BioNetGen model
%   ${model_name} and then (optionally) plots the observable trajectories,
%   or species trajectories if no observables are defined. Trajectories are
%   generated using either default or user-defined parameters and initial
%   species values. Integration is performed by the CVode library interfaced
%   to MATLAB via the MEX interface. Before running this script, the model
%   source in file ${mexfile} must be compiled (see that file for details).
%   ${prefix_caps} returns an error value, a vector of timepoints,
%   species trajectories, and observable trajectories.
%   
%   [err, timepoints, species_out, observables_out]
%        = $prefix( timepoints, species_init, parameters, suppress_plot )
%
%   INPUTS:
%   -------
%   timepoints      : column vector of time points returned by integrator.
%   species_init    : row vector of $n_species initial species populations.
%   parameters      : row vector of $n_parameters model parameters.
%   suppress_plot   : 0 if a plot is desired (default), 1 if plot is suppressed.
%
%   Note: to specify default value for an input argument, pass the empty array.
%
%   OUTPUTS:
%   --------
%   err             : 0 if the integrator exits without error, non-zero otherwise.
%   timepoints      : a row vector of timepoints returned by the integrator.
%   species_out     : array of species population trajectories
%                        (columns correspond to species, rows correspond to time).
%   observables_out : array of observable trajectories
%                        (columns correspond to observables, rows correspond to time).
%
%   QUESTIONS about the BNG Mfile generator?  Email justinshogg\@gmail.com



%% Process input arguments

% define any missing arguments
if ( nargin < 1 )
    timepoints = [];
end

if ( nargin < 2 )
    species_init = [];
end

if ( nargin < 3 )
    parameters = [];
end

if ( nargin < 4 )
    suppress_plot = 0;
end


% initialize outputs (to avoid error msgs if script terminates early
err = 0;
species_out     = [];
observables_out = [];


% setup default parameters, if necessary
if ( isempty(parameters) )
   parameters = [ $mscript_param_values ];
end
% check that parameters has proper dimensions
if (  size(parameters,1) ~= 1  |  size(parameters,2) ~= $n_parameters  )
    fprintf( 1, 'Error: size of parameter argument is invalid! Correct size = [1 $n_parameters].\\n' );
    err = 1;
    return;
end

% setup default initial values, if necessary
if ( isempty(species_init) )
   species_init = initialize_species( parameters );
end
% check that species_init has proper dimensions
if (  size(species_init,1) ~= 1  |  size(species_init,2) ~= $n_species  )
    fprintf( 1, 'Error: size of species_init argument is invalid! Correct size = [1 $n_species].\\n' );
    err = 1;
    return;
end

% setup default timepoints, if necessary
if ( isempty(timepoints) )
   timepoints = linspace($t_start,$t_end,$n_steps+1)';
end
% check that timepoints has proper dimensions
if (  size(timepoints,1) < 2  |  size(timepoints,2) ~= 1  )
    fprintf( 1, 'Error: size of timepoints argument is invalid! Correct size = [t 1], t>1.\\n' );
    err = 1;
    return;
end

% setup default suppress_plot, if necessary
if ( isempty(suppress_plot) )
   suppress_plot = 0;
end
% check that suppress_plot has proper dimensions
if ( size(suppress_plot,1) ~= 1  |  size(suppress_plot,2) ~= 1 )
    fprintf( 1, 'Error: suppress_plots argument should be a scalar!\\n' );
    err = 1;
    return;
end

% define parameter labels (this is for the user's reference!)
param_labels = { $mscript_param_names };



%% Integrate Network Model
try 
    % run simulation
    [err, species_out, observables_out] = ${prefix}_cvode( timepoints, species_init, parameters );

catch
    err = 1;
    fprintf( 1, 'Error: some problem encountered while integrating ODE network!\\n' );
    return;
end



%% Plot Output, if desired

if ( ~suppress_plot )
    
    % define plot labels
$mscript_plot_labels
    % construct figure
$mscript_make_plot
end



%~~~~~~~~~~~~~~~~~~~~~%
% END of main script! %
%~~~~~~~~~~~~~~~~~~~~~%



% initialize species function
function [species_init] = initialize_species( params )

    species_init = zeros(1,$n_species);
$mscript_species_init
end


end
EOF
	close Mscript;
	print "Wrote Mexfile $mexfile and M-file script $mscript.\n";
	return ();
}



###
###
###



sub quit
{
    # quick exit. no cleanup. no error messages
    # This is useful when the user desires to exit before
    #  performing a set of actions and it would be tedious to 
    #  comment out all those actions.
    exit;
}



###
###
###
sub writeMfile_QueryNames
{
	my $model = shift;
	my $plist = $model->ParamList;
	my $slist = $model->SpeciesList;
	my $err;
	
	my $mscript_param_names;
	my $mscript_param_values;
	($mscript_param_names, $mscript_param_values, $err) = $plist->getMatlabConstantNames();
    if ($err) { return ($err) };
    
    my $mscript_observable_names;
	($mscript_observable_names, $err) = $plist->getMatlabObservableNames();
    if ($err) { return ($err) };
    
    my $mscript_species_names;
	($mscript_species_names, $err) = $slist->getMatlabSpeciesNamesOnly();
    if ($err) { return ($err) };
    
    my $q_mscript = 'QueryNames.m';
    
    open(Q_Mscript,">$q_mscript");
    print Q_Mscript <<"EOF";
function [ param_labels, param_defaults, obs_labels, species_labels] = QueryNames( inputlist )
% % Loads all the parameter labels, parameter defaults, observable labels and species labels in the model
% % If generate_network() was executed, then the nanmes of all species are passed
% % If generate_network() was not executed, then the names of the seed speceis are passed

	param_labels = { $mscript_param_names };
	param_defaults = [ $mscript_param_values ];
	obs_labels = { $mscript_observable_names };
	species_labels = { $mscript_species_names };
end

EOF
	close Q_Mscript;
	print "Wrote M-file script $q_mscript.\n";
	return ();
    
}

sub writeMfile_ParametersObservables
{
	# John Sekar created this subroutine
	my $model = shift;
	my $params = (@_) ? shift: undef;
	
	my $err;
	
	#Get ref to parameter list
	my $plist = $model->ParamList;
	
	#Names of M-file
	my $par_mscript = 'ParameterList.m';
	my $obs_mscript = 'ObservableList.m';
	
	#Getting param names and observable names
	my $mscript_param_names;
	my $mscript_param_values;
	($mscript_param_names, $mscript_param_values, $err) = $plist->getMatlabConstantNames();
    if ($err) { return ($err) };
    
    my $mscript_observable_names;
	($mscript_observable_names, $err) = $plist->getMatlabObservableNames();
    if ($err) { return ($err) };
    
    #Writing parameter list script
	open( Par_Mscript, ">$par_mscript" ) || die "Couldn't open $par_mscript: $!\n";
    print Par_Mscript <<"EOF";
function [outputlist,defaultvals ] = ParameterList( inputlist )
% Used to manipulate and access parameter names
% If inputlist is empty, the entire list of labels is given as output
% If inputlist is a vector of indices, output is a cell array of parameter
% names corresponding to those indices, returns default error if not found
% If inputlist is a cell array of names, output is a vector of indices
% corresponding to those parameter names, returns zero if not found
	param_labels = { $mscript_param_names };
	param_defaults = [ $mscript_param_values ];
	
    param_num = max(size(param_labels));
	
    if nargin < 1
        outputlist = param_labels;
        defaultvals = param_defaults;
        return;
    end

    defaultvals = zeros(size(inputlist));

    if(isnumeric(inputlist))
        outputlist = cell(size(inputlist));
        
        	
        for i=1:1:max(size(inputlist))
            outputlist{i} = param_labels{inputlist(i)}; 
            defaultvals(i) = param_defaults(inputlist(i));
        end
    end
    
   if(iscellstr(inputlist))
       outputlist = zeros(size(inputlist));
       for i=1:1:max(size(inputlist))
           compare = strcmp(inputlist{i},param_labels);
           if(sum(compare)>0)
               outputlist(i) = find(compare,1);
               if(outputlist(i))
                   defaultvals(i) = param_defaults(outputlist(i));
               end
           end
           
       end
	end
end
EOF
	close Par_Mscript;
	print "Wrote M-file script $par_mscript.\n";
	
	#Writing observable list script
	open( Obs_Mscript, ">$obs_mscript" ) || die "Couldn't open $obs_mscript: $!\n";
    print Obs_Mscript <<"EOF";
function [outputlist ] = ObservableList( inputlist )
% Used to manipulate and access observable names
% If inputlist is empty, the entire list of labels is given as output
% If inputlist is a vector of indices, output is a cell array of observable
% names corresponding to those indices, returns default error if not found
% If inputlist is a cell array of names, output is a vector of indices
% corresponding to those observable names, returns zero if not found
	obs_labels = { $mscript_observable_names };
    obs_num = max(size(obs_labels));

    if nargin < 1
        outputlist = obs_labels;
        return;
    end
    
    if(isnumeric(inputlist))
        outputlist = cell(size(inputlist));
        for i=1:1:max(size(inputlist))
            outputlist{i} = obs_labels{inputlist(i)};
        end
    end
    
   if(iscellstr(inputlist))
       outputlist = zeros(size(inputlist));
       for i=1:1:max(size(inputlist))
           compare = strcmp(inputlist{i},obs_labels);
           if(sum(compare)>0)
               outputlist(i) = find(compare,1);
           else
               outputlist(i) = 0;
           end
       end 
end
EOF
	close Obs_Mscript;
	print "Wrote M-file script $obs_mscript.\n";
	return ();
}



sub writeLatex
{
	my $model = shift;
	my $params = (@_) ? shift(@_) : "";

	return ("") if $NO_EXEC;

	if ( !$model->RxnList ) {
		return ("No reactions in current model.");
	}

	my $plist = $model->ParamList;

	my $model_name = $model->Name;

	# Strip prefixed path
	$model_name =~ s/^.*\///;
	my $prefix =
	  ( defined( $params->{prefix} ) ) ? $params->{prefix} : $model->Name;
	my $suffix = ( defined( $params->{suffix} ) ) ? $params->{suffix} : "";
	if ( $suffix ne "" ) {
		$prefix .= "_${suffix}";
	}

	my $file = "${prefix}.tex";

	open( Lfile, ">$file" ) || die "Couldn't open $file: $!\n";
	my $version = BNGversion();
	print Lfile "% Latex formatted differential equations for model $prefix created by BioNetGen $version\n";

	# Document Header
	print Lfile <<'EOF';
\documentclass{article}
\begin{document}
EOF

	# Dimensions
	my $Nspecies   = scalar( @{ $model->SpeciesList->Array } );
	my $Nreactions = scalar( @{ $model->RxnList->Array } );
	print Lfile "\\section{Model Summary}\n";
	printf Lfile "The model has %d species and %d reactions.\n", $Nspecies,
	  $Nreactions;
	print Lfile "\n";

	# Stoichiometry matrix
	#my @St=();
	my %S      = ();
	my @fluxes = ();
	my $irxn   = 1;
	for my $rxn ( @{ $model->RxnList->Array } ) {

		# Each reactant contributes a -1
		for my $r ( @{ $rxn->Reactants } ) {
			--$S{ $r->Index }{$irxn};
		}

		# Each product contributes a +1
		for my $p ( @{ $rxn->Products } ) {
			++$S{ $p->Index }{$irxn};
		}
		my ( $flux, $err ) =
		  $rxn->RateLaw->toLatexString( $rxn->Reactants, $rxn->StatFactor,
			$model->ParamList );
		$err && return ($err);
		push @fluxes, $flux;
		++$irxn;
	}

	print Lfile "\\section{Differential Equations}\n";
	print Lfile "\\begin{eqnarray*}\n";
	for my $ispec ( sort { $a <=> $b } keys %S ) {

		#    print Lfile "\\begin{eqnarray*}\n";
		printf Lfile "\\dot{x_{%d}}&=& ", $ispec;
		my $nrxn = 1;
		for my $irxn ( sort { $a <=> $b } keys %{ $S{$ispec} } ) {
			my $s = $S{$ispec}{$irxn};
			if ( $s == 1 ) {
				$mod = "+";
			}
			elsif ( $s == -1 ) {
				$mod = "-";
			}
			elsif ( $s > 0 ) {
				$mod = "+$s";
			}
			else {
				$mod = "+($s)";
			}
			if ( ( $nrxn % 5 ) == 0 ) { print Lfile "\\\\ &&"; }
			if ($s) {
				printf Lfile " %s %s", $mod, $fluxes[ $irxn - 1 ];
				++$nrxn;
			}
		}

		#    print Lfile "\n\\end{eqnarray*}\n";
		if ( $nrxn == 1 ) {
			print Lfile "0";
		}
		print Lfile "\n\\\\\n";
	}
	print Lfile "\\end{eqnarray*}\n";
	print Lfile "\n";

	# Document Footer
	print Lfile <<'EOF';
\end{document}
EOF
	close(Lfile);
	print "Wrote Latex equations to  $file.\n";
	return ();
}



###
###
###



sub toSBMLfile
{
	my $model = shift;
	my $params = (@_) ? shift(@_) : "";

	return ("") if $NO_EXEC;

	send_warning("Use writeSBML instead of toSBMLfile");
	return ( $model->writeSBML($params) );
}



###
###
###



sub writeSSC
{
	my $model = shift;
	my $params = (@_) ? shift(@_) : "";
	return ("") if $NO_EXEC;

	my $model_name = $model->Name;

	# Strip prefixed path
	$model_name =~ s/^.*\///;
	my $prefix =
	  ( defined( $params->{prefix} ) ) ? $params->{prefix} : $model->Name;
	my $suffix = ( defined( $params->{suffix} ) ) ? $params->{suffix} : "";
	if ( $suffix ne "" ) {
		$prefix .= "_${suffix}";
	}
	my $file = "${prefix}.rxn";
	open( SSCfile, ">$file" ) || die "Couldn't open $file: $!\n";
	my $version = BNGversion();
	print SSCfile
	  "--# SSC-file for model $prefix created by BioNetGen $version\n";
	print "Writing SSC translator .rxn file.....";

	#-- Compartment default for SSC ---- look more into it
	printf SSCfile
	  "region World \n  box width 1 height 1 depth 1\nsubvolume edge 1";

	# --This part correspond to seed specie
	print SSCfile "\n\n";
	print SSCfile "--# Initial molecules and their concentrations\n";
	$sp_string =
	  $model->SpeciesList->writeSSC( $model->Concentrations,
		$model->ParamList );
	print SSCfile $sp_string;

	# --This part in SSC corrsponds to Observables
	if ( @{ $model->Observables } ) {
		print SSCfile"\n\n--# reads observables";
		print SSCfile "\n";
		for my $obs ( @{ $model->Observables } ) {
			$ob_string = $obs->toStringSSC();
			if ( $ob_string =~ /\?/ ) {
				print STDOUT " \n WARNING: SSC does not implement ?. The observable has been commented. Please see .rxn file for more details \n";
				print STDOUT "\n See Observable\n", $obs->toString();
				$ob_string = "\n" . "--#" . "record " . $ob_string;
				print SSCfile $ob_string;
			}    #putting this string as a comment and carrying on
			else {
				print SSCfile "\nrecord ", $ob_string;
			}
		}
	}

	# --Reaction rules
	print SSCfile" \n\n--# reaction rules\n";
	for my $rset ( @{ $model->RxnRules } ) {
		my $id = 0;
		my $rreverse = ( $#$rset > 0 ) ? $rset->[1] : "";
		( my $reac1, my $errorSSC ) = $rset->[0]->toStringSSC($rreverse);
		if ( $errorSSC == 1 ) {
			print STDOUT "\nSee rule in .rxn \n",
			  $rset->[0]->toString($rreverse);
			$reac1 = "--#" . $reac1;
		}
		print SSCfile $reac1;
		print SSCfile "\n";
		if ($rreverse) {
			( my $reac2, my $errorSSC ) = $rset->[1]->toStringSSC($rreverse);
			if ( $errorSSC == 1 ) { $reac2 = "--#" . $reac2; }
			print SSCfile $reac2;
			print SSCfile "\n";
		}
	}
	print "\nWritten SSC file\n";
	return ();
}



###
###
###



# This subroutine writes a file which contains the information corresponding to the parameter block in BNG
sub writeSSCcfg
{
	my $model = shift;
	my $params = (@_) ? shift(@_) : "";
	return ("") if $NO_EXEC;

	my $model_name = $model->Name;

	# Strip prefixed path
	$model_name =~ s/^.*\///;
	my $prefix =
	  ( defined( $params->{prefix} ) ) ? $params->{prefix} : $model->Name;
	my $suffix = ( defined( $params->{suffix} ) ) ? $params->{suffix} : "";
	if ( $suffix ne "" ) {
		$prefix .= "_${suffix}";
	}
	my $file    = "${prefix}.cfg";
	my $version = BNGversion();
	open( SSCcfgfile, ">$file" ) || die "Couldn't open $file: $!\n";
	print STDOUT "\n Writting SSC cfg file \n";
	print SSCcfgfile
	  "# SSC cfg file for model $prefix created by BioNetGen $version\n";
	print SSCcfgfile $model->ParamList->writeSSCcfg( $vars{NETfile} );
	return ();
}



###
###
###



# Write BNG model specification in BNG XML format
sub writeBNGXML
{
	return ( writeXML(@_) );
}



###
###
###



sub writeXML
{
	my $model = shift;
	my $params = (@_) ? shift @_ : '';

	return '' if $NO_EXEC;

	my $model_name = $model->Name;

	# Strip prefixed path
	$model_name =~ s/^.*\///;
	my $prefix =
	  ( defined( $params->{prefix} ) ) ? $params->{prefix} : $model->Name;
	my $suffix = ( defined( $params->{suffix} ) ) ? $params->{suffix} : "";
	my $EvaluateExpressions =
	  ( defined( $params->{EvaluateExpressions} ) )
	  ? $params->{EvaluateExpressions}
	  : 1;
	if ( $suffix ne "" ) {
		$prefix .= "_${suffix}";
	}

	my $file = "${prefix}.xml";

	open( XML, ">$file" ) || die "Couldn't open $file: $!\n";
	my $version = BNGversion();

	#HEADER
	print XML <<"EOF";
<?xml version="1.0" encoding="UTF-8"?>
<!-- Created by BioNetGen $version  -->
<sbml xmlns="http://www.sbml.org/sbml/level3" level="3" version="1">
  <model id="$model_name">
EOF

	$indent = "    ";

	# Parameters
	print XML $indent . "<ListOfParameters>\n";
	my $indent2 = "  " . $indent;
	my $plist   = $model->ParamList;
	for my $param ( @{ $plist->Array } ) {
		my $value;
		my $type;
		my $do_print = 0;
		if ( $param->Type =~ /^Constant/ )
		{
			$value = ($EvaluateExpressions) ? $param->evaluate([], $plist) : $param->toString($plist);
			$type = ($EvaluateExpressions) ? "Constant" : $param->Type;
			$do_print = 1;
		}
		next unless $do_print;
		printf XML "$indent2<Parameter id=\"%s\"", $param->Name;
		printf XML " type=\"%s\"",                 $type;
		printf XML " value=\"%s\"",                $value;
		printf XML "/>\n";
	}
	print XML $indent . "</ListOfParameters>\n";

	# Molecule Types
	print XML $model->MoleculeTypesList->toXML($indent);

	# Compartments
	print XML $model->CompartmentList->toXML($indent);

	# Species
	if (@{$model->Concentrations}){
	    print XML $model->SpeciesList->toXML($indent,$model->Concentrations);
	} else {
	    print XML $model->SpeciesList->toXML($indent);
	}

	# Reaction rules
	my $string  = $indent . "<ListOfReactionRules>\n";
	my $indent2 = "  " . $indent;
	my $rindex  = 1;
	for my $rset ( @{ $model->RxnRules } ) {
		for my $rr ( @{$rset} ) {
			$string .= $rr->toXML( $indent2, $rindex, $plist );
			++$rindex;
		}
	}
	$string .= $indent . "</ListOfReactionRules>\n";
	print XML $string;

	# Observables
	my $string  = $indent . "<ListOfObservables>\n";
	my $indent2 = "  " . $indent;
	my $oindex  = 1;
	for my $obs ( @{ $model->Observables } ) {
		$string .= $obs->toXML( $indent2, $oindex );
		++$oindex;
	}
	$string .= $indent . "</ListOfObservables>\n";
	print XML $string;

	# Functions
	print XML $indent . "<ListOfFunctions>\n";
	my $indent2 = "  " . $indent;
	for my $param ( @{ $plist->Array } ) {
		next unless ( $param->Type eq "Function" );

		#print $param->Name,"\n";
		print XML $param->Ref->toXML( $plist, $indent2 );
	}
	print XML $indent . "</ListOfFunctions>\n";

	#FOOTER
	print XML <<"EOF";
  </model>
</sbml>
EOF
	print "Wrote BNG XML to $file.\n";
	return ();
}



###
###
###



sub writeSBML
{
	my $model = shift;
	my $params = (@_) ? shift : '';

	return '' if $NO_EXEC;

	unless ( defined $model->RxnList  and  @{$model->RxnList->Array} )
	{
		return ("No reactions in current model.");
	}

	my $plist = $model->ParamList;

	my $model_name = $model->Name;

	# Strip prefixed path
	$model_name =~ s/^.*\///;
	my $prefix =
	  ( defined( $params->{prefix} ) ) ? $params->{prefix} : $model->Name;
	my $suffix = ( defined( $params->{suffix} ) ) ? $params->{suffix} : "";
	if ( $suffix ne "" ) {
		$prefix .= "_${suffix}";
	}

	my $file = "${prefix}.xml";

	open( SBML, ">$file" ) || die "Couldn't open $file: $!\n";
	my $version = BNGversion();

	#HEADER
	print SBML <<"EOF";
<?xml version="1.0" encoding="UTF-8"?>
<!-- Created by BioNetGen $version  -->
<sbml xmlns="http://www.sbml.org/sbml/level2" level="2" version="1">
  <model id="$model_name">
EOF

	# 1. Compartments (currently one dimensionsless compartment)
	print SBML <<"EOF";
    <listOfCompartments>
      <compartment id="cell" size="1"/>
    </listOfCompartments>
EOF

	# 2. Species
	print SBML "    <listOfSpecies>\n";

	my $use_array = ( @{$model->Concentrations} ) ? 1 : 0;
	foreach my $spec ( @{$model->SpeciesList->Array} )
	{
		my $conc;
		if ($use_array) {
			$conc = $model->Concentrations->[ $spec->Index - 1 ];
		}
		else {
			$conc = $spec->Concentration;
		}
		if ( !isReal($conc) ) {
			$conc = $plist->evaluate([], $conc);
		}
		printf SBML "      <species id=\"S%d\" compartment=\"%s\" initialConcentration=\"%s\"",
		            $spec->Index, "cell", $conc;
		if ( $spec->SpeciesGraph->Fixed ) {
			printf SBML " boundaryCondition=\"true\"";
		}
		printf SBML " name=\"%s\"", $spec->SpeciesGraph->StringExact;
		print SBML "/>\n";
	}
	print SBML "    </listOfSpecies>\n";

	# 3. Parameters
	# A. Rate constants
	print SBML "    <listOfParameters>\n";
	print SBML "      <!-- Independent variables -->\n";
	foreach my $param ( @{$plist->Array} )
	{
	    next unless ( $param->Type eq 'Constant' );
		printf SBML "      <parameter id=\"%s\" value=\"%s\"/>\n", $param->Name, $param->evaluate([], $plist);
	}
	print SBML "      <!-- Dependent variables -->\n";
	foreach my $param ( @{$plist->Array} )
	{
	    next unless ( $param->Type eq 'ConstantExpression' );	
		printf SBML "      <parameter id=\"%s\" constant=\"false\"/>\n", $param->Name;
	}

	# B. Observables
	if ( @{$model->Observables} )
	{
		print SBML "      <!-- Observables -->\n";
	}
	foreach my $obs ( @{$model->Observables} )
	{
		printf SBML "      <parameter id=\"%s\" constant=\"false\"/>\n", "Group_" . $obs->Name;
	}
	print SBML "    </listOfParameters>\n";

	# 4. Rules (for observables)
	print SBML "    <listOfRules>\n";
	print SBML "      <!-- Dependent variables -->\n";
	for my $param ( @{ $plist->Array } ) {
		next if ( $param->Expr->Type eq 'NUM' );
		printf SBML "      <assignmentRule variable=\"%s\">\n", $param->Name;

  #    print  SBML "        <notes>\n";
  #    print  SBML "          <xhtml:p>\n";
  #    printf SBML "            %s=%s\n", $param->Name,$param->toString($plist);
  #    print  SBML "          </xhtml:p>\n";
  #    print  SBML "        </notes>\n";
		printf SBML $param->toMathMLString( $plist, "        " );
		print SBML "      </assignmentRule>\n";
	}
	if ( @{ $model->Observables } ) {
		print SBML "      <!-- Observables -->\n";
		for my $obs ( @{ $model->Observables } ) {
			printf SBML "      <assignmentRule variable=\"%s\">\n",
			  "Group_" . $obs->Name;
			my ( $ostring, $err ) = $obs->toMathMLString();
			if ($err) { return ($err); }
			for my $line ( split( "\n", $ostring ) ) {
				print SBML"          $line\n";
			}
			print SBML "      </assignmentRule>\n";
		}
	}
	print SBML "    </listOfRules>\n";

	# 5. Reactions
	print SBML "    <listOfReactions>\n";
	my $index = 0;
	for $rxn ( @{ $model->RxnList->Array } ) {
		++$index;
		printf SBML "      <reaction id=\"R%d\" reversible=\"false\">\n",
		  $index;

		#Get indices of reactants
		my @rindices = ();
		for $spec ( @{ $rxn->Reactants } ) {
			push @rindices, $spec->Index;
		}
		@rindices = sort { $a <=> $b } @rindices;

		#Get indices of products
		my @pindices = ();
		for $spec ( @{ $rxn->Products } ) {
			push @pindices, $spec->Index;
		}
		@pindices = sort { $a <=> $b } @pindices;

		print SBML "        <listOfReactants>\n";
		for my $i (@rindices) {
			printf SBML "          <speciesReference species=\"S%d\"/>\n", $i;
		}
		print SBML "        </listOfReactants>\n";

		print SBML "        <listOfProducts>\n";
		for my $i (@pindices) {
			printf SBML "          <speciesReference species=\"S%d\"/>\n", $i;
		}
		print SBML "        </listOfProducts>\n";

		print SBML "        <kineticLaw>\n";
		my ( $rstring, $err ) =
		  $rxn->RateLaw->toMathMLString( \@rindices, \@pindices,
			$rxn->StatFactor );
		if ($err) { return ($err); }
		for my $line ( split( "\n", $rstring ) ) {
			print SBML"          $line\n";
		}
		print SBML "        </kineticLaw>\n";

		print SBML "      </reaction>\n";
	}
	print SBML "    </listOfReactions>\n";

	#FOOTER
	print SBML <<"EOF";
  </model>
</sbml>
EOF
	print "Wrote SBML to $file.\n";

	return ();
}



###
###
###



# Add equilibrate option, which uses additional parameters
# t_equil and spec_nonequil.  If spec_nonequil is set, these
# species are not used in equilibration of the network and are only
# added after equilibration is performed. Network generation should
# re-commence after equilibration is performed if spec_nonequil has
# been set.

sub generate_network
{
	my $model  = shift;
	my $params = shift;

	my %vars = (
		'max_iter'   => '100',
		'max_agg'    => '1e99',
		'max_stoich' => '',
		'check_iso'  => '1',
		'prefix'     => $model->Name,
		'overwrite'  => 0,
		'print_iter' => 0,
		'verbose'    => 0
	);
	
	my %vars_pass = (
		'TextReaction' => '',
		'prefix'       => $model->Name
	);

	for my $key ( keys %$params ) {
		if ( defined( $vars{$key} ) ) {
			$vars{$key} = $params->{$key};
			if ( defined( $vars_pass{$key} ) ) {
				$vars_pass{$key} = $params->{$key};
			}
		}
		elsif ( defined( $vars_pass{$key} ) ) {
			$vars_pass{$key} = $params->{$key};
		}
		else {
			return "Unrecognized parameter $key in generate_network";
		}
	}

	return '' if $NO_EXEC;

	#print "max_iter=$max_iter\n";
	#print "max_agg=$max_agg\n";
	#print "check_iso=$check_iso\n";

    # Check if existing net file has been created since last modification time of .bngl file
	my $prefix    = $vars{prefix};
	my $overwrite = $vars{overwrite};
	if ( -e "$prefix.net" && -e "$prefix.bngl" ) {
		if ($overwrite) {
			send_warning("Removing old network file $prefix.net.");
			unlink("$prefix.net");
		}
		elsif ( -M "$prefix.net" < -M "$prefix.bngl" ) {
			send_warning(
				"$prefix.net is newer than $prefix.bngl so reading NET file.");
			my $err = $model->readFile( { file => "$prefix.net" } );
			return ($err);
		}
		else {
			return ( "Previously generated $prefix.net exists.  Set overwrite=>1 option to overwrite." );
		}
	}

	unless ( defined $model->SpeciesList ) {
		return "No species defined in call to generate_network";
	}
	my $slist = $model->SpeciesList;

	unless ( defined $model->RxnList ) {
		$model->RxnList( RxnList->new );
		$model->RxnList->SpeciesList($slist);
	}
	my $rlist = $model->RxnList;

    
	# Initialize observables
	foreach my $obs ( @{$model->Observables} )
	{
        $obs->update( $slist->Array );
    }	
    # Set ObservablesApplied attribute to everything in SpeciesList
    foreach my $spec ( @{$slist->Array} )
    {
        $spec->ObservablesApplied(1);
    }


    # Initialize energy patterns (for energyBNG only)
    if ( $model->Options->{energyBNG} )
	{
	    foreach my $epatt ( @{$model->EnergyPatterns} )
	    {
	        (my $err) = $epatt->updateSpecies( $slist->Array );
	    }
	}
	

	unless ( defined $model->RxnRules ) {
		return "No reaction_rules defined in call to generate_network";
	}

	my $nspec       = scalar @{$slist->Array};
	my $nrxn        = scalar @{$rlist->Array};
	my @rule_timing = ();
	my @rule_nrxn   = ();
	
	# update user with initial report
	report_iter( 0, $nspec, $nrxn );

    # now perform network generation steps
	foreach my $niter ( 1 .. $vars{max_iter} )
	{
		$t_start_iter = cpu_time(0);
		my @species = @{$slist->Array};

		# Apply reaction rules
		my $irule = 0;
		my $n_new, $t_off, $n_new_tot = 0;
		# NOTE: each element of @RxnRules is an array of reactions.
		#  If a rule is unidirectional, then the array has a single element.
		#  If a rule is bidirectional, then the array has two elements (forward and reverse)


		foreach my $rset ( @{$model->RxnRules} )
		{
			if ($verbose) { printf "Rule %d:\n", $irule + 1; }
			$n_new = 0;
			$t_off = cpu_time(0);
			my $dir = 0;

			foreach my $rr (@$rset)
			{

				if ($verbose) {
					if ( $dir == 0 ) {
						print "  forward:\n";
					}
					else {
						print "  reverse:\n";
					}
				}
             
				# change by Justin for compartments
				# added plist
				$n_new += $rr->applyRule(  $slist, $rlist,
					                        $model->ParamList,
					                        \@species,
					                        {  max_agg    => $vars{max_agg},
						                       check_iso  => $vars{check_iso},
						                       max_stoich => $vars{max_stoich},
						                       verbose    => $vars{verbose},
					                        }
				                         );
				++$dir;
			}
		
			my $time = cpu_time(0) - $t_off;
			$rule_timing[$irule] += $time;
			$rule_nrxn[$irule]   += $n_new;
			if ($verbose) {
				printf "Result: %5d new reactions %.2e CPU s\n", $n_new, $time;
			}
			$n_new_tot += $n_new;
			++$irule;
		}

		#printf "Total   : %3d\n", $n_new_tot;

        # update RulesApplied for species processed in this interation
		foreach my $spec (@species)
		{
			$spec->RulesApplied($niter)  unless ( $spec->RulesApplied );
		}

		# Update observables
        foreach my $obs ( @{$model->Observables} )
	    {
            $obs->update( $slist->Array );
        }
        # Set ObservablesApplied attribute to everything in SpeciesList
        foreach my $spec ( @{$slist->Array} )
        {
            $spec->ObservablesApplied(1);
        }

		# update energy patterns (for energyBNG only)
		if ( $model->Options->{energyBNG} )
		{
		    foreach my $epatt ( @{$model->EnergyPatterns} )
		    {
		        (my $err) = $epatt->updateSpecies( $slist->Array );
		    }
		}
	
	    # Finalize ratelaws for each new Rxn (energyBNG only)
        if ( $model->Options->{energyBNG} )
	    {
    	    foreach my $rxn_set ( keys %{$rlist->Hash} )
    	    {
    	        foreach my $rxn ( @{$rlist->Hash->{$rxn_set}} )
    	        {
    	            (my $err) = $rxn->updateEnergyRatelaw( $model );
    	        }
    	    }
        }

		$nspec = scalar @{$slist->Array};
		$nrxn  = scalar @{$rlist->Array};
		report_iter( $niter, $nspec, $nrxn );


		# Free memory associated with RxnList hash
		$rlist->resetHash;

		# Stop iteration if no new species were generated
		#printf "nspec=$nspec last= %d\n", scalar(@species);
		last if ( $nspec == scalar @species );

		# Print network after current iteration to netfile
		if ( $vars{print_iter} ) {
			$vars_pass{prefix} = "${prefix}_${niter}";
			if ( $err = $model->writeNET( \%vars_pass ) ) { return ($err); }
			$vars_pass{prefix} = $prefix;
		}
	}
        
        		
	# Print rule timing information
	printf "Cumulative CPU time for each rule\n";
	my $t_tot = 0, $n_tot = 0;
	foreach my $irule ( 0 .. $#RxnRules )
	{
		my $eff = ( $rule_nrxn[$irule] ) ?
		                  $rule_timing[$irule] / $rule_nrxn[$irule]
		                : 0.0;
		printf ( "Rule %3d: %5d reactions %.2e CPU s %.2e CPU s/rxn\n",
		           $irule + 1, $rule_nrxn[$irule], $rule_timing[$irule], $eff );
		$t_tot += $rule_timing[$irule];
		$n_tot += $rule_nrxn[$irule];
	}
	my $eff = ($n_tot) ? $t_tot / $n_tot : 0.0;
	printf ( "Total   : %5d reactions %.2e CPU s %.2e CPU s/rxn\n", $n_tot, $t_tot, $eff );

	# Print result to netfile
	if ( $err = $model->writeNET( \%vars_pass ) ) {
		return $err;
	}

	return '';
}



###
###
###



# construct a hybrid particle population model
#  --Justin, 21mar2001
sub generate_hybrid_model
{
	my $model        = shift;
	my $user_options = shift;


    my $indent = '    ';
    my $step_index = 0;
    printf "generate_hybrid_model( %s )\n", $model->Name;


    # default options
	my $options =
	{
		'prefix'     => $model->Name,
		'suffix'     => 'hybrid',
		'overwrite'  => 0,
		'verbose'    => 0,
		'actions'    => ['writeXML()'],
		'NETfile'    => 0,
		'execute'    => 0
	};
    # get user options
    while ( my ($opt,$val) = each %$user_options )
    {
        unless ( exists $options->{$opt} )
        {   return "Unrecognized option $opt in call to generate_hybrid_model";   }
        
        # overwrite default option
        $options->{$opt} = $val;
    }

    # do nothing if $NO_EXEC is true
	return '' if $NO_EXEC;


    # Check if existing net file has been created since last modification time of .bngl file
	my $modelfile = $options->{prefix} . '_' . $options->{suffix} . '.bngl';
	if ( -e $modelfile )
	{
		if ($options->{overwrite})
		{
			send_warning( "Overwriting older model file: $modelfile" );
			unlink $modelfile;
		}
		else
		{
			return "Model file $modelfile already exists. Set overwrite=>1 option to force overwrite.";
		}
	}


    # check if a ParamList exists
	unless ( defined $model->ParamList )
	{   return sprintf "Cannot continue! Model %s does not have a parameter list.", $model->Name;   }

    # Check for MoleculeTypes
	unless ( defined $model->MoleculeTypesList  and  %{$model->MoleculeTypesList->MolTypes} )
	{   return sprintf "Nothing to do! Model %s has zero molecule type definitions.", $model->Name;   } 	

    # check if a SpeciesList exists
	unless ( defined $model->SpeciesList  and  @{$model->SpeciesList->Array} )
	{   return sprintf "Nothing to do! Model %s has zero seed species definitions.", $model->Name;   }

    # Check for RxnRules
    unless ( defined $model->RxnRules  and  @{$model->RxnRules} )
	{   return sprintf "Nothing to do! Model %s has zero reaction rule definitions.", $model->Name;   } 

    # check if PopulationTypesList exists
	unless ( defined $model->PopulationTypesList  and  %{$model->PopulationTypesList->MolTypes} )
	{   return sprintf "Nothing to do! Model %s has zero population type definitions.", $model->Name;   }

    # check if PopulationList exists
	unless ( defined $model->PopulationList  and  @{$model->PopulationList->List} )
	{   return sprintf "Nothing to do! Model %s has zero population map definitions.", $model->Name;   }
   
    
    # create new model!
    my $hybrid_model = BNGModel::new();
	
	$hybrid_model->Name( $model->Name . '_hybrid' );
	$hybrid_model->Version( $model->Version );
	$hybrid_model->SubstanceUnits( $model->SubstanceUnits );
	%{$hybrid_model->Options} = %{$model->Options};
	
	

    # copy the constants in the parameter list
    #  NOTE: we'll add observable and functions later
    print $indent . "$step_index:Fetching model parameters.. ";  ++$step_index;
    my $plist_new = $model->ParamList->copyConstant();
    $hybrid_model->ParamList( $plist_new );
    print sprintf "found %d constants and expressions.\n", scalar @{$plist_new->Array};
    
    
    # Copy compartments
    my $clist_new = undef;
    if ( defined $model->CompartmentList )
    {
        print $indent . "$step_index:Fetching compartments.. "; ++$step_index;
        $clist_new = $model->CompartmentList->copy( $plist_new );
        $hybrid_model->CompartmentList( $clist_new );
        print $indent . sprintf "found %d compartments.\n", @{$clist_new->Array};
        send_warning( "generate_hybrid_model() does not support compartments at this time" ) if (@{$clist_new->Array});  
    }
    
    
    
    # Copying the moleculeTypesList and add population types
    print $indent . "$step_index:Fetching molecule types..   "; ++$step_index;
    my $mtlist_new =  $model->MoleculeTypesList->copy();
    $hybrid_model->MoleculeTypesList( $mtlist_new );
    print sprintf "found %d molecule types.\n", scalar keys %{$mtlist_new->MolTypes};
    {
        # Add population types
        print $indent . "$step_index:Adding population types..   "; ++$step_index;
        while ( my ($name,$mt) = each %{$model->PopulationTypesList->MolTypes} )
        {
            my $mt_copy = $mt->copy();
            $mt_copy->PopulationType(1);
            unless ( $mtlist_new->add($mt_copy) )
            {   return "PopulationType $name clashes with MoleculeType of the same name";  }
        }
        print sprintf "found %d population types.\n", scalar keys %{$model->PopulationTypesList->MolTypes};
    }


    # Copy seed species, replacing with populations if possible, and add empty populations
    my $slist_new = SpeciesList::new();
    $hybrid_model->SpeciesList( $slist_new );   
    {    
        print $indent . "$step_index:Fetching seed species..\n"; ++$step_index; 
 
        # loop over species in species list
        foreach my $species ( @{$model->SpeciesList->Array} )
        {
            my $sg   = $species->SpeciesGraph;
            my $conc = $species->Concentration;
        
            # check if this is isomorphic to any of our populations
            my $is_pop = 0;
	        foreach my $pop ( @{$model->PopulationList->List} )
	        {
                if ( SpeciesGraph::isomorphicTo($species->SpeciesGraph, $pop->Species) )
                {   # add the population instead of the speciesGraph
                    my $sg_copy = $pop->Population->copy();
                    $sg_copy->relinkCompartments( $hybrid_model->CompartmentList );
                    $slist_new->add( $sg_copy, $species->Concentration );
                    $is_pop = 1;
                    if ( $options->{verbose} )
                    {
                        print $indent.$indent
                            . sprintf "replaced species %s with population %s.\n", $sg->toString(), $sg_copy->toString();
                    }
                    last;
                }
            }
            unless ($is_pop)
            {   # this isn't a population, so add SpeciesGraph directly.
                my $sg_copy = $species->SpeciesGraph->copy();
                $sg_copy->relinkCompartments( $hybrid_model->CompartmentList );
                $slist_new->add( $sg_copy, $species->Concentration );
            }
        }
        print $indent . sprintf "  ..found %d seed species.\n", scalar @{$slist_new->Array};    
    }

    
    # Add population species to seed species
    {
        print $indent . "$step_index:Adding populations with zero counts to seed species..\n"; ++$step_index;     
        my $zero_pops = 0;
    	foreach my $pop ( @{$model->PopulationList->List} )
    	{
            my ($sp) = $slist_new->lookup( $pop->Population );
            unless ( $sp )
            {
                my $sg_copy = $pop->Population->copy();
                $sg_copy->relinkCompartments( $hybrid_model->CompartmentList );  
                $slist_new->add( $sg_copy, 0 );
                ++$zero_pops;
            }
        }
        print $indent . sprintf "  ..added %d populations to seed species list.\n", $zero_pops;      
    }
            

    # Copy the observables and add matches to populations (also register observable names in parameter list)
    my $obslist_new = [];
    $hybrid_model->Observables( $obslist_new );
    {
        print $indent . "$step_index:Fetching observables and adding population matches..\n"; ++$step_index;         
        # loop over observables
        foreach my $obs ( @{$model->Observables} )
        {
            my $obs_copy = $obs->copy();
            $obs_copy->relinkCompartments( $hybrid_model->CompartmentList );
            push @{$obslist_new}, $obs_copy;
        
            # get a parameter that points to this observable
            if ( $plist_new->set( $obs_copy->Name, '0', 1, "Observable", $obs_copy) )
            {
      	        my $name = $obs_copy->Name;
                return "Observable name $name clashes with previously defined Observable or Parameter";
            }
      
            # find populations to add to observable
            my @add_patterns = ();
            foreach my $pop ( @{$model->PopulationList->List} )
	        {
                my $matches = $obs_copy->match( $pop->Species );
            
                if ($matches)
                {   
                    my $ii = 0;
                    while ( $ii < $matches )
                    {
                        push @add_patterns, $pop->Population->copy()->relinkCompartments( $hybrid_model->CompartmentList );
                        ++$ii
                    }
                    if ( $options->{verbose} )
                    {
                        print $indent.$indent . sprintf "observable '%s':  +%d match%s to %s.\n",
                                                        $obs_copy->Name, $matches, ($matches>1 ? 'es' : ''), $pop->Population->toString();
                    }
                }
            }      
            push @{$obs_copy->Patterns}, @add_patterns;      
        }
        print $indent . sprintf "  ..found %d observables.\n", scalar @{$obslist_new};
    }
    
    
    # Copy functions
    {
        print $indent . "$step_index:Fetching functions.. "; ++$step_index;     
        my $fcn_copies = $model->ParamList->copyFunctions();
        foreach my $fcn ( @$fcn_copies )
        {
            $hybrid_model->ParamList->set( $fcn->Name, $fcn->Expr, 0, 'Function', $fcn );
        }
        print sprintf "found %d functions.\n", scalar @{$fcn_copies};
    }
   

    # Refine rules
    my $rxnrules_new = [];
    $hybrid_model->RxnRules( $rxnrules_new );
    {
        print $indent . "$step_index:Refining rules with respect to population objects..\n"; ++$step_index;   
	
        # get the species graphs corresponding to each population
        my $pop_species = [];
        foreach my $pop ( @{$model->PopulationList->List} )
        {   push @$pop_species, $pop->Species;   }
        my $n_popspec = scalar @pop_species;
	
	    # loop over rules
	    my $rule_count = 0;
	    foreach my $rset ( @{$model->RxnRules} )
	    {
	        # NOTE: each element of @RxnRules is an array of reactions.
	        #  If a rule is unidirectional, then the array has a single element.
	        #  If a rule is bidirectional, then the array has two elements (forward and reverse)	
		    foreach my $rr (@$rset)
		    {    
		        # first copy the rule so we don't mess with the orginal model
		        my $rr_copy = $rr->copy();
		        $rr_copy->resetLabels();
		    
                # apply rule to species
			    my $refinements = $rr_copy->refineRule(  $pop_species, $model, $hybrid_model, {verbose => $options->{verbose}} );
			    foreach my $refinement ( @$refinements )
			    {
                    push @$rxnrules_new, [$refinement];
                }
                if ( $options->{verbose} )
                {
                    print $indent.$indent . sprintf "Rule %s: created %d refinement%s.\n",
                                                    $rr_copy->Name, scalar @$refinements, ((scalar @$refinements > 1)?'s':'');
                }
			    ++$dir;
			    ++$rule_count;
	        }
	    }
        print $indent . sprintf "  ..finished processing %d reaction rules.\n", $rule_count;
    }


    # Add population maps to the list of rules
    {
        print $indent . "$step_index:Fetching population maps.. "; ++$step_index;
        foreach my $pop ( @{$model->PopulationList->List} )
	    {
	        # write rule as string
            my $rr_string = $pop->MappingRule->toString();
            # remove the linebreak
            $rr_string =~ s/\\\s//;
            # parse string to create "copy" of rule
            my ($rrs, $err) = RxnRule::newRxnRule( $rr_string, $hybrid_model );
            push @$rxnrules_new, $rrs;
        }
        print sprintf "found %d maps.\n", scalar @{$model->PopulationList->List};
    }


    # create empty RxnList
    print $indent . "$step_index:Creating empty reaction list.\n"; ++$step_index;        
    my $rxnlist_new = RxnList::new();
    $hybrid_model->RxnList( $rxnlist_new );
    

	# Print hybrid model to file
    print $indent . "$step_index:Attempting to write hybrid BNGL.. "; ++$step_index;    	
	unless ( open out, '>', $modelfile ) {  return "Couldn't write to $modelfile: $!\n";  }
    print out $hybrid_model->writeBNGL( {NETfile=>$options->{NETfile}} );
    # writing actions!
    if ( @{$options->{actions}} )
    {
        my $action_string = "\n\n###  model actions  ###\n\n";
        foreach my $action ( @{$options->{actions}} )
        {
            $action_string .= "$action;\n";
        }
        $action_string .= "\n";
        print out $action_string;
    }
	close out;
	
	
	print "done.\n";
	print "Wrote hybrid model to file $modelfile.\n";
	
	if ( $options->{execute} )
	{   # execute actions
	    my $errors = [];
        foreach my $action ( @{$options->{actions}} )
        {
            my $action_string = "\$hybrid_model->$action";
            my $err = eval "$action_string";
            if ($@)   {  warn $@;  }
            if ($err) {  push @$errors, $err;  }
        }	
        if (@$errors) {  return join "\n", $errors;  }
	}
	
	return '';
}



###
###
###



sub report_iter
{
	my $niter = shift;
	my $nspec = shift;
	my $nrxn  = shift;

	printf "Iteration %3d: %5d species %6d rxns", $niter, $nspec, $nrxn;
	my $t_cpu = ( $niter > 0 ) ? cpu_time(0) - $t_start_iter : 0;
	printf "  %.2e CPU s", $t_cpu;
	if ($HAVE_PS) {
		my ( $rhead, $vhead, $rmem, $vmem ) = split ' ', `ps -o rss,vsz -p $$`;
		printf " %.2e (%.2e) Mb real (virtual) memory.", $t_cpu, $rmem / 1000,
		  $vmem / 1000;
	}
	printf "\n";
	return;
}



###
###
###



sub simulate_ode
{
	use IPC::Open3;

	my $model  = shift;
	my $params = shift;
	my $err;

	my $prefix =
	  ( defined( $params->{prefix} ) ) ? $params->{prefix} : $model->Name;
	my $suffix  = ( defined( $params->{suffix} ) )  ? $params->{suffix}  : "";
	my $netfile = ( defined( $params->{netfile} ) ) ? $params->{netfile} : "";
	my $method = ( defined( $params->{method} ) ) ? $params->{method} : "cvode";
	my $sparse = ( defined( $params->{sparse} ) ) ? $params->{sparse} : 0;
	my $atol   = ( defined( $params->{atol} ) )   ? $params->{atol}   : 1e-8;
	my $rtol   = ( defined( $params->{rtol} ) )   ? $params->{rtol}   : 1e-8;
	my $print_end =
	  ( defined( $params->{print_end} ) ) ? $params->{print_end} : 0;
	my $steady_state =
	  ( defined( $params->{steady_state} ) ) ? $params->{steady_state} : 0;
	my $verbose = ( defined( $params->{verbose} ) ) ? $params->{verbose} : 0;
    # Added explicit argument for simulation continuation.  --Justin
    my $continue = exists $params->{continue} ? $params->{continue} : 0;
    # print number of active species
    my $print_n_species_active = exists $params->{print_n_species_active} ? $params->{print_n_species_active} : 0;

	return ("") if $NO_EXEC;

	if ( $model->ParamList->writeFunctions() )
	{
		#		return (
		#"Simulation using Functions in .net file is currently not implemented."
		#		);
	}

	if ( $suffix ne "" ) {
		$prefix .= "_${suffix}";
	}

	print "Network simulation using ODEs\n";
	my $program;
	if ( !( $program = findExec("run_network") ) ) {
		return ("Could not find executable run_network");
	}
	my $command = "\"" . $program . "\"";
	$command .= " -o \"$prefix\"";

	# Specify netfile to read from existing netfile.
	# New netfile will be generated if prefix is set or
	# is UpdateNet is true.

	# Default netfile based on prefix
	my $netpre;
	if ( $netfile eq "" ) {
		$netfile = $prefix . ".net";
		$netpre  = $prefix;

		# Generate net file if not already created or if prefix is set in params
		if (   ( !-e $netfile )
			|| $model->UpdateNet
			|| ( defined( $params->{prefix} ) )
			|| ( defined( $params->{suffix} ) ) )
		{
			if ( $err = $model->writeNET( { prefix => "$netpre" } ) ) {
				return ($err);
			}
		}
	}
	else {

		# Make sure NET file has proper suffix
		$netpre = $netfile;
		$netpre =~ s/[.]([^.]+)$//;
		if ( !( $1 =~ /net/i ) ) {
			return ("File $netfile does not have net suffix");
		}
	}

	$command .= " -p $method";
	if ( $method eq "cvode" ) {

		# Set paramters related to CVODE integration
		$command .= " -a $atol";
		$command .= " -r $rtol";
		if ($sparse) {
			$command .= " -b";
		}
	}
	else {
		return ("method set to unrecognized type: $method");
	}

	# Checking of steady state
	if ($steady_state) {
		$command .= " -c";
	}

	# Printing of _end.net file
	if ($print_end) {
		$command .= " -e";
	}

	# More detailed output
	if ($verbose) {
		$command .= " -v";
	}

	# Continuation
	# NOTE: continuation must now be specified explicitly!
	if ($continue) {
		$command .= " -x";
	}

	# Print number of active species
	if ($print_n_species_active) {
		$command .= " -j";
	}


	# Set start time for trajectory
	my $t_start;
	# t_start argument is defined
	if ( defined( $params->{t_start} ) )
	{
		$t_start = $params->{t_start};		
		# if this is a continuation, check that model time equals t_start
		if ( $continue )
		{
		    unless ( defined($model->Time)  and  ($model->Time == $t_start) )
		    {
		        return ("t_start must equal current model time for continuation.");
		    }
		}
	}
	# t_start argument not defined
	else 
	{
	    if ( $continue   and   defined($model->Time) )
	    {   $t_start = $model->Time;   }
 		else
 		{   $t_start = 0.0;   }
	}

    # set the model time to t_start
    $model->Time($t_start);

  	# CHANGES: to preserve backward compatibility: only output start time if ne 0
	unless ( $t_start == 0.0 )
	{   $command.= " -i $t_start"; 	}

	# Use program to compute observables
	$command .= " -g \"$netfile\"";

	# Read network from $netfile
	$command .= " \"$netfile\"";

	if ( defined( $params->{t_end} ) ) {
		my $n_steps, $t_end;
		$t_end = $params->{t_end};
		# Extend interval for backward compatibility.  Previous versions default assumption was $t_start=0.
		if (($t_end-$t_start)<=0.0){ 
		     return ("t_end must be greater than t_start.");
		}
		$n_steps = ( defined( $params->{n_steps} ) ) ? $params->{n_steps} : 1;
		my $step_size = ( $t_end - $t_start ) / $n_steps;
		$command .= " ${step_size} ${n_steps}";
	}
	elsif ( defined( $params->{sample_times} ) ) {

		# Two sample points are given.
		*sample_times = $params->{sample_times};
		if ( $#sample_times > 1 ) {
			$command .= " " . join( " ", @sample_times );
			$t_end = $sample_times[$#sample_times];
		}
		else {
			return ("sample_times array must contain 3 or more points");
		}
	}
	else {
		return ("Either t_end or sample_times must be defined");
	}

	print "Running run_network on ", `hostname`;
	print "full command: $command\n";

	# Compute timecourses using run_network
	local ( *Reader, *Writer, *Err );
	if ( !( $pid = open3( \*Writer, \*Reader, \*Err, "$command" ) ) ) {
		return ("$command failed: $?");
	}
	my $last                 = "";
	my $steady_state_reached = 0;
	while (<Reader>) {
		print;
		$last = $_;
		if ($steady_state) {
			if (/Steady state reached/) {
				$steady_state_reached = 1;
			}
		}
	}
	my @err = <Err>;
	close Writer;
	close Reader;
	close Err;
	waitpid( $pid, 0 );

	# Check for errors in running the simulation command
	if (@err) {
		print @err;
		return ("$command\n  did not run successfully.");
	}
	if ( !( $last =~ /^Program times:/ ) ) {
		return ("$command\n  did not run successfully.");
	}

	if ($steady_state) {
		send_warning("Steady_state status= $steady_state_reached");
		if ( !$steady_state_reached ) {
			return ("Simulation did not reach steady state by t_end=$t_end");
		}
	}

	# Process output concentrations
	if ( !( $model->RxnList ) ) {
		send_warning(
			"Not updating species concnetrations because no model has been read"
		);
	}
	elsif ( -e "$prefix.cdat" ) {
		print "Updating species concentrations from $prefix.cdat\n";
		open( CDAT, "$prefix.cdat" );
		my $last = "";
		while (<CDAT>) {
			$last = $_;
		}
		close(CDAT);

		# Update Concentrations with concentrations from last line of CDAT file
		my ( $time, @conc ) = split( ' ', $last );
		*species = $model->SpeciesList->Array;
		if ( $#conc != $#species ) {
			$err =
			  sprintf
			  "Number of species in model (%d) and CDAT file (%d) differ",
			  scalar(@species), scalar(@conc);
			return ($err);
		}
		$model->Concentrations( [@conc] );
		$model->UpdateNet(1);
	}
	else {
		return ("CDAT file is missing");
	}
	$model->Time($t_end);
	#printf "t_end=%g\n", $t_end;

	return '';
}



###
###
###



# Set the concentration of a species to specified value.
# Value may be a number or a parameter.
sub setConcentration
{
	my $model = shift;
	my $sname = shift;
	my $value = shift;
    
	return '' if $NO_EXEC;

	my $plist = $model->ParamList;
	my $err;

	#print "sname=$sname value=$value\n";

	# SpeciesGraph specified by $sname
	my $sg = SpeciesGraph->new;
	$err = $sg->readString( \$sname, $model->CompartmentList );
	if ($err) { return ($err); }

	# Should check that this SG specifies a complete species, otherwise
	# may match a number of species.

	# Find matching species
	my $spec;
	unless ( $spec = $model->SpeciesList->lookup($sg) )
	{
		$err = sprintf "Species %s not found in SpeciesList", $sg->toString();
		return ($err);
	}

	# Read expression
	my $expr    = Expression->new();
	my $estring = $value;
	if ( my $err = $expr->readString( \$estring, $plist ) )
	{
		return ( '', $err );
	}
	my $conc = $expr->evaluate($plist);


	# Set concentration in Species object
	$spec->Concentration($conc);

	# Set concentration in Concentrations array if defined
	if ( @{$model->Concentrations} )
	{
		$model->Concentrations->[$spec->Index - 1] = $conc;
	}

	# Set flag to update netfile when it's used
	$model->UpdateNet(1);

	printf "Set concentration of species %s to value %s\n",
	       $spec->SpeciesGraph->StringExact, $conc;

	return '';
}



###
###
###



sub setParameter
{
	my $model = shift;
	my $pname = shift;
	my $value = shift;

	return ("") if $NO_EXEC;

	my $plist = $model->ParamList;
	my $param, $err;

	# Error if parameter doesn't exist
	( $param, $err ) = $plist->lookup($pname);
	if ($err) { return ($err) }

	# Read expression
	my $expr    = Expression->new();
	my $estring = "$pname=$value";
	if ( $err = $expr->readString( \$estring, $plist ) ) { return ($err) }

	# Set flag to update netfile when it's used
	$model->UpdateNet(1);

	printf "Set parameter %s to value %s\n", $pname, $expr->evaluate($plist);
	return ("");
}



###
###
###



sub saveConcentrations
{
	my $model = shift;

	my $i = 0;
	*conc = $model->Concentrations;
	if (@conc) {
		for my $spec ( @{ $model->SpeciesList->Array } ) {
			$spec->Concentration( $conc[$i] );

			#printf "%6d %s\n", $i+1, $conc[$i];
			++$i;
		}
	}
	return ("");
}



###
###
###



sub resetConcentrations
{
	my $model = shift;

	return ("") if $NO_EXEC;

	$model->Concentrations( [] );
	return ("");
}



###
###
###



sub setModelName
{
	my $model = shift;
	my $name  = shift;

	$model->Name($name);
	return ("");
}



###
###
###



sub simulate_ssa
{
	use IPC::Open3;

	my $model  = shift;
	my $params = shift;
	my $err;

	my $prefix =
	  ( defined( $params->{prefix} ) ) ? $params->{prefix} : $model->Name;
	my $suffix  = ( defined( $params->{suffix} ) )  ? $params->{suffix}  : "";
	my $netfile = ( defined( $params->{netfile} ) ) ? $params->{netfile} : "";
	my $verbose = ( defined( $params->{verbose} ) ) ? $params->{verbose} : 0;
	my $print_end =
	  ( defined( $params->{print_end} ) ) ? $params->{print_end} : 0;
	my $print_net =
	  ( defined( $params->{print_net} ) ) ? $params->{print_net} : 0;
	my $seed =
	  ( defined( $params->{seed} ) )
	  ? $params->{seed}
	  : int( rand( 2**32 ) ) + 1;
	my $verbose = ( defined( $params->{verbose} ) ) ? $params->{verbose} : 0;
    # Added explicit argument for simulation continuation.  --Justin
    my $continue = exists $params->{continue} ? $params->{continue} : 0;	
    # Write number of active species to a file
    my $print_n_species_active = exists $params->{print_n_species_active} ? $params->{print_n_species_active} : 0;

	return ("") if $NO_EXEC;

	if ( $model->ParamList->writeFunctions() ) {
        #return (
        #   "Simulation using Functions in .net file is currently not implemented."
        #);
	}

	if ( $suffix ne "" ) {
		$prefix .= "_${suffix}";
	}

	print "Network simulation using SSA\n";
	my $program;
	if ( !( $program = findExec("run_network") ) ) {
		return ("Could not find executable run_network");
	}
	my $command = "\"" . $program . "\"";
	$command .= " -o \"$prefix\"";

	# Default netfile based on prefix
	my $netpre;
	if ( $netfile eq "" ) {
		$netfile = $prefix . ".net";
		$netpre  = $prefix;

		# Generate net file if not already created or if prefix is set in params
		if (   ( !-e $netfile )
			|| $model->UpdateNet
			|| ( defined( $params->{prefix} ) )
			|| ( defined( $params->{suffix} ) ) )
		{
			if ( $err = $model->writeNET( { prefix => "$netpre" } ) ) {
				return ($err);
			}		
		}
	}
	else {

		# Make sure NET file has proper suffix
		$netpre = $netfile;
		$netpre =~ s/[.]([^.]+)$//;
		if ( !( $1 =~ /net/i ) ) {
			return ("File $netfile does not have net suffix");
		}
	}


	my $update_interval =
	  ( defined( $params->{update_interval} ) )
	  ? $params->{update_interval}
	  : 1;
	my $expand = ( defined( $params->{expand} ) ) ? $params{$expand} : "lazy";
	if ( $expand eq "lazy" ) {
	}
	elsif ( $expand eq "layered" ) {
	}
	else {
		return ("Unrecognized expand method $expand");
	}

	$command .= " -p ssa -h $seed";

	if ($print_net) {
		$command .= " -n";
	}

	if ($print_end) {
		$command .= " -e";
	}

	# More detailed output
	if ($verbose) {
		$command .= " -v";
	}
	
	# Continuation
	# NOTE: continuation must now be specified explicitly!
	if ($continue) {
		$command .= " -x";
	}	

	# Print number of active species
	if ($print_n_species_active) {
		$command .= " -j";
	}

	# Set start time for trajectory
	my $t_start;
	# t_start argument is defined
	if ( defined( $params->{t_start} ) )
	{
		$t_start = $params->{t_start};		
		# if this is a continuation, check that model time equals t_start
		if ( $continue )
		{
		    unless ( defined($model->Time)  and  ($model->Time == $t_start) )
		    {
		        return ("t_start must equal current model time for continuation.");
		    }
		}
	}
	# t_start argument not defined
	else 
	{
	    if ( $continue   and   defined($model->Time) )
	    {   $t_start = $model->Time;   }
 		else
 		{   $t_start = 0.0;   }
	}

    # set the model time to t_start
    $model->Time($t_start);

  	# To preserve backward compatibility: only output start time if != 0
	unless ( $t_start == 0.0 )
	{   $command.= " -i $t_start"; 	}
	

	# Use program to compute observables
	$command .= " -g \"$netfile\"";

	# Read network from $netfile
	$command .= " \"$netfile\"";

	if ( defined( $params->{n_steps} ) ) {
		my $n_steps, $t_end;
		if ( defined( $params->{t_end} ) ) {
			$t_end = $params->{t_end};
		}
		else {
			return ("Parameter t_end must be defined");
		}
		# Extend interval for backward compatibility.  Previous versions default assumption was $t_start=0.
		if (($t_end-$t_start)<=0.0){
		    return ("t_end must be greater than t_start.");
        }
		$n_steps = ( defined( $params->{n_steps} ) ) ? $params->{n_steps} : 1;
		my $step_size = ( $t_end - $t_start ) / $n_steps;
		$command .= " ${step_size} ${n_steps}";
	}
	elsif ( defined( $params->{sample_times} ) ) {

		# Two sample points are given.
		*sample_times = $params->{sample_times};
		if ( $#sample_times > 1 ) {
			$command .= " " . join( " ", @sample_times );
		}
		else {
			return ("sample_times array must contain 3 or more points");
		}
	}

	# Determine index of last rule iteration
	if ( $model->SpeciesList ) {
		my $n_iter = 0;
		for my $spec ( @{ $model->SpeciesList->Array } ) {
			my $iter = $spec->RulesApplied;
			$n_iter = ( $iter > $n_iter ) ? $iter : $n_iter;
		}

		#print "Last iteration was number $n_iter\n";
	}
	print "Running run_network on ", `hostname`;
	print "full command: $command\n";

	#print "seed=$seed\n";

	# Compute timecourses using run_network
	local ( *Reader, *Writer, *Err );
	unless ( $pid = open3( \*Writer, \*Reader, \*Err, "$command" ) )
    {   return "$command failed: $?";   }


	my $last    = '';
	my $edgepop = 0;
	while ( my $message = <Reader> )
    {
		# If network generation is on-the-fly, look for signal that
		# species at the edge of the network is newly populated
		if ( $message =~ s/^edgepop:\s*// )
        {
			unless ( $model->SpeciesList )
            {   # Can't generate new species if running from netfile
				++$edgepop;
				print Writer "continue\n";
				next;
			}

			my (@newspec) = split /\s+/, $message;

			my $species;
			++$n_iter;
			if ( $expand eq 'lazy' )
            {
				my @sarray, $spec;
				foreach my $sname (@newspec)
                {
					unless ( $spec = $model->SpeciesList->lookup_bystring($sname) )
                    {   return "Couldn't find species $sname.";   }
					push @sarray, $spec;
				}
				if ($verbose)
                {   printf "Applying rules to %d species\n", scalar @sarray;    }
				$species = \@sarray;
			}
			else
            {
				# Do full next iteration of rule application
				$species = $model->SpeciesList->Array;
			}

			# Apply reaction rules
			my $nspec = scalar @{$model->SpeciesList->Array};
			my $nrxn  = scalar @{$model->RxnList->Array};
			my $irule = 1;
			my $n_new, $t_off;
			foreach my $rset ( @{$model->RxnRules} )
            {
				if ($verbose) {  $t_off = cpu_time(0);  }
				$n_new = 0;
				foreach my $rr (@$rset)
                {
					$n_new += $rr->applyRule( $model->SpeciesList, $model->RxnList, $model->ParamList, $species, $params );
				}
				if ($verbose) {
					printf "Rule %3d: %3d new reactions %.2e s CPU time\n",
					  $irule,
					  $n_new, cpu_time(0) - $t_off;
				}
				++$irule;
			}

			# Set RulesApplied attribute to everything in @$species
			foreach my $spec (@$species)
            {
				$spec->RulesApplied($n_iter) unless ($spec->RulesApplied);
			}


			# Update observables
	        foreach my $obs (@{$model->Observables})
            {
		        $obs->update( $model->SpeciesList->Array, $nspec );
			}
            # Set ObservablesApplied attribute to everything in SpeciesList
            my $new_species = [];
            foreach my $spec ( @{$model->SpeciesList->Array} )
            {
                unless ( $spec->ObservablesApplied )
                {
                    push @$new_species, $spec  unless ( $spec->RulesApplied );
                    $spec->ObservablesApplied(1);
                }
            }

			# Print new species, reactions, and observable entries
			if ( scalar @{$model->RxnList->Array} > $nrxn )
            {
				print Writer "read\n";

				$model->SpeciesList->print( *Writer, $nspec );
                #$model->SpeciesList->print( *STDERR, $nspec );
				$model->RxnList->print( *Writer, $nrxn );
                #$model->RxnList->print( *STDERR, $nrxn );
				print Writer "begin groups\n";
				my $i = 1;
				foreach my $obs ( @{$model->Observables} )
                {
					print Writer "$i ";
					$obs->printGroup( *Writer, $model->SpeciesList->Array, $nspec );
                    #$obs->printGroup( *STDERR, $new_species );
					++$i;
				}
				print Writer "end groups\n";
			}
			else {
				print Writer "continue\n";
			}
		}
		else {
			print $message;
			$last = $message;
		}
	}

	my @err = <Err>;
	close Writer;
	close Reader;
	close Err;
	waitpid( $pid, 0 );

	# Report number of times edge species became populated
	# without network expansion
	#  if ($edgepop){
	if (1) {
		printf "Edge species became populated %d times.\n", $edgepop;
	}

	# Print final netfile
	if ( $model->SpeciesList
		&& ( $err = $model->writeNET( { prefix => "$netpre" } ) ) )
	{
		return ($err);
	}

	# Process output concentrations
	if ( !( $model->RxnList ) ) {
		send_warning(
			"Not updating species concnetrations because no model has been read"
		);
	}
	elsif ( -e "$prefix.cdat" ) {
		print "Updating species concentrations from $prefix.cdat\n";
		open( CDAT, "$prefix.cdat" );
		my $last = "";
		while (<CDAT>) {
			$last = $_;
		}
		close(CDAT);

		# Update Concentrations with concentrations from last line of CDAT file
		my ( $time, @conc ) = split( ' ', $last );
		*species = $model->SpeciesList->Array;
		if ( $#conc != $#species ) {
			$err =
			  sprintf
			  "Number of species in model (%d) and CDAT file (%d) differ",
			  scalar(@species), scalar(@conc);
			return ($err);
		}
		$model->Concentrations( [@conc] );
		$model->UpdateNet(1);
	}
	else {
		return ("CDAT file is missing");
	}

	if (@err) {
		print @err;
		return ("$command\n  did not run successfully.");
	}
	if ( !( $last =~ /^Program times:/ ) ) {
		return ("$command\n  did not run successfully.");
	}

	$model->Time($t_end);

	return ("");
}



###
###
###



sub simulate_nf
{
	use IPC::Open3;

	my $model  = shift;
	my $params = shift;
	my $err;

	my $prefix =
	  ( defined( $params->{prefix} ) ) ? $params->{prefix} : $model->Name;
	my $suffix = ( defined( $params->{suffix} ) ) ? $params->{suffix} : "";

	my $verbose = ( defined( $params->{verbose} ) ) ? $params->{verbose} : 0;
	my $complex = ( defined( $params->{complex} ) ) ? $params->{complex} : 0;

	# Handle other command line args.
	my $otherCommandLineParameters =
	  ( defined( $params->{param} ) ) ? $params->{param} : "";

	#print "$otherCommandLineParameters\n";

	return ("") if $NO_EXEC;

	if ( $suffix ne "" ) {
		$prefix .= "_${suffix}";
	}

	print "Network simulation using NFsim\n";
	my $program;
	if ( !( $program = findExec("NFsim") ) ) {
		return ("Could not find executable NFsim");
	}
	my $command = "\"" . $program . "\"";

	# Write BNG xml file
	$model->writeXML( { prefix => $prefix } );

	# Read network from $netfile
	$command .= " -ss \"${prefix}.species\" -xml \"${prefix}.xml\" -o \"${prefix}.gdat\"";

	# Append the run time and output intervals
	my $t_start;
	if ( defined( $params->{t_start} ) ) {
		$t_start = $params->{t_start};
		$model->Time($t_start);
	}
	else {
		$t_start = ( defined( $model->Time ) ) ? $model->Time : 0;
	}

	if ( defined( $params->{n_steps} ) ) {
		my $n_steps, $t_end;
		$n_steps = $params->{n_steps};
		if ( $n_steps < 1 ) {
			return ("No simulation output requested: set n_steps>0");
		}
		if ( defined( $params->{t_end} ) ) {
			$t_end = $params->{t_end};
		}
		else {
			return ("Parameter t_end must be defined");
		}
		$command .= " -sim ${t_end} -oSteps ${n_steps}";
	}
	elsif ( defined( $params->{sample_times} ) ) {
		return ("sample_times not supported in this version of NFsim");
	}
	else {
		return ("No simulation output requested: set n_steps>0");
	}

	# Append the other command line arguments
	$command .= " " . $otherCommandLineParameters;

	# Turn on complex bookkeeping if requested
	# TODO: Automatic check for turning this on
	if ($complex) { $command .= " -cb"; }
	if ($verbose) { $command .= " -v"; }

	print "Running NFsim on ", `hostname`;
	print "full command: $command\n";

	# Compute timecourses using nfsim
	local ( *Reader, *Writer, *Err );
	if ( !( $pid = open3( \*Writer, \*Reader, \*Err, "$command" ) ) ) {
		return ("$command failed: $?");
	}
	my $last = "";
	while (<Reader>) {
		print;
		$last = $_;
	}
	( my @err = <Err> );

	close Writer;
	close Reader;
	close Err;
	waitpid( $pid, 0 );

	if (@err) {
		print "Error log:\n", @err;
		return ("$command\n  did not run successfully.");
	}

    # Update final species concentrations to allow trajectory continuation
    if (my $err= $model->readNFspecies("${prefix}.species")){ 
        return($err);
    }
    print $model->SpeciesList->writeBNGL( $model->Concentrations, $model->ParamList, 0);

    $model->Time($t_end);
	return ("");
}



###
###
###



sub writeNET
{
	my $model = shift;
	my $params = (@_) ? shift(@_) : '';

	my %vars = (
		'simple' => 0,
		'prefix' => $model->Name,
		'suffix' => ''
	);
	my %vars_pass = (
		'TextReaction' => '',
		'NETfile'      => '1'
	);

	for my $key ( keys %$params ) {
		if ( defined( $vars{$key} ) ) {
			$vars{$key} = $params->{$key};
			if ( defined( $vars_pass{$key} ) ) {
				$vars_pass{$key} = $params->{$key};
			}
		}
		elsif ( defined( $vars_pass{$key} ) ) {
			$vars_pass{$key} = $params->{$key};
		}
		else {
			die "Unrecognized parameter $key in writeNET";
		}
	}

	return ("") if $NO_EXEC;

	my $suffix = $vars{suffix};
	my $prefix = $vars{prefix};
	my $simple = $vars{simple};
	if ( $suffix ne "" ) {
		$prefix .= "_${suffix}";
	}
	my $file = "${prefix}.net";

	unless ( $model->RxnList )
	{
	    return ( "writeNET() has nothing to do: no reactions in current model.\n"
	            ."  Did you remember to call generate_network() before attempting to\n"
	            ."  write network output?");
	}

	# Print network to file
	open( out, ">$file" ) || return ("Couldn't write to $file: $!\n");
	if ($simple) {
		print out $model->writeSimpleBNGL();
	}
	else {
		print out $model->writeBNGL( \%vars_pass );
	}
	close(out);
	print "Wrote network to $file.\n";
	$model->UpdateNet(0);

	return ("");
}



###
###
###



# Function to require the version conform to specified requirement
# Syntax: version(string);
# string= major[.minor][.dist][+-]

# major, minor, and dist. indicate the major, minor, and distribution number
# respectively against which the BioNetGen version numbers will be compared.
# + indicates version should be the specified version or later (default)
# - indicates version should be the specified version or earlier

sub version
{
	my $model   = shift;
	my $vstring = shift;

	return ("") if $NO_EXEC;

	if (@_) {
		return ("Additional arguments to function version.");
	}

	# Determine whether specified version is upper or lower bound
	my $crit = 1;
	if ( $vstring =~ s/([+-])$// ) {
		$crit = $1 . "1";
	}

	# Process requested version
	my @version;
	@version = ();
	my $sstring = $vstring;
	while ( $sstring =~ s/^(\d+)[.]?// ) {
		push @version, $1;
	}
	if ($sstring) {
		return ("String $vstring is an invalid version number specification.");
	}

	# Convert version to 15 digit number
	my $r_number = sprintf "%05d%05d%05d", @version;

	# Determine current version of BNG
	my $bng_string = BNGversion();
	my ( $major, $minor, $rel ) = split( '\.', $bng_string );

    # Increment release if '+' appended to increment development version to next release.
	if ( $rel =~ s/[+]$// ) {
		++$rel;
	}
	my $bng_number = sprintf "%05d%05d%05d", $major, $minor, $rel;

	if ( $crit > 0 ) {
		if ( $bng_number < $r_number ) {
			return ( "This file requires BioNetGen version $vstring or later.  Active version is $bng_string." );
		}
	}
	else {
		if ( $bng_number > $r_number ) {
			return ( "This file requires BioNetGen version $vstring or earlier. Active version is $bng_string." );
		}
	}

	# Add current version requirement to the model
	push @{ $model->Version }, $vstring;

	return ("");
}



###
###
###



sub findExec
{
	use Config;
	my $prog = shift;

	my $exec = BNGpath( "bin", $prog );

	# First look for generic binary in BNGpath
	if ( -x $exec ) {
		return ($exec);
	}

	my $arch = $Config{myarchname};

	# Currently recognized values of $arch are
	# i686-linux, ppc-darwin, MSWin32

	# Then look for os specific binary
	$exec .= "_" . $arch;

	if ( $arch =~ /MSWin32/ ) {
		$exec .= ".exe";
	}

	if ( -x $exec ) {
		return ($exec);
	}
	else {
		print "findExec: $exec not found.\n";
		return ("");
	}
}



###
###
###



sub LinearParameterSensitivity
{
    #This function will perform a brute force linear sensitivity analysis
    #bumping one parameter at a time according to a user specified bump
    #For each parameter, simulations are saved as:
    #'netfile_paramname_suffix.(c)(g)dat', where netfile is the .net model file
    #and paramname is the bumped parameter name, and c/gdat files have meaning as normal

	######################
	#NOT IMPLEMENTED YET!!
	#Additional files are written containing the raw sensitivity coefficients
	#for each parameter bump
	#format: 'netfile_paramname_suffix.(c)(g)sc'
	#going across rows is increasing time
	#going down columns is increasing species/observable index
	#first row is time
	#first column is species/observable index
	######################

	#Starting time assumed to be 0

    #Input Hash Elements:
    #REQUIRED PARAMETERS
    #net_file:  the base .net model to work with; string;
    #t_end:  the end simulation time; real;
    #OPTIONAL PARAMETERS
    #bump:  the percentage parameter bump; real; default 5%
    #inp_ppert:  model input parameter perturbations; hash{pnames=>array,pvalues=>array};
    #default empty
    #inp_cpert:  model input concentration perturbations; hash{cnames=>array,cvalues=>array};
    #default empty
    #stochast:  simulate_ssa (1) or simulate_ode (0) is used; boolean; default 0 (ode)
    #CANNOT HANDLE simulate_ssa CURRENTLY
    #sparse:    use sparse methods for integration?; boolean; 1
    #atol:  absolute tolerance for simulate_ode; real; 1e-8
    #rtol:  relative tolerance for simulate_ode; real; 1e-8
    #init_equil:  equilibrate the base .net model; boolean; default 1 (true)
    #re_equil:  equilibrate after each parameter bump but before simulation; boolean; default 1 (true)
    #n_steps:  the number of evenly spaced time points for sensitivity measures; integer;
    #default 50
    #suffix:  added to end of filename before extension; string; default ""

	#Variable Declaration and Initialization
	use strict;
	my $model;     #the BNG model
	my %params;    #the input parameter hash table
	my $net_file = "";
	my %inp_pert;
	my $t_end;
	my %readFileinputs;
	my %simodeinputs;
	my $simname;
	my $basemodel = BNGModel->new();
	my $plist;
	my $param_name;
	my $param_value;
	my $new_param_value;
	my $pperts;
	my $cperts;
	my $pert_names;
	my $pert_values;
	my $pert_names;
	my $pert_values;
	my $newbumpmodel = BNGModel->new();
	my $foo;
	my $i;

	#Initialize model and input parameters

	my $model  = shift;
	my $params = shift;

	#Required params
	if ( defined( $params->{net_file} ) ) {
		$net_file = $params->{net_file};
	}
	else {
		$net_file = $model->Name;
	}
	if ( defined( $params->{t_end} ) ) {
		$t_end = $params->{t_end};
	}
	else {
		return ("t_end not defined");
	}

	#Optional params
	my $bump     = ( defined( $params->{bump} ) )     ? $params->{bump}     : 5;
	my $stochast = ( defined( $params->{stochast} ) ) ? $params->{stochast} : 0;
	my $sparse   = ( defined( $params->{sparse} ) )   ? $params->{sparse}   : 1;
	my $atol = ( defined( $params->{atol} ) ) ? $params->{atol} : 1e-8;
	my $rtol = ( defined( $params->{rtol} ) ) ? $params->{rtol} : 1e-8;
	my $init_equil =
	  ( defined( $params->{init_equil} ) ) ? $params->{init_equil} : 1;
	my $t_equil = ( defined( $params->{t_equil} ) ) ? $params->{t_equil} : 1e6;
	my $re_equil = ( defined( $params->{re_equil} ) ) ? $params->{re_equil} : 1;
	my $n_steps = ( defined( $params->{n_steps} ) ) ? $params->{n_steps} : 50;
	my $suffix  = ( defined( $params->{suffix} ) )  ? $params->{suffix}  : "";

	#Run base case simulation
	%readFileinputs = ( file => "$net_file.net" );
	$basemodel->readFile( \%readFileinputs );

	#if initial equilibration is required
	if ($init_equil) {
		$simname      = "_baseequil_";
		%simodeinputs = (
			prefix       => "$net_file$simname$suffix",
			t_end        => $t_equil,
			sparse       => $sparse,
			n_steps      => $n_steps,
			steady_state => 1,
			atol         => $atol,
			rtol         => $rtol
		);
		$basemodel->simulate_ode( \%simodeinputs );
	}
	$simname      = "_basecase_";
	%simodeinputs = (
		prefix       => "$net_file$simname$suffix",
		t_end        => $t_end,
		sparse       => $sparse,
		n_steps      => $n_steps,
		steady_state => 0,
		atol         => $atol,
		rtol         => $rtol
	);

	#Implement input perturbations
	if ( defined( $params->{inp_ppert} ) ) {
		$pperts      = $params->{inp_ppert};
		$pert_names  = $pperts->{pnames};
		$pert_values = $pperts->{pvalues};
		$i           = 0;
		while ( $pert_names->[$i] ) {
			$param_name  = $pert_names->[$i];
			$param_value = $pert_values->[$i];
			$basemodel->setParameter( $param_name, $param_value );
			$i = $i + 1;
		}
	}
	if ( defined( $params->{inp_cpert} ) ) {
		$cperts      = $params->{inp_cpert};
		$pert_names  = $cperts->{cnames};
		$pert_values = $cperts->{cvalues};
		$i           = 0;
		while ( $pert_names->[$i] ) {
			$param_name  = $pert_names->[$i];
			$param_value = $pert_values->[$i];
			$basemodel->setConcentration( $param_name, $param_value );
			$i = $i + 1;
		}
	}
	$basemodel->simulate_ode( \%simodeinputs );

	$plist = $basemodel->ParamList;

	#For every parameter in the model
	for my $model_param ( @{ $plist->Array } ) {
		$param_name      = $model_param->Name;
		$param_value     = $model_param->evaluate();
		$new_param_value = $param_value * ( 1 + $bump / 100 );

		#Get fresh model and bump parameter
		$newbumpmodel->readFile( \%readFileinputs );
		$newbumpmodel->setParameter( $param_name, $new_param_value );

		#Reequilibrate
		if ($re_equil) {
			$simname = "_equil_$param_name", "_";
			%simodeinputs = (
				prefix       => "$net_file$simname$suffix",
				t_end        => $t_equil,
				sparse       => $sparse,
				n_steps      => $n_steps,
				steady_state => 1,
				atol         => $atol,
				rtol         => $rtol
			);
			$newbumpmodel->simulate_ode( \%simodeinputs );
		}

		#Implement input and run simulation
		$simname = "_$param_name", "_";
		%simodeinputs = (
			prefix       => "$net_file$simname$suffix",
			t_end        => $t_end,
			sparse       => $sparse,
			n_steps      => $n_steps,
			steady_state => 0,
			atol         => $atol,
			rtol         => $rtol
		);
		if ( defined( $params->{inp_ppert} ) ) {
			$pperts      = $params->{inp_ppert};
			$pert_names  = $pperts->{pnames};
			$pert_values = $pperts->{pvalues};
			$i           = 0;
			while ( $pert_names->[$i] ) {
				$param_name  = $pert_names->[$i];
				$param_value = $pert_values->[$i];
				$newbumpmodel->setParameter( $param_name, $param_value );
				$i = $i + 1;
			}
		}
		if ( defined( $params->{inp_cpert} ) ) {
			$cperts      = $params->{inp_cpert};
			$pert_names  = $cperts->{cnames};
			$pert_values = $cperts->{cvalues};
			$i           = 0;
			while ( $pert_names->[$i] ) {
				$param_name  = $pert_names->[$i];
				$param_value = $pert_values->[$i];
				$newbumpmodel->setConcentration( $param_name, $param_value );
				$i = $i + 1;
			}
		}
		$newbumpmodel->simulate_ode( \%simodeinputs );

		#Evaluate sensitivities and write to file

		#Get ready for next bump
		$newbumpmodel = BNGModel->new();
	}

  
}


sub readNFspecies 
{
    # This function reads a list of species strings from NFsim output to form a 
    # canonical species list with correct concentrations. Note that it overwritees
    # any existing species.
    my $model= shift;
    my $fname= shift;

	# Species
	my @Conc=();
	if ($model->SpeciesList){
	    @Conc = (0)x scalar(@{$model->SpeciesList->Array});
	} else {
	    $model->SpeciesList(SpeciesList->new);
	}
    my $slist= $model->SpeciesList;

	# Allow new types?
	my $AllowNewTypes = 1;

	# Read NFsim species file
	print "readNFspecies::Reading from file $fname\n";
	if ( !open( FH, $fname ) ) {
			return ("Couldn't read from file $fname: $!");
	}

    my $n_spec_read=0;
    my $n_spec_new=0;
    my $line_num=0;
	while (my $string=<FH>)
	{
        ++$line_num;
		chomp($string);
		$string =~ s/\#.*$//;    # remove comments
		next unless $string =~ /\S+/;    # skip blank lines

        # Read species string
        $sg = SpeciesGraph->new;
        $string =~ s/^\s+//;
        $err = $sg->readString( \$string, $model->CompartmentList, 1, '^\s+', 
                                $model->MoleculeTypesList, $AllowNewTypes );
        if ($err) { return ($err."at line $line_num of file $name"); }

        # Read species concentration - may only be integer value
        my $conc;
        if ( $string=~ /^\s*(\d+)\s*$/ )
        {
            $conc=$1;
        }
        else
        {
            return ("species concnetration must be single integer at line $line_num of file $fname");        
        }

        # Check if isomorphic to existing species 
        my $existing= $slist->lookup($sg);
        if($existing){
            # Add concentration to concentration of existing species
            $Conc[$existing->Index - 1]+= $conc;            
        } else {
            # Create new Species entry in SpeciesList with zero default concentration
            my $newspec= $slist->add($sg, 0);
            $Conc[$newspec->Index - 1]= $conc;
            ++$n_spec_new;
        }
        ++$n_spec_read;
    }
    
	$model->Concentrations([@Conc]);
    printf "Read %d unique species of %d total.\n", $n_spec_new, $n_spec_read;
	return("");
}



###
###
###

1;

