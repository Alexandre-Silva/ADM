#!/bin/bash

####
# Imports
####
if [[ -z ${ADM+x} ]]; then
    echo "ERROR: ADM var must be defined with the path to the ADM directory"
    return 1
fi

source "$ADM/lib.sh"
source "$ADM/package_manager.sh"

TO_BE_UNSET+=( "DIR" )
TO_BE_UNSET_f+=( "__import" )

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

adm_reset_setup() {
    ret=()
    pm_reset
}

adm_find_setups() {
    local root_dir="$1"
    local setup
    ret=()

    for setup in $(find "$(realpath "$root_dir")" -type f -name "*.setup.sh" | sort); do
        ret+=( "$setup" )
    done

    return 0
}
TO_BE_UNSET_f+=( "adm_find_setups" )


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

    __extract_var "$setup" "packages" || return 1
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
        __extract_var "$setup" "packages" || return 0
        pm_remove "${ret[@]}"
    done

    return 0
}
TO_BE_UNSET_f+=( "adm_remove_setups" )


adm_link() {
    local target="$1"
    local name="$2"

    if [[ ! -e "$target" ]]; then
        echo -e "$COL_RED $target: Target does not exist  $COL_RESET"
        return 1
    fi

    if [[ -e "$name" ]]; then
        if [[ -L "$name" ]]; then
            if [[ $(readlink "$name") == "$target" ]]; then
                echo -ne "$COL_CYAN"
                ln --no-target-directory --force --verbose --symbolic "$target" "$name"
                echo -ne "$COL_RESET"
            else
                echo -e "$COL_RED $name: File already exists $COL_RESET"
                return 1
            fi
        else
            echo -e "$COL_RED $name: File already exists $COL_RESET"
            return 1
        fi
    else # either `name` does not exist at all or is broken link
        echo -ne "$COL_GREEN"
        ln --no-target-directory --force --verbose --symbolic "$target" "$name"
        echo -ne "$COL_RESET"
    fi
    return 0
}
TO_BE_UNSET_f+=( "adm_link" )

# Creates the soft links specified in the `links` var of the `setups` files
adm_link_setup() {
    local setups=( "$@" )
    ret=()

    for setup in "${setups[@]}"; do
        __extract_var "$setup" "links" || return 1
        local links=( "${ret[@]}" )

        local i=0
        local j=1
        while [[ $i < "${#links[@]}" ]]; do
            adm_link "${links[$i]}" "${links[$j]}"

            (( i += 2 ))
            (( j = i + 1 ))
        done
    done

    return 0
}
TO_BE_UNSET_f+=( "adm_link_setup" )

adm_main() {
    local args=( "$@" )
    local command="${args[0]}"

    adm_find_setups "$DOTFILES" && local setups=( "${ret[*]}" )

    case $command in
        install)
            pm_init

            if [ -n "${args[1]}" ]; then
                adm_install_setup "$(realpath "${args[1]}")"
            else
                echo "No setup provided. Installing ALL of them."
                adm_install_setups
            fi
            ;;

        remove) pm_init; adm_remove_setups ;;
        profile) __run_function "st_profile" "$(realpath "${args[1]}")" ;;
        profiles) __run_function "st_profile" "${setups[@]}" ;;
        rc) __run_function "st_rc" "$(realpath "${args[1]}")" ;;
        rcs) __run_function "st_rc" "${setups[@]}" ;;
        link) adm_link_setup "$(realpath "${args[1]}")" ;;
        links) adm_link_setup "${setups[@]}" ;;
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
    local args=( "$@" )
    local func="$1"
    local setups=( "${args[@]:1}" )
    ret=()

    local setup
    for setup in "${setups[@]}"; do
        if [ ! -f "$setup" ]; then
            error "Cant run $func on non existent setup file: $setup"
            return 1
        fi

        __clean_setup_env

        # create an empty-ish stub function
        eval 'function '"$func"'() { warn "Target: $func not found in $setup" ; return 0 ;}'

        source "$setup"
        "$func" || return $?
    done

    return 0
}
TO_BE_UNSET_f+=( "__run_function" )

# Extracts a variable with a certain `name` of the `setup` file
__extract_var() {
    local setup="$1"
    local name="$2"
    ret=()

    __clean_setup_env
    source "$setup"

    # is `name` defined ?
    if $(eval '[[ -z ${'"$name"'+x} ]]'); then
        warn $(printf 'Var %s unset in %s' "$name" "$setup")
        set +x
        return 1
    fi

    ret+=( $(eval 'echo ${'"$name"'[@]}') )

    return 0
}
TO_BE_UNSET_f+=( "__extract_var" )


__clean_setup_env() {
    local vars=( "packages" )
    btr_unset "${bars[@]}"

    local functions=( "st_install" "st_profile" "st_rc")
    btr_unset_f "${functions[@]}"
}
TO_BE_UNSET_f+=( "__clean_setup_env" )


####
# Main
####

[ -n "$ZSH_VERSION" ] && emulate bash
adm_main "$@"
[ -n "$ZSH_VERSION" ] && emulate zsh
