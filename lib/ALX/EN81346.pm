#
# ALX::EN81346 - Basic function implementation to handle
# identifier string according the EN81346 specification.
#
package ALX::EN81346;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    segments,
    sort,
    concat,
    is_valid
);

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;

use Log::Log4perl ();
use Log::Log4perl::Level ();

=pod

=encoding utf8

=head1 EN81346 Library

International Standard IEC/ISO 81346 series "Industrial systems, installations and equipment
and industrial products – structuring principles and reference designations" defines the rules
for reference designation systems (RDS).

This library is designed to help working with the reference designations structure and supplies
several functions to check and manipulate reference strings.

=cut

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

=pod

=head2 segments($string)

While working with the references it is very useful to have access to all
aspects directly. Therefore this function is splitting the complete reference
string into its aspect elements.

It returns a hash, with the identifier as keys and an array containing all
subelements for the identifier as value.

For example, the reference string "=112.345+CAB.EL01-X11" will result in a
structure like this:

    {
        '=' => ['112', '345'],
        '+' => ['CAB', 'EL01'],
        '-' => [X11]
    }

=cut

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
        my @subsegments = ( $value =~ m/([0-9a-zA-Z]+)\.?/gi );

        # Building the structure for each identifier
        %segments = concat( \%segments, $identifier, \@subsegments );
    }
    # Returning the segment structure
    return %segments;
}

=pod

=head2 concat($segments_ref, $identifier, $subsegments_ref)

This function adds the given subsegments by $subsegments_ref to the segment tree which
must be given as reference in $segments_ref.

    my $input_string = "==200=A1.23=100==ABC+200-300";
    my %segments = ALX::EN81346::segments($input_string);
    my @subsegments - ('ALX123', 'ALX8BB');
    %identifier = ALX::EN81346::concat(\%segments, '=', \@subsegments);

Results in the following segment string:

    ==200.ABC=A1.23.100.ALX123.ALX8BB+200-300

=cut

sub concat {
    my ( $segments_ref, $identifier, $subsegments_ref) = @_;
    my %segments = %{$segments_ref};

    foreach my $subsegment ( @$subsegments_ref ) {
        Log::Log4perl->get_logger->debug("Adding [$subsegment] to the identifier [$identifier] in concat");

        # Building the structure for each identifier in a key-value pairing.
        # As key the identifier is used and the value is an array with the
        # sorted values as array
        $segments{$identifier} = [] unless defined $segments{$identifier};
        $segments{$identifier} = [ @{$segments{$identifier}}, $subsegment ];
    }

    return %segments;
}

=pod

=head2 to_string($segments)

This function returns the string representation of the segment structure given
by the $segments reference. The string is ordered by the identifier and uses
the dot notation for multi level identifier.

    my $input_string = "==200=A1.23=100==ABC+200-300";
    my %identifier = ALX::EN81346::segments($input_string);
    print(ALX::EN81346::to_string(\%identifier));

Will result in the following string:

    ==200.ABC=A1.23.100+200-300

=cut

sub to_string($;) {
    # TODO: Not sure if this is the correct way to handle hash references
    my %segments = %{shift()};

    my $string_representation = '';
    foreach my $key (ALX::EN81346::sort(keys(%segments))) {
        $string_representation .= $key . join('.', @{$segments{$key}})
    };
    return $string_representation;
}

=pod

=head2 is_valid($string)

This function simply checks if the given string is a valid identifier string according
the IEC 81346 standard.

=cut

sub is_valid($;) {
    return $_[0] =~ m/^(([+=-]+|:)[0-9a-zA-Z.]+)+$/gi;
}

=pod

=head2 sort(@identifier)

This function returns a sorted array of identifiers. Pass a list of identifiers to
the array and they will be ordered according its prefix.

B<Example>:
Passing the following array:

    ['-S11', '+CAB', ='AN1', '++SEG01']

Will produce the following returned array:

    [='AN1', '++SEG01', '+CAB', '-S11']

=cut

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