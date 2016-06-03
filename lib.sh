#!/usr/bin/env bash



###
# some bash library helpers by:
# @author Adam Eivy
# #url https://github.com/atomantic/dotfiles/blob/master/lib.sh
# *slightly altered*
###

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

function ok() {
    echo -e "$COL_GREEN[ok]$COL_RESET "$1
}

function bot() {
    echo -e "\n$COL_GREEN\[._.]/$COL_RESET - "$1
}

function running() {
    echo -en "$COL_YELLOW ⇒ $COL_RESET"$1"\n"
}

function action() {
    echo -e "\n$COL_YELLOW[action]:$COL_RESET\n ⇒ $1..."
}

function warn() {
    echo -e "$COL_YELLOW[warning]$COL_RESET "$1
}

function error() {
    echo -e "$COL_RED[error]$COL_RESET "$1
}

function symlinkifne {
    running "$1"

    if [[ -e $1 ]]; then
        # file exists
        if [[ -L $1 ]]; then
            # it's already a simlink (could have come from this project)
            echo -en '\tsimlink exists, skipped\t';ok
            return
        fi
        # backup file does not exist yet
        if [[ ! -e ~/.dotfiles_backup/$1 ]];then
            mv $1 ~/.dotfiles_backup/
            echo -en 'backed up saved...';
        fi
    fi
    # create the link
    ln -s ~/.dotfiles/$1 $1
    echo -en '\tlinked';ok
}


# Better unset, unsets all variables passed as names in `args`.
# It's smart about and unsets iff they are defined.
function btr_unset() {
    local args=( "$@" )

    local target
    for target in "${args[@]}"; do
        [ -z "$(eval echo $(printf '${%s+x}' "$target"))" ] || unset "${opts[@]}" "$target"
    done
}

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
