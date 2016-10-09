
# Example install  instructions for module **Example::Module**

## Installation requirements

With a normal rakudo installation, you should have available one or
both of the installer tools:

- `zef`
- `panda`

`zef` is becoming the preferred tool because of more features
(including an uninstall function) and more active development, but
either tool should work fine for a first installation of a desired
module.  We'll use `zef` for the rest of the examples.

## Installation

```Perl6
zef install Example::Module
```

If the attempt shows that the module isn't found or available, ensure
your installer is current:

```Perl6
zef update
```

If you want to use the latest version in the git repository (or it's
not available in the Perl 6 ecosystem), clone it and then install it
from its local directory.  Here we assume the module is on Github in
location "https://github.com/jhancock/Example-Module-Perl6", but use
the Github clone instructions for the desired module. (Note the
repository name is usually not the exact name of the module as used in
Perl 6.)


```Perl6
git clone https://github.com/jhancock/Example-Module-Perl6.git
cd /path/to/cloned/repository/directory
zef install .
```
