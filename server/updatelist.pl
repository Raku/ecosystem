BEGIN { $ENV{HTTPS_CA_FILE} = '/etc/ssl/certs/ca-certificates.crt' }
use 5.010;
use strict;
use warnings;
use JSON::MaybeXS;
use LWP::UserAgent;
use autodie;
use File::Spec;
use FindBin;
use File::AtomicWrite;
use Data::Dumper;

$|++;

my $OUTDIR = shift(@ARGV) // 'public/';
my $ua = LWP::UserAgent->new;
$ua->timeout(10);

my @modules;
my @errors;

open my $fh, '<', "$FindBin::Bin/../META.list";
for my $url (<$fh>) {
    chomp $url;
    next unless $url =~ /\S/;
    eval {
        print "$url ";
        my $response = $ua->get($url);
        say $response->code;
        if ($response->is_success) {
            my $module = decode_json $response->content;
            _normalize_module($module);
            my $name = $module->{name};
            if ($name =~ m{[/\\]} || $name =~ m{\.\.}) {
                die "Invalid module name '$name'";
            }
            open my $OUT, '>', File::Spec->catfile($OUTDIR, 'module', $name);
            print $OUT $response->content;
            close $OUT;
            push @modules, $module;
        }
        else {
            die 'Unsuccessful HTTP response: ' . $response->code
                . ' ' . $response->status_line;
        }
    };
    if ($@) {
        warn $@;
        push @errors, {
            url => $url,
            message => $@,
        };
    }
}
close $fh;

for my $basename ('projects1.json',  'list') {
    File::AtomicWrite->write_file({
        file  => File::Spec->catfile($OUTDIR, $basename),
        input => \encode_json(\@modules),
        mode  => 0644,
    });
}
File::AtomicWrite->write_file({
    file  => File::Spec->catfile($OUTDIR, 'errors.json'),
    input => \JSON::MaybeXS->new->pretty(1)->encode(\@errors),
    mode  => 0644,
});
downgrade(\@modules);
File::AtomicWrite->write_file({
    file  => File::Spec->catfile($OUTDIR, 'projects.json'),
    input => \encode_json(\@modules),
    mode  => 0644,
});

sub _normalize_module {
    my $module = shift;

    for ( qw/source-url  repo-url/ ) {
        next unless defined $module->{ $_ };
        _normalize_source_url( $module->{ $_ } );
    }

    _normalize_source_url( $module->{support}{source} )
        if defined $module->{support} and defined $module->{support}{source};
}
sub _normalize_source_url {
    for ( @_ ) {
        next unless defined;
        s/^\s+|\s+$//g;
        s{git\@github\.com:}{git://github.com/};
        $_ .= '.git' if m{^git://} and not m{\.git$};
        s{/$}{.git}  if m{^https?://};
    }
}

sub downgrade {
    my ($modules) = @_;

    foreach my $meta (grep { exists $_->{'meta-version'} and 0 < $_->{'meta-version'} } @$modules) {
        if (exists $meta->{depends} and ref $meta->{depends} eq 'HASH') {
            my $depends = $meta->{depends};
            delete $meta->{depends};
            $meta->{depends} = $depends->{runtime}{requires}
                if exists $depends->{runtime} and exists $depends->{runtime}{requires};
            $meta->{'build-depends'} = $depends->{build}{requires}
                if exists $depends->{build} and exists $depends->{build}{requires};
            $meta->{'test-depends'} = $depends->{test}{requires}
                if exists $depends->{test} and exists $depends->{test}{requires};
        }
        foreach (qw(depends build-depends test-depends)) {
            $meta->{$_} = [
                    grep {
                        $_ !~ /:from/
                    }
                    map {
                        (ref $_ and ref $_ eq 'HASH') ? $_->{name} : $_
                    }
                    grep {
                        defined $_
                    }
                    @{ $meta->{$_} }
                ]
                if exists $meta->{$_};
        }

        if (exists $meta->{builder}) {
            $meta->{'build-depends'} //= [];
            push @{ $meta->{'build-depends'} }, "Distribution::Builder::$meta->{builder}";
        }
    }
}
