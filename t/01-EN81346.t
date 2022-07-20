#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use ALX::EN81346;

use Log::Log4perl;

Log::Log4perl->init("conf/log_test.ini");

#my $interpreter = ALX::EN81346->new("=100+200-300");

ok(ALX::EN81346::segments("=100+200-300") eq "OK");

done_testing();

