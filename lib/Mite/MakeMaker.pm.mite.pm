{

    package Mite::MakeMaker;
    use strict;
    use warnings;

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Mite::Shim";
    our $MITE_VERSION = "0.007002";

    BEGIN {
        require Scalar::Util;
        *bare    = \&Mite::Shim::bare;
        *blessed = \&Scalar::Util::blessed;
        *carp    = \&Mite::Shim::carp;
        *confess = \&Mite::Shim::confess;
        *croak   = \&Mite::Shim::croak;
        *false   = \&Mite::Shim::false;
        *guard   = \&Mite::Shim::guard;
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

        # Enforce strict constructor
        my @unknown = grep not(
            do {

                package Mite::Shim;
                defined($_) and do {
                    ref( \$_ ) eq 'SCALAR'
                      or ref( \( my $val = $_ ) ) eq 'SCALAR';
                }
            }
          ),
          keys %{$args};
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
        no warnings 'once';
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

    our %SIGNATURE_FOR;

    $SIGNATURE_FOR{"change_parent_dir"} = sub {
        my $__NEXT__ = shift;

        my ( @out, %tmp, $tmp, $dtmp, @head );

        @_ == 3
          or croak(
            "Wrong number of parameters in signature for %s: %s, got %d",
            "change_parent_dir", "expected exactly 3 parameters",
            scalar(@_)
          );

        @head = splice( @_, 0, 0 );

        # Parameter $_[0] (type: Path)
        $tmp = (
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed( $_[0] )
                      and $_[0]->isa(q[Path::Tiny]);
                }
            )
        ) ? $_[0] : (
            do {

                package Mite::Shim;
                defined( $_[0] ) and do {
                    ref( \$_[0] ) eq 'SCALAR'
                      or ref( \( my $val = $_[0] ) ) eq 'SCALAR';
                }
            }
          )
          ? scalar(
            do { local $_ = $_[0]; Path::Tiny::path($_) }
          )
          : (
            do {

                package Mite::Shim;
                defined( $_[0] ) && !ref( $_[0] )
                  or Scalar::Util::blessed( $_[0] ) && (
                    sub {
                        require overload;
                        overload::Overloaded( ref $_[0] or $_[0] )
                          and overload::Method( ( ref $_[0] or $_[0] ), $_[1] );
                    }
                )->( $_[0], q[""] );
            }
          )
          ? scalar(
            do { local $_ = $_[0]; Path::Tiny::path($_) }
          )
          : ( ( ref( $_[0] ) eq 'ARRAY' ) ) ? scalar(
            do { local $_ = $_[0]; Path::Tiny::path(@$_) }
          )
          : $_[0];
        (
            do {
                use Scalar::Util ();
                Scalar::Util::blessed($tmp) and $tmp->isa(q[Path::Tiny]);
            }
          )
          or croak(
"Type check failed in signature for change_parent_dir: %s should be %s",
            "\$_[0]", "Path"
          );
        push( @out, $tmp );

        # Parameter $_[1] (type: Path)
        $tmp = (
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed( $_[1] )
                      and $_[1]->isa(q[Path::Tiny]);
                }
            )
        ) ? $_[1] : (
            do {

                package Mite::Shim;
                defined( $_[1] ) and do {
                    ref( \$_[1] ) eq 'SCALAR'
                      or ref( \( my $val = $_[1] ) ) eq 'SCALAR';
                }
            }
          )
          ? scalar(
            do { local $_ = $_[1]; Path::Tiny::path($_) }
          )
          : (
            do {

                package Mite::Shim;
                defined( $_[1] ) && !ref( $_[1] )
                  or Scalar::Util::blessed( $_[1] ) && (
                    sub {
                        require overload;
                        overload::Overloaded( ref $_[0] or $_[0] )
                          and overload::Method( ( ref $_[0] or $_[0] ), $_[1] );
                    }
                )->( $_[1], q[""] );
            }
          )
          ? scalar(
            do { local $_ = $_[1]; Path::Tiny::path($_) }
          )
          : ( ( ref( $_[1] ) eq 'ARRAY' ) ) ? scalar(
            do { local $_ = $_[1]; Path::Tiny::path(@$_) }
          )
          : $_[1];
        (
            do {
                use Scalar::Util ();
                Scalar::Util::blessed($tmp) and $tmp->isa(q[Path::Tiny]);
            }
          )
          or croak(
"Type check failed in signature for change_parent_dir: %s should be %s",
            "\$_[1]", "Path"
          );
        push( @out, $tmp );

        # Parameter $_[2] (type: Path)
        $tmp = (
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed( $_[2] )
                      and $_[2]->isa(q[Path::Tiny]);
                }
            )
        ) ? $_[2] : (
            do {

                package Mite::Shim;
                defined( $_[2] ) and do {
                    ref( \$_[2] ) eq 'SCALAR'
                      or ref( \( my $val = $_[2] ) ) eq 'SCALAR';
                }
            }
          )
          ? scalar(
            do { local $_ = $_[2]; Path::Tiny::path($_) }
          )
          : (
            do {

                package Mite::Shim;
                defined( $_[2] ) && !ref( $_[2] )
                  or Scalar::Util::blessed( $_[2] ) && (
                    sub {
                        require overload;
                        overload::Overloaded( ref $_[0] or $_[0] )
                          and overload::Method( ( ref $_[0] or $_[0] ), $_[1] );
                    }
                )->( $_[2], q[""] );
            }
          )
          ? scalar(
            do { local $_ = $_[2]; Path::Tiny::path($_) }
          )
          : ( ( ref( $_[2] ) eq 'ARRAY' ) ) ? scalar(
            do { local $_ = $_[2]; Path::Tiny::path(@$_) }
          )
          : $_[2];
        (
            do {
                use Scalar::Util ();
                Scalar::Util::blessed($tmp) and $tmp->isa(q[Path::Tiny]);
            }
          )
          or croak(
"Type check failed in signature for change_parent_dir: %s should be %s",
            "\$_[2]", "Path"
          );
        push( @out, $tmp );

        return ( &$__NEXT__( @head, @out ) );
    };

    $SIGNATURE_FOR{"fix_pm_to_blib"} = sub {
        my $__NEXT__ = shift;

        my ( @out, %tmp, $tmp, $dtmp, @head );

        @_ == 3
          or croak(
            "Wrong number of parameters in signature for %s: %s, got %d",
            "fix_pm_to_blib", "expected exactly 3 parameters",
            scalar(@_)
          );

        @head = splice( @_, 0, 1 );

        # Parameter $head[0] (type: Defined)
        ( defined( $head[0] ) )
          or croak(
"Type check failed in signature for fix_pm_to_blib: %s should be %s",
            "\$_[0]", "Defined"
          );

        # Parameter $_[0] (type: Path)
        $tmp = (
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed( $_[0] )
                      and $_[0]->isa(q[Path::Tiny]);
                }
            )
        ) ? $_[0] : (
            do {

                package Mite::Shim;
                defined( $_[0] ) and do {
                    ref( \$_[0] ) eq 'SCALAR'
                      or ref( \( my $val = $_[0] ) ) eq 'SCALAR';
                }
            }
          )
          ? scalar(
            do { local $_ = $_[0]; Path::Tiny::path($_) }
          )
          : (
            do {

                package Mite::Shim;
                defined( $_[0] ) && !ref( $_[0] )
                  or Scalar::Util::blessed( $_[0] ) && (
                    sub {
                        require overload;
                        overload::Overloaded( ref $_[0] or $_[0] )
                          and overload::Method( ( ref $_[0] or $_[0] ), $_[1] );
                    }
                )->( $_[0], q[""] );
            }
          )
          ? scalar(
            do { local $_ = $_[0]; Path::Tiny::path($_) }
          )
          : ( ( ref( $_[0] ) eq 'ARRAY' ) ) ? scalar(
            do { local $_ = $_[0]; Path::Tiny::path(@$_) }
          )
          : $_[0];
        (
            do {
                use Scalar::Util ();
                Scalar::Util::blessed($tmp) and $tmp->isa(q[Path::Tiny]);
            }
          )
          or croak(
"Type check failed in signature for fix_pm_to_blib: %s should be %s",
            "\$_[1]", "Path"
          );
        push( @out, $tmp );

        # Parameter $_[1] (type: Path)
        $tmp = (
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed( $_[1] )
                      and $_[1]->isa(q[Path::Tiny]);
                }
            )
        ) ? $_[1] : (
            do {

                package Mite::Shim;
                defined( $_[1] ) and do {
                    ref( \$_[1] ) eq 'SCALAR'
                      or ref( \( my $val = $_[1] ) ) eq 'SCALAR';
                }
            }
          )
          ? scalar(
            do { local $_ = $_[1]; Path::Tiny::path($_) }
          )
          : (
            do {

                package Mite::Shim;
                defined( $_[1] ) && !ref( $_[1] )
                  or Scalar::Util::blessed( $_[1] ) && (
                    sub {
                        require overload;
                        overload::Overloaded( ref $_[0] or $_[0] )
                          and overload::Method( ( ref $_[0] or $_[0] ), $_[1] );
                    }
                )->( $_[1], q[""] );
            }
          )
          ? scalar(
            do { local $_ = $_[1]; Path::Tiny::path($_) }
          )
          : ( ( ref( $_[1] ) eq 'ARRAY' ) ) ? scalar(
            do { local $_ = $_[1]; Path::Tiny::path(@$_) }
          )
          : $_[1];
        (
            do {
                use Scalar::Util ();
                Scalar::Util::blessed($tmp) and $tmp->isa(q[Path::Tiny]);
            }
          )
          or croak(
"Type check failed in signature for fix_pm_to_blib: %s should be %s",
            "\$_[2]", "Path"
          );
        push( @out, $tmp );

        return ( &$__NEXT__( @head, @out ) );
    };

    1;
}
