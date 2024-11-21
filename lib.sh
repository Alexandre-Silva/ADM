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

function ok()      { echo -e "$COL_GREEN[ok]$COL_RESET "$@  ;}
function bot()     { echo -e "\n$COL_GREEN\[._.]/$COL_RESET - "$@ ;}
function running() { echo -en "$COL_YELLOW ⇒ $COL_RESET"$@"\n" ;}
function action()  { echo -e "\n$COL_YELLOW[action]:$COL_RESET\n ⇒ $1..." ;}
function info()    { echo -e "$COL_BLUE[info]$COL_RESET "$@ ;}
function warn()    { echo -e "$COL_YELLOW[warning]$COL_RESET "$@ ;}
function error()   { echo -e "$COL_RED[error]$COL_RESET "$@ ;}

TO_BE_UNSET_f+=(
    "ok" "bot" "running" "action" "info" "warn" "error"
)

# Returns 0 if function of name `func` is defined
# Works in bash and zsh
if [ -n "$ZSH_VERSION" ]; then
  function is_function() {
      local func="$1"
      if [[ "$(type -w $func)" = *function ]] ; then
          return 0
      fi
      return 1
  }
else
  function is_function() {
      local func="$1"

      if [ -n "$(type -t $func)" ] && [ "$(type -t $func)" = function ]; then
          return 0
      fi
      return 1
  }
fi
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

    return 0
}
# not to be unset

#--------------------------------------------------------------------------------
# Shell compatibility functions between ZSH and BASH
#--------------------------------------------------------------------------------

# Sets the shell (bash/zsh) such that adm can work on both shells
adm_sh_compat_mode_on() {
    if [ -n "${ZSH_VERSION:-}" ]; then adm_sh_shopt_push +ksharrays +shwordsplit; fi
}

# Sets the shell (bash/zsh) such that adm can work on both shells
adm_sh_compat_mode_off() {
    if [ -n "${ZSH_VERSION:-}" ]; then adm_sh_shopt_pop; emulate zsh; fi
}

adm_sh_shopt_bash() {
    for opt in "$@"; do
        local cmd=""

        # This handles the shell opts (e.g. errexit) for /bin/sh which need to
        # be handled by 'set' instead of bash specific options which are handled
        # by shopt
        case "$opt" in
            -errexit) cmd="set -o" ;;
            +errexit) cmd="set +o" ;;
            +*)       cmd="shopt -s" ;;
            -*)       cmd="shopt -u" ;;
        esac

        case "${opt}" in
            +*) ${cmd} "${opt#+}" ;;
            -*) ${cmd} "${opt#-}" ;;
            '') ;;
            *) error "$0: options must be in format +<optname> or -<optname>"
        esac
    done
}

adm_sh_shopt() {
    if [ "$ZSH_VERSION" ]; then
        for opt in "$@"; do
            case "$opt" in
                +*) setopt "${opt#+}" ;;
                -*) unsetopt "${opt#-}" ;;
                '') ;;
                *) error "$0: options must be in format +<optname> or -<optname>"
            esac
        done

    elif [ "$BASH_VERSION" ]; then
        adm_sh_shopt_bash "$@"

    else
        error "Unknown shell"
        exit 1
    fi
}

SHELL_OPT_STACK=()
adm_sh_shopt_push() {
    local opts_group=""

    if [ "$ZSH_VERSION" ]; then
        for opt in "$@"; do
            case "$opt" in
                +*) unsetopt | grep "${opt#+}" &>/dev/null && opts_group+=":-${opt#+}" ;;
                -*) setopt   | grep "${opt#-}" &>/dev/null && opts_group+=":+${opt#-}" ;;
                '') ;;
                *) error "$0: options must be in format +<optname> or -<optname>: $opt"
            esac
        done

    elif [ "$BASH_VERSION" ]; then
        for opt in "$@"; do
            case "$opt" in
                +*) shopt -q "${opt#+}" || opts_group+=":$opt" ;;
                -*) shopt -q "${opt#-}" && opts_group+=":$opt" ;;
                '') ;;
                *) error "$0: options must be in format +<optname> or -<optname>"
            esac
        done

    else
        error "Unknown shell"
        exit 1
    fi

    if [ -z "${opts_group}" ]; then
        opts_group=":_"
    fi

    SHELL_OPT_STACK+=( "${opts_group}" )
    adm_sh_shopt "$@"
}

adm_sh_shopt_pop() {
    local opts_group="${SHELL_OPT_STACK[-1]}"

    if   [ "$ZSH_VERSION" ];  then unset 'SHELL_OPT_STACK[${#SHELL_OPT_STACK[@]}-1]'
    elif [ "$BASH_VERSION" ]; then unset 'SHELL_OPT_STACK[${#SHELL_OPT_STACK[@]}-1]'
    else                      error "Unknown shell"; exit 1
    fi

    if   [ "$ZSH_VERSION" ];  then local opts=("${(@s/:/)opts_group}")
    elif [ "$BASH_VERSION" ]; then IFS=':' read -a opts <<< "${opts_group}";
    else                      error "Unknown shell"; exit 1
    fi

    if [ "${opts[1]}" != "_" ]; then
        adm_sh_shopt "${opts[@]}"
    fi
}


adm_sh_shopt_push_zsh() {
    if [ "$ZSH_VERSION" ]; then
        adm_sh_shopt_push "$@"
    fi
}

adm_sh_shopt_pop_zsh() {
    if [ "$ZSH_VERSION" ]; then
        adm_sh_shopt_pop "$@"
    fi
}
