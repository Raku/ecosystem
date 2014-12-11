BEGIN { $ENV{HTTPS_CA_FILE} = '/etc/ssl/certs/ca-certificates.crt' }
use 5.010;
use JSON::XS;
use LWP::UserAgent;
use autodie;
system "wget https://raw.githubusercontent.com/perl6/ecosystem/master/META.list -O metalist";

my $OUTFILE = shift(@ARGV) // "/home/tjs/modules/public/projects.json";
my $ua = LWP::UserAgent->new;
$ua->timeout(10);

my @modules;

open my $fh, '<', "metalist";
for my $url (<$fh>) {
    chomp $url;
    eval {
        print "$url ";
        my $response = $ua->get($url);
        say $response->code;
        if ($response->is_success) {
            my $hash = decode_json $response->content;
            push @modules, $hash;
        }
    };
    warn $@ if $@;
}
close $fh;
#unlink 'metalist';

open($fh, '>', $OUTFILE);

print $fh encode_json \@modules;
close $fh;
