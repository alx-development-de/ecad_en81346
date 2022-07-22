#
# ALX::EN81346 - Basic function implementation to handle
# identifier string according the EN81346 specification.
#
package ALX::EN81346;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    segments,
    sort
);

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;

use Log::Log4perl ();
use Log::Log4perl::Level ();

# Initializing the logging if not already specified by the application
# which uses the module
BEGIN {
	if (not Log::Log4perl->initialized()) {
    	Log::Log4perl->easy_init(Log::Log4perl::Level::to_priority('OFF'));
	}
}

# The ID prefixes is used to check if the ids are valid and to
# configure the sort order for the string representation
my %id_prefixes = ( ':' => 0, '-' => 1, '+' => 2, '=' => 3 );

sub segments($;) {
    my $string = shift();
	Log::Log4perl->get_logger->debug("Segmenting string value: [$string]");

    # Initializing the returned hash structure
    my %segments;

    # Splitting the string into segments according the prefix
    my @matches = $string =~ m/([+:=-]+[0-9a-zA-Z.]+)/gi;

    # Looking for subsegments in the separate segments and splitting
    # them into individual segments
    foreach (@matches) {
        my ($identifier, $value) = $_ =~ m/([+:=-]+)([0-9a-zA-Z.]+)+/gi;
        #print "Segments identified   : [$identifier] - [$string]\n";

        # Subsegments must be split if the dot-notation is used
        my @subsegments = $value =~ m/([0-9a-zA-Z]+)\.?/gi;

        # Building the structure for each identifier in a key-value pairing.
        # As key the identifier is used and the value is an array with the
        # sorted values as array
        $segments{$identifier} = [] unless defined $segments{$identifier};
        $segments{$identifier} = [ @{$segments{$identifier}}, @subsegments ];
    }
    # Returning the segment structure
    return \%segments;
}

sub to_string($;) {
    # TODO: Not sure if this is the correct way to handle hash references
    my %segments = %{shift()};

    my $string_representation = '';
    foreach my $key (ALX::EN81346::sort(keys(%segments))) {
        $string_representation .= $key . join('.', @{$segments{$key}})
    };
    return $string_representation;
}

sub is_valid($;) {
    return $_[0] =~ m/^(([+=-]+|:)[0-9a-zA-Z.]+)+$/gi;
}

sub sort {
    # Return the sorted array of given IDs
    return sort compare_id @_;
}

# compare two numbers
sub compare_id {
    my( $first, $second ) = ( $a, $b );

	Log::Log4perl->get_logger->debug("Comparing input $first and $second");

    # Transforming the literals to numeric values to sort them using
    # simple number comparison
	if ( $first =~ m/([+:=-]).*/g ) {
        $first = $id_prefixes{$1} +  length($first) * 0.001;
        Log::Log4perl->get_logger->debug('Result of $x $1: '."[$1]->[$first]");
    } else {
        carp "Not a valid ID provided for comparison: [$first]";
    }

	if ( $second =~ m/([:+=-]).*/g ) {
        $second = $id_prefixes{$1} + length($second) * 0.001;
        Log::Log4perl->get_logger->debug('Result of $y $1: '."[$1]->[$second]");
    } else {
        carp "Not a valid ID provided for comparison: [$second]";
    }

    # Doing the comparison if the transformation has been successfully finished
    if( defined($first) && defined($second) ) {
        Log::Log4perl->get_logger->debug("Comparing $first and $second");

        # Doing the comparison
        if    ( $first > $second ) { return -1; }
        elsif ( $first < $second ) { return  1; }
        elsif ( $first == $second ) { return 0; }

    } else {
        croak "ID Comparison failed!";
    }
}

#------------------------------------------------------------------------------------------------
1;