use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::NiigataUnyu',
    AUTHOR              => 'OONO Yoshitaka <aab61120@pop12.odn.ne.jp>',
    VERSION_FROM        => 'lib/WebService/NiigataUnyu.pm',
    ABSTRACT_FROM       => 'lib/WebService/NiigataUnyu.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-NiigataUnyu-*' },
);
