#!/usr/bin/env perl

use strict;
use warnings;

use Agave::Client::Client();
use Term::ReadKey;
use Data::Dumper;

my $u = $ENV{AGAVE_USERNAME} || $ENV{IPLANT_USERNAME};
my $p = $ENV{AGAVE_PASSWORD} || $ENV{IPLANT_PASSWORD};

while (!defined $u || 0 == length $u) {
    print "Enter username> ";
    $u = ReadLine(0);
    chomp $u;
}

unless ($p) {
    ReadMode('noecho');
    ReadMode('raw');

    print "Enter password> ";
    while (1) {
        my $c;
        1 until defined($c = ReadKey(-1));
        if (ord($c) == 3) {
            ReadMode('restore');
            exit 0;
        }
        last if $c eq "\n";
        print "*";
        $p .= $c;
    }
    ReadMode('restore');
}


my $arg = shift;
my ($add);
if (defined $arg && $arg =~ /^-+a(dd)?/) {
    $add = 1;
}

my $apic = Agave::Client::Client->new({ 
                username => $u,
                password => $p,
                debug => 0,
            });


if ($add) {
    print "\nEnter a name for the new client> ";

    my $cname = ReadLine(0);
    chomp $cname;
    if ( "" eq $cname) {
        print STDERR  "\nError: No name entered. Bailling out...\n\n";
        exit 0;
    }
    my $client = $apic->create({ name => $cname });
    if ($client) {
        print "Client created successfully. Please store the following info:\n";
        for (qw/name tier consumerKey consumerSecret/) {
            print "  ", $_, ":", $client->{$_}, "\n";
        }
    }
    else {
        print "Unable to create the new client!!\n";
    }
}

my $clients = $apic->clients;

#print STDERR Dumper( $clients), $/;
print "\n\nYou have ", scalar @$clients, " client(s):\n";
for my $c (@$clients) {
    print " ", $c->{name}, 
        "\tkey:", $c->{consumerKey}, 
        "\t", $c->{description}, "\n";
}
print "\n";


