use 5.010001;
use strict;
use warnings;

package Mite::Role;
use Mite::Miteception -all;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.009002';

use Path::Tiny;
use B ();

BEGIN {
    *_CONSTANTS_DEFLATE = "$]" >= 5.012 && "$]" < 5.020 ? sub(){1} : sub(){0};
};

has attributes =>
  is            => ro,
  isa           => HashRef[MiteAttribute],
  default       => sub { {} };

has name =>
  is            => ro,
  isa           => ValidClassName,
  required      => true;

has shim_name =>
  is            => rw,
  isa           => ValidClassName,
  lazy          => true,
  builder       => sub {
    my $self = shift;
    eval { $self->project->config->data->{shim} } // 'Mite::Shim'
  };

has source =>
  is            => rw,
  isa           => MiteSource,
  # avoid a circular dep with Mite::Source
  weak_ref      => true;

has roles =>
  is            => rw,
  isa           => ArrayRef[MiteRole],
  builder       => sub { [] };

has role_args =>
  is            => rw,
  isa           => Map[ NonEmptyStr, HashRef|Undef ],
  builder       => sub { {} };

has imported_functions =>
  is            => ro,
  isa           => Map[ MethodName, Str ],
  builder       => sub { {} };

has required_methods =>
  is            => ro,
  isa           => ArrayRef[MethodName],
  builder       => sub { [] };

has method_signatures =>
  is            => ro,
  isa           => Map[ MethodName, MiteSignature ],
  builder       => sub { {} };

sub BUILD {
    my $self = shift;

    require Type::Registry;
    my $reg = 'Type::Registry'->for_class( $self->name );
    $reg->add_types( 'Types::Standard' );
    $reg->add_types( 'Types::Common::Numeric' );
    $reg->add_types( 'Types::Common::String' );

    my $library = eval { $self->project->config->data->{types} };
    $reg->add_types( $library ) if $library;
}

sub _all_subs {
    my $self = shift;
    my $package = $self->name;
    no strict 'refs';
    my $stash = \%{"$package\::"};
    return {
        map {;
          # this is an ugly hack to populate the scalar slot of any globs, to
          # prevent perl from converting constants back into scalar refs in the
          # stash when they are used (perl 5.12 - 5.18). scalar slots on their own
          # aren't detectable through pure perl, so this seems like an acceptable
          # compromise.
          ${"${package}::${_}"} = ${"${package}::${_}"}
            if _CONSTANTS_DEFLATE;
          $_ => \&{"${package}::${_}"}
        }
        grep exists &{"${package}::${_}"},
        grep !/::\z/,
        keys %$stash
    };
}

sub _native_methods {
    my $self = shift;
    my %methods = %{ $self->_all_subs };

    require B;
    for my $name ( sort keys %methods ) {
        my $cv        = B::svref_2object( $methods{$name} );
        my $stashname = eval { $cv->GV->STASH->NAME };
        $stashname eq $self->name
            or $stashname eq 'constant'
            or delete $methods{$name};
    }

    delete $methods{meta};

    return \%methods;
}

sub methods_to_import_from_roles {
    my $self = shift;

    my %methods;
    for my $role ( @{ $self->roles } ) {
        my $role_args = $self->role_args->{ $role->name } || {};
        my %exported  = %{ $role->methods_to_export( $role_args ) };
        for my $name ( sort keys %exported ) {
            if ( defined $methods{$name} and  $methods{$name} ne $exported{$name} ) {
                croak "Conflict between %s and %s; %s must implement %s\n",
                    $methods{$name}, $exported{$name}, $self->name, $name;
            }
            else {
                $methods{$name} = $exported{$name};
            }
        }
    }

    # This package provides a native version of these
    # methods, so don't import.
    my %native = %{ $self->_native_methods };
    for my $name ( keys %native ) {
        delete $methods{$name};
    }

    # Never propagate
    delete $methods{$_} for qw(
        new
        DESTROY
        DOES
        does
        __META__
        __FINALIZE_APPLICATION__
    );

    return \%methods;
}

sub methods_to_export {
    my ( $self, $role_args ) = @_;

    my %methods = %{ $self->methods_to_import_from_roles };
    my %native  = %{ $self->_native_methods };
    my $package = $self->name;

    for my $name ( keys %native ) {
        $methods{$name} = "$package\::$name";
    }

    if ( my $excludes = $role_args->{'-excludes'} ) {
        for my $excluded ( ref( $excludes ) ? @$excludes : $excludes ) {
            delete $methods{$excluded};
        }
    }

    if ( my $alias = $role_args->{'-alias'} ) {
        for my $oldname ( sort keys %$alias ) {
            my $newname = $alias->{$oldname};
            $methods{$newname} = delete $methods{$oldname};
        }
    }

    return \%methods;
}

