use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Pastebin::NoPasteCom::Create',
    license             => 'perl',
    dist_author         => q|Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/WWW/Pastebin/NoPasteCom/Create.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Carp'                  => 1.04,
        'URI'                   => 1.37,
        'LWP::UserAgent'        => 5.823,
        'HTTP::Request::Common' => 5.822,
        'Class::Data::Accessor' => 0.04001,
        'overload'              => 1.04,
    },
    add_to_cleanup      => [ 'WWW-Pastebin-NoPasteCom-Create-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
