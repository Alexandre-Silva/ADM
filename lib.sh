#!/usr/bin/env bash
###
# some bash library helpers based on:
# #url https://github.com/atomantic/dotfiles/blob/master/lib.sh
# @author Adam Eivy
###

## Consts and Vars


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

# Returns 0 if function of name `func` is defined
# Works in bash and zsh
function is_function() {
    local func="$1"

    if [ -n "$ZSH_VERSION" ]; then
        if [ "$(type -w $func | cut -d ' ' -f 2)" = function ] ; then
            return 0
        fi

    else # assume BASH or equivalent
        if [ -n "$(type -t $func)" ] && [ "$(type -t $func)" = function ]; then
            return 0
        fi
    fi

    return 1
}
# not to be unset

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

    local target
    for target in "${args[@]}"; do
        is_function "$target" && unset -f "$target"
    done

}
# not to be unset

# calls btr_unset and btr_unset_f on the values marked to be unset
function btr_unset_marked() {
    btr_unset "${TO_BE_UNSET[@]}"
    btr_unset_f "${TO_BE_UNSET_f[@]}"

    btr_unset "TO_BE_UNSET" "TO_BE_UNSET_f"
}
TO_BE_UNSET_f+=( "btr_unset_marked" )

# Returns the lines which are in A but not in B. The (-) of set theory.
#
# @Usage: $(adm_not_in ...)
# @Param $1:A string were each line is a element
# @Param $2:B string were each line is a element
# @Returns: Trough stdout the different elements
function adm_not_in() {
    local a="$1"
    local b="$2"

    a=$(echo -ne $a | sort)
    b=$(echo -ne $b | sort)

    # http://stackoverflow.com/questions/18204904/fast-way-of-finding-lines-in-one-file-that-are-not-in-another
    diff --text --new-line-format="" --unchanged-line-format="" <(echo -n "$a") <(echo -n "$b") \
        | sed '/^$/d' # deletes empty lines
    return 0
}
