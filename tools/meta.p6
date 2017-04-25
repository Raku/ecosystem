use WWW;
constant REPO = 'https://github.com/perl6/ecosystem/';
constant REPO-DIR = 'repo'.IO;
constant META-FILE = REPO-DIR.add: 'META.list';

REPO-DIR.e or run <git clone >, REPO, REPO-DIR.absolute;
chdir REPO-DIR;

loop {
    DateTime.now.say;
    run <git pull>;

    my @metas = META-FILE.lines;
    my $changed = 0;
    for @metas {
        next unless .ends-with: '/META.info';
        my $new = .substr(0, * - chars '/META.info') ~ '/META6.json';
        say "Trying to fetch $new";
        get($new) and ++$changed and $_ = $new and say "\t$new is good!";
    }

    if $changed {
        META-FILE.spurt: (|@metas, '').join: "\n";
        run <git commit>,
            '-m', '[automated commit] META.info→META6.json ('
                ~ $changed ~ ' URLs)',
            META-FILE.absolute;

        run <git pull --rebase>;
        run <git push>;
    }
    else {
        say "No dists changed";
    }
    say "Sleeping for half an hour";
    sleep 60*30;
}

=finish

Checks the ecosystem dist URLs to META.info files to see whether
META6.json alternative is available. If yes, swaps to META6.json
and commits the change to the repo.

Creates directory `repo` in current directory and clones repo there.
Performs the check every 30 minutes. Requires cached github
credentials that have commit bit to ecosystem repo.
