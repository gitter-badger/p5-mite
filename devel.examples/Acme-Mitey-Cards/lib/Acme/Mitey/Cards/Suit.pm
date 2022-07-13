package Acme::Mitey::Cards::Suit;

our $VERSION   = '0.010';
our $AUTHORITY = 'cpan:TOBYINK';

use Acme::Mitey::Cards::Mite qw( -bool -is );
use Acme::Mitey::Cards::Types qw(:types);

has name => (
	is       => ro,
	isa      => NonEmptyStr,
	required => true,
);

has abbreviation => (
	is       => lazy,
	isa      => Str,
	builder  => sub { uc substr( shift->name, 0, 1 ) },
);

has colour => (
	is       => ro,
	isa      => Str,
	required => true,
);

{
	my ( $hearts, $diamonds, $spades, $clubs );
	
	sub hearts {
		$hearts ||= Acme::Mitey::Cards::Suit->new( name => 'Hearts', colour => 'red' );
	}

	sub diamonds {
		$diamonds ||= Acme::Mitey::Cards::Suit->new( name => 'Diamonds', colour => 'red' );
	}

	sub spades {
		$spades ||= Acme::Mitey::Cards::Suit->new( name => 'Spades', colour => 'black' );
	}

	sub clubs {
		$clubs ||= Acme::Mitey::Cards::Suit->new( name => 'Clubs', colour => 'black' );
	}
}

sub standard_suits {
	my $class = shift;

	return (
		$class->spades,
		$class->hearts,
		$class->diamonds,
		$class->clubs,
	);
}

1;
