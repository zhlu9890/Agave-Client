#!/usr/bin/perl -w

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


if (0) {
    # now let's get the permissions
    my $perms = $meta->permissions($new_mt);
    #print STDERR Dumper( $perms), $/;
    my ($owner_perm) = grep { $new_mt->{owner} eq $_->{username} } @$perms; 
    ok ($owner_perm, 'Owner has permissions');
    is ($owner_perm->{permission}->{write}, 1, "Owner has write permissions");
    is ($owner_perm->{permission}->{read},  1, "Owner has read permissions");

    my $SHARE_WITH_USER = 'dnalcadmin';

    my $perm = $meta->permissions($new_mt, $SHARE_WITH_USER, 'READ');
    ok($perm && ref($perm), 'Permissions set');
    is ($perm->{username}, $SHARE_WITH_USER, 'Permissions set to the right user');
    is ($perm->{permission}->{read}, 1, 'READ permission is set');
    isnt ($perm->{permission}->{write}, 1, 'WRITE permission is not set');

    # re read permissions
    $perms = $meta->permissions($new_mt);
    my ($dnalc_perm) = grep { $SHARE_WITH_USER eq $_->{username} } @$perms; 
    ok( $dnalc_perm && ref($dnalc_perm), "Double checking user has permissions set");
    is ($dnalc_perm->{permission}->{read}, 1, '2nd check: READ permission is set');
    isnt ($dnalc_perm->{permission}->{write}, 1, '2nd check: WRITE permission is not set');


    $perm = $meta->delete_permissions($new_mt, $SHARE_WITH_USER);
    #print STDERR Dumper( $perm ), $/;

    $perms = $meta->permissions($new_mt);
    ($dnalc_perm) = grep { $SHARE_WITH_USER eq $_->{username} } @$perms; 
    is( $dnalc_perm, undef, "User has permissions unset");

}

    # create metadata object based on this schema
    # see if you can associate any Ids to it
    # then query for any metadata objects based on these Metadata object
    my $mt_desc = {
        name => 'rice' . rand(),
        value => { name => 'rice', species => 'Oryza sativa' },
        schemaId => $new_ms->{uuid},
        #associationIds => '',
    };

    my $meta = $api->meta;
    my $mtd = $meta->create($mt_desc);
    ok($mtd, 'New metadata created');
    is($mtd->{schemaId}, $new_ms->{uuid}, 'Metadata name ok');

    #$api->debug(1);
    #$mtd = $meta->query({ associationIds => '7366700481179151899-e0bd34dffff8de6-0001-002'});
    $meta->delete($mtd);

    my $st = $metas->delete($new_ms);
    is($st, !undef, 'Schema succeesfully deleted');

    done_testing();
}

