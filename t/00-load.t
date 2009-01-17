#!/usr/bin/env perl

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('URI');
    use_ok('LWP::UserAgent');
    use_ok('HTTP::Request::Common');
    use_ok('Class::Data::Accessor');
    use_ok('overload');
	use_ok( 'WWW::Pastebin::NoPasteCom::Create' );
}

diag( "Testing WWW::Pastebin::NoPasteCom::Create $WWW::Pastebin::NoPasteCom::Create::VERSION, Perl $], $^X" );