sub project {
    my $self = shift;

    return $self->source->project;
}

sub autolax {
    my $self = shift;

    return undef
        if not eval { $self->project->config->data->{autolax} };

    return $self->imported_functions->{STRICT}
        ? 'STRICT'
        : sprintf( '%s::STRICT', $self->project->config->data->{shim} );
}

signature_for add_attributes => (
    pos => [ slurpy ArrayRef[InstanceOf['Mite::Attribute']] ],
);

sub add_attributes {
    my ( $self, $attributes ) = @_;

    for my $attribute (@$attributes) {
        croak '%s already has an attribute called %s', $self->name, $attribute->_q_name
            if $self->attributes->{ $attribute->name };
        $self->attributes->{ $attribute->name } = $attribute;
    }

    return;
}

sub add_attribute {
    shift->add_attributes( @_ );
}

sub extend_attribute {
    my ($self, %attr_args) = ( shift, @_ );

    my $name = delete $attr_args{name};

    my $attr = $self->attributes->{$name};
    croak <<'ERROR', $name, $self->name unless $attr;
Could not find an attribute by the name of '%s' to extend in %s
ERROR

    if ( ref $attr_args{default} ) {
        $attr_args{_class_for_default} = $self;
    }

    $self->attributes->{$name} = $attr->clone(%attr_args);

    return;
}

sub add_method_signature {
    my ( $self, $method_name, %opts ) = @_;

    defined $self->method_signatures->{ $method_name }
        and croak( 'Method signature for %s already exists', $method_name );

    require Mite::Signature;
    $self->method_signatures->{ $method_name } = 'Mite::Signature'->new(
        method_name => $method_name,
        class => $self,
        %opts,
    );

    return;
}

sub add_role {
    my ( $self, $role ) = @_;

    my @attr = sort { $a->_order <=> $b->_order }
        values %{ $role->attributes };
    for my $attr ( @attr ) {
        $self->add_attribute( $attr )
            unless $self->attributes->{ $attr->name };
    }
    push @{ $self->roles }, $role;

    return;
}

sub add_roles_by_name {
    my ( $self, @names ) = @_;

    for my $name ( @names ) {
        my $role = $self->_get_role( $name );
        $self->add_role( $role );
    }

    return;
}

sub _get_role {
    my ( $self, $role_name ) = ( shift, @_ );

    my $project = $self->project;

    # See if it's already loaded
    my $role = $project->class($role_name);
    return $role if $role;

    # If not, try to load it
    eval "require $role_name;";
    if ( $INC{'Role/Tiny.pm'} and 'Role::Tiny'->is_role( $role_name ) ) {
        require Mite::Role::Tiny;
        $role = 'Mite::Role::Tiny'->inhale( $role_name );
    }
    else {
        $role = $project->class( $role_name, 'Mite::Role' );
    }
    return $role if $role;

    croak <<"ERROR", $role_name;
%s loaded but is not a recognized role. Mite roles and Role::Tiny
roles are the only supported roles. Sorry.
ERROR
}

sub add_required_methods {
    my $self = shift;

    push @{ $self->required_methods }, @_;

    return;
}

sub does_list {
    my $self = shift;
    return (
        $self->name,
        map( $_->does_list, @{ $self->roles } ),
    );
}

sub handle_extends_keyword {
    croak "Cannot extend roles";
}

sub handle_with_keyword {
    my $self = shift;

    while ( @_ ) {
        my $role = shift;
        my $args = Str->check( $_[0] ) ? undef : shift;
        $self->role_args->{$role} = $args;
        $self->add_roles_by_name( $role );
    }

    return;
}

for my $function ( qw/ carp croak confess / ) {
    no strict 'refs';
    *{"_function_for_$function"} = sub {
        my $self = shift;
        return $function
            if $self->imported_functions->{$function};
        return sprintf '%s::%s', $self->shim_name, $function
            if $self->shim_name;
        $function eq 'carp' ? 'warn sprintf' : 'die sprintf';
    };
}

sub compilation_stages {
    return qw(
        _compile_package
        _compile_pragmas
        _compile_uses_mite
        _compile_imported_functions
        _compile_with
        _compile_meta_method
        _compile_does
        _compile_composed_methods
        _compile_method_signatures
        _compile_callback
    );
}

sub compile {
    my $self = shift;

    my $code = join "\n",
        '{',
        map( $self->$_, $self->compilation_stages ),
        '1;',
        '}';

    #::diag $code if main->can('diag');
    return $code;
}

