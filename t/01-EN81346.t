#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use ALX::EN81346;

use Log::Log4perl;

Log::Log4perl->init("conf/log_test.ini");

#my $interpreter = ALX::EN81346->new("=100+200-300");

ok(ALX::EN81346::segments('==FZ910=113++CAB+1CC01-X8.1:13') eq "OK");
ok(ALX::EN81346::segments('==AbC910=113+1CC01.CAB-X9.1:13') eq "OK");
ok(ALX::EN81346::segments('=FUNC+1MCC01.CAB-X9.1:13') eq "OK");
ok(ALX::EN81346::segments('=100+110-X1') eq "OK");
ok(ALX::EN81346::segments('=100+110-X2') eq "OK");

done_testing();
