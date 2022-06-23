{

    package Acme::Mitey::Cards::Hand;
    use strict;
    use warnings;

    BEGIN {
        require Acme::Mitey::Cards::Set;

        use mro 'c3';
        our @ISA;
        push @ISA, q[Acme::Mitey::Cards::Set];
    }

    sub new {
        my $class = shift;
        my $args  = { ( @_ == 1 ) ? %{ $_[0] } : @_ };

        my $self = bless {}, $class;

        if ( exists( $args->{q[cards]} ) ) {
            (
                do { package Type::Tiny; ref( $args->{q[cards]} ) eq 'ARRAY' }
                  and do {
                    my $ok = 1;
                    for my $i ( @{ $args->{q[cards]} } ) {
                        ( $ok = 0, last )
                          unless (
                            do {
                                use Scalar::Util ();
                                Scalar::Util::blessed($i)
                                  and $i->isa(q[Acme::Mitey::Cards::Card]);
                            }
                          );
                    };
                    $ok;
                }
              )
              or require Carp
              && Carp::croak(
q[Type check failed in constructor: cards should be ArrayRef[InstanceOf["Acme::Mitey::Cards::Card"]]]
              );
            $self->{q[cards]} = $args->{q[cards]};
            delete $args->{q[cards]};
        }
        if ( exists( $args->{q[owner]} ) ) {
            do {

                package Type::Tiny;
                (
                    do {

                        package Type::Tiny;
                        defined( $args->{q[owner]} ) and do {
                            ref( \$args->{q[owner]} ) eq 'SCALAR'
                              or ref( \( my $val = $args->{q[owner]} ) ) eq
                              'SCALAR';
                        }
                      }
                      or (
                        do {

                            package Type::Tiny;
                            use Scalar::Util ();
                            Scalar::Util::blessed( $args->{q[owner]} );
                        }
                      )
                );
              }
              or require Carp
              && Carp::croak(
                q[Type check failed in constructor: owner should be Str|Object]
              );
            $self->{q[owner]} = $args->{q[owner]};
            delete $args->{q[owner]};
        }

        keys %$args
          and require Carp
          and Carp::croak( "Unexpected keys in constructor: "
              . join( q[, ], sort keys %$args ) );

        return $self;
    }

    my $__XS = !$ENV{MITE_PURE_PERL}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for owner
    *owner = sub {
        @_ > 1
          ? do {
            $_[0]{q[owner]} = do {
                my $value = $_[1];
                do {

                    package Type::Tiny;
                    (
                        do {

                            package Type::Tiny;
                            defined($value) and do {
                                ref( \$value ) eq 'SCALAR'
                                  or ref( \( my $val = $value ) ) eq 'SCALAR';
                            }
                          }
                          or (
                            do {

                                package Type::Tiny;
                                use Scalar::Util ();
                                Scalar::Util::blessed($value);
                            }
                          )
                    );
                  }
                  or require Carp
                  && Carp::croak(
                    q[Type check failed in accessor: value should be Str|Object]
                  );
                $value;
            };
            $_[0];
          }
          : $_[0]{q[owner]};
    };

    # Accessors for cards
    *cards = sub {
        @_ > 1
          ? require Carp
          && Carp::croak("cards is a read-only attribute of @{[ref $_[0]]}")
          : (
            exists( $_[0]{q[cards]} ) ? $_[0]{q[cards]} : (
                $_[0]{q[cards]} = do {
                    my $default_value = $_[0]->_build_cards;
                    do {

                        package Type::Tiny;
                        ( ref($default_value) eq 'ARRAY' ) and do {
                            my $ok = 1;
                            for my $i ( @{$default_value} ) {
                                ( $ok = 0, last )
                                  unless (
                                    do {
                                        use Scalar::Util ();
                                        Scalar::Util::blessed($i)
                                          and
                                          $i->isa(q[Acme::Mitey::Cards::Card]);
                                    }
                                  );
                            };
                            $ok;
                        }
                      }
                      or do {
                        require Carp;
                        Carp::croak(
q[Type check failed in default: cards should be ArrayRef[InstanceOf["Acme::Mitey::Cards::Card"]]]
                        );
                      };
                    $default_value;
                }
            )
          );
    };

    1;
}
