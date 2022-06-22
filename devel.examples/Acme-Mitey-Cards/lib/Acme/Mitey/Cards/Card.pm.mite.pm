{
package Acme::Mitey::Cards::Card;
use strict;
use warnings;


sub new {
    my $class = shift;
    my $args  = { ( @_ == 1 ) ? %{$_[0]} : @_ };

    my $self = bless {}, $class;

    if ( exists($args->{q[deck]}) ) { (do { use Scalar::Util (); Scalar::Util::blessed($args->{q[deck]}) and $args->{q[deck]}->isa(q[Acme::Mitey::Cards::Deck]) }) or do { require Carp; Carp::croak(q[Type check failed in constructor: deck should be InstanceOf["Acme::Mitey::Cards::Deck"]]) }; $self->{q[deck]} = delete $args->{q[deck]};  }
    if ( exists($args->{q[reverse]}) ) { do { package Type::Tiny; defined($args->{q[reverse]}) and do { ref(\$args->{q[reverse]}) eq 'SCALAR' or ref(\(my $val = $args->{q[reverse]})) eq 'SCALAR' } } or do { require Carp; Carp::croak(q[Type check failed in constructor: reverse should be Str]) }; $self->{q[reverse]} = delete $args->{q[reverse]};  }

    keys %$args and do { require Carp; Carp::croak("Unexpected keys in constructor: " . join(q[, ], sort keys %$args)) };

    return $self;
}

if( !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor } ) {
Class::XSAccessor->import(
    getters => { q[deck] => q[deck] },
);

}
else {
    *deck = sub { @_ > 1 ? require Carp && Carp::croak("deck is a read-only attribute of @{[ref $_[0]]}") : $_[0]->{q[deck]} };

}
if( !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor } ) {
*reverse = sub { @_ > 1 ? require Carp && Carp::croak("reverse is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[reverse]}) ? $_[0]{q[reverse]} : ( $_[0]{q[reverse]} = do { my $default_value = $_[0]->_build_reverse; do { package Type::Tiny; defined($default_value) and do { ref(\$default_value) eq 'SCALAR' or ref(\(my $val = $default_value)) eq 'SCALAR' } } or do { require Carp; Carp::croak(q[Type check failed in default: reverse should be Str]) }; $default_value } ) ) };

}
else {
    *reverse = sub { @_ > 1 ? require Carp && Carp::croak("reverse is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[reverse]}) ? $_[0]{q[reverse]} : ( $_[0]{q[reverse]} = do { my $default_value = $_[0]->_build_reverse; do { package Type::Tiny; defined($default_value) and do { ref(\$default_value) eq 'SCALAR' or ref(\(my $val = $default_value)) eq 'SCALAR' } } or do { require Carp; Carp::croak(q[Type check failed in default: reverse should be Str]) }; $default_value } ) ) };

}

1;
}