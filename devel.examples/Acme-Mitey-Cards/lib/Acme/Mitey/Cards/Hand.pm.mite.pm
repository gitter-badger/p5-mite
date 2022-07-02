{

    package Acme::Mitey::Cards::Hand;
    our $USES_MITE = "Mite::Class";
    use strict;
    use warnings;

    BEGIN {
        require Acme::Mitey::Cards::Set;

        use mro 'c3';
        our @ISA;
        push @ISA, "Acme::Mitey::Cards::Set";
    }

    sub new {
        my $class = ref( $_[0] ) ? ref(shift) : shift;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $self  = bless {}, $class;
        my $args =
            $meta->{HAS_BUILDARGS}
          ? $class->BUILDARGS(@_)
          : { ( @_ == 1 ) ? %{ $_[0] } : @_ };
        my $no_build = delete $args->{__no_BUILD__};

        # Initialize attributes
        if ( exists $args->{"cards"} ) {
            (
                do {

                    package Acme::Mitey::Cards::Mite;
                    ref( $args->{"cards"} ) eq 'ARRAY';
                  }
                  and do {
                    my $ok = 1;
                    for my $i ( @{ $args->{"cards"} } ) {
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
                sprintf "Type check failed in constructor: %s should be %s",
                "cards", "ArrayRef[InstanceOf[\"Acme::Mitey::Cards::Card\"]]" );
            $self->{"cards"} = $args->{"cards"};
        }
        if ( exists $args->{"owner"} ) {
            do {

                package Acme::Mitey::Cards::Mite;
                (
                    do {

                        package Acme::Mitey::Cards::Mite;
                        defined( $args->{"owner"} ) and do {
                            ref( \$args->{"owner"} ) eq 'SCALAR'
                              or ref( \( my $val = $args->{"owner"} ) ) eq
                              'SCALAR';
                        }
                      }
                      or (
                        do {

                            package Acme::Mitey::Cards::Mite;
                            use Scalar::Util ();
                            Scalar::Util::blessed( $args->{"owner"} );
                        }
                      )
                );
              }
              or require Carp
              && Carp::croak(
                sprintf "Type check failed in constructor: %s should be %s",
                "owner", "Str|Object" );
            $self->{"owner"} = $args->{"owner"};
        }

        # Enforce strict constructor
        my @unknown = grep not(/\A(?:cards|owner)\z/), keys %{$args};
        @unknown
          and require Carp
          and Carp::croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        # Call BUILD methods
        unless ($no_build) {
            $_->( $self, $args ) for @{ $meta->{BUILD} || [] };
        }

        return $self;
    }

    defined ${^GLOBAL_PHASE}
      or eval { require Devel::GlobalDestruction; 1 } or do {
        *Devel::GlobalDestruction::in_global_destruction = sub { undef; }
      };

    sub DESTROY {
        my $self  = shift;
        my $class = ref($self) || $self;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $in_global_destruction =
          defined ${^GLOBAL_PHASE}
          ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
          : Devel::GlobalDestruction::in_global_destruction();
        for my $demolisher ( @{ $meta->{DEMOLISH} || [] } ) {
            my $e = do {
                local ( $?, $@ );
                eval { $demolisher->( $self, $in_global_destruction ) };
                $@;
            };
            no warnings 'misc';    # avoid (in cleanup) warnings
            die $e if $e;          # rethrow
        }
        return;
    }

    sub __META__ {
        no strict 'refs';
        require mro;
        my $class = shift;
        $class = ref($class) || $class;
        my $linear_isa = mro::get_linear_isa($class);
        return {
            BUILD => [
                map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                map { "$_\::BUILD" } reverse @$linear_isa
            ],
            DEMOLISH => [
                map   { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                  map { "$_\::DEMOLISH" } @$linear_isa
            ],
            HAS_BUILDARGS => $class->can('BUILDARGS'),
        };
    }

    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        return $self->SUPER::DOES($role);
    }

    sub does {
        shift->DOES(@_);
    }

    my $__XS = !$ENV{MITE_PURE_PERL}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for owner
    sub owner {
        @_ > 1
          ? do {
            do {

                package Acme::Mitey::Cards::Mite;
                (
                    do {

                        package Acme::Mitey::Cards::Mite;
                        defined( $_[1] ) and do {
                            ref( \$_[1] ) eq 'SCALAR'
                              or ref( \( my $val = $_[1] ) ) eq 'SCALAR';
                        }
                      }
                      or (
                        do {

                            package Acme::Mitey::Cards::Mite;
                            use Scalar::Util ();
                            Scalar::Util::blessed( $_[1] );
                        }
                      )
                );
              }
              or require Carp
              && Carp::croak(
                sprintf "Type check failed in %s: value should be %s",
                "accessor", "Str|Object" );
            $_[0]{"owner"} = $_[1];
            $_[0];
          }
          : ( $_[0]{"owner"} );
    }

    1;
}
