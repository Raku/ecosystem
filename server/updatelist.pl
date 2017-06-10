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
            my $name = $module->{name};
            if ($name =~ m{[/\\]} || $name =~ m{\.\.}) {
                die "Invalid module name '$name'";
            }
            _check_source_url($module, $url);
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

for my $basename ('projects.json',  'list') {
    File::AtomicWrite->write_file({
        file  => File::Spec->catfile($OUTDIR, $basename),
        input => \encode_json(\@modules),
        mode  => 0644,
    });
}
File::AtomicWrite->write_file({
    file  => File::Spec->catfile($OUTDIR, 'errors.json'),
    input => \JSON::XS->new->pretty(1)->encode(\@errors),
    mode  => 0644,
});

sub _check_source_url {
    my ($module, $meta_url) = @_;
    my $url;
    $url = $module->{support}{source}
      if    defined $module->{support}
        and defined $module->{support}{source};
    $url //= $module->{'source-url'};
    $url //= $module->{'repo-url'};
    length $url or die 'Empty source URL';

    # we only check GitHub URLs ATM
    return 1 unless $url =~ m{^ (?:http s?|git):// github\.com }x;

    my $mangled_url = $url;
    $meta_url =~ s{^https://raw\.githubusercontent\.com/}{https://github.com/};
    for ($mangled_url, $meta_url) {
        s{^ (?:http s?|git):// }{}x;
        $_ = join '/', grep length, (split '/')[0..2];
        s{\.git$}{};
    };
    return 1 if $url eq $meta_url; # easy way out

    $url =~ s{^git://}{https://};
    my $res = $ua->get($url);
    return 1 if $res->is_success;
    die "404 on source url (mangled version: $url): " . $res->status_line;
}

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
