#
# ECAD::EN81346 - Basic function implementation to handle
# identifier string according the EN81346 specification.
#
package ECAD::EN81346;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(segments sort concat is_valid);

our $VERSION = '0.02';

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
        Log::Log4perl->easy_init(Log::Log4perl::Level::to_priority('WARN'));
    }
}

# The ID prefixes is used to check if the ids are valid and to
# configure the sort order for the string representation
my %id_prefixes = (':' => 0, '-' => 1, '+' => 2, '=' => 3);

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
    # Initializing the returned hash structure
    my %segments;

    unless (length($string)) {
        Log::Log4perl->get_logger->warn("Empty string passed to subroutine, exiting without segmenting");
        return;
    }

    Log::Log4perl->get_logger->trace("Segmenting string value: [$string]");

    # Splitting the string into segments according the prefix
    my @matches = $string =~ m/([+:=-]+[0-9a-zA-Z._]+)/gi;

    # Looking for subsegments in the separate segments and splitting
    # them into individual segments
    foreach (@matches) {
        my ($identifier, $value) = $_ =~ m/([+:=-]+)([0-9a-zA-Z._]+)+/gi;

        # Removing all elements from the identifier which do not match with the last
        # character of the identifier. This is to avoid identifier with multiple
        # characters. See also  #6
        # TODO: If the connection point is marked with an identifier character (e.g. + or -) it fails!
        my $identifier_char = substr($identifier, -1);
        $identifier =~ s/^[^$identifier_char]//;

        Log::Log4perl->get_logger->trace("Segments id:[$identifier] val:[$value] detected from [$string]");

        # Subsegments must be split if the dot-notation is used
        my @subsegments = ($value =~ m/([0-9a-zA-Z_]+)\.?/gi);

        # Building the structure for each identifier
        %segments = concat(\%segments, $identifier, \@subsegments);
    }
    # Returning the segment structure
    return %segments;
}

=pod

=head2 base($string, $string)

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

sub base($$;) {
    my ($base, $reference) = @_;

    my %base_segments = segments($base);
    my %reference_segments = segments($reference);
    my %result_segments = ();

    foreach my $identifier (keys(%reference_segments)) {
        my ($base_string, $reference_string);
        $reference_string = join('.', @{$reference_segments{$identifier}});
        if (defined($base_segments{$identifier})) {
            $base_string = join('.', @{$base_segments{$identifier}});
            Log::Log4perl->get_logger->trace("Comparing Identifier [$identifier] " .
                "on base [$base_string] and reference " .
                "[$reference_string]");
            # Adding the segment to the result string, if not equal to the reference
            # in the base
            $result_segments{$identifier} = $reference_segments{$identifier}
                unless ($base_string eq $reference_string);
        }
        else {
            Log::Log4perl->get_logger->trace("Not contained in base reference [${identifier}${reference_string}]");
            $result_segments{$identifier} = $reference_segments{$identifier};
        }
    }
    # Returning the different elements in segment structure
    return &to_string(\%result_segments);
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
    my ($segments_ref, $identifier, $subsegments_ref) = @_;
    my %segments = %{$segments_ref};

    foreach my $subsegment (@$subsegments_ref) {
        Log::Log4perl->get_logger->trace("Adding [$subsegment] to the identifier [$identifier] in concat");

        # Building the structure for each identifier in a key-value pairing.
        # As key the identifier is used and the value is an array with the
        # sorted values as array
        $segments{$identifier} = [] unless defined $segments{$identifier};
        $segments{$identifier} = [ @{$segments{$identifier}}, $subsegment ];
    }

    return %segments;
}

=pod

=head2 to_string($;$)

This function returns the string representation of the segment structure given
by the $segments reference. The string is ordered by the identifier and uses
the dot notation for multi level identifier.

    my $input_string = "==200=A1.23=100==ABC+200-300";
    my %identifier = ALX::EN81346::segments($input_string);
    print(ALX::EN81346::to_string(\%identifier));

Will result in the following string:

    ==200.ABC=A1.23.100+200-300

As parameter you may pass a hash reference to a segments hash as first parameter
or alternative a string, which is internally converted to it's segments hash.

