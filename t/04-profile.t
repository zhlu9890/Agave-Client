#!/usr/bin/perl -w

use strict;
use Test::More;

my $TNUM = 11;
plan tests => $TNUM;

use FindBin;
use Data::Dumper;
use Agave::Client ();

my $conf_file = "$FindBin::Bin/agave-auth.json";

diag <<EOF


********************* WARNING ********************************
The t/agave-auth.json is missing. Here's the structure:
    {
        "username"  :"", 
        "password"  :"",
        "apisecret" :"",
        "apikey"    :""
    }

For more details go to http://agaveapi.co/authentication-token-management/


EOF
unless (-f $conf_file);

SKIP: {
    skip "Create the t/agave-auth.json file for tests to run", $TNUM
        unless (-f $conf_file);

    my $api = Agave::Client->new( config_file => $conf_file, debug => 0);

    ok( defined $api, "API object created");
    ok( defined $api->token, "Authentication succeeded" );

    unless ($api && $api->token) {
        skip "Auth failed. No reason to continue..", $TNUM - 2;
    }

    my $profile = $api->profile;
    ok(defined $profile, 'Profile endpoint succeeded defined');

    # get profile base on username
    my $up = $profile->list($api->username);
    #diag(Dumper($up));
    ok($up && 'HASH' eq ref $up, 'Retrieved profile');
    is(lc $up->{username}, lc $api->username, 'Profile  has the same username');

    # let's search by username
    my $sup = $profile->search({ username => $api->username });
    #diag(Dumper($sup));
    ok($sup && 'ARRAY' eq ref $sup, 'Got search results');
    is(scalar( @$sup ), 1, 'Got one probile as expected');
    is_deeply($$sup[0], $up, 'Got the same profile');

    # let's search by email address
    my $eup = $profile->search({ email => $up->{email} });
    #diag(Dumper($eup));
    ok($eup && 'ARRAY' eq ref $eup, 'Got search results');
    is(scalar(@$eup), 1, 'Got one probile as expected');
    is_deeply($sup, $eup, 'Got the same profile');

    done_testing();
}

