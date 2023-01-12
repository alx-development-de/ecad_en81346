use strict;
use warnings;

use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'ECAD::EN81346',
    AUTHOR        => q{Alexander Thiel <alex@alx-development.de>},
    VERSION_FROM  => 'lib/ECAD/EN81346.pm',
    ABSTRACT      => 'Interpreter for EN81346 encoded technical reference identifiers',
    LICENSE       => 'mit',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Log::Log4perl' => 1.55,
    },
    TEST_REQUIRES => {
        'Test::More' => 1.001014,
    },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/alx-development-de/ecad_en81346.git',
                web  => 'https://github.com/alx-development-de/ecad_en81346',
            },
            bugtracker => { web => 'https://github.com/alx-development-de/ecad_en81346/issues' },
            homepage   => 'https://alx-development.de/',
        },
    },
);
