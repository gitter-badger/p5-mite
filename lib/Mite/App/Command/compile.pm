package Mite::App::Command::compile;

use feature ':5.10';
use Mouse;
use MouseX::Foreign;
extends qw(Mite::App::Command);

use Method::Signatures;
use Path::Tiny;
use Carp;

method abstract() {
    return "Make your code ready to run";
}

method opt_spec(...) {
    return(
      [ "search-mite-dir!" => "only look for .mite/ in the current directory",
        { default => 1 } ],
      [ "exit-if-no-mite-dir!" => "exit quietly if a .mite dir cannot be found",
        { default => 0 } ],
    );
}

method execute($opts, $args) {
    return if $self->should_exit_quietly($opts);

    my $config = Mite::Config->new(
        search_for_mite_dir => $opts->{search_mite_dir}
    );
    my $project = Mite::Project->new(
        config => $config
    );
    Mite::Project->set_default( $project );

    $project->add_mite_shim;
    $project->load_directory;
    $project->write_mites;

    return;
}

method project() {
    require Mite::Project;
    return Mite::Project->default;
}

method config() {
    return $self->project->config;
}

method should_exit_quietly($opts) {
    my $config = $self->config;

    return unless $opts->{exit_if_no_mite_dir};
    return 1 if !$opts->{search_mite_dir} && !$config->dir_has_mite(".");
    return 1 if !$config->find_mite_dir;
}

1;
