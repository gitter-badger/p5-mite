package Mite::Source;

=head1 NAME

Mite::Source - Representing the human written .pm file.

=head1 SYNOPSIS

    use Mite::Source;
    my $source = Mite::Source->new( file => $pm_filename );

=head1 DESCRIPTION

Represents a .pm file, written by a human, which uses Mite.

It is responsible for information about the source file.

* The Mite classes contained in the source.
* The compiled Mite file associated with it.

It delegates most work to other classes.

This object is necessary because there can be multiple Mite classes in
one source file.

=head1 SEE ALSO

L<Mite::Class>, L<Mite::Compiled>, L<Mite::Project>

=cut

use v5.10;
use Mouse;

use Mite::Compiled;
use Mite::Class;
use Method::Signatures;

use Mouse::Util::TypeConstraints;
class_type 'Path::Tiny';

has file =>
  is            => 'ro',
  isa           => 'Str|Path::Tiny',
  required      => 1;

has classes =>
  is            => 'ro',
  isa           => 'HashRef[Mite::Class]',
  default       => sub { {} };

has compiled =>
  is            => 'ro',
  isa           => 'Mite::Compiled',
  lazy          => 1,
  default       => method {
      return Mite::Compiled->new( source => $self );
  };

method compile() {
    return $self->compiled->compile();
}

method class_for($class) {
    return $self->classes->{$class} ||= Mite::Class->new(
        name    => $class
    );
}

1;
