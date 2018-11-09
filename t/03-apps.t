#!/usr/bin/perl -w

use Test::More;

use Env qw(AGAVE_APPID AGAVE_USERNAME);

my $TNUM = 18;
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
        skip "Auth failed. No reason to continue..", $TNUM - 4;
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



	unless (defined $AGAVE_APPID && $AGAVE_APPID) {
        skip "Agave app not defined", 10;
    }
    else {
        my $pems = $apps->pems($AGAVE_APPID);
        ok(ref $pems eq 'ARRAY', 'Got back an array ref..');
        ok(@$pems > 0, 'At least one permission set for this app..');
        ok(defined $pems->[0]->{username} && $pems->[0]->{username} ne '', 
            'Able to extract the username');
        ok(defined $pems->[0]->{permission} && ref $pems->[0]->{permission} eq 'HASH', 
            'Able to extract the permissions');
        #diag( Dumper($pems) );
    }

	unless (defined $AGAVE_APPID && defined $AGAVE_USERNAME && $AGAVE_APPID && $AGAVE_USERNAME) {
        skip "Agave app or username not defined", 6;
    }
    else {

        my $rc = $apps->pems_update($AGAVE_APPID, $AGAVE_USERNAME, 'READ_EXECUTE');
        #diag(Dumper($rc));
        ok(ref $rc eq 'HASH', 'Permission set. Got back a HASH ref');
        is($rc->{username}, $AGAVE_USERNAME, 'Permission set for the right user...');
        ok($rc->{permission}{read}, 'User set read permission...');
        ok($rc->{permission}{execute}, 'User set execute permission...');

        my $pems = $apps->pems($AGAVE_APPID);
        my ($p) = grep {$_->{username} eq $AGAVE_USERNAME} @$pems;
        #diag( Dumper($p) );
        is($p->{username}, $AGAVE_USERNAME, 'Double check, permission username matches response ...');
        is_deeply($p->{permission}, $rc->{permission}, 'Double check, permissions match response ...');

    }

}
