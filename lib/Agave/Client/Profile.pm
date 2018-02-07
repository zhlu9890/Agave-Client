package Agave::Client::Profile;

use warnings;
use strict;
use Data::Dumper;

use base qw/Agave::Client::Base/;

=head1 NAME

Agave::Client::Profile

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

{
	sub list {
		my ($self, $username) = @_;

		return unless (defined $username);
		return eval {$self->do_get("/$username");};
	}
}

1;
