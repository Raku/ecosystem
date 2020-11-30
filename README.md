# Overview

In this repository you'll find metadata for projects and modules. It's nice
to have that in a central place, apart from any specific module installer
for at least these three reasons:

* The set of people who want access to a module installer and the set of
  people who want access to module metadata are two different sets.

* If each installer has one set of metadata, that's more for everyone to
  keep updated. If it's in a central place, there's less work.

* The list of projects in the ecosystem is really an orthogonal to the
  installer, or even *an* installer. It might be used for other things,
  such as rendering the list at http://modules.raku.org

# Adding a module

To add a new module to the ecosystem, add the URL of the module's raw `META6.json`
file to the `META.list` file here in the ecosystem. Since the updates to
the ecosystem are announced in the #raku IRC channel, it is helpful
if you include the HTTP URL to your repo in your commit message so others
could easily view your new module, e.g.:

    git commit -m 'Add FooBar to ecosystem' -m 'See https://github.com/foobar/FooBar'

### Common Errors

Be sure to check your distro to avoid these common issues:

#### META6.json

* The correct filename is `META6.json`.
* Check that your META file contains valid JSON. To do so, you can use an online service,
such as [JSON Lint](http://jsonlint.com/).
* Ensure you have a `provides` section
that lists all the modules in your distribution, with correct filenames,
otherwise your module will not be installable.

For more information on the `META6.json` specification, see https://docs.raku.org/language/modules

There is a module [Test::META](https://github.com/jonathanstowe/Test-META) that can
help you detect some, but not all, of the common problems people have with `META6.json` files.

# Generated File

After the META.list file is processed, the list of modules is available at
[http://ecosystem-api.p6c.org/projects.json](http://ecosystem-api.p6c.org/projects.json) and any
errors encountered during processing at
[http://ecosystem-api.p6c.org/errors.json](http://ecosystem-api.p6c.org/errors.json). If your
module is missing after about an hour since its addition, there may be issues with your META6.json file.

The generated file contains invalid META6.json fragments. This is intentional and any software using it is
expected to handle errors gracefully.

# Module Take Over

It's a fact of life that some modules end up being abandoned, either due to authors losing interest,
moving on to other hobbies, or even dying. In such cases, it's possible you may be interested in
taking over the module, by replacing the version in the ecosystem with your own repo. To avoid accidental
take overs of modules that *aren't* abandoned, we try to follow this process before taking over:

* First, ensure what you're planning to do (e.g. copying the code and modifying it) is permitted by the
  module's license. Note that *lack* of a license does *not* mean you're free to take and modify the
  project and many jurisdictions give the authors of a work automatic implicit copyright.
* If possible, contact the author by email, CCing [perl6-users@perl.org](mailto:perl6-users@perl.org),
  asking them if they'd be willing to give you a commit bit to the repository or let you take over
  the module entirely. The email address is usually visible on user's GitHub profile.
* Try to contact the user by other means, as their GitHub notifications/emails may be disabled. Perhaps,
  there's a Twitter account with similar username.
* If attempts to contact the author fail, after four weeks the module can be taken over.

In short, try to contact the user by more ways than simply opening a PR in their repo and give them
enough time to have a chance to respond.

# LEGAL

The operation of the ecosystem requires that we copy, distribute, and possibly modify your META file (`META6.json`
or legacy `META.info`) in full or in part, or that we display information from that file on various websites
and other systems. We can't always guarantee proper attribution, that copies are accurate, or that modifications
do not inadvertently produce unintended results.

By submitting your module to the ecosystem, you agree that all entities involved in the operation of the ecosystem,
including its testing, mirroring, or archiving, as well as any package installers and auxiliary tools,
are allowed to copy, distribute, and modify your META file without limitation for the
purposes of making your module available to the Raku community&mdash;regardless of what license you choose for the
rest of your distribution. You also agree not to hold these entities liable for any damage or inconvenience caused
by the operation of the ecosystem or the failure to do so.
