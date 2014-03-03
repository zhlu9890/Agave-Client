use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Agave::Client',
    license             => 'perl',
    dist_author         => q{Cornel Ghiban <cghiban@gmail.com>},
    dist_version_from   => 'lib/Agave/Client.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Agave-Client-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
