#!/usr/bin/perl -w


use strict;
use Test::More;

my $TNUM = 27;
#plan tests => $TNUM;

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

    my $metas = $api->schema;
    ok(defined $metas, 'Metadata Schema object succeeded created');

    my $schemas = $metas->list;
    ok('ARRAY' eq ref $schemas, 'Received a list of metadata schemas');
    #diag( Dumper( $schemas ));

	my $schema_def = {
	  	title => "Example Schema",
	  	type => "object",
	  	properties => {
			"species" => {
		  		"type" => "string"
			},
			"name" => {
		  		"type" => "string"
			}
	  	},
	  	required => ["species", "name"]
	};

    my $nonsensical_uuid = 'x-y-z-123-' . rand();
    my $ms = $metas->list($nonsensical_uuid);
    is($ms, undef, 'Successfully not found nonsensical uuid');

    my $new_ms = $metas->create($schema_def);
    #diag(Dumper($new_ms->{schema}));

    ok($new_ms->{uuid}, 'New schema created, has UUID property');
    ok($new_ms->{schema}, 'New schema created, has schema property');

    is_deeply($new_ms->{schema}, $schema_def, "Schema matches");


    $schema_def->{properties}->{description} = { "type" => "string" };
    
    #$metas->debug(1);
    my $ms_updated = $metas->update($schema_def, $new_ms->{uuid});
    #diag(Dumper($ms_updated->{schema}));
    ok($ms_updated, 'Schema updated successfully');
    ok(ref($ms_updated), 'Schema updated successfully');
    ok($ms_updated->{uuid} ne '', 'Updated schema has a UUID');
    is($ms_updated->{uuid}, $new_ms->{uuid}, 'Updated schema UUID is unchanged');
    is($ms_updated->{name}, $new_ms->{name}, 'Updated schema has the same name');

    is_deeply($ms_updated->{schema}, $schema_def, 'Updated schema has the right "schema"');
    #diag(Dumper($ms_updated));


    # now let's get the permissions
    my $perms = $metas->permissions($new_ms);
    #diag(Dumper( $perms));
    my ($owner_perm) = grep { $new_ms->{owner} eq $_->{username} } @$perms; 
    ok ($owner_perm, 'Owner has permissions');
    is ($owner_perm->{permission}->{write}, 1, "Owner has write permissions");
    is ($owner_perm->{permission}->{read},  1, "Owner has read permissions");

    my $SHARE_WITH_USER = 'dnalcadmin';

    my $perm = $metas->permissions($new_ms, $SHARE_WITH_USER, 'READ');
    #diag(Dumper( $perm));
    ok($perm && ref($perm), 'Permissions set');
    is ($perm->{username}, $SHARE_WITH_USER, 'Permissions set to the right user');
    is ($perm->{permission}->{read}, 1, 'READ permission is set');
    isnt ($perm->{permission}->{write}, 1, 'WRITE permission is not set');

    # re read permissions
    $perms = $metas->permissions($new_ms->{uuid});
    my ($user_perms) = grep { $SHARE_WITH_USER eq $_->{username} } @$perms; 
    ok( $user_perms && ref($user_perms), "Double checking user has permissions set");
    is ($user_perms->{permission}->{read}, 1, '2nd check: READ permission is set');
    isnt ($user_perms->{permission}->{write}, 1, '2nd check: WRITE permission is not set');

    $perm = $metas->delete_permissions($new_ms->{uuid}, $SHARE_WITH_USER);
    #print STDERR Dumper( $perm ), $/;

    $perms = $metas->permissions($new_ms);
    ($user_perms) = grep { $SHARE_WITH_USER eq $_->{username} } @$perms; 
    is( $user_perms, undef, "User has permissions unset");

    # create metadata object based on this schema
    # see if you can associate any Ids to it
    # then query for any metadata objects based on these Metadata object
    my $mt_desc = {
        name => 'athaliana-' . rand(),
        value => { name => 'mouse-ear cress', species => 'Arabidopsis thaliana' },
        schemaId => $new_ms->{uuid},
        associationIds => [],
    };

    # get a file and associate it to this metadata object
    my $files = $api->io->ls('shared/iplant_DNA_subway/genomes/arabidopsis_thaliana/genome.fas');
    my $genome = $files && @$files ? $files->[0] : undef;

    if ($genome && $genome->uuid) {
        $mt_desc->{associationIds} = [ $genome->uuid ]
    }

    my $meta = $api->meta;
    my $mtd = $meta->create($mt_desc);
    ok($mtd, 'New metadata created');
    is($mtd->{schemaId}, $new_ms->{uuid}, 'Metadata name ok');

    if ($genome && $genome->uuid) {
        my $result = $meta->query({ associationIds => $genome->uuid});
        #diag(Dumper($result));
        ok($result && ref $result, 'Metadata query worked');

        my ($amtd) = grep {$_->{uuid} eq $mtd->{uuid}} @$result if $result;
        ##diag(Dumper($amtd));
        ok($amtd, 'Got a metadata object');

        my $assocIds = $amtd->{associationIds};
        ok($assocIds && ref $assocIds && @$assocIds, 'Metadata has associationIds');
        is_deeply($mtd->{associationIds}, $amtd->{associationIds}, 'Got the same associationIds');
    }

    my $st = $meta->delete($mtd);
    is($st, !undef, 'Metadata succeesfully deleted');

    $st = $metas->delete($new_ms);
    is($st, !undef, 'Schema succeesfully deleted');

    done_testing();
}

