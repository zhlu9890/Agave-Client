#!/usr/bin/env perl

use Test::More tests => 5;

BEGIN {
    use_ok( 'Agave::Client' );
    use_ok( 'Agave::Client::IO' );
    use_ok( 'Agave::Client::Auth' );
    use_ok( 'Agave::Client::Apps' );
    use_ok( 'Agave::Client::Job' );
}

diag( "Testing Agave::Client $Agave::Client::VERSION, Perl $], $^X" );
