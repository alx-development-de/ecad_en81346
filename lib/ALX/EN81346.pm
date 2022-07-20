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

use Data::Dumper;

sub segments($;) {
	my $string = shift();
	print("To Analyze: [$string]\n");

	# Splitting the string into segments according the prefix
	print("Segmenting 1:\n");
	my @matches = $string =~ m/([+=-]+[0-9a-zA-Z.]+)/gi;
	print Dumper @matches;

	# Looking for subsegments in the separate segments and splitting
	# them into individual segments
	print("Segmenting 2:\n");
	foreach my $segment (@matches){
		my @subsegments = $segment =~ m/([+=-]+)([0-9a-zA-Z.]+)+/gi;
		# TODO: Subsegments must be split if the dot-notation is used
		print Dumper @subsegments;
	}

	print("After\n");
	return "OK";
}
#------------------------------------------------------------------------------------------------
1;