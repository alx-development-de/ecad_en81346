package ALX::EN81346;
our $VERSION = '0.01';

use strict;
use warnings;

use Carp;
use Log::Log4perl qw(get_logger :levels);

sub new($$;) {
    my $class = shift();
    my $source_string = shift();

    my $self = {
        _string      => $source_string,
        logger       => get_logger("EN81346")
    };

	$self->{logger}->debug("Identifier parsing for [$source_string] initialized");

    bless $self, $class;
    return $self;
}

# This function returns true, if a lock file for the project is existing. It is not proofed,
# if the lock is writable for the current user. Therefore use the function "is_writable".
sub get_string {
    my $self = shift();

    return $self->{_string};
}

#------------------------------------------------------------------------------------------------
1;