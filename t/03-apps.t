#!/usr/bin/perl -w

use Test::More;

my $TNUM = 4;
plan tests => $TNUM;

use File::Temp ();
use File::Basename;
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

    my $apps = $api->apps;
    ok( defined $apps, "APPS endpoint successfully created");

    my @list = $apps->list;
    ok(scalar(@list) > 0, "Got a list of apps");

    my @list1_10 = $apps->list(limit => 10);
    is(scalar(@list1_10), 10, "Got top 10 apps");
    is($list[0]->id, $list1_10[0]->id, "App limiting works (take 1)");

    my @list11_10 = $apps->list(limit => 10, offset => 10);
    is(scalar(@list11_10), 10, "Got next 10 apps");
    is($list[10]->id, $list11_10[0]->id, "App limiting works (take 2)");
}
