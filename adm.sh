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

####
# Mark funcs defined inside ADM to be deleted
####
old_env_f=$(mktemp)

# store func names
typeset -f | awk '/ \(\) {?$/ && !/^main / {print $1}' >$old_env_f

# add funcs to TO_BE_UNSET_f
while IFS='' read -r func_name || [[ -n "$var_name" ]]; do
    if [[ "$func_name" =~ ^adm_.* ]]; then
        TO_BE_UNSET_f+=( "$func_name" )
    fi
done < "$old_env_f"

rm -f $old_env_f


####
# Main
####

[ -n "${ZSH_VERSION:-}" ] && emulate bash
adm_main "$@"
[ -n "${ZSH_VERSION:-}" ] && emulate zsh
