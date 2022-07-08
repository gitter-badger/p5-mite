{

    package Mite::Project;
    our $USES_MITE = "Mite::Class";
    our $MITE_SHIM = "Mite::Shim";
    use strict;
    use warnings;

    BEGIN {
        *bare    = \&Mite::Shim::bare;
        *blessed = \&Scalar::Util::blessed;
        *carp    = \&Mite::Shim::carp;
        *confess = \&Mite::Shim::confess;
        *croak   = \&Mite::Shim::croak;
        *false   = \&Mite::Shim::false;
        *lazy    = \&Mite::Shim::lazy;
        *ro      = \&Mite::Shim::ro;
        *rw      = \&Mite::Shim::rw;
        *rwp     = \&Mite::Shim::rwp;
        *true    = \&Mite::Shim::true;
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
        if ( exists $args->{"sources"} ) {
            (
                do { package Mite::Shim; ref( $args->{"sources"} ) eq 'HASH' }
                  and do {
                    my $ok = 1;
                    for my $i ( values %{ $args->{"sources"} } ) {
                        ( $ok = 0, last )
                          unless (
                            do {
                                use Scalar::Util ();
                                Scalar::Util::blessed($i)
                                  and $i->isa(q[Mite::Source]);
                            }
                          );
                    };
                    $ok;
                }
              )
              or croak(
                "Type check failed in constructor: %s should be %s",
                "sources",
                "HashRef[InstanceOf[\"Mite::Source\"]]"
              );
            $self->{"sources"} = $args->{"sources"};
        }
        else {
            my $value = do {
                my $default_value = do {
                    my $method = $Mite::Project::__sources_DEFAULT__;
                    $self->$method;
                };
                do {

                    package Mite::Shim;
                    ( ref($default_value) eq 'HASH' ) and do {
                        my $ok = 1;
                        for my $i ( values %{$default_value} ) {
                            ( $ok = 0, last )
                              unless (
                                do {
                                    use Scalar::Util ();
                                    Scalar::Util::blessed($i)
                                      and $i->isa(q[Mite::Source]);
                                }
                              );
                        };
                        $ok;
                    }
                  }
                  or croak(
                    "Type check failed in default: %s should be %s",
                    "sources",
                    "HashRef[InstanceOf[\"Mite::Source\"]]"
                  );
                $default_value;
            };
            $self->{"sources"} = $value;
        }
        if ( exists $args->{"config"} ) {
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed( $args->{"config"} )
                      and $args->{"config"}->isa(q[Mite::Config]);
                }
              )
              or croak( "Type check failed in constructor: %s should be %s",
                "config", "InstanceOf[\"Mite::Config\"]" );
            $self->{"config"} = $args->{"config"};
        }
        if ( exists $args->{"_limited_parsing"} ) {
            do {

                package Mite::Shim;
                !ref $args->{"_limited_parsing"}
                  and (!defined $args->{"_limited_parsing"}
                    or $args->{"_limited_parsing"} eq q()
                    or $args->{"_limited_parsing"} eq '0'
                    or $args->{"_limited_parsing"} eq '1' );
              }
              or croak( "Type check failed in constructor: %s should be %s",
                "_limited_parsing", "Bool" );
            $self->{"_limited_parsing"} = $args->{"_limited_parsing"};
        }
        else {
            my $value = do {
                my $default_value = "";
                (
                    !ref $default_value
                      and (!defined $default_value
                        or $default_value eq q()
                        or $default_value eq '0'
                        or $default_value eq '1' )
                  )
                  or croak( "Type check failed in default: %s should be %s",
                    "_limited_parsing", "Bool" );
                $default_value;
            };
            $self->{"_limited_parsing"} = $value;
        }
        if ( exists $args->{"_module_fakeout_namespace"} ) {
            do {

                package Mite::Shim;
                defined( $args->{"_module_fakeout_namespace"} ) and do {
                    ref( \$args->{"_module_fakeout_namespace"} ) eq 'SCALAR'
                      or
                      ref( \( my $val = $args->{"_module_fakeout_namespace"} ) )
                      eq 'SCALAR';
                }
              }
              or croak( "Type check failed in constructor: %s should be %s",
                "_module_fakeout_namespace", "Str" );
            $self->{"_module_fakeout_namespace"} =
              $args->{"_module_fakeout_namespace"};
        }
        if ( exists $args->{"debug"} ) {
            do {

                package Mite::Shim;
                !ref $args->{"debug"}
                  and (!defined $args->{"debug"}
                    or $args->{"debug"} eq q()
                    or $args->{"debug"} eq '0'
                    or $args->{"debug"} eq '1' );
              }
              or croak( "Type check failed in constructor: %s should be %s",
                "debug", "Bool" );
            $self->{"debug"} = $args->{"debug"};
        }
        else {
            my $value = do {
                my $default_value = "";
                (
                    !ref $default_value
                      and (!defined $default_value
                        or $default_value eq q()
                        or $default_value eq '0'
                        or $default_value eq '1' )
                  )
                  or croak( "Type check failed in default: %s should be %s",
                    "debug", "Bool" );
                $default_value;
            };
            $self->{"debug"} = $value;
        }

        # Enforce strict constructor
        my @unknown = grep not(
/\A(?:_(?:limited_parsing|module_fakeout_namespace)|config|debug|sources)\z/
        ), keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        return $self;
    }

    sub BUILDALL {
        my $class = ref( $_[0] );
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        $_->(@_) for @{ $meta->{BUILD} || [] };
    }

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
            HAS_BUILDARGS        => $class->can('BUILDARGS'),
            HAS_FOREIGNBUILDARGS => $class->can('FOREIGNBUILDARGS'),
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

    # Accessors for _limited_parsing
    sub _limited_parsing {
        @_ > 1
          ? do {
            (
                !ref $_[1]
                  and (!defined $_[1]
                    or $_[1] eq q()
                    or $_[1] eq '0'
                    or $_[1] eq '1' )
              )
              or croak( "Type check failed in %s: value should be %s",
                "accessor", "Bool" );
            $_[0]{"_limited_parsing"} = $_[1];
            $_[0];
          }
          : ( $_[0]{"_limited_parsing"} );
    }

    # Accessors for _module_fakeout_namespace
    if ($__XS) {
        Class::XSAccessor->import(
            chained             => 1,
            "exists_predicates" => {
                "_has__module_fakeout_namespace" => "_module_fakeout_namespace"
            },
        );
    }
    else {
        *_has__module_fakeout_namespace =
          sub { exists $_[0]{"_module_fakeout_namespace"} };
    }

    sub _module_fakeout_namespace {
        @_ > 1
          ? do {
            do {

                package Mite::Shim;
                defined( $_[1] ) and do {
                    ref( \$_[1] ) eq 'SCALAR'
                      or ref( \( my $val = $_[1] ) ) eq 'SCALAR';
                }
              }
              or croak( "Type check failed in %s: value should be %s",
                "accessor", "Str" );
            $_[0]{"_module_fakeout_namespace"} = $_[1];
            $_[0];
          }
          : ( $_[0]{"_module_fakeout_namespace"} );
    }

    # Accessors for config
    sub config {
        @_ > 1 ? croak("config is a read-only attribute of @{[ref $_[0]]}") : (
            exists( $_[0]{"config"} ) ? $_[0]{"config"} : (
                $_[0]{"config"} = do {
                    my $default_value = do {
                        my $method =
                          $Mite::Project::__config_DEFAULT__;
                        $_[0]->$method;
                    };
                    (
                        do {
                            use Scalar::Util ();
                            Scalar::Util::blessed($default_value)
                              and $default_value->isa(q[Mite::Config]);
                        }
                      )
                      or croak(
                        "Type check failed in default: %s should be %s",
                        "config",
                        "InstanceOf[\"Mite::Config\"]"
                      );
                    $default_value;
                }
            )
        );
    }

    # Accessors for debug
    sub debug {
        @_ > 1
          ? do {
            (
                !ref $_[1]
                  and (!defined $_[1]
                    or $_[1] eq q()
                    or $_[1] eq '0'
                    or $_[1] eq '1' )
              )
              or croak( "Type check failed in %s: value should be %s",
                "accessor", "Bool" );
            $_[0]{"debug"} = $_[1];
            $_[0];
          }
          : ( $_[0]{"debug"} );
    }

    # Accessors for sources
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "sources" => "sources" },
        );
    }
    else {
        *sources = sub {
            @_ > 1
              ? croak("sources is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"sources"};
        };
    }

    1;
}
