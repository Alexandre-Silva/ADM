#!/usr/bin/env bash
###
# some bash library helpers based on:
# #url https://github.com/atomantic/dotfiles/blob/master/lib.sh
# @author Adam Eivy
###

## Consts and Vars

if [[ -z "$NO_COLOR" ]]; then
    # Colors
    ESC_SEQ="\x1b["
    COL_RESET=$ESC_SEQ"39;49;00m"
    COL_RED=$ESC_SEQ"31;01m"
    COL_GREEN=$ESC_SEQ"32;01m"
    COL_YELLOW=$ESC_SEQ"33;01m"
    COL_BLUE=$ESC_SEQ"34;01m"
    COL_MAGENTA=$ESC_SEQ"35;01m"
    COL_CYAN=$ESC_SEQ"36;01m"
fi

TO_BE_UNSET+=(
    "ESC_SEQ" "COL_RESET" "COL_RED" "COL_GREEN"
    "COL_YELLOW" "COL_BLUE" "COL_MAGENTA" "COL_CYAN"
)

function ok()      { echo -e "$COL_GREEN[ok]$COL_RESET "$1  ;}
function bot()     { echo -e "\n$COL_GREEN\[._.]/$COL_RESET - "$1 ;}
function running() { echo -en "$COL_YELLOW ⇒ $COL_RESET"$1"\n" ;}
function action()  { echo -e "\n$COL_YELLOW[action]:$COL_RESET\n ⇒ $1..." ;}
function info()    { echo -e "$COL_BLUE[info]$COL_RESET "$1 ;}
function warn()    { echo -e "$COL_YELLOW[warning]$COL_RESET "$1 ;}
function error()   { echo -e "$COL_RED[error]$COL_RESET "$1 ;}

TO_BE_UNSET_f+=(
    "ok" "bot" "running" "action" "info" "warn" "error"
)

# Returns 0 if function of name `func` is defined
# Works in bash and zsh
function is_function() {
    local func="$1"

    if [ -n "$ZSH_VERSION" ]; then
        if [[ "$(type -w $func)" = *function ]] ; then
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
        unset "$target"
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

#--------------------------------------------------------------------------------
# Shell compatibility functions between ZSH and BASH
#--------------------------------------------------------------------------------

# Registers $exit_cmd to be executed when exiting.
adm_sh_on_exit() {
    local exit_cmd="$1"

    if [ "$ZSH_VERSION" ]; then
        ADM_SH_ON_EXIT="${exit_cmd}"
        zshexit() { "${ADM_SH_ON_EXIT}"; }
        TO_BE_UNSET+=( 'ADM_SH_ON_EXIT' )

    elif [ "$BASH_VERSION" ]; then
        trap "$exit_cmd" EXIT     # POSIX

    else
        error "Unknown shell"
        exit 1
    fi
}

# Sets the shell (bash/zsh) such that adm can work on both shells
adm_sh_compat_mode_on() {
    if [ -n "${ZSH_VERSION:-}" ]; then set +o ksh_arrays +o sh_word_split; fi
}

# Sets the shell (bash/zsh) such that adm can work on both shells
adm_sh_compat_mode_off() {
    if [ -n "${ZSH_VERSION:-}" ]; then set -o ksh_arrays -o sh_word_split; fi
}

adm_sh_setopt() {
    if [ "$ZSH_VERSION" ]; then
        for opt in "$@"; do
            case "$opt" in
                +*) setopt "${opt#+}" ;;
                -*) unsetopt "${opt#-}" ;;
                *) error "$0: options must be in format +<optname> or -<optname>"
            esac
        done

    elif [ "$BASH_VERSION" ]; then
        for opt in "$@"; do
            case "$opt" in
                +*) shopt -s "${opt#+}" ;;
                -*) shopt -u "${opt#-}" ;;
                *) error "$0: options must be in format +<optname> or -<optname>"
            esac
        done

    else
        error "Unknown shell"
        exit 1
    fi
}

SHELL_OPT_STACK=()
adm_sh_setopt_push() {
    if [ "$ZSH_VERSION" ]; then
        for opt in "$@"; do
            case "$opt" in
                +*) unsetopt | grep "${opt#+}" &>/dev/null && SHELL_OPT_STACK+=( "$opt") ;;
                -*) setopt   | grep "${opt#-}" &>/dev/null && SHELL_OPT_STACK+=( "$opt") ;;
                *) error "$0: options must be in format +<optname> or -<optname>"
            esac
        done

    elif [ "$BASH_VERSION" ]; then
        for opt in "$@"; do
            case "$opt" in
                +*) shopt -q "${opt#+}" || SHELL_OPT_STACK+=( "$opt" ) ;;
                -*) shopt -q "${opt#-}" && SHELL_OPT_STACK+=( "$opt" ) ;;
                *) error "$0: options must be in format +<optname> or -<optname>"
            esac
        done

    else
        error "Unknown shell"
        exit 1
    fi

    adm_sh_setopt "$@"
}

adm_sh_setopt_pop() {
    adm_sh_setopt "${SHELL_OPT_STACK[@]}"
}
