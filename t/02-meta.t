#!/usr/bin/perl -w

use Test::More;

my $TNUM = 27;
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

    my $meta = $api->meta;
    ok(defined $meta, 'Meta encode succeeded created');

    my $metas = $meta->list;
    ok('ARRAY' eq ref $metas, 'Received a list of metas');
    #diag( Dumper( $metas ));

    my $nonsensical_uuid = 'x-y-z-123-' . rand();
    my $mt = $meta->list($nonsensical_uuid);
    is($mt, undef, 'Successfully not found nonsensical uuid');

    my $mt_desc = {
        name => 'my-own-test-' . rand(),
        title => 'this is a test',
        value => { ana => 'are mere' },
    };
    $meta->debug(0);
    my $new_mt = $meta->create($mt_desc);
    #print STDERR Dumper( $new_mt), $/;
    #sleep(2);
    ok($new_mt, 'New metadata created');
    is($new_mt->{name}, $mt_desc->{name}, 'Metadata name ok');

    is_deeply($new_mt->{value}, $mt_desc->{value}, "Value matches");

    #print STDERR Dumper( $new_mt), $/;
    $new_mt->{value} = 'ana are mere';
    
    my $mt_updated = $meta->update($new_mt, $new_mt->{uuid});
    #print STDERR Dumper( $mt_updated), $/;
    ok($mt_updated, 'Metadata updated successfully');
    ok(ref($mt_updated), 'Metadata updated successfully');
    ok($mt_updated->{uuid} ne '', 'Updated metadata has a UUID');
    is($mt_updated->{uuid}, $new_mt->{uuid}, 'Updated metadata has the same UUID');
    is($mt_updated->{name}, $new_mt->{name}, 'Updated metadata has the same name');
    isnt($mt_updated->{value}, $mt_desc->{value}, 'Updated metadata changed its value');
    is_deeply($mt_updated->{value}, $new_mt->{value}, 'Updated metadata has the right value');

    # now let's get the permissions
    my $perms = $meta->permissions($new_mt);
    #print STDERR Dumper( $perms), $/;
    my ($owner_perm) = grep { $new_mt->{owner} eq $_->{username} } @$perms; 
    ok ($owner_perm, 'Owner has permissions');
    is ($owner_perm->{permission}->{write}, 1, "Owner has write permissions");
    is ($owner_perm->{permission}->{read},  1, "Owner has read permissions");

    my $perm = $meta->permissions($new_mt, 'dnalcadmin', 'READ');
    #print STDERR Dumper( $perm ), $/;
    ok($perm && ref($perm), 'Permissions set');
    is ($perm->{username}, 'dnalcadmin', 'Permissions set to the right user');
    is ($perm->{permission}->{read}, 1, 'READ permission is set');
    isnt ($perm->{permission}->{write}, 1, 'WRITE permission is not set');


    # re read permissions
    $perms = $meta->permissions($new_mt);
    my ($dnalc_perm) = grep { 'dnalcadmin' eq $_->{username} } @$perms; 
    ok( $dnalc_perm && ref($dnalc_perm), "Double checking user has permissions set");
    is ($dnalc_perm->{permission}->{read}, 1, '2nd check: READ permission is set');
    isnt ($dnalc_perm->{permission}->{write}, 1, '2nd check: WRITE permission is not set');


    $perm = $meta->delete_permissions($new_mt, 'dnalcadmin');
    #print STDERR Dumper( $perm ), $/;

    $perms = $meta->permissions($new_mt);
    ($dnalc_perm) = grep { 'dnalcadmin' eq $_->{username} } @$perms; 
    is( $dnalc_perm, undef, "User has permissions unset");

    my $st = $meta->delete($new_mt);
    is($st, !undef, 'Metadata succeeded deleted');

    #done_testing();
}

