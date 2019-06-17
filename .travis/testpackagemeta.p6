use v6;
use LWP::Simple;
use JSON::Fast;
use Test;
use Test::META;

# If you want to debug locally, change a line in META.list, do a commit and then
# export TRAVIS_COMMIT_RANGE="HEAD^1...HEAD"
if ! defined %*ENV<TRAVIS_COMMIT_RANGE> {
    say "TRAVIS_COMMIT_RANGE wasn't set, don't know what to do.";
    exit 1;
}

my ($from, $to) = split("...", %*ENV<TRAVIS_COMMIT_RANGE>);

my $diffproc = run 'git', 'diff', '--no-color', '-p', '-U0', $from, $to, '--', 'META.list', :out;
my $metadiff = $diffproc.out.slurp;

if $metadiff ~~ /^\s*$/ {
  say "Nothing changed all fine.";
  exit;
}

# Skip first 5 lines of `gif diff` header, grep off empty lines
my @urls = $metadiff.lines[5..*].grep(/^\+/)».substr(1).grep(*.trim.chars != 0) or do {
    say "No packages have been added";
    exit;
};

my $amountUrls = @urls.end + 1;
say "$amountUrls packages were added";

plan $amountUrls;

my $lwp = LWP::Simple.new();

my $oldpwd = $*CWD;

my @failed = ();

for @urls -> $url {
  my $subres = subtest {
    my $sourcedir;
    my $res = lives-ok {
      my $resp = $lwp.get($url);
      if ! defined $resp {
          fail "$url not reachable";
          return;
      }

      my $meta = from-json($resp);

      if ! $meta<source-url> {
          fail "no source-url defined in META file";
          return;
      }

      $_ = $meta<name>;
      s:g/\:\:/__/;
      $sourcedir = $*TMPDIR ~ "/" ~ $_;
      my $sourceurl = $meta<source-url>;
      my $git = run "git", "clone", $sourceurl, $sourcedir;
      if $git.exitcode ne 0 {
        fail "Couldn't clone repo " ~ $sourceurl;
        return;
      }
    }, "Downloading $url";

    if $res {
        chdir($sourcedir);

        my $*DIST-DIR = $sourcedir.IO;
        my $*TEST-DIR //= Any;
        my $*META-FILE //= Any;
        meta-ok();
        if ( "Build.pm".IO.e or "Build.pm6".IO.e ) {
            my $build = run "zef", "build", ".";
            ok $build.exitcode eq 0, "Build done";
        }
        my $zef = run "zef", "install", "--depsonly", "--/build", ".";
        ok $zef.exitcode eq 0, "Able to install deps";
        $zef = run "zef", "test", ".";
        ok $zef.exitcode eq 0, "Package tests pass";

        rm-all($sourcedir.IO);
        chdir($oldpwd);
    }
  }, "Checking correctness of $url";

  if ! $subres {
      @failed.push: $url;
  }
}

say "\nThe following urls failed:\n" ~ @failed.join("\n");

# When we have a directory first recurse, then remove it
multi sub rm-all(IO::Path $path where :d) {
    .&rm-all for $path.dir;
    rmdir($path)
}

# Otherwise just remove the thing directly
multi sub rm-all(IO::Path $path) { $path.unlink }
