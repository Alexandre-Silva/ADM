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
# Mark funcs defined inside ADM to be deleted
####
old_env_f=$(mktemp)

# store func names
typeset -f | awk '/ \(\) {?$/ && !/^main / {print $1}' >$old_env_f

# dynamically adds functions of name 'adm_*' to TO_BE_UNSET_f
while IFS='' read -r func_name || [[ -n "$var_name" ]]; do
    if [[ "$func_name" =~ ^adm_.* ]]; then
        TO_BE_UNSET_f+=( "$func_name" )
    fi
done < <(cat "${old_env_f}")

rm -f $old_env_f


####
# Main
####

if [ -n "${ZSH_VERSION:-}" ]; then emulate bash ; fi
adm_main "$@"
if [ -n "${ZSH_VERSION:-}" ]; then emulate zsh ; fi
