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

adm_reset_setup() {
    ret=()
    pm_reset
}


adm_find_setups() {
    ret=()
    local root_dir="$1"

    for setup in $(find "$root_dir" -type f -name "*.setup.sh" | sort ); do
        ret+=( "$setup" )
    done

    return 0
}


adm_extract_packages() {
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
adm_install_setup() {
    local setup=$1
    ret=()

    if [ ! -f "$setup" ]; then
        error "Non existent setup file: $setup"
        return 1
    fi

    extract_packages "$setup" || return 0
    adm_pm_install "${ret[@]}"

    __run_function "install" "$setup"

    return $?
}

# finds all *.setup.sh files and installs the all `packages`
adm_install_setups() {
    ret=()

    adm_find_setups "$DOTFILES_ROOT" && local setups=( ${ret[*]} )

    for setup in "${setups[@]}"; do
        adm_install_setup "$setup"

        local ret_code=$?
        [ $ret_code -ne 0 ] && return $ret_code
    done

    return 0
}


# finds all *.setup.sh files and removes the all `packages`
remove_setups() {
    ret=()

    adm_find_setups "$DOTFILES_ROOT" && local setups=( ${ret[@]} )
    for setup in "${setups[@]}"; do
        adm_extract_packages "$setup" || return 0
        pm_remove "${ret[@]}"
    done

    return 0
}

# runs the "profile" function of the provided `setups` files
adm_load_profile() {
    local setups=( "$@" )
    local setup
    ret=()

    for setup in "${setups[@]}"; do
        if [ ! -f "$setup" ]; then
            error "Non existent setup file: $setup"
            return 1
        fi
        __run_function "profile" "$setup" || return $?
    done

    return $?
}

adm_main() {
    local args=( "$@" )
    local command="${args[0]}"


    pm_init

    adm_find_setups "$DOTFILES_ROOT" && local setups=( ${ret[*]} )

    case $command in
        install)
            if [ -n "${args[1]}" ]; then
                adm_install_setup "${args[1]}"
            else
                echo "No setup provided. Installing ALL of them."
                adm_install_setups
            fi
            ;;

        remove) remove_setups ;;
        profile) adm_load_profile "${args[1]}" ;;
        profiles) adm_load_profile "${setups[@]}" ;;

        *) error "Invalid commands: $command" ;;
    esac

    return 0
}

####
# Private Funcs
####

# runs a `func` from the given `setup` file
__run_function() {
    local func="$1"
    local setup="$2"
    ret=()
    __clean_setup_env

    if [ ! -f "$setup" ]; then
        error "Cant run $func on non existent setup file: $setup"
        return 1
    fi

    source "$setup"

    "$func"

    return $?
}

__clean_setup_env() {
    unset packages
    unset -f install profile
}


####
# Main
####
[ -n "$ZSH_VERSION" ] && emulate bash
adm_main "$@"
[ -n "$ZSH_VERSION" ] && emulate zsh
