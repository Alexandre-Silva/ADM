#!/bin/bash

####
# Imports
####
source "./lib.sh"
source "./package_manager.sh"

####
# CONFIGS and VARS
####
DOTFILES=${DOTFILES:-$(pwd)}
ADM_INSTALL_DIR=${ADM_INSTALL_DIR:-"/tmp/ADM"}

ret=()

####
# Funcs
####

adm_init() {
    pm_init
}

adm_find_setups() {
    local root_dir="$1"
    local setup
    ret=()

    for setup in $(find "$root_dir" -type f -name "*.setup.sh" | sort); do
        ret+=( "$setup" )
    done

    return 0
}
TO_BE_UNSET_f+=( "adm_find_setups" )


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
TO_BE_UNSET_f+=( "adm_extract_packages" )

# installs the provided `setup` file
adm_install_setup() {
    local setup=$1
    ret=()

    if [ ! -f "$setup" ]; then
        error "Non existent setup file: $setup"
        return 1
    fi

    if [ -f "$ADM_INSTALL_DIR" ] || [ -d "$ADM_INSTALL_DIR" ]; then
        error "$ADM_INSTALL_DIR already exists. Possibly previous installion did not exit safely."
        return 1;
    fi

    local curr_dir=$(pwd)
    mkdir "$ADM_INSTALL_DIR" && cd "$ADM_INSTALL_DIR"

    adm_extract_packages "$setup" || return 1
    pm_install "${ret[@]}"

    __run_function "st_install" "$setup"
    local ret_code=$?

    cd "$curr_dir"
    rm -rf "$ADM_INSTALL_DIR"
    return $ret_code
}
TO_BE_UNSET_f+=( "adm_install_setup" )

# finds all *.setup.sh files and installs the all `packages`
adm_install_setups() {
    ret=()

    adm_find_setups "$DOTFILES" && local setups=( ${ret[*]} )

    local setup
    for setup in "${setups[@]}"; do
        adm_install_setup "$setup"

        local ret_code=$?
        [ $ret_code -ne 0 ] && return $ret_code
    done

    return 0
}
TO_BE_UNSET_f+=( "adm_install_setups" )


# finds all *.setup.sh files and removes the all `packages`
adm_remove_setups() {
    ret=()

    adm_find_setups "$DOTFILES" && local setups=( ${ret[@]} )
    for setup in "${setups[@]}"; do
        adm_extract_packages "$setup" || return 0
        pm_remove "${ret[@]}"
    done

    return 0
}
TO_BE_UNSET_f+=( "adm_remove_setups" )

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
        __run_function "st_profile" "$setup" || return $?
    done

    return $?
}
TO_BE_UNSET_f+=( "adm_load_profile" )

adm_main() {
    local args=( "$@" )
    local command="${args[0]}"

    adm_find_setups "$DOTFILES" && local setups=( ${ret[*]} )

    case $command in
        install)
            pm_init

            if [ -n "${args[1]}" ]; then
                adm_install_setup "${args[1]}"
            else
                echo "No setup provided. Installing ALL of them."
                adm_install_setups
            fi
            ;;

        remove) pm_init; adm_remove_setups ;;
        profile) adm_load_profile "${args[1]}" ;;
        profiles) adm_load_profile "${setups[@]}" ;;

        *) error "Invalid commands: $command" ; return 1 ;;
    esac

    __clean_setup_env
    btr_unset_marked

    return 0
}
TO_BE_UNSET_f+=( "adm_main" )

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
TO_BE_UNSET_f+=( "__run_function" )

__clean_setup_env() {
    local vars=( "packages" )
    btr_unset "${bars[@]}"

    local functions=( "st_install" "st_profile" )
    btr_unset_f "${functions[@]}"
}
TO_BE_UNSET_f+=( "__clean_setup_env" )


####
# Main
####

# only exec if not beeing source by other script
# usually test.sh
echo "${BASH_SOURCE[@]}"
#if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then

[ -n "$ZSH_VERSION" ] && emulate bash
adm_main "$@"
[ -n "$ZSH_VERSION" ] && emulate zsh

#fi