sub _compile_with {
    my $self = shift;

    my $roles = [ map $_->name, @{ $self->roles } ];
    return unless @$roles;

    my $source = $self->source;

    my $require_list = join "\n\t",
        map  { "require $_;" }
        # Don't require a role from the same source
        grep { !$source || !$source->has_class($_) }
        @$roles;

    my $version_tests = join "\n\t",
        map { sprintf '%s->VERSION( %s );',
            B::perlstring( $_ ),
            B::perlstring( $self->role_args->{$_}{'-version'} )
        }
        grep {
            $self->role_args->{$_}
            and $self->role_args->{$_}{'-version'}
        }
        @$roles;

    my $does_hash = join ", ", map sprintf( "%s => 1", B::perlstring($_) ), $self->does_list;

    return <<"END";
BEGIN {
    $require_list
    $version_tests
    our \%DOES = ( $does_hash );
}
END
}

sub _compile_does {
    my $self = shift;
    return <<'CODE'
# See UNIVERSAL
sub DOES {
    my ( $self, $role ) = @_;
    our %DOES;
    return $DOES{$role} if exists $DOES{$role};
    return 1 if $role eq __PACKAGE__;
    return $self->SUPER::DOES( $role );
}

# Alias for Moose/Moo-compatibility
sub does {
    shift->DOES( @_ );
}
CODE
}

sub _compile_composed_methods {
    my $self = shift;
    my $code = '';

    my %methods = %{ $self->methods_to_import_from_roles };
    keys %methods or return;

    $code .= "# Methods from roles\n";
    for my $name ( sort keys %methods ) {
        # Use goto to help namespace::autoclean recognize these as
        # not being imported methods.
        $code .= sprintf 'sub %s { goto \&%s; }' . "\n", $name, $methods{$name};
    }

    return $code;
}

sub _compile_imported_functions {
    my $self = shift;
    my %func = %{ $self->imported_functions } or return;

    return join "\n",
        'BEGIN {',
        ( $func{blessed} ? '    require Scalar::Util;' : () ),
        map(
            sprintf( '    *%s = \&%s;',  $_, $func{$_} ),
            sort keys %func
        ),
        '};',
        '';
}

sub _compile_package {
    my $self = shift;

    return "package @{[ $self->name ]};";
}

sub _compile_uses_mite {
    my $self = shift;

    my @code = sprintf 'our $USES_MITE = %s;', B::perlstring( ref($self) );
    if ( $self->shim_name ) {
        push @code, sprintf 'our $MITE_SHIM = %s;', B::perlstring( $self->shim_name );
    }
    push @code, sprintf 'our $MITE_VERSION = %s;', B::perlstring( $self->VERSION );
    join "\n", @code;
}

sub _compile_pragmas {
    my $self = shift;

    return <<'CODE';
use strict;
use warnings;
no warnings qw( once void );
CODE
}

sub _compile_meta_method {
    my $self = shift;

    my $code = <<'CODE';
# Gather metadata for constructor and destructor
sub __META__ {
    no strict 'refs';
    no warnings 'once';
    my $class      = shift; $class = ref($class) || $class;
    my $linear_isa = mro::get_linear_isa( $class );
    return {
        BUILD => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::BUILD" } reverse @$linear_isa
        ],
        DEMOLISH => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::DEMOLISH" } @$linear_isa
        ],
        HAS_BUILDARGS => $class->can('BUILDARGS'),
        HAS_FOREIGNBUILDARGS => $class->can('FOREIGNBUILDARGS'),
    };
}
CODE

    if ( eval { $self->project->config->data->{mop} } ) {
        $code .= sprintf <<'CODE', $self->project->config->data->{mop};

# Moose-compatibility method
sub meta {
    require %s;
    Moose::Util::find_meta( ref $_[0] or $_[0] );
}
CODE
    }

    return $code;
}

sub _compile_method_signatures {
    my $self = shift;
    my %sigs = %{ $self->method_signatures } or return;

    my $code = "# Method signatures\n"
        . "our \%SIGNATURE_FOR;\n\n";

    for my $name ( sort keys %sigs ) {
        my $guard = $sigs{$name}->locally_set_compiling_class( $self );

        $code .= sprintf(
            '$SIGNATURE_FOR{%s} = %s;' . "\n\n",
            B::perlstring( $name ),
            $sigs{$name}->_compile_coderef,
        );

        if ( my $support = $sigs{$name}->_compile_support ) {
            $code .= "$support\n\n";
        }
    }

    return $code;
}

