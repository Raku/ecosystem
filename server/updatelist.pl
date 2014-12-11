BEGIN { $ENV{HTTPS_CA_FILE} = '/etc/ssl/certs/ca-certificates.crt' }
use 5.010;
use JSON::XS;
use File::Slurp 'slurp';
use LWP::Simple;
use autodie;
system "wget https://raw.githubusercontent.com/perl6/ecosystem/master/META.list -O metalist";

my $OUTFILE = shift(@ARGV) // "/home/tjs/modules/public/projects.json";

my @modules;

open my $fh, '<', "metalist";
for(<$fh>) {
    chomp;
    eval {
        print "$_ ";
        say getstore($_, 'tmp');
        my $hash = decode_json slurp 'tmp';
        push @modules, $hash;
    };
    unlink 'tmp' if -e 'tmp';
}
close $fh;
#unlink 'metalist';

open($fh, '>', $OUTFILE);

print $fh encode_json \@modules;
close $fh;
