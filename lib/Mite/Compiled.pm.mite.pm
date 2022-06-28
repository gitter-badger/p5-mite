{
package Mite::Compiled;
use strict;
use warnings;


sub new {
    my $class = shift;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $self  = bless {}, $class;
    my $args  = $meta->{HAS_BUILDARGS} ? $class->BUILDARGS( @_ ) : { ( @_ == 1 ) ? %{$_[0]} : @_ };
    my $no_build = delete $args->{__no_BUILD__};

    # Initialize attributes
    if ( exists($args->{q[file]}) ) { my $value = do { my $to_coerce = $args->{q[file]}; ((do { use Scalar::Util (); Scalar::Util::blessed($to_coerce) and $to_coerce->isa(q[Path::Tiny]) })) ? $to_coerce : (do { package Mite::Miteception; defined($to_coerce) and do { ref(\$to_coerce) eq 'SCALAR' or ref(\(my $val = $to_coerce)) eq 'SCALAR' } }) ? scalar(do { local $_ = $to_coerce; Path::Tiny::path($_) }) : $to_coerce }; (do { use Scalar::Util (); Scalar::Util::blessed($value) and $value->isa(q[Path::Tiny]) }) or require Carp && Carp::croak(q[Type check failed in constructor: file should be Path]); $self->{q[file]} = $value;  }
    if ( exists($args->{q[source]}) ) { (do { use Scalar::Util (); Scalar::Util::blessed($args->{q[source]}) and $args->{q[source]}->isa(q[Mite::Source]) }) or require Carp && Carp::croak(q[Type check failed in constructor: source should be InstanceOf["Mite::Source"]]); $self->{q[source]} = $args->{q[source]};  } else { require Carp; Carp::croak("Missing key in constructor: source") } require Scalar::Util && Scalar::Util::weaken($self->{q[source]});

    # Enforce strict constructor
    my @unknown = grep not( do { package Mite::Miteception; (defined and !ref and m{\A(?:(?:file|source))\z}) } ), keys %{$args}; @unknown and require Carp and Carp::croak("Unexpected keys in constructor: " . join(q[, ], sort @unknown));

    # Call BUILD methods
    !$no_build and @{$meta->{BUILD}||[]} and $self->BUILDALL($args);

    return $self;
}

sub BUILDALL {
    $_->(@_) for @{ $Mite::META{ref($_[0])}{BUILD} || [] };
}

sub __META__ {
    no strict 'refs';
    require mro;
    my $class = shift;
    my $linear_isa = mro::get_linear_isa( $class );
    return {
        BUILD => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::BUILD" } reverse @$linear_isa
        ],
        DEMOLISH => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::DEMOLISH" } reverse @$linear_isa
        ],
        HAS_BUILDARGS => $class->can('BUILDARGS'),
    };
}

my $__XS = !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

# Accessors for file
*file = sub { @_ > 1 ? require Carp && Carp::croak("file is a read-only attribute of @{[ref $_[0]]}") : ( exists($_[0]{q[file]}) ? $_[0]{q[file]} : ( $_[0]{q[file]} = do { my $default_value = do { my $to_coerce = do { our $__file_DEFAULT__; $__file_DEFAULT__->($_[0]) }; ((do { use Scalar::Util (); Scalar::Util::blessed($to_coerce) and $to_coerce->isa(q[Path::Tiny]) })) ? $to_coerce : (do { package Mite::Miteception; defined($to_coerce) and do { ref(\$to_coerce) eq 'SCALAR' or ref(\(my $val = $to_coerce)) eq 'SCALAR' } }) ? scalar(do { local $_ = $to_coerce; Path::Tiny::path($_) }) : $to_coerce }; (do { use Scalar::Util (); Scalar::Util::blessed($default_value) and $default_value->isa(q[Path::Tiny]) }) or do { require Carp; Carp::croak(q[Type check failed in default: file should be Path]) }; $default_value } ) ) };

# Accessors for source
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        getters => { q[source] => q[source] },
    );
}
else {
    *source = sub { @_ > 1 ? require Carp && Carp::croak("source is a read-only attribute of @{[ref $_[0]]}") : $_[0]{q[source]} };
}


1;
}