package modules;
use Dancer ':syntax';
use File::Slurp 'slurp';
use Data::Dump;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/list' => sub {
    redirect 'projects.json';
};

get '/module/:name' => sub {
    my $mod = params->{name};
    $mod =~ s/;/::/g;
    my $list = from_json slurp '/home/tjs/modules/public/projects.json';
    for (@$list) {
        debug Data::Dump::dump($_->{name});
        if ($_->{name} eq $mod) {
            return to_json $_;
        }
    }
    return "$mod not found";
};

true;
