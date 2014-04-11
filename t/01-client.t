#!/usr/bin/perl -w

use Test::More;

my $TNUM = 9;
plan tests => $TNUM;

use FindBin;
use JSON::XS;
use File::Slurp;
use Data::Dumper;
use Try::Tiny;

use Agave::Client ();
use Agave::Client::Client ();

my $env_set = (defined $ENV{AGAVE_USERNAME} || defined $ENV{IPLANT_USERNAME}) 
            && (defined $ENV{AGAVE_PASSWORD} || $ENV{IPLANT_PASSWORD});

my $conf_file = "$FindBin::Bin/agave-auth.json";

diag <<EOF


********************* WARNING ********************************
The ENV variables AGAVE_USERNAME and AGAVE_PASSWORD are not set.
Also, the t/agave-auth.json is missing. Here's the structure:
    {
        "username"  :"", 
        "password"  :"",
        "apisecret" :"", # optional for this test
        "apikey"    :""  # optional for this test
    }

To pass this test, please eithe set the AGAVE_ environment variables or
create the t/agave-auth.json as specified above.

For more details go to http://agaveapi.co/authentication-token-management/ and
http://agaveapi.co/client-registration/


EOF
unless ($env_set || -f $conf_file);

my ($u, $p);

if ($env_set) {
    ($u, $p) = map {$ENV{ "IPLANT_$_" } || $ENV{"AGAVE_$_"}} (qw/USERNAME PASSWORD/);
}
else {
    my $json_text = read_file($conf_file);
    my $config = decode_json($json_text);
    ($u, $p) = ($$config{username} || $$config{user}, $$config{password})
}

SKIP: {
    skip "Create the t/agave-auth.json file for tests to run", $TNUM
        unless ($env_set || -f $conf_file);

    my $apic = Agave::Client::Client->new({ 
                    username => $u, 
                    password => $p, 
                    http_timeout => 40, 
                    debug => 0
                });

    ok( defined $apic, "API Client object created");
    isa_ok( $apic, 'Agave::Client::Client' );

    $DB::single = 1;
    my $clients = $apic->clients;
    is(ref $clients, 'ARRAY', "Received list of clients as an arrayref.");

    my $new_client_name = 'agave-test-' . int(rand(1_000_000)) . '-' . time();

    my $client = $apic->create({ name => $new_client_name });
    is(ref $client, 'HASH', "New client received is a hashref.");

    # refetch the client's list
    $clients = $apic->clients;
    my @filter_result = grep {$_->{name} eq $new_client_name} @$clients;
    ok(scalar @filter_result, "Found new client among all clients..");

    # retrieve info about this client

    my $xclient = $apic->client($new_client_name);
    is($xclient->{name}, $client->{name}, "Client matches name");
    is($xclient->{tier}, $client->{tier}, "Client matches tier");
    is($xclient->{consumerKey}, $client->{consumerKey}, "Client matches key");

    #$DB::single = 1;
    my $deleted_ok = 0;
    try {
        my $ok = $apic->delete($client->{name});
        $deleted_ok = $ok;
    };
    ok($deleted_ok, "Successfully deleted the client.");
 
    #unless ($api && $api->token) {
    #    skip "Auth failed. No reason to continue..", $TNUM - 2;
    #}

}


