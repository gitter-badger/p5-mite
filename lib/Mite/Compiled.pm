use 5.010001;
use strict;
use warnings;

package Mite::Compiled;
use Mite::Miteception;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001003';

use Path::Tiny;

# Don't load Mite::Source else it will go circular

has file =>
  is            => ro,
  isa           => Path->no_coercions->plus_coercions(Str, 'Path::Tiny::path($_)'),
  coerce        => true,
  lazy          => true,
  default       => sub {
      my $self = shift;
      return $self->_source_file2compiled_file( $self->source->file );
  };

has source =>
  is            => ro,
  isa           => InstanceOf['Mite::Source'],
  # avoid a circular dep with Mite::Source
  weak_ref      => true,
  required      => true;

##-

sub compile {
    my $self = shift;

    my $code;
    for my $class (values %{$self->classes}) {

        # Only supported by Type::Tiny 1.013_001 but no harm
        # in doing this anyway.
        local $Type::Tiny::SafePackage = sprintf 'package %s;',
            eval { $self->source->project->config->data->{shim} }
            // do { $class->name . '::__SAFE_NAMESPACE__' };

        $code .= $class->compile;
    }

    my $tidied;
    eval {
        my $flag;
        if ( $self->source->project->config->should_tidy ) {
            $flag = Perl::Tidy::perltidy(
                source      => \$code,
                destination => \$tidied,
                argv        => [],
            );
        }
        !$flag;
    } and length($tidied) and ( $code = $tidied );

    return $code;
}

sub write {
    my $self = shift;

    return $self->file->spew_utf8($self->compile);
}

sub remove {
    my $self = shift;

    return $self->file->remove;
}

sub classes {
    my $self = shift;

    return $self->source->classes;
}

sub _source_file2compiled_file {
    state $sig = sig_pos( Object, Defined );
    my ( $self, $source_file ) = &$sig;

    # Changes here must be coordinated with Mite.pm
    return $source_file . '.mite.pm';
}

1;

__END__

=pod

=head1 NAME

Mite::Compiled - The extra class file written by Mite.

=head1 SYNOPSIS

    use Mite::Compiled;
    my $compiled = Mite::Compiled->new( source => $source );

=head1 DESCRIPTION

NO USER SERVICABLE PARTS INSIDE.  This is a private class.

Represents the extra file written by Mite containing the compiled code.

There is a one-to-one mapping between a source file and a compiled
file, but there can be many Mite classes in one file.  Mite::Compiled
manages the compliation and ensures classes don't write over each
other.

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
