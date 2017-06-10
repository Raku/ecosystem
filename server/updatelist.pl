BEGIN { $ENV{HTTPS_CA_FILE} = '/etc/ssl/certs/ca-certificates.crt' }
use 5.010;
use strict;
use warnings;
use JSON::XS;
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
            push @modules, $module;
            my $name = $module->{name};
            if ($name =~ m{[/\\]} || $name =~ m{\.\.}) {
                die "Invalid module name '$name'";
            }
            open my $OUT, '>', File::Spec->catfile($OUTDIR, 'module', $name);
            print $OUT $response->content;
            close $OUT;
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

for my $basename ('projects.json',  'list') {
    File::AtomicWrite->write_file({
        file  => File::Spec->catfile($OUTDIR, $basename),
        input => \encode_json(\@modules),
    });
}
File::AtomicWrite->write_file({
    file  => File::Spec->catfile($OUTDIR, 'errors.json'),
    input => \JSON::XS->new->pretty(1)->encode(\@errors),
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