As second parameter an optional identifier may be supplied. if this value is provided
only the segment identified by this is returned as string.

    my $input_string = "==200=A1.23=100==ABC+200-300";
    print(ALX::EN81346::to_string($input_string, '=='));

Will result in the following string:

    ==200.ABC
=cut

sub to_string($;$) {
    my ($args, $identifier) = @_;
    my %segments;

    # Checking, whether the passed argument is a reference
    # or a string.
    if (ref($args) eq 'HASH') {
        %segments = %{$args};
    }
    else {
        %segments = &segments($args);
    }

    my $string_representation = '';
    foreach my $key (&sort(keys(%segments))) {
        if ($identifier && $key ne $identifier) {next;}
        $string_representation .= $key . join('.', @{$segments{$key}});
    };
    return $string_representation;
}

sub to_string2($;$) {
    my ($args, $identifier) = @_;
    my %segments;

    # Checking, whether the passed argument is a reference
    # or a string.
    if (ref($args) eq 'HASH') {
        %segments = %{$args};
    }
    else {
        %segments = &segments($args);
    }

    my $string_representation = '';
    foreach my $key (&sort(keys(%segments))) {
        if ($identifier && $key ne $identifier) {next;}
        $string_representation .= $key . join($key, @{$segments{$key}});
    };
    return $string_representation;
}

sub to_string3($;$) {
    my ($args, $identifier) = @_;
    my %segments;

    # Checking, whether the passed argument is a reference
    # or a string.
    if (ref($args) eq 'HASH') {
        %segments = %{$args};
    }
    else {
        %segments = &segments($args);
    }

    my $string_representation = '';
    foreach my $key (&sort(keys(%segments))) {
        if ($identifier && $key ne $identifier) {next;}
        # Building the string representation in mixed mode. This means, if an element
        # only contains numbers it will divides by a dot instead the key delimiter.
        # The $level counter is used to ensure, the first element of a representation is always
        # leading by the full delimiter and not the dot notation
        my $level = 0;
        foreach my $segment ( @{$segments{$key}} ) {
            my $delimiter = $segment =~ m/^[0-9]+$/ && $level > 0 ? '.' : $key;
            $string_representation .= $delimiter . $segment;
            $level++;
        }
    };
    return $string_representation;
}

=pod

=head2 is_valid($string)

This function simply checks if the given string is a valid identifier string according
the IEC 81346 standard.

=cut

sub is_valid($;) {
    return $_[0] =~ m/^(([+=-]+|:)[0-9a-zA-Z._]+)+$/gi;
}

=pod

=head2 sort(@identifier)

This function returns a sorted array of identifiers. Pass a list of identifiers to
the array and they will be ordered according its prefix.

B<Example>:
Passing the following array:

    ['-S11', '+CAB', ='AN1', '++SEG01']

Will produce the following returned array:

    ['=AN1', '++SEG01', '+CAB', '-S11']

=cut

sub sort {
    # Return the sorted array of given IDs
    return sort compare_id @_;
}

# compare two numbers
sub compare_id {
    my ($first, $second) = ($a, $b);

    Log::Log4perl->get_logger->trace("Comparing input $first and $second");

    # Transforming the literals to numeric values to sort them using
    # simple number comparison
    if ($first =~ m/([+:=-]).*/g) {
        $first = $id_prefixes{$1} + length($first) * 0.001;
        Log::Log4perl->get_logger->trace('Result of $x $1: ' . "[$1]->[$first]");
    }
    else {
        carp "Not a valid ID provided for comparison: [$first]";
    }

    if ($second =~ m/([:+=-]).*/g) {
        $second = $id_prefixes{$1} + length($second) * 0.001;
        Log::Log4perl->get_logger->trace('Result of $y $1: ' . "[$1]->[$second]");
    }
    else {
        carp "Not a valid ID provided for comparison: [$second]";
    }

    # Doing the comparison if the transformation has been successfully finished
    if (defined($first) && defined($second)) {
        Log::Log4perl->get_logger->trace("Comparing $first and $second");

        # Doing the comparison
        if ($first > $second) {return -1;}
        elsif ($first < $second) {return 1;}
        elsif ($first == $second) {return 0;}

    }
    else {
        croak "ID Comparison failed!";
    }
}

#------------------------------------------------------------------------------------------------
1;