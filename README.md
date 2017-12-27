[![CircleCI](https://circleci.com/gh/Alexandre-Silva/ADM.svg?style=svg)](https://circleci.com/gh/Alexandre-Silva/ADM)

# Introduction

Tipically, one wants to keep track of the configuration files of used
applications (i.e. dotfiles). However, that's not all we want to keep track of.
Usually, we also have shell aliases, functions and environment variables. Also,
we also want keep track which packages these dotfiles and shell configurations
relate to. For example, when installing one's favorite text editor, we want to
also install the spell-checking tool and accompanying dictionary, some
auto-complete tool, code linters, etc. This ilustrates that for some *thing* we
can have a multitude of dotfiles, shell configurations, and packages to keep
track of.

After some research into other tools to perform dotfile management, I found that
these, typically, only handle soft-link management. That is not enough for
managing *all* that we want about our applications. Enter Alex's Dotfile Manager
(ADM).

ADM is a tool to support these mentioned functionalities. It was heavily
inspired by ArchLinux's PKGBUILD system. It is also:

* A one stop shop for dotfile management.
* Totally implemented in bash/zsh without other dependencies making it very
  portable.
* Configuration can be written in any shell script, thus simple things are easy
to express while still permitting complex things.

As a side, ADM was implemented such that it works both on Bash and ZSH. However,
if you setup.sh files use ZSH only features, don't expect your configurations to
work properly in BASH or vice-versa.


# Installation
1a - Download and save the repository.
```bash
git clone --recursive https://github.com/Alexandre-Silva/ADM.git
```
1b - Or as submodule inside a git repository.

```bash
git submodule add https://github.com/Alexandre-Silva/ADM.git
```
Then, to update other machines.
```bash
git submodule sync --recursive
git submodule update --recursive --init
```

2 - Add the following to your .profile or .zprofile
```bash
export ADM=/path/to/ADM
function adm() { source $ADM/adm.sh "$@" }
```

Note that 'adm.sh' must be sourced and not executed in a sub-shell. Otherwise,
most configurations (aliases, environment variables, functions, etc) would not
be exported to the current shell.

# Requirements
ADM is designed to work on both Bash and ZSH. The required are, respectively:

- Bash: version 4.0.0 or higher (required for associative arrays)
- ZSH: any version


# Usage

The core idea of ADM is the use of setup.sh files were all information about one
*thing* is located. This *thing* can be any unit of configuration. For example,
a configuration of emacs can have several .el (i.e. configuration) files, shell
aliases for launching it, the necessary packages to install emacs and other
tools such as jedi or JSLint. Additionally, some specific text font could be
used which is contained in some other setup.sh. To express all this, one would
only need to create a setup.sh similar to the example below.

```bash
# emacs.setup.sh
depends=( path/to/font.setup.sh )
packages=( apt:emacs apt:python-jedi )
links=( ~/dotfiles/emacs.el ~/.emacs.el )
st_profile() {
  EMACS_HOME=~/.emacs.d
}
st_rc() {
  alias ec='emacs'            # launch GUI
  alias et='emacs --terminal' # launch in terminal
}
```

Then, we can, for example, run
```bash
adm install emacs.setup.sh
```
to install the specified setup and its dependencies and associated softlinks.

## adm tool

TODO: intro

It's important to note that, the actual setups that will be installed includes
all those specified in the original command *and* their dependencies.
Furthermore, in each phase the setups are processed in an order which doesn't
break dependency chains. Unless circular dependencies exist, at which point you
should reconsider your life choices.

### install

```bash
adm install <path to setup> [<more setups> [...]]
```

the `install` command has three phases:

1. Install all packages specified in the `packages` variables of all setup
   files. (Equivalent to executing `adm pkgs <setup1> <setup2> ...`)
2. Runs the st_install function of the setups (if present)
3. Creates all necessary symlinks. (Equivalent to executing `adm link <setup1> <setup2> ...`)

### pkgs

```bash
adm pkgs <path to setup> [<more setups> [...]]
```

Install all packages specified by the setups using the appropriate package
manager. See the [packages variable section](#packages)

### link

```bash
adm install <path to setup> [<more setups> [...]]
```

Creates all symlinks specified by the setups. See the [links variable section](#links)

### profile

```bash
adm profile <path to setup> [<more setups> [...]]
```

For each setup, executes the `st_profile` function (if present).

### rc

```bash
adm rc <path to setup> [<more setups> [...]]
```

For each setup, executes the `st_rc` function (if present).

### list


```bash
adm rc [<path to file or dir> [...]]
```

Finds and lists all setup files in the provided directories of files. If no file
or dir is provided, the directory in environment variable `DOTFILES` is searched
instead.

## *.setup.sh

This files are all source into the current shell. Therefore, it's a good idea to
use some helper functions to prevent polluting the shell's environment.
TODO: put example

### depends
This var should contain a list of other setup.sh which must be processed. The
dependencies must be specified using absolute paths. Note that the ADM_DIR
helper variable can be, well, helpful.

### packages
The *packages* variable contains a list of packages to install. These can be
packages of any supported package manager (pacman, pip, npm, etc). As shown in
the example below, the variable is a bash array of packages names. ([Relevant
XKCD](https://xkcd.com/1654/))

Each package is specified in format \<environment\>:\<package name\>. The
environment is the space were the package name is to searched and not the actual
tool used to install the packege. For example, javascript packages can be
install using both *npm* or *yarn*. However, both tools share the same packages.

Note that for Arch Linux the tools used for installing AUR packages can also be
used to install packges from the normal arch repositories. But for clarity
reasons, the two separate environment prefixes are used, respectively, *pm:* and
*aur:*.

```bash
packages=(
    "pm:cmake"                # for ycmd
    "aur:vim-youcompleteme-git"

    # realgud-package
    "pip:trepan3k"            # better python debugger
    "pip:xdis"                # undeclared dependency for trepan3k

    # javascript
    "npm:tern"                # auto-complete
    "npm:js-beautify"         # code formatter
    "npm:eslint"              # linter
)
```


### links
The *links* var specifies the soft-links to be created. Each link is specified
using a pair of paths (like for *ln*), the first if the origninal file and the
second the path were to create the softlink.

```bash
links=(
  ~/dotfiles/file1 ~/.file1
  ~/dotfiles/file2 ~/.file2
  ~/dotfiles/file3 ~/.file3
  # <original file>  <path to softlink>
)
```

Don't forget that this is a bash/zsh array. Therefore, special care around
special characters and spaces should be taken. Furthermore, helper variables and
other bash/zsh logic can be used. For example:

```bash
links=()
for file in some/path/*.wildcard; do
    links+=( "$file" "other/path/$(basename "$file")" )
done
```

### install()
If a function named *install* is present it's executed when the adm command of
the same is called.

### st_profile(), st_rc()
Functions named *st\_profile*, and *st\_rc* are executed when the adm commands profile and rc, respectively.

### Helpers
When writing the setup.sh, there are a few quality of life features that can be used.

* *ADM\_DIR*: is a var containing the absolute path to the directory which contains the setup.sh being executed.
* *ADM\_FILE*: Like *ADM\_DIR* but for the setup.sh itself.

## Configurations

### Environment vars

- ADM\_INSTALL\_DIR: The folder in which setup.sh files are given to create
  temporary files and alike. Note that each setup file is given its own directory,
  e.g. foo.setup.sh uses $ADM\_INSTALL\_DIR/foo/

# Important notes
The prefix ```'adm_*'``` is reserved for internal ADM functions. However, you
will note that no function is exported to the shell environment even though
$ADM/adm.sh is sourced. This is because ADM dynamically unsets **all** functions
with that prefix.
