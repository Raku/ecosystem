use v6;
use JSON::Tiny;

sub run-or-die($x) {
    run $x and die "Failed running '$x'"
}

my @modules;

my $fh = open('META.list');
for $fh.lines -> $url {
    run-or-die "wget $url";
    my $info = from-json(slurp('META.info'));
    @modules.push($info);
    say $info.perl;
    unlink 'META.info';
}

given open('projects.json', :w) {
    .say(to-json @modules);
    .close;
}

$fh.close;
