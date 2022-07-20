package ALX::EN81346::Identifier;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.01';

#use Carp;
use Log::Log4perl;

sub new($;$) {
    my $class = shift();
    my $source_string = shift();

    my $self = {
        _string      => $source_string,
        logger       => Log::Log4perl::get_logger("ALX::EN81346")
    };

	$self->{logger}->info("Identifier parsing for [$source_string] initialized");

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