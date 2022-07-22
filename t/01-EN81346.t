#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use Log::Log4perl;
Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority( 'OFF' ) );

require_ok( 'ALX::EN81346' );
# Testing the simple structure detection without duplicate identifiers (multi-level structures)
is_deeply( ALX::EN81346::segments('=100+110-X1'), {
    '='  => [ '100' ],
    '+'  => [ '110' ],
    '-'  => [ 'X1' ]
}, "EN81346 Simple structure");
is_deeply( ALX::EN81346::segments('=100+110-X2'), {
    '='  => [ '100' ],
    '+'  => [ '110' ],
    '-'  => [ 'X2' ]
}, "EN81346 Simple structure");
# Testing multi-level structures with different approaches
is_deeply( ALX::EN81346::segments('==AbC910==23AX=113=aBc+1CC01+CAB-X9-7'), {
    '==' => [ 'AbC910', '23AX' ],
    '='  => [ '113', 'aBc' ],
    '+'  => [ '1CC01', 'CAB' ],
    '-'  => [ 'X9', '7' ]
}, "EN81346 deep structure with multiple identifiers")
    || diag explain ALX::EN81346::segments('==AbC910==23AX=113=aBc+1CC01+CAB-X9-7');
is_deeply( ALX::EN81346::segments('==AbC910.23AX=113.aBc+1CC01.CAB-X9.7'), {
    '==' => [ 'AbC910', '23AX' ],
    '='  => [ '113', 'aBc' ],
    '+'  => [ '1CC01', 'CAB' ],
    '-'  => [ 'X9', '7' ]
}, "EN81346 deep structure with dot separator")
    || diag explain ALX::EN81346::segments('==AbC910.23AX=113.aBc+1CC01.CAB-X9.7');
is_deeply( ALX::EN81346::segments('==AbC910+1CC01=113+CAB-X9==23AX-7=aBc'), {
    '==' => [ 'AbC910', '23AX' ],
    '='  => [ '113', 'aBc' ],
    '+'  => [ '1CC01', 'CAB' ],
    '-'  => [ 'X9', '7' ]
}, "EN81346 deep structure with scrambled identifiers")
    || diag explain ALX::EN81346::segments('==AbC910+1CC01=113+CAB-X9==23AX-7=aBc');

TODO: {
    local $TODO = "The connector pin must also been detected with the colon as identifier";
    is_deeply( ALX::EN81346::segments('==FZ910=113++CAB+1CC01-X8.1:13'), {
        '==' => [ 'FZ910' ],
        '++' => [ 'CAB' ],
        '='  => [ '113' ],
        '+'  => [ '1CC01' ],
        '-'  => [ 'X8', '1' ],
        ':'  => [ '13' ]
    }, "Connector pin detection with colon seperator")
        || diag explain ALX::EN81346::segments('==FZ910=113++CAB+1CC01-X8.1:13');
}

# Testing the sort implementation of the ID sorting
my @tests = (
    {
        'unsorted' => ['-', '+', '='],
        'sorted'   => ['=', '+', '-']
    },
    {
        'unsorted' => ['-', '--', '---'],
        'sorted'   => ['---', '--', '-']
    },
    {
        'unsorted' => ['+', '=', '==', '-', ':', '++++++++', '--', '---', '========'],
        'sorted'   => ['========', '==', '=', '++++++++', '+', '---', '--', '-', ':']
    }
);
for my $i (0 .. $#tests)
{
    my %test= %{$tests[$i]};
    my @sorted =  ALX::EN81346::sort(@{$test{'unsorted'}});
    is_deeply(\@sorted, \@{$test{'sorted'}}, 'ID sorting algorithm');
}

done_testing();
