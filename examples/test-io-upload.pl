#!/usr/bin/perl

use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Agave::Client ();
use Data::Dumper; 

sub list_dir {
    my ($dir_contents) = @_;
    for (@$dir_contents) {
        print sprintf(" %6s\t%-40s\t%-40s", $_->type, $_->name, $_),  $/;
    }
    print "\n";
}

# this will read the configs from the ~/.agave or ../t/agave-auth.json file:
#    conf file content: 
#        {"user":"iplant_username", "password":"iplant_password", "apikey":"", "apisecret":"", "token":""}
#        # set either the password or the token

my $api_instance = Agave::Client->new(debug => 0, config_file => 't/agave-auth.json');

unless ($api_instance->token) {
    warn "\nError: Authentication failed!\n";
    exit 1;
}
print "Token: ", $api_instance->token, "\n" if $api_instance->debug;

my $base_dir = '/' . $api_instance->user;
print "Working in [", $base_dir, "]", $/;

my ($st, $dir_contents_href);

#-----------------------------
# IO
#
    my $io = $api_instance->io;
    #$io->debug(1);

    print "---------------------------------------------------------\n";
    print "\t** Listing of directory: ", $base_dir, $/;
    print "---------------------------------------------------------\n";

    $dir_contents_href = $io->readdir($base_dir);
    list_dir($dir_contents_href);

    # to generate a 3GB file, use this
    # dd if=/dev/zero of=3GB.dat count=3072 bs=1048576
    $st = $io->upload($base_dir, 
            fileType =>'raw', 
            fileToUpload => '3GB.dat', 
            fileName => 'a-large-file.dat');

    print STDERR 'upload status: ', Dumper( $st ), $/;

    sleep 3;
    $dir_contents_href = $io->readdir($base_dir), $/;
    list_dir($dir_contents_href);

