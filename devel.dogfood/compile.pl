#!/usr/bin/env perl
use v5.34;
use warnings;
use FindBin qw($Bin);
#use lib "$Bin/../lib";
use Path::Tiny qw(path);
use Mite::Class;
use Mite::Source;
use Mite::Project;
use Data::Dumper;

our $class;

sub has {
	my ( $names, %args ) = @_;
	$names = [$names] unless ref $names;
	
	if ( ref($args{isa}) ) {
		$args{type} = delete $args{isa};
	}
	
	for my $name ( @$names ) {
		if( my $is_extension = $name =~ s{^\+}{} ) {
			$class->extend_attribute(
					class   => $class,
					name    => $name,
					%args
			);
		}
		else {
			require Mite::Attribute;
			my $attribute = Mite::Attribute->new(
					class   => $class,
					name    => $name,
					%args
			);
			$class->add_attribute($attribute);
		}
	}

	return;
}

sub extends {
	my (@classes) = @_;
	$class->superclasses(\@classes);
	return;
}

sub compile {
	my ( $module, $in_file, $out_file ) = @_;
	$in_file  //= path sprintf 'lib/%s.pm', ( $module =~ s{::}{/}gr );
	$out_file //= path "$in_file.mite.pm";
	
	warn "Compile $module [$in_file -> $out_file]\n";
	
	my $code = $in_file->slurp;
	my ( $head, $tail ) = split '##-', $code;
	
	my $fake_module = "Fake::$module";
	$head =~ s/package /package Fake::/;
	$head =~ s/use Mite::Miteception/use Mite::Miteception '-Basic'/;

	my $source = Mite::Source->new(
		file => $in_file,
		project => Mite::Project->default,
	);
	$class = Mite::Class->new(
		name   => $fake_module,
		source => $source,
	);

	do {
		no strict 'refs';
		*{"$fake_module\::has"} = \&has;
		*{"$fake_module\::extends"} = \&extends;
		$fake_module->can('has') or die;
		$fake_module->can('extends') or die;
	};

	do {
		local $@;
		eval("$head; 1") or die($@);
	};

	# This is bad, but $class->project is undef, so
	# otherwise it can't find attributes at all.
	#
	no warnings 'redefine';
	local *Mite::Class::all_attributes = sub { shift->attributes };

	local $Type::Tiny::SafePackage = 'package Mite::Miteception;';
	my $compiled = $class->compile;
	$compiled =~ s/Fake:://;
	$compiled =~ s/use Mite::Miteception '-Basic'/use Mite::Miteception/;
	$out_file->spew( $compiled );
}

compile($_) for qw(
	Mite::App::Command
	Mite::App::Command::clean
	Mite::App::Command::compile
	Mite::App::Command::init
	Mite::Attribute
	Mite::Class
	Mite::Compiled
	Mite::Config
	Mite::MakeMaker
	Mite::Project
	Mite::Source
);
