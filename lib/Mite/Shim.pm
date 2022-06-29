use 5.010001;
use strict;
use warnings;

package Mite::Shim;

# NOTE: Since the intention is to ship this file with a project, this file
# cannot have any non-core dependencies.

use strict;
use warnings;

sub _is_compiling {
    return $ENV{MITE_COMPILE} ? 1 : 0;
}

sub import {
    my $class = shift;
    my($caller, $file) = caller;

    # Turn on warnings and strict in the caller
    warnings->import;
    strict->import;

    if( _is_compiling() ) {
        require Mite::Project;
        Mite::Project->default->inject_mite_functions(
            package     => $caller,
            file        => $file,
        );
    }
    else {
        # Work around Test::Compile's tendency to 'use' modules.
        # Mite.pm won't stand for that.
        return if $ENV{TEST_COMPILE};

        # Changes to this filename must be coordinated with Mite::Compiled
        my $mite_file = $file . ".mite.pm";
        if( !-e $mite_file ) {
            require Carp;
            Carp::croak("Compiled Mite file ($mite_file) for $file is missing");
        }

        {
            local @INC = ('.', @INC);
            require $mite_file;
        }

        no strict 'refs';
        *{ $caller .'::has' } = sub {
            my $names = shift;
            $names = [$names] unless ref $names;
            my %args = @_;
            for my $name ( @$names ) {
               $name =~ s/^\+//;

               my $default = $args{default};
               if ( ref $default eq 'CODE' ) {
                   ${$caller .'::__'.$name.'_DEFAULT__'} = $default;
               }

               my $builder = $args{builder};
               if ( ref $builder eq 'CODE' ) {
                   *{"$caller\::_build_$name"} = $builder;
               }

               my $trigger = $args{trigger};
               if ( ref $trigger eq 'CODE' ) {
                   *{"$caller\::_trigger_$name"} = $trigger;
               }
            }

            return;
        };

        # Inject blank Mite routines
        for my $name (qw( extends )) {
            no strict 'refs';
            *{ $caller .'::'. $name } = sub {};
        }
    }
}

1;

__END__

=pod

=head1 NAME

Mite::Shim - shim to load .mite.pm files

=head1 DESCRIPTION

This is a copy of L<Mite::Shim>.

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