sub _compile_callback {
    my $self = shift;

    my @required = @{ $self->required_methods };
    my %uniq; undef $uniq{$_} for @required;
    @required = sort keys %uniq;

    my $role_list = join q[, ], map B::perlstring( $_->name ), @{ $self->roles };
    my $shim = B::perlstring(
        $self->shim_name
        || eval { $self->project->config->data->{shim} }
        || 'Mite::Shim'
    );
    my $croak = $self->_function_for_croak;
    my $missing_methods = '()';
    if ( @required ) {
        require B;
        $missing_methods = sprintf 'grep( !$target->can($_), %s )',
            join q[, ], map B::perlstring( $_ ), @required;
    }

    return sprintf <<'CODE', $missing_methods, $croak, $role_list, $croak, $shim;
# Callback which classes consuming this role will call
sub __FINALIZE_APPLICATION__ {
    my ( $me, $target, $args ) = @_;
    our ( %%CONSUMERS, @METHOD_MODIFIERS );

    # Ensure a given target only consumes this role once.
    if ( exists $CONSUMERS{$target} ) {
        return;
    }
    $CONSUMERS{$target} = 1;

    my $type = do { no strict 'refs'; ${"$target\::USES_MITE"} };
    return if $type ne 'Mite::Class';

    my @missing_methods;
    @missing_methods = %s
        and %s( "$me requires $target to implement methods: " . join q[, ], @missing_methods );

    my @roles = ( %s );
    my %%nextargs = %%{ $args || {} };
    ( $nextargs{-indirect} ||= 0 )++;
    %s( "PANIC!" ) if $nextargs{-indirect} > 100;
    for my $role ( @roles ) {
        $role->__FINALIZE_APPLICATION__( $target, { %%nextargs } );
    }

    my $shim = %s;
    for my $modifier_rule ( @METHOD_MODIFIERS ) {
        my ( $modification, $names, $coderef ) = @$modifier_rule;
        $shim->$modification( $target, $names, $coderef );
    }

    return;
}
CODE
}

sub _mop_metaclass {
    return 'Moose::Meta::Role';
}

sub _mop_attribute_metaclass {
   return 'Moose::Meta::Role::Attribute';
}

sub _compile_mop {
    my $self = shift;

    return sprintf <<'CODE', $self->_mop_metaclass, B::perlstring( $self->name ), B::perlstring( $self->name ), $self->_compile_mop_attributes, $self->_compile_mop_required_methods, $self->_compile_mop_modifiers, $self->_compile_mop_methods, $self->_compile_mop_tc;
{
    my $PACKAGE = %s->initialize( %s, package => %s );

%s
%s
%s
%s
%s
}
CODE
}

sub _compile_mop_attributes {
    my $self = shift;

    my $code = '';

    my @attrs =
        sort { $a->_order <=> $b->_order }
        values %{ $self->attributes };
    if ( @attrs ) {
        $code .= "    my \%ATTR;\n\n";
        for my $attr ( @attrs ) {
            my $guard = $attr->locally_set_compiling_class( $self );
            my $attr_code = $attr->_compile_mop;
            $attr_code =~ s/^/    /gm;
            $code .= $attr_code . "\n";
        }
    }

    return $code;
}

sub _compile_mop_modifiers {
    my $self = shift;

    return sprintf <<'CODE', $self->name;
    for ( @%s::METHOD_MODIFIERS ) {
        my ( $type, $names, $code ) = @$_;
        $PACKAGE->${\"add_$type\_method_modifier"}( $_, $code ) for @$names;
    }
CODE
}

sub _compile_mop_methods {
    my $self = shift;
    return sprintf <<'CODE', $self->name, B::perlstring( $self->name );
    $PACKAGE->add_method(
        "meta" => Moose::Meta::Method::Meta->_new(
            name => "meta",
            body => \&%s::meta,
            package_name => %s,
        ),
    );
CODE
}

sub _compile_mop_required_methods {
    my $self = shift;
    my $code = '';
    if ( my @req = @{ $self->required_methods } ) {
        $code .= sprintf "    \$PACKAGE->add_required_methods( %s );\n", 
            join( q{, }, map B::perlstring( $_ ), @req ),
    }
    return $code;
}

sub _compile_mop_postamble {
    my $self = shift;
    my $code = '';
    for my $role ( @{ $self->roles } ) {
        $code .= sprintf "\$PACKAGE->add_role( Moose::Util::find_meta( %s ) );\n",
            B::perlstring( $role->name );
    }
    return $code;
}

sub _compile_mop_tc {
    return sprintf '    Moose::Util::TypeConstraints::find_or_create_does_type_constraint( %s );',
        B::perlstring( shift->name );
}

1;

__END__

=pod

=head1 NAME

Mite::Role - a role within a project

=head1 DESCRIPTION

NO USER SERVICABLE PARTS INSIDE.  This is a private class.

=head1 BUGS

Please report any bugs to L<https://github.com/tobyink/p5-mite/issues>.

=head1 AUTHOR

Michael G Schwern E<lt>mschwern@cpan.orgE<gt>.

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2014 by Michael G Schwern.

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
