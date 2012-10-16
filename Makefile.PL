use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::EJS',
    AUTHOR              => q{Mahiro Ando <mahiro@cpan.org>},
    VERSION_FROM        => 'lib/Template/EJS.pm',
    ABSTRACT_FROM       => 'lib/Template/EJS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'IO::Scalar' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-EJS-*' },
);
