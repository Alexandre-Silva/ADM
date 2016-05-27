#!/bin/bash

####
# Imports
####
source "./lib.sh"
source "./package_manager.sh"

####
# CONFIGS and VARS
####
DOTFILES_ROOT=${DOTFILES_ROOT:-$(pwd)}

ret=()

####
# Funcs
####

adm_init() {
    pm_init
}

reset_setup() {
    ret=()
    pm_reset
}


find_setups() {
    ret=()
    local root_dir="$1"

    for setup in $(find "$root_dir" -type f -name "*.setup.sh" | sort ); do
        ret+=( "$setup" )
    done

    return 0
}


extract_packages() {
    local file="$1"
    ret=()

    unset packages

    source "$file"

    # is `packages` defined ?
    if [ -z ${packages+x} ]; then
        warn 'Var `packages` unset in '"$file"
        return 1
    fi

    for p in "${packages[@]}"; do
        ret+=( "$p" )
    done

    return 0
}

install_setups() {
    ret=()

    pm_init

    find_setups "$DOTFILES_ROOT" && local setups=( ${ret[*]} )

    for setup in "${setups[@]}"; do
        extract_packages "$setup" || return 0
        pm_install "${ret[@]}"
    done

    return 0
}

adm_main() {
    local args=( "$@" )
    local command="${args[0]}"
    #TODO check if commands exists and print usage

    case $command in
        install) install_setups ;;
        *) error "Invalid commands: $command" ;;
    esac
}

adm_main "$@"
