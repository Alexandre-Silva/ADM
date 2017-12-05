# Introduction

# Quick-Start

# Installation
1) Download and save the repository.
```bash
git clone --recursive https://github.com/Alexandre-Silva/ADM.git
```

2) Add the following to your .profile or .zprofile
```bash
export ADM=/path/to/ADM
function adm() { source $ADM/adm.sh "$@" }
```

Note that 'adm.sh' is sourced and not executed in a sub-shell. This is necessary since otherwise most configurations (aliases, environment variables, functions, etc) would not be exported to the current shell.

# Requirements
ADM is designed to work on both Bash and ZSH. The required are, respectively:

- Bash: version 4.0.0 or higher (required for associative arrays)
- ZSH: any version


# Usage

## adm tool
```bash
adm install
```
To install all *.config.sh in the directory and sub-directories.


## *.setup.sh

This files are all source into the current shell. Therefore, it's a good idea to
use some helper functions to prevent polluting the shell's environment.
TODO: put example

### depends
This var should contain a list of other setup.sh which must be processed. The
dependencies must be specified using absolute paths. Note that the ADM_DIR
helper var can be, well, helpful.

### packages
[Relevant XKCD](https://xkcd.com/1654/)

### links
TODO

### install()
If a function named *install* is present it's when the adm command of the same is called.

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
The prefix ```'adm_*'``` is reserved for internal ADM functions. However you will note that no function is exported to the shell environment even though $ADM/adm.sh is sourced. This is because internally, ADM dynamically unsets *all* functions with that prefix.
