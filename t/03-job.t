#!/usr/bin/perl -w

use Test::More;

use Env qw(AGAVE_JOBID);

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
    plan(skip_all, '') unless (-f $conf_file);

    plan(skip_all => '$AGAVE_JOBID not defined') 
		unless (defined $AGAVE_JOBID && $AGAVE_JOBID);

    my $api = Agave::Client->new( config_file => $conf_file, debug => 0);

    ok( defined $api, "API object created");
    ok( defined $api->token, "Authentication succeeded" );

    unless ($api && $api->token) {
        plan(skip_all => "Can't continue without a token...");
    }

    my $ep = $api->job;
    ok(defined $ep, 'Job endpoint created');

	# check for status
	my $status = $ep->job_status($AGAVE_JOBID);
	ok(defined $status, "We've got the status of the job");

	# check for job details
	my $job = $ep->job_details($AGAVE_JOBID);

	ok(defined $job, "We've an object");
	is('Agave::Client::Object::Job', ref $job, "We've got the right kind of object");
	is($AGAVE_JOBID, $job->id, "We've got the job we asked for");

	# get job history
	my $history = $ep->job_history($AGAVE_JOBID);

	is('ARRAY', ref $history, "We've got an array of history events");
	cmp_ok(scalar @$history, '>', 0, 'We have at leas one history entry');
	is('HASH', ref $$history[0], "We've got a hash as the 1st history event");

	my @stata = map { $$_{status} } @$history;
	cmp_ok(scalar(grep {/PENDING|STAGED|SUBMITTING|RUNNING/} @stata), '>', 0, 'We have at least one known status' );
	diag(join(' ', @stata));

    done_testing();
}
