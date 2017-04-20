#!/usr/bin/perl -w

use Test::More;

my $TNUM = 14;
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

    my $io = $api->io;
    ok( defined $io, "IO endpoint successfully created");

    # read users directory 
    my $base_dir = '/' . $api->user;
    my $dir_data = eval {$io->readdir($base_dir);};
    if (my $err = $@) {
        diag(ref $err ? $err->message . "\n" . $err->content : $err);
    }
    ok( defined $dir_data, "Received IO response");
    ok( 'ARRAY' eq ref $dir_data, "IO response is valid");
    ok( @$dir_data > 0, "We have at least one file/dir");

    # First file is the directory itself
    my $dir = $$dir_data[0];
    ok( $dir && ref($dir), "We received an object");
    ok( $dir->isa('Agave::Client::Object::File'),  "We received the right kind of object");
    is( $dir->name, '.', "We received the user's directory");

    my $new_dir = '000-automated-test-' . rand(1000);
    my $st = $io->mkdir($base_dir, $new_dir);
    is( $st->{status}, 'success', "Directory created successfully");


    # upload a file
    my $content = 'Ana are mere.\nViorel vine și cere.';

    my $fh = File::Temp->new(SUFFIX => '.txt');
    print $fh $content;
    $fh->close;

    #$io->debug(1);

    $st = $io->upload($base_dir . '/' . $new_dir, fileToUpload => $fh->filename);

    sleep 3;
    # get the contents of the uploaded file
    my $remote_file = $base_dir . '/' . $new_dir . '/' . basename($fh->filename);
    my $dcontent = $io->stream_file($remote_file, limit_size => 100);

    is($content, $dcontent, "Streamed content matches the original");
    
    # let's get the whole thing now
    $dcontent = $io->stream_file($remote_file);
    is($content, $dcontent, "Streamed content matches the original (x2)");

    # lets store the file first
    my $dlfile = $fh->filename . '.copy';
    $st = $io->stream_file($remote_file, save_to => $dlfile);
    #diag(Dumper($st));
    is(-s $fh->filename, -s $dlfile, "Downloaded file has the same size as the original");

    # unlink the downloaded file
    unlink $dlfile;

    # remove the new directory
    $st = eval {$io->remove($base_dir . '/' . $new_dir);};
    diag("Directory not removed: " . ($st->{message}) || '')
        unless( $st->{status} eq 'success' );

    ok ( $st, "Directory removed successfully");

}

