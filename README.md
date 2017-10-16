# Installation
1) Dowload and save the repository.
```bash
git clone --recursive https://github.com/Alexandre-Silva/ADM.git
```

2) Add the following to your .profile or .zprofile
```bash
export ADM=/path/to/ADM
function adm() { source $ADM/adm.sh "$@" }
```

Note that 'adm.sh' is sourced and not executed in a subshell. This is necessary since otherwise most configurations (aliases, environment variables, functions, etc) would not be exported to the current shell.

# Usage

## adm tool
```bash
adm install
```
To install all *.config.sh in the directory and subdirectorys.


## *.setup.sh

This files are all source into the current shell. Thefore, it's a good idea to
use some helper functions to prevent polluting the shell's environment.
TODO: put example

## Configurations

### Envrionment vars

- ADM\_INSTALL\_DIR: The folder in which setup.sh files are given to create
  temporary files and alike. Note that each setup file is given its own dir,
  e.g. foo.setup.sh uses $ADM\_INSTALL\_DIR/foo/

# Important notes
The prefix ```'adm_*'``` is reserved for internal ADM functions. However you will note that no function is exported to the shell environment even tought $ADM/adm.sh is sourced. This is because internally, ADM dinamically unsets *all* functions with that prefix.
