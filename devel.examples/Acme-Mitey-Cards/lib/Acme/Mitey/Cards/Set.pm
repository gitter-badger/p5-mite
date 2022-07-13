package Acme::Mitey::Cards::Set;

our $VERSION   = '0.009';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -bool -is croak );
use Acme::Mitey::Cards::Types::Compiled qw(:types);

use List::Util ();

has cards => (
	is       => lazy,
	isa      => CardArray,
);

sub _build_cards {
	my $self = shift;

	return [];
}

sub to_string {
	my $self = shift;

	return join " ", map $_->to_string, @{ $self->cards };
}

sub count {
	my $self = shift;

	scalar @{ $self->cards };
}

sub take {
	my ( $self, $n ) = ( shift, @_ );

	croak "Not enough cards: wanted %d but only have %d", $n, $self->count
		if $n > $self->count;

	my @taken = splice( @{ $self->cards }, 0, $n );
	return __PACKAGE__->new( cards => \@taken );
}

sub shuffle {
	my $self = shift;

	@{ $self->cards } = List::Util::shuffle( @{ $self->cards } );

	return $self;
}

1;
