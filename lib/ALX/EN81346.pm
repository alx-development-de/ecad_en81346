#
# ALX::EN81346 - Basic function implementation to handle
# identifier string according the EN81346 specification.
#
package ALX::EN81346;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
					segments
				);

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;

use Log::Log4perl ();
use Log::Log4perl::Level ();
use Data::Dumper::Perltidy;

# Initializing the logging if not already specified by the application
# which uses the module
if (not Log::Log4perl->initialized()) {
        Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority( 'OFF' ) );
    }

sub segments($;) {
	my $string = shift();

	my $logger = Log::Log4perl->get_logger();
	$logger->debug("Segmenting string value: [$string]");

	# Initializing the returned hash structure
	my %segments;

	# Splitting the string into segments according the prefix
	my @matches = $string =~ m/([+=-]+[0-9a-zA-Z.]+)/gi;

	# Looking for subsegments in the separate segments and splitting
	# them into individual segments
	foreach (@matches){
		my ($identifier, $value) = $_ =~ m/([+=-]+)([0-9a-zA-Z.]+)+/gi;
		#print "Segments identified   : [$identifier] - [$string]\n";

		# Subsegments must be split if the dot-notation is used
		my @subsegments = $value =~ m/([0-9a-zA-Z]+)\.?/gi;

		# Building the structure for each identifier in a key-value pairing.
		# As key the identifier is used and the value is an array with the
		# sorted values as array
		$segments{$identifier} = [] unless defined $segments{$identifier};
		$segments{$identifier} = [@{$segments{$identifier}}, @subsegments];
	}
	# Returning the segment structure
	return \%segments;
}

sub to_string($;) {
	# TODO: Not sure if this is the correct way to handle hash references
	my %segments = %{shift()};

	my $string_representation = '';
	# TODO: Need to implement some sorting algorithm for the identifiers
	foreach my $key (keys(%segments)){
		$string_representation .= $key.join('.', @{$segments{$key}})
	};
	return $string_representation;
}

#------------------------------------------------------------------------------------------------
1;