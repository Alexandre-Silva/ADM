#!/usr/bin/env bash
###
# some bash library helpers based on:
# #url https://github.com/atomantic/dotfiles/blob/master/lib.sh
# @author Adam Eivy
###

## Consts and Vars

# Since ADM is to be sourced rather than being run in a subshell
# the global environment will be poluted with many unessessary
# functions and vars.
# The following two vars are lists of vars and functs to be unset
# after the normal functioning of the adm.sh script.
TO_BE_UNSET=()
TO_BE_UNSET_f=()


# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

TO_BE_UNSET+=(
    "ESC_SEQ" "COL_RESET" "COL_RED" "COL_GREEN"
    "COL_YELLOW" "COL_BLUE" "COL_MAGENTA" "COL_CYAN"
)

function ok()      { echo -e "$COL_GREEN[ok]$COL_RESET "$1  ;}
function bot()     { echo -e "\n$COL_GREEN\[._.]/$COL_RESET - "$1 ;}
function running() { echo -en "$COL_YELLOW ⇒ $COL_RESET"$1"\n" ;}
function action()  { echo -e "\n$COL_YELLOW[action]:$COL_RESET\n ⇒ $1..." ;}
function warn()    { echo -e "$COL_YELLOW[warning]$COL_RESET "$1 ;}
function error()   { echo -e "$COL_RED[error]$COL_RESET "$1 ;}

TO_BE_UNSET_f+=(
    "ok" "bot" "running" "action" "warn" "error"
)

# Better unset, unsets all variables passed as names in `args`.
# It's smart about and unsets iff they are defined.
function btr_unset() {
    local args=( "$@" )

    local target
    for target in "${args[@]}"; do
        [ -z "$(eval echo $(printf '${%s+x}' "$target"))" ] || unset "${opts[@]}" "$target"
    done
}
# not to be unset

# Like btr_unset but for functions
function btr_unset_f() {
    local args=( "$@" )

    if [ -n "$ZSH_VERSION" ]; then
        local target
        for target in "${args[@]}"; do
            if [ "$(type -w $target | cut -d ' ' -f 2)" = function ] ; then
                unset -f $target
            fi
        done

    else # assume BASH or equivalent
        local target
        for target in "${args[@]}"; do
            if [ -n "$(type -t $target)" ] && [ "$(type -t $target)" = function ]; then
                unset -f $target
            fi
        done
    fi
}
# not to be unset

# calls btr_unset and btr_unset_f on the values marked to be unset
function btr_unset_marked() {
    btr_unset "${TO_BE_UNSET[@]}"
    btr_unset_f "${TO_BE_UNSET_f[@]}"

    btr_unset "TO_BE_UNSET" "TO_BE_UNSET_f"
}
TO_BE_UNSET_f+=( "btr_unset_marked" )
