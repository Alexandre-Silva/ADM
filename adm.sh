#!/bin/bash

####
# Vars whre funcs and vars to be unset are stored
####
TO_BE_UNSET=( "DIR" "ret" )
TO_BE_UNSET_f=( "__import" )

####
# Imports
####
source "$ADM/lib.sh"
source "$ADM/pm.sh"
source "$ADM/core.sh"
source "$ADM/opts.sh"

####
# Main
####

if [ -n "${ZSH_VERSION:-}" ]; then emulate bash ; fi
adm_main "$@"
if [ -n "${ZSH_VERSION:-}" ]; then emulate zsh ; fi
