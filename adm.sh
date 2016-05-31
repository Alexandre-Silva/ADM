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
    __clean_setup_env

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

# installs the provided `setup` file
install_setup() {
    local setup=$1
    ret=()

    if [ ! -f "$setup" ]; then
        error "Cant install non existent setup file: $setup"
        return 1
    fi

    extract_packages "$setup" || return 0
    pm_install "${ret[@]}"

    run_function "install" "$setup"

    return $?
}

# finds all *.setup.sh files and installs the all `packages`
install_setups() {
    ret=()

    find_setups "$DOTFILES_ROOT" && local setups=( ${ret[*]} )

    for setup in "${setups[@]}"; do
        install_setup "$setup"

        local ret_code=$?
        [ $ret_code -ne 0 ] && return $ret_code
    done

    return 0
}

# finds all *.setup.sh files and removes the all `packages`
remove_setups() {
    ret=()

    find_setups "$DOTFILES_ROOT" && local setups=( ${ret[@]} )
    for setup in "${setups[@]}"; do
        extract_packages "$setup" || return 0
        pm_remove "${ret[@]}"
    done

    return 0
}

# runs a `func` from the given `setup` file
run_function() {
    local func="$1"
    local setup="$2"
    ret=()
    __clean_setup_env

    if [ ! -f "$setup" ]; then
        error "Cant run $func of non existent setup file: $setup"
        return 1
    fi

    source "$setup"

    "$func"

    return $?
}

adm_main() {
    local args=( "$@" )
    local command="${args[0]}"

    pm_init

    case $command in
        install)
            if [ -n "${args[1]}" ]; then
                install_setup "${args[1]}"
            else
                echo "No setup provided. Installing ALL of them."
                install_setups
            fi
            ;;

        remove) remove_setups ;;

        *) error "Invalid commands: $command" ;;
    esac
}

####
# Private Funcs
####
__clean_setup_env() {
    packages=()
    install(){ return 0; }
}


####
# Main
####
adm_main "$@"
